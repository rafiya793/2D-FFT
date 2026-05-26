 /* visualize.c  --  Host-side visualization wrapper for Milestone 4
 * Reads fft_result_8.bin, fft_result_16.bin, fft_result_32.bin and produces
 * two PNG images per size (6 total):
 *   fft_output_8.png / fft_output_16.png / fft_output_32.png
 *   edges_output_8.png / edges_output_16.png / edges_output_32.png
 *
 * Compile on host:
 *   gcc visualize_test_2.c -o visualize_test_2 -lm
 * Run:
 *   ./visualize_test_2
 *
 * Requires: stb_image_write.h */

#define STB_IMAGE_WRITE_IMPLEMENTATION
#include "stb_image_write.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>

  // fftshift_2d
  //Swap quadrants of a 2D float array so the DC component moves to centre
static void fftshift_2d(float* data, int width, int height)
{
    int half_w = width / 2;
    int half_h = height / 2;

    float* tmp = (float*)malloc(width * height * sizeof(float));
    if (!tmp) return;

    for (int i = 0; i < height; i++) {
        for (int j = 0; j < width; j++) {
            int si = (i + half_h) % height;
            int sj = (j + half_w) % width;
            tmp[i * width + j] = data[si * width + sj];
        }
    }
    memcpy(data, tmp, width * height * sizeof(float));
    free(tmp);
}

//normalize_and_write_png
static void normalize_and_write_png(const char* filename, float* data,
    int width, int height, int do_fftshift)
{
    int n = width * height;

    if (do_fftshift) {
        fftshift_2d(data, width, height);
    }

    float max_val = 0.0f, min_val = 1e30f;
    for (int i = 0; i < n; i++) {
        if (data[i] > max_val) max_val = data[i];
        if (data[i] < min_val) min_val = data[i];
    }
    if ((max_val - min_val) < 1e-6f) max_val = min_val + 1.0f;

    if (!do_fftshift && min_val < max_val * 0.05f) {
        for (int i = 0; i < n; i++)
            if (data[i] < max_val * 0.05f) data[i] = 0.0f;
    }

    unsigned char* img = (unsigned char*)malloc(n);
    for (int i = 0; i < n; i++) {
        float v = (data[i] - min_val) / (max_val - min_val);
        if (v < 0.0f) v = 0.0f;
        if (v > 1.0f) v = 1.0f;
        img[i] = (unsigned char)(v * 255.0f);
    }

    int scale = 1;
    int big_w = width * scale;
    int big_h = height * scale;
    unsigned char* big = (unsigned char*)malloc(big_w * big_h);
    for (int y = 0; y < height; y++)
        for (int x = 0; x < width; x++)
            for (int dy = 0; dy < scale; dy++)
                for (int dx = 0; dx < scale; dx++)
                    big[(y * scale + dy) * big_w + (x * scale + dx)] = img[y * width + x];
    stbi_write_png(filename, big_w, big_h, 1, big, big_w);
    free(big);
    printf("  Written: %-20s (max intensity: %.4f)\n", filename, max_val);
    free(img);
}

//process_bin_file
static int process_bin_file(const char* bin_file,
    const char* fft_png,
    const char* edge_png)
{
    FILE* f = fopen(bin_file, "rb");
    if (!f) {
        fprintf(stderr, "  Cannot open %s  (was QEMU run yet?)\n", bin_file);
        return 0;
    }

    int width = 0, height = 0;
    if (fread(&width, sizeof(int), 1, f) != 1 ||
        fread(&height, sizeof(int), 1, f) != 1) {
        fprintf(stderr, "  Failed to read dimensions from %s\n", bin_file);
        fclose(f);
        return 0;
    }

    printf("  Reading %-26s  %dx%d ...\n", bin_file, width, height);

    int n = width * height;
    float* fft_mag = (float*)malloc(n * sizeof(float));
    float* edge_mag = (float*)malloc(n * sizeof(float));
    if (!fft_mag || !edge_mag) {
        fprintf(stderr, "  OOM allocating buffers for %s\n", bin_file);
        free(fft_mag);
        free(edge_mag);
        fclose(f);
        return 0;
    }

    if ((int)fread(fft_mag, sizeof(float), n, f) != n ||
        (int)fread(edge_mag, sizeof(float), n, f) != n) {
        fprintf(stderr, "  Truncated data in %s\n", bin_file);
        free(fft_mag);
        free(edge_mag);
        fclose(f);
        return 0;
    }
    fclose(f);

    normalize_and_write_png(fft_png, fft_mag, width, height, 1);
    normalize_and_write_png(edge_png, edge_mag, width, height, 0);

    free(fft_mag);
    free(edge_mag);
    return 1;
}

// main
int main(void)
{
    printf("============================================================\n");
    printf("  M4 Visualizer -- FFT + Edge PNGs for 8x8, 16x16, 32x32\n");
    printf("============================================================\n\n");

    int ok = 0;

    ok += process_bin_file("fft_result_8.bin", "fft_output_8.png", "edges_output_8.png");
    ok += process_bin_file("fft_result_16.bin", "fft_output_16.png", "edges_output_16.png");
    ok += process_bin_file("fft_result_32.bin", "fft_output_32.png", "edges_output_32.png");

    printf("\n============================================================\n");
    printf("  Done. %d/3 bin files processed successfully.\n", ok);
    printf("============================================================\n");
    return (ok == 3) ? 0 : 1;
}
