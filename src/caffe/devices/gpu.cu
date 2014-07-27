// Copyright 2014 BVLC and contributors.

#include <math_functions.h>  // CUDA's, not caffe's, for fabs, signbit
#include <thrust/device_vector.h>
#include <thrust/functional.h>  // thrust::plus
#include <thrust/reduce.h>
#include <cmath>
#include <cstdlib>
#include <cstring>

#include "caffe/common.hpp"
#include "caffe/devices/gpu.hpp"

namespace caffe {

template <typename Dtype>
__global__ void set_kernel(const int n, const Dtype alpha, Dtype* y) {
  CUDA_KERNEL_LOOP(index, n) {
    y[index] = alpha;
  }
}

template <typename Dtype>
void GPUDevice<Dtype>::set(const int N, const Dtype alpha, Dtype* Y) {
  if (alpha == 0) {
    CUDA_CHECK(cudaMemset(Y, 0, sizeof(Dtype) * N));
    return;
  }
  // NOLINT_NEXT_LINE(whitespace/operators)
  set_kernel<Dtype><<<CAFFE_GET_BLOCKS(N), CAFFE_CUDA_NUM_THREADS>>>(
      N, alpha, Y);
}

template <typename Dtype>
__global__ void add_scalar_kernel(const int n, const Dtype alpha, Dtype* y) {
  CUDA_KERNEL_LOOP(index, n) {
    y[index] += alpha;
  }
}

template <typename Dtype>
void GPUDevice<Dtype>::add_scalar(const int N, const Dtype alpha, Dtype* Y) {
  // NOLINT_NEXT_LINE(whitespace/operators)
  add_scalar_kernel<Dtype><<<CAFFE_GET_BLOCKS(N), CAFFE_CUDA_NUM_THREADS>>>(
      N, alpha, Y);
}

template <typename Dtype>
__global__ void add_kernel(const int n, const Dtype* a, const Dtype* b,
                           Dtype* y) {
  CUDA_KERNEL_LOOP(index, n) {
    y[index] = a[index] + b[index];
  }
}

template <typename Dtype>
void GPUDevice<Dtype>::add(const int N, const Dtype* a, const Dtype* b,
                           Dtype* y) {
  // NOLINT_NEXT_LINE(whitespace/operators)
  add_kernel<Dtype><<<CAFFE_GET_BLOCKS(N), CAFFE_CUDA_NUM_THREADS>>>(
      N, a, b, y);
}

template <typename Dtype>
__global__ void sub_kernel(const int n, const Dtype* a, const Dtype* b,
                           Dtype* y) {
  CUDA_KERNEL_LOOP(index, n) {
    y[index] = a[index] - b[index];
  }
}

template <typename Dtype>
void GPUDevice<Dtype>::sub(const int N, const Dtype* a, const Dtype* b,
                           Dtype* y) {
  // NOLINT_NEXT_LINE(whitespace/operators)
  sub_kernel<Dtype><<<CAFFE_GET_BLOCKS(N), CAFFE_CUDA_NUM_THREADS>>>(
      N, a, b, y);
}

template <typename Dtype>
__global__ void mul_kernel(const int n, const Dtype* a, const Dtype* b,
                           Dtype* y) {
  CUDA_KERNEL_LOOP(index, n) {
    y[index] = a[index] * b[index];
  }
}

template <typename Dtype>
void GPUDevice<Dtype>::mul(const int N, const Dtype* a, const Dtype* b,
                           Dtype* y) {
  // NOLINT_NEXT_LINE(whitespace/operators)
  mul_kernel<Dtype><<<CAFFE_GET_BLOCKS(N), CAFFE_CUDA_NUM_THREADS>>>(
      N, a, b, y);
}

template <typename Dtype>
__global__ void div_kernel(const int n, const Dtype* a, const Dtype* b,
                           Dtype* y) {
  CUDA_KERNEL_LOOP(index, n) {
    y[index] = a[index] / b[index];
  }
}

template <typename Dtype>
void GPUDevice<Dtype>::div(const int N, const Dtype* a, const Dtype* b,
                           Dtype* y) {
  // NOLINT_NEXT_LINE(whitespace/operators)
  div_kernel<Dtype><<<CAFFE_GET_BLOCKS(N), CAFFE_CUDA_NUM_THREADS>>>(
      N, a, b, y);
}

template <typename Dtype>
__global__ void powx_kernel(const int n, const Dtype* a, const Dtype alpha,
                            Dtype* y) {
  CUDA_KERNEL_LOOP(index, n) {
    y[index] = pow(a[index], alpha);
  }
}

template<>
__global__ void powx_kernel<int>(const int n, const int* a, const int alpha,
                                 int* y) {}

template<>
__global__ void powx_kernel<unsigned int>(const int n, const unsigned int* a,
                                          const unsigned int alpha,
                                          unsigned int* y) {}

template <typename Dtype>
void GPUDevice<Dtype>::powx(const int N, const Dtype* a, const Dtype alpha,
                            Dtype* y) {
  // NOLINT_NEXT_LINE(whitespace/operators)
  powx_kernel<Dtype><<<CAFFE_GET_BLOCKS(N), CAFFE_CUDA_NUM_THREADS>>>(
      N, a, alpha, y);
}

template <>
void GPUDevice<int>::powx(const int N, const int* a, const int alpha, int* y) {
  NOT_IMPLEMENTED;
}

template <>
void GPUDevice<unsigned int>::powx(const int N, const unsigned int* a,
                                   const unsigned int alpha, unsigned int* y) {
  NOT_IMPLEMENTED;
}

template <typename Dtype>
__global__ void sign_kernel(const int n, const Dtype* x, Dtype* y) {
  CUDA_KERNEL_LOOP(index, n) {
    y[index] = (Dtype(0) < x[index]) - (x[index] < Dtype(0));
  }
}

template<>
__global__ void sign_kernel<unsigned int>(const int n, const unsigned int* x,
                                          unsigned int* y) {
  CUDA_KERNEL_LOOP(index, n) {
    y[index] = x[index] != 0;
  }
}

template <typename Dtype>
void GPUDevice<Dtype>::sign(const int n, const Dtype* x, Dtype* y) {
  /* NOLINT_NEXT_LINE(whitespace/operators) */
  sign_kernel<Dtype><<<CAFFE_GET_BLOCKS(n), CAFFE_CUDA_NUM_THREADS>>>(
      n, x, y);
}

template <typename Dtype>
__global__ void sgnbit_kernel(const int n, const Dtype* x, Dtype* y) {
  CUDA_KERNEL_LOOP(index, n) {
    y[index] = signbit(x[index]);
  }
}

template <typename Dtype>
void GPUDevice<Dtype>::sgnbit(const int n, const Dtype* x, Dtype* y) {
  /* NOLINT_NEXT_LINE(whitespace/operators) */
  sgnbit_kernel<Dtype><<<CAFFE_GET_BLOCKS(n), CAFFE_CUDA_NUM_THREADS>>>(
      n, x, y);
}

template <typename Dtype>
__global__ void fabs_kernel(const int n, const Dtype* x, Dtype* y) {
  CUDA_KERNEL_LOOP(index, n) {
    y[index] = fabs(x[index]);
  }
}

template<>
__global__ void fabs_kernel<int>(const int n, const int* x, int* y) {}

template<>
__global__ void fabs_kernel<unsigned int>(const int n, const unsigned int* x,
                                          unsigned int* y) {}

template <typename Dtype>
void GPUDevice<Dtype>::fabs(const int n, const Dtype* x, Dtype* y) {
  /* NOLINT_NEXT_LINE(whitespace/operators) */
  fabs_kernel<Dtype><<<CAFFE_GET_BLOCKS(n), CAFFE_CUDA_NUM_THREADS>>>(
      n, x, y);
}

template<>
void GPUDevice<int>::fabs(const int n, const int* x, int* y) {
  NOT_IMPLEMENTED;
}

template<>
void GPUDevice<unsigned int>::fabs(const int n, const unsigned int* x,
                                   unsigned int* y) { NOT_IMPLEMENTED; }

template <typename Dtype>
__global__ void sqr_kernel(const int n, const Dtype* a, Dtype* y) {
  CUDA_KERNEL_LOOP(index, n) {
    y[index] = a[index] * a[index];
  }
}

template <typename Dtype>
void GPUDevice<Dtype>::sqr(const int n, const Dtype* a, Dtype* y) {
  /* NOLINT_NEXT_LINE(whitespace/operators) */
  sqr_kernel<Dtype><<<CAFFE_GET_BLOCKS(n), CAFFE_CUDA_NUM_THREADS>>>(
      n, a, y);
}

template <typename Dtype>
__global__ void exp_kernel(const int n, const Dtype* a, Dtype* y) {
  CUDA_KERNEL_LOOP(index, n) {
    y[index] = exp(a[index]);
  }
}

template <>
__global__ void exp_kernel<int>(const int n, const int* a, int* y) {}

template <>
__global__ void exp_kernel<unsigned int>(const int n, const unsigned int* a,
                                         unsigned int* y) {}

template <typename Dtype>
void GPUDevice<Dtype>::exp(const int n, const Dtype* a, Dtype* y) {
  /* NOLINT_NEXT_LINE(whitespace/operators) */
  exp_kernel<Dtype><<<CAFFE_GET_BLOCKS(n), CAFFE_CUDA_NUM_THREADS>>>(
      n, a, y);
}

template <>
void GPUDevice<int>::exp(const int n, const int* a, int* y) { NOT_IMPLEMENTED; }

template <>
void GPUDevice<unsigned int>::exp(const int n, const unsigned int* a,
                                  unsigned int* y) { NOT_IMPLEMENTED; }

__global__ void popc_kernel(const int n, const float* a,
    const float* b, uint8_t* y) {
  CUDA_KERNEL_LOOP(index, n) {
    y[index] = __popc(static_cast<uint32_t>(a[index]) ^
                      static_cast<uint32_t>(b[index]));
  }
}

__global__ void popcll_kernel(const int n, const double* a,
    const double* b, uint8_t* y) {
  CUDA_KERNEL_LOOP(index, n) {
    y[index] = __popcll(static_cast<uint64_t>(a[index]) ^
                        static_cast<uint64_t>(b[index]));
  }
}

template <>
void GPUDevice<float>::hamming_distance(const int n, const float* x,
                                        const float* y, int* out) {
  // TODO: Fix caffe_gpu_hamming_distance (see failing unit test
  // TestHammingDistanceGPU in test_math_functions.cpp).
  NOT_IMPLEMENTED;
  thrust::device_vector<uint8_t> popcounts(n);
  // NOLINT_NEXT_LINE(whitespace/operators)
  popc_kernel<<<CAFFE_GET_BLOCKS(n), CAFFE_CUDA_NUM_THREADS>>>(
      n, x, y, thrust::raw_pointer_cast(popcounts.data()));
  *out = thrust::reduce(popcounts.begin(), popcounts.end(),
                        (uint32_t) 0, thrust::plus<uint32_t>());
}

template <>
void GPUDevice<double>::hamming_distance(const int n, const double* x,
                                         const double* y, int* out) {
  // TODO: Fix caffe_gpu_hamming_distance (see failing unit test
  // TestHammingDistanceGPU in test_math_functions.cpp).
  NOT_IMPLEMENTED;
  thrust::device_vector<uint8_t> popcounts(n);
  // NOLINT_NEXT_LINE(whitespace/operators)
  popcll_kernel<<<CAFFE_GET_BLOCKS(n), CAFFE_CUDA_NUM_THREADS>>>(
      n, x, y, thrust::raw_pointer_cast(popcounts.data()));
  *out = thrust::reduce(popcounts.begin(), popcounts.end(),
                        /* NOLINT_NEXT_LINE(build/include_what_you_use) */
                        (uint32_t) 0, thrust::plus<uint32_t>());
}

template<>
void GPUDevice<int>::hamming_distance(const int N, const int* x, const int* y,
                                      int* out) { NOT_IMPLEMENTED; }

template<>
void GPUDevice<unsigned int>::hamming_distance(const int N,
                                               const unsigned int* x,
                                               const unsigned int* y,
                                               int* out) { NOT_IMPLEMENTED; }

template <>
void GPUDevice<float>::rng_uniform(const int n, const float a, const float b,
                                   float* r) {
  CURAND_CHECK(curandGenerateUniform(Caffe::curand_generator(), r, n));
  const float range = b - a;
  if (range != static_cast<float>(1)) {
    GetDevice<float>(Caffe::GPU)->scal(n, range, r);
  }
  if (a != static_cast<float>(0)) {
    GetDevice<float>(Caffe::GPU)->add_scalar(n, a, r);
  }
}

template <>
void GPUDevice<double>::rng_uniform(const int n, const double a, const double b,
                                    double* r) {
  CURAND_CHECK(curandGenerateUniformDouble(Caffe::curand_generator(), r, n));
  const double range = b - a;
  if (range != static_cast<double>(1)) {
    GetDevice<double>(Caffe::GPU)->scal(n, range, r);
  }
  if (a != static_cast<double>(0)) {
    GetDevice<double>(Caffe::GPU)->add_scalar(n, a, r);
  }
}

template <>
void GPUDevice<int>::rng_uniform(const int n, const int a, const int b,
                                 int* r) { NOT_IMPLEMENTED; }

template <>
void GPUDevice<unsigned int>::rng_uniform(const int n, const unsigned int a,
                                          const unsigned int b,
                                          unsigned int* r) { NOT_IMPLEMENTED; }

template <>
void GPUDevice<float>::rng_gaussian(const int n, const float mu,
                                    const float sigma, float* r) {
  CURAND_CHECK(
      curandGenerateNormal(Caffe::curand_generator(), r, n, mu, sigma));
}

template <>
void GPUDevice<double>::rng_gaussian(const int n, const double mu,
                                     const double sigma, double* r) {
  CURAND_CHECK(
      curandGenerateNormalDouble(Caffe::curand_generator(), r, n, mu, sigma));
}

template <>
void GPUDevice<int>::rng_gaussian(const int n, const int mu, const int sigma,
                                  int* r) { NOT_IMPLEMENTED; }

template <>
void GPUDevice<unsigned int>::rng_gaussian(const int n, const unsigned int mu,
                                           const unsigned int sigma,
                                           unsigned int* r) { NOT_IMPLEMENTED; }

template <typename Dtype>
__global__ void im2col_gpu_kernel(const int n, const Dtype* data_im,
    const int height, const int width, const int kernel_h, const int kernel_w,
    const int pad_h, const int pad_w,
    const int stride_h, const int stride_w,
    const int height_col, const int width_col,
    Dtype* data_col) {
  CUDA_KERNEL_LOOP(index, n) {
    int w_out = index % width_col;
    int h_index = index / width_col;
    int h_out = h_index % height_col;
    int channel_in = h_index / height_col;
    int channel_out = channel_in * kernel_h * kernel_w;
    int h_in = h_out * stride_h - pad_h;
    int w_in = w_out * stride_w - pad_w;
    Dtype* data_col_ptr = data_col;
    data_col_ptr += (channel_out * height_col + h_out) * width_col + w_out;
    const Dtype* data_im_ptr = data_im;
    data_im_ptr += (channel_in * height + h_in) * width + w_in;
    for (int i = 0; i < kernel_h; ++i) {
      for (int j = 0; j < kernel_w; ++j) {
        int h = h_in + i;
        int w = w_in + j;
        *data_col_ptr = (h >= 0 && w >= 0 && h < height && w < width) ?
            data_im_ptr[i * width + j] : 0;
        data_col_ptr += height_col * width_col;
      }
    }
  }
}

template <typename Dtype>
void GPUDevice<Dtype>::im2col(const Dtype* data_im, const int channels,
    const int height, const int width, const int kernel_h, const int kernel_w,
    const int pad_h, const int pad_w, const int stride_h, const int stride_w,
    Dtype* data_col) {
  // We are going to launch channels * height_col * width_col kernels, each
  // kernel responsible for copying a single-channel grid.
  int height_col = (height + 2 * pad_h - kernel_h) / stride_h + 1;
  int width_col = (width + 2 * pad_w - kernel_w) / stride_w + 1;
  int num_kernels = channels * height_col * width_col;
  // NOLINT_NEXT_LINE(whitespace/operators)
  im2col_gpu_kernel<Dtype><<<CAFFE_GET_BLOCKS(num_kernels),
                             CAFFE_CUDA_NUM_THREADS>>>(
      num_kernels, data_im, height, width, kernel_h, kernel_w, pad_h,
      pad_w, stride_h, stride_w, height_col,
      width_col, data_col);
  CUDA_POST_KERNEL_CHECK;
}

template <typename Dtype>
__global__ void col2im_gpu_kernel(const int n, const Dtype* data_col,
    const int height, const int width, const int channels,
    const int patch_h, const int patch_w,
    const int pad_h, const int pad_w,
    const int stride_h, const int stride_w,
    const int height_col, const int width_col,
    Dtype* data_im) {
  CUDA_KERNEL_LOOP(index, n) {
    Dtype val = 0;
    int w = index % width + pad_w;
    int h = (index / width) % height + pad_h;
    int c = index / (width * height);
    // compute the start and end of the output
    int w_col_start = (w < patch_w) ? 0 : (w - patch_w) / stride_w + 1;
    // NOLINT_NEXT_LINE(build/include_what_you_use)
    int w_col_end = min(w / stride_w + 1, width_col);
    int h_col_start = (h < patch_h) ? 0 : (h - patch_h) / stride_h + 1;
    // NOLINT_NEXT_LINE(build/include_what_you_use)
    int h_col_end = min(h / stride_h + 1, height_col);
    /*
    for (int h_col = h_col_start; h_col < h_col_end; ++h_col) {
      for (int w_col = w_col_start; w_col < w_col_end; ++w_col) {
        // the col location: [c * width * height + h_out, w_out]
        int c_col = c * patch_h * patch_w + (h - h_col * stride_h) * ksize
            + (w - w_col * stride_w);
        val += data_col[(c_col * height_col + h_col) * width_col + w_col];
      }
    }
    */
    // equivalent implementation
    int offset =
        (c * patch_h * patch_w + h * patch_w + w) * height_col * width_col;
    int coeff_h_col = (1 - stride_h * patch_w * height_col) * width_col;
    int coeff_w_col = (1 - stride_w * height_col * width_col);
    for (int h_col = h_col_start; h_col < h_col_end; ++h_col) {
      for (int w_col = w_col_start; w_col < w_col_end; ++w_col) {
        val += data_col[offset + h_col * coeff_h_col + w_col * coeff_w_col];
      }
    }
    data_im[index] = val;
  }
}

template <typename Dtype>
void GPUDevice<Dtype>::col2im(const Dtype* data_col, const int channels,
    const int height, const int width, const int patch_h, const int patch_w,
    const int pad_h, const int pad_w, const int stride_h,
    const int stride_w, Dtype* data_im) {
  int height_col = (height + 2 * pad_h - patch_h) / stride_h + 1;
  int width_col = (width + 2 * pad_w - patch_w) / stride_w + 1;
  int num_kernels = channels * height * width;
  // To avoid involving atomic operations, we will launch one kernel per
  // bottom dimension, and then in the kernel add up the top dimensions.
  // NOLINT_NEXT_LINE(whitespace/operators)
  col2im_gpu_kernel<Dtype><<<CAFFE_GET_BLOCKS(num_kernels),
                             CAFFE_CUDA_NUM_THREADS>>>(
      num_kernels, data_col, height, width, channels, patch_h, patch_w,
      pad_h, pad_w, stride_h, stride_w,
      height_col, width_col, data_im);
  CUDA_POST_KERNEL_CHECK;
}

INSTANTIATE_CLASS(GPUDevice);
template class GPUDevice<int>;
template class GPUDevice<unsigned int>;

}  // namespace caffe