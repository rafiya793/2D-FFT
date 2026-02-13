#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <stdbool.h>
#define STB_IMAGE_IMPLEMENTATION
#include "stb_image.h"

#define STB_IMAGE_WRITE_IMPLEMENTATION
#include "stb_image_write.h"

#include <time.h>


// Constants
#define PI 3.14159265358979323846f
#define EPSILON 0.001

// Forward declarations for helper functions
unsigned int reverse_bits(unsigned int x, int log_n);
void bit_reverse_array(float* x_real, float* x_imag, int n);
void fft_1d_iterative(float* x_real, float* x_imag, float* twiddle_real, float* twiddle_imag, int n);


// SECTION 1: MATH FUNCTIONS 

float my_sin(float x) {
    // Argument Reduction: Map x into [-pi, pi]
    x = fmod(x + PI, 2 * PI) - PI;
    
    float x2 = x * x;
    float result = x;
    float term = x;
    
    // x - x^3/3! + x^5/5! - x^7/7! + x^9/9!
    for (int i = 1; i <= 5; i++) {
        term *= -x2 / ((2*i) * (2*i + 1));
        result += term;
    }
    
    return result;
}

float my_cos(float x) {
    
    x = fmod(x + PI, 2 * PI) - PI;
    
    float x2 = x * x;
    float result = 1.0f;
    float term = 1.0f;
    
    // 1 - x^2/2! + x^4/4! - x^6/6! + x^8/8!
    for (int i = 1; i <= 5; i++) {
        term *= -x2 / ((2*i - 1) * (2*i));
        result += term;
    }
    
    return result;
}

float my_exp(float x) {
    
    if (x == 0.0f) return 1.0f;
    if (x < -20.0f) return 0.0f; 
    if (x > 20.0f) x = 20.0f;    

    
    bool negative = false;
    if (x < 0) {
        negative = true;
        x = -x;
    }

    
    float sum = 1.0f;
    float term = 1.0f;
    
    
    for (int i = 1; i <= 20; i++) {
        term *= x / i;
        sum += term;
        
        // if the term is tiny, stop early
        if (term < 1e-9f) break;
    }


    return negative ? (1.0f / sum) : sum;
}

int log2_int(int n) {
    if (n <= 0) return -1;
    int count = 0;
    while (n > 1) {
        n >>= 1;
        count++;
    }
    return count;
}


// SECTION 2: TWIDDLE FACTOR GENERATION

void twiddle_generator_internal(float* twiddle_real, float* twiddle_imag, int n, int inverse) {
    float sign = inverse ? 1.0f : -1.0f;
    int half_n = n / 2;

    for (int k = 0; k < half_n; k++) {
        float angle = sign * 2.0f * PI * k / n;
        
        twiddle_real[k] = my_cos(angle);
        twiddle_imag[k] = my_sin(angle); 
    }
}

void generate_twiddle_factors(float* twiddle_real, float* twiddle_imag, int n) {
    twiddle_generator_internal(twiddle_real, twiddle_imag, n, 0); // 0 for forward
}

void generate_inverse_twiddle_factors(float* twiddle_real, float* twiddle_imag, int n) {
    twiddle_generator_internal(twiddle_real, twiddle_imag, n, 1); // 1 for inverse
}


// SECTION 3: BIT REVERSAL AND REORDER

unsigned int reverse_bits(unsigned int x, int log_n) {
    unsigned int reversed = 0;
    for (int i = 0; i < log_n; i++) {
        if ((x >> i) & 1) {
            reversed |= (1 << (log_n - 1 - i));
        }
    }
    return reversed;
}

void bit_reverse_array(float* x_real, float* x_imag, int n) {
    int log_n = log2_int(n);
    float temp_r, temp_i;

    for (int i = 0; i < n; i++) {
        unsigned int j = reverse_bits(i, log_n);
        
        if (i < j) {
            temp_r = x_real[i];
            x_real[i] = x_real[j];
            x_real[j] = temp_r;

            temp_i = x_imag[i];
            x_imag[i] = x_imag[j];
            x_imag[j] = temp_i;
        }
    }
}


// SECTION 4: 1D FFT CORE LOGIC

void butterfly_iterative(float* x_real, float* x_imag, float* twiddle_real, float* twiddle_imag, int n) {
    for (int M = 2; M <= n; M *= 2) {
        int L = M / 2;
        int twiddle_step = n / M;
        
        for (int k = 0; k < n; k += M) {
            for (int j = 0; j < L; j++) {
                
                int index1 = k + j;
                int index2 = index1 + L;
                
                int twiddle_idx = j * twiddle_step;
                
                float W_r = twiddle_real[twiddle_idx];
                float W_i = twiddle_imag[twiddle_idx];
                
                float X1_r = x_real[index1];
                float X1_i = x_imag[index1];
                float X2_r = x_real[index2];
                float X2_i = x_imag[index2];
                
                //  T = X2 * W
                float T_r = X2_r * W_r - X2_i * W_i;
                float T_i = X2_r * W_i + X2_i * W_r;
                
                
                x_real[index1] = X1_r + T_r;
                x_imag[index1] = X1_i + T_i;
                
                x_real[index2] = X1_r - T_r;
                x_imag[index2] = X1_i - T_i;
            }
        }
    }
}

