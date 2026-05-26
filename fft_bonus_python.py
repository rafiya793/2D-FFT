#!/usr/bin/env python3
""" live_edge.py
Strategy: split frame into top/bottom halves, process each in a separate
QEMU process in parallel, stitch results back together.
"""

import cv2
import numpy as np
import subprocess
import struct
import threading
import queue
import sys
import time

FFT_BINARY   = "./fft_service"
QEMU         = "qemu-riscv64"
QEMU_CPU     = "rv64,v=on"
FRAME_DIM    = 256          # full output resolution
HALF         = FRAME_DIM // 2   # each QEMU handles this many rows
CAMERA_INDEX = 0
DISPLAY_SIZE = 540

def launch_qemu():
    return subprocess.Popen(
        [QEMU, "-cpu", QEMU_CPU, FFT_BINARY],
        stdin=subprocess.PIPE,
        stdout=subprocess.PIPE,
        stderr=subprocess.DEVNULL,
    )

def recv_exact(proc, nbytes):
    buf = b""
    while len(buf) < nbytes:
        chunk = proc.stdout.read(nbytes - len(buf))
        if not chunk:
            raise EOFError("QEMU closed")
        buf += chunk
    return buf

def make_edge(lum):
    lo, hi = np.percentile(lum, 15.0), np.percentile(lum, 98.5)
    if hi - lo < 1e-6:
        hi = lo + 1e-6
    lum_norm  = np.clip((lum - lo) / (hi - lo), 0.0, 1.0)
    lum_sharp = np.power(lum_norm, 1.5)
    lum_u8    = (lum_sharp * 255.0).astype(np.uint8)
    return cv2.cvtColor(lum_u8, cv2.COLOR_GRAY2BGR)

def half_worker(proc, strip_h, strip_w, in_q, out_q):
    """
    Processes one horizontal strip.
    strip_h = HALF (128), strip_w = FRAME_DIM (256)
    """
    N      = strip_h          # 128 — each tile is 128x128
    nbytes = N * N * 4
    header = struct.pack('<i', N)

    try:
        while True:
            strip = in_q.get()   # shape: (HALF, FRAME_DIM) grayscale
            if strip is None:
                break

            # Split strip into left and right 128x128 tiles
            left  = strip[:, :N]           # (128, 128)
            right = strip[:, N:N+N]        # (128, 128)

            results = []
            for tile in (left, right):
                ch = tile.astype(np.float32) * (1.0 / 255.0)
                proc.stdin.write(header + ch.tobytes())
                proc.stdin.flush()
                raw    = recv_exact(proc, nbytes)
                result = np.frombuffer(raw, dtype=np.float32).reshape(N, N)
                results.append(result)

            # Stitch left+right back into full-width strip
            full_strip = np.hstack(results)   # (128, 256)

            if out_q.full():
                try:
                    out_q.get_nowait()
                except queue.Empty:
                    pass
            out_q.put(full_strip)

    except (EOFError, OSError, BrokenPipeError):
        pass

def open_camera():
    cap = cv2.VideoCapture(CAMERA_INDEX, cv2.CAP_V4L2)
    cap.set(cv2.CAP_PROP_FOURCC, cv2.VideoWriter_fourcc(*'MJPG'))
    cap.set(cv2.CAP_PROP_FPS, 30)
    cap.set(cv2.CAP_PROP_BUFFERSIZE, 2)
    for w, h in [(1280, 720), (640, 360)]:
        cap.set(cv2.CAP_PROP_FRAME_WIDTH,  w)
        cap.set(cv2.CAP_PROP_FRAME_HEIGHT, h)
        cap.read(); cap.read()
        ret, frame = cap.read()
        if ret and frame is not None:
            aw = int(cap.get(cv2.CAP_PROP_FRAME_WIDTH))
            ah = int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT))
            print(f"[host] Camera: {aw}×{ah} MJPG")
            return cap, aw, ah
    cap.release()
    return None, 0, 0

def main():
    import subprocess as sp
    sp.run(["v4l2-ctl", "--device=/dev/video0",
            "--set-fmt-video=width=1280,height=720,pixelformat=MJPG"],
           capture_output=True)

    # Two QEMU processes — one per half
    proc_top = launch_qemu()
    proc_bot = launch_qemu()
    print(f"[host] QEMU top PID {proc_top.pid} | bot PID {proc_bot.pid}")
    print(f"[host] Effective resolution: {FRAME_DIM}×{FRAME_DIM} "
          f"(2 × {HALF}×{FRAME_DIM} strips in parallel)")

    cap, actual_w, actual_h = open_camera()
    if cap is None:
        print("[host] ERROR: cannot open camera")
        proc_top.terminate(); proc_bot.terminate()
        sys.exit(1)

    # Queues for top and bottom workers
    in_top  = queue.Queue(maxsize=1)
    out_top = queue.Queue(maxsize=1)
    in_bot  = queue.Queue(maxsize=1)
    out_bot = queue.Queue(maxsize=1)

    t_top = threading.Thread(
        target=half_worker,
        args=(proc_top, HALF, FRAME_DIM, in_top, out_top),
        daemon=True)
    t_bot = threading.Thread(
        target=half_worker,
        args=(proc_bot, HALF, FRAME_DIM, in_bot, out_bot),
        daemon=True)
    t_top.start()
    t_bot.start()

    # Latest stitched halves
    last_top = np.zeros((HALF, FRAME_DIM), dtype=np.float32)
    last_bot = np.zeros((HALF, FRAME_DIM), dtype=np.float32)
    last_edge = np.zeros((DISPLAY_SIZE, DISPLAY_SIZE, 3), dtype=np.uint8)

    frame_count = 0
    t0 = time.time()
    print("[host] Press Q to quit")

    while True:
        ret, frame = cap.read()
        if not ret:
            continue

        # Convert to grayscale, resize to full 256x256
        gray  = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
        small = cv2.resize(gray, (FRAME_DIM, FRAME_DIM))
        small = cv2.GaussianBlur(small, (3, 3), 0)

        # Split into top and bottom halves
        top_strip = small[:HALF, :]    # rows 0..127
        bot_strip = small[HALF:, :]    # rows 128..255

        
        # 1. Only send a new frame when both workers are completely idle and ready.
        if in_top.empty() and in_bot.empty() and out_top.empty() and out_bot.empty():
            in_top.put(top_strip.copy())
            in_bot.put(bot_strip.copy())

        # 2. Only stitch and render when both top and bottom halves of the current frame are ready. This completely eliminates temporal skew.
        if not out_top.empty() and not out_bot.empty():
            last_top = out_top.get()
            last_bot = out_bot.get()

            full = np.vstack([last_top, last_bot])   # (256, 256)
            
            # 3. Smooth out the central white cross
            for offset, w_r in zip([126, 127, 128, 129], [0.2, 0.4, 0.6, 0.8]):
                w_l = 1.0 - w_r
                full[:, offset] = w_l * full[:, 125] + w_r * full[:, 130]
                full[offset, :] = w_l * full[125, :] + w_r * full[130, :]
                
            # 4.Remove the white outer frame 
            full[0:3, :] = 0.0
            full[253:256, :] = 0.0
            full[:, 0:3] = 0.0
            full[:, 253:256] = 0.0
            
            edge = make_edge(full)
            last_edge = cv2.resize(
                edge, (DISPLAY_SIZE, DISPLAY_SIZE),
                interpolation=cv2.INTER_CUBIC)

        # Display
        orig_disp = cv2.resize(frame, (DISPLAY_SIZE, DISPLAY_SIZE))
        disp_edge = last_edge.copy()

        cv2.putText(orig_disp, f"Original {actual_w}x{actual_h}",
                    (10, 30), cv2.FONT_HERSHEY_SIMPLEX, 0.65, (0,255,0), 2)
        cv2.putText(disp_edge, f"FFT Edges RISC-V {FRAME_DIM}x{FRAME_DIM}",
                    (10, 30), cv2.FONT_HERSHEY_SIMPLEX, 0.65, (0,180,255), 2)

        cv2.imshow("Live FFT Edge Detection",
                   np.hstack([orig_disp, disp_edge]))

        frame_count += 1
        if frame_count % 30 == 0:
            fps = frame_count / (time.time() - t0)
            print(f"\r[host] {frame_count} frames | {fps:.1f} fps display | "
                  f"FFT lag ~{1000/fps:.0f}ms",
                  end="", flush=True)

        if cv2.waitKey(1) & 0xFF == ord('q'):
            break

    in_top.put(None)
    in_bot.put(None)
    cap.release()
    cv2.destroyAllWindows()
    proc_top.terminate()
    proc_bot.terminate()
    print(f"\n[host] Done. {frame_count} frames.")

if __name__ == "__main__":
    main()