void fft_1d_iterative(float* x_real, float* x_imag, float* twiddle_real, float* twiddle_imag, int n) {
    bit_reverse_array(x_real, x_imag, n);
    butterfly_iterative(x_real, x_imag, twiddle_real, twiddle_imag, n);
}


void recursive_butterfly_core(float* x_real, float* x_imag, int offset, int n, int N_full, float* twiddle_real, float* twiddle_imag) {
    if (n <= 1) {
        return; 
    }

    int half_n = n / 2;
    
    // Divide and Recurse
    recursive_butterfly_core(x_real, x_imag, offset, half_n, N_full, twiddle_real, twiddle_imag);
    recursive_butterfly_core(x_real, x_imag, offset + half_n, half_n, N_full, twiddle_real, twiddle_imag);
    
    int twiddle_stride = N_full / n;
    
    for (int j = 0; j < half_n; j++) {
        int index1 = offset + j;
        int index2 = index1 + half_n;
        
        int twiddle_idx = j * twiddle_stride;

        float W_r = twiddle_real[twiddle_idx];
        float W_i = twiddle_imag[twiddle_idx];

        float A_r = x_real[index1];
        float A_i = x_imag[index1];
        float B_r = x_real[index2];
        float B_i = x_imag[index2];
        
        float T_r = B_r * W_r - B_i * W_i;
        float T_i = B_r * W_i + B_i * W_r;
        
        x_real[index1] = A_r + T_r;
        x_imag[index1] = A_i + T_i;
        
        x_real[index2] = A_r - T_r;
        x_imag[index2] = A_i - T_i;
    }
}

void butterfly_recursive(float* x_real, float* x_imag, float* twiddle_real, float* twiddle_imag, int n) {
    recursive_butterfly_core(x_real, x_imag, 0, n, n, twiddle_real, twiddle_imag);
}

void fft_1d_recursive (float* x_real, float* x_imag, float* twiddle_real, float* twiddle_imag, int n) {
    bit_reverse_array(x_real, x_imag, n);
    butterfly_recursive(x_real, x_imag, twiddle_real, twiddle_imag, n);
}


// SECTION 5: 2D FFT AND IFFT



 //Assuming for M1 , the matrices will be square (rows=cols).
 
void transpose(float** matrix, int rows, int cols) {
    
    if (rows == cols) {
        for (int i = 0; i < rows; i++) {
            for (int j = i + 1; j < cols; j++) {
                float temp = matrix[i][j];
                matrix[i][j] = matrix[j][i];
                matrix[j][i] = temp;
            }
        }
    } else {
    }
}


void fft_2d(float** x_real, float** x_imag, float* twiddle_real, float* twiddle_imag, int rows, int cols, bool test, bool inverse) {
    int max_dim = (rows > cols) ? rows : cols;
    
    
    if (inverse) {
        generate_inverse_twiddle_factors(twiddle_real, twiddle_imag, max_dim);
    } else {
        generate_twiddle_factors(twiddle_real, twiddle_imag, max_dim);
    }

    // -Apply 1D FFT to each Row 
    for (int i = 0; i < rows; i++) {
        fft_1d_iterative(x_real[i], x_imag[i], twiddle_real, twiddle_imag, cols);
    }

    
    // Transpose the real and imaginary matrices separately.
    transpose(x_real, rows, cols);
    transpose(x_imag, rows, cols);
    
    //  Apply 1D FFT to each Column (now rows) 
    int temp_rows = cols;
    int temp_cols = rows;

    for (int i = 0; i < temp_rows; i++) {
        fft_1d_iterative(x_real[i], x_imag[i], twiddle_real, twiddle_imag, temp_cols);
    }
    
    //  Transpose Back 
    transpose(x_real, temp_rows, temp_cols);
    transpose(x_imag, temp_rows, temp_cols);
}

void ifft_2d (float ** x_real, float** x_imag, float* twiddle_real, float* twiddle_imag, int rows, int cols, bool test) {
    fft_2d(x_real, x_imag, twiddle_real, twiddle_imag, rows, cols, test, true);

    float N_M = (float)rows * cols;
    for (int i = 0; i < rows; i++) {
        for (int j = 0; j < cols; j++) {
            x_real[i][j] /= N_M;
            x_imag[i][j] /= N_M;
        }
    }
}


// SECTION 6: EDGE DETECTION (Filtering)
// 


float get_D_squared(int i, int j, int rows, int cols) {
    int center_i = rows / 2;
    int center_j = cols / 2;

    int di = (i <= center_i) ? i : i - rows;
    int dj = (j <= center_j) ? j : j - cols;
    
    return (float)(di * di + dj * dj);
}

void create_highpass_filter(float** filter, int rows, int cols, float cutoff) {
    float D0_sq = cutoff * cutoff;

    for (int i = 0; i < rows; i++) {
        for (int j = 0; j < cols; j++) {
            float D_sq = get_D_squared(i, j, rows, cols);
            
            filter[i][j] = 1.0f - my_exp(-D_sq / (2.0f * D0_sq));
        }
    }
}


void edge_detection(float** x_real, float** x_imag, float* twiddle_real, float* twiddle_imag, float** filter, int rows, int cols, float cutoff) {
    //  Create Highpass filter
    create_highpass_filter(filter, rows, cols, cutoff);

    // Apply iterative 2D FFT (Forward)
    fft_2d(x_real, x_imag, twiddle_real, twiddle_imag, rows, cols, false, false);
    
    
    for (int i = 0; i < rows; i++) {
        for (int j = 0; j < cols; j++) {
            x_real[i][j] *= filter[i][j];
            x_imag[i][j] *= filter[i][j];
        }
    }

    ifft_2d(x_real, x_imag, twiddle_real, twiddle_imag, rows, cols, false);
}


// END OF MILESTONE 1 CODE


int main() {
     int width, height, channels;
    unsigned char *img = stbi_load("16x16.png", &width, &height, &channels, 0);
    
    if (img == NULL) {
        printf("Failed to load image\n");
        exit(1);
    }
    
    printf("Loaded %dx%d image with %d channels\n", width, height, channels);
    
    // Allocate arrays
    float** x_real = (float**)malloc(height * sizeof(float*));
    float** x_imag = (float**)malloc(height * sizeof(float*));
    float** filter = (float**)malloc(height * sizeof(float*));
    float* twiddle_real = (float*)malloc(width/2 * sizeof(float));
    float* twiddle_imag = (float*)malloc(width/2 * sizeof(float));
    unsigned char* fft_output = (unsigned char*)malloc(width * height);
    unsigned char* edge_output = (unsigned char*)malloc(width * height);
    
    for (int i = 0; i < height; i++) {
        x_real[i] = (float*)malloc(width * sizeof(float));
        x_imag[i] = (float*)malloc(width * sizeof(float));
        filter[i] = (float*)malloc(width * sizeof(float));
    }
    
    // Convert from uint8 [0-255] to float [0.0-1.0] (grayscale)
    for (int i = 0; i < height; i++) {
        for (int j = 0; j < width; j++) {
            int idx = (i * width + j) * channels;
            float gray = (channels >= 3) ? 
                (img[idx] + img[idx+1] + img[idx+2]) / (3.0f * 10.0f) :
                img[idx] / 255.0f;
            x_real[i][j] = gray;
            x_imag[i][j] = 0.0f;
        }
    }
    
    // Perform 2D FFT
    fft_2d(x_real, x_imag, twiddle_real, twiddle_imag, height, width, false, false);
    
    // Compute magnitude (sqrt(real^2 + imaginary^2)) and apply log scaling
    float max_mag = 0.0f;
    for (int i = 0; i < height; i++) {
        for (int j = 0; j < width; j++) {
            float mag = sqrt(x_real[i][j] * x_real[i][j] + x_imag[i][j] * x_imag[i][j]);
            float log_mag = log(1.0f + mag);
            x_real[i][j] = log_mag;
            if (log_mag > max_mag) max_mag = log_mag;
        }
    }
    
    // Convert back to char in RGB (255.0f * mag / max_mag)
    for (int i = 0; i < height; i++) {
        for (int j = 0; j < width; j++) {
            fft_output[i * width + j] = (unsigned char)(255.0f * x_real[i][j] / max_mag);
        }
    }
    
    stbi_write_png("fft_output.png", width, height, 1, fft_output, width);
    
    // Reload for edge detection
    for (int i = 0; i < height; i++) {
        for (int j = 0; j < width; j++) {
            int idx = (i * width + j) * channels;
            float gray = (channels >= 3) ? 
                (img[idx] + img[idx+1] + img[idx+2]) / (3.0f * 255.0f) :
                img[idx] / 255.0f;
            x_real[i][j] = gray;
            x_imag[i][j] = 0.0f;
        }
    }
    
    // Compute edge detection
    edge_detection(x_real, x_imag, twiddle_real, twiddle_imag, filter, height, width, 2.5f);
    
    // Find max magnitude of edge
    float max_edge = 0.0f;
    for (int i = 0; i < height; i++) {
        for (int j = 0; j < width; j++) {
            float val = fabs(x_real[i][j]);
            if (val > max_edge) max_edge = val;
        }
    }
    
    // Convert back to char in RGB
    for (int i = 0; i < height; i++) {
        for (int j = 0; j < width; j++) {
            edge_output[i * width + j] = (unsigned char)(255.0f * fabs(x_real[i][j]) / max_edge);
        }
    }
    
    stbi_write_png("edges_output.png", width, height, 1, edge_output, width);
    
    // Free all resources
    for (int i = 0; i < height; i++) {
        free(x_real[i]);
        free(x_imag[i]);
        free(filter[i]);
    }
    free(x_real);
    free(x_imag);
    free(filter);
    free(twiddle_real);
    free(twiddle_imag);
    free(fft_output);
    free(edge_output);
    stbi_image_free(img);
   
    return 0;

}

