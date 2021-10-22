#!/bin/bash
set -e
set -x

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
SRC_DIR="$SCRIPT_DIR/build-dep-src"
INSTALL_DIR="$SCRIPT_DIR/build-dep-install"
git config --global http.postBuffer 1048576000

mkdir -p "$SRC_DIR"
mkdir -p "$INSTALL_DIR"

cd "$SRC_DIR"

if [ ! -d "$SRC_DIR/tensorflow" ]; then
    # TensorFlow 2 master
    git clone https://github.com/tensorflow/tensorflow.git
fi
cd tensorflow
git checkout v2.4.0

# Tensorflow build config
export PYTHON_BIN_PATH="${PYTHON_BIN_PATH:-/usr/bin/python3.7}"
export PYTHON_LIB_PATH="$($PYTHON_BIN_PATH -c 'import site; print(site.getsitepackages()[0])')"
export TF_ENABLE_XLA=0
export TF_NEED_OPENCL_SYCL=0
export TF_NEED_ROCM=0
export TF_NEED_CUDA=1
export TF_NEED_TENSORRT=0
export TF_CUDA_COMPUTE_CAPABILITIES="${TF_CUDA_COMPUTE_CAPABILITIES:-5.2,6.1,7.5}"
export TF_CUDA_PATHS="${TF_CUDA_PATHS:-/usr/local/cuda-11.0,/usr}"
export TF_CUDA_VERSION="11.0"
export TF_CUDNN_VERSION="8"
export TF_CUDA_CLANG=0
export GCC_HOST_COMPILER_PATH="${GCC_HOST_COMPILER_PATH:-/usr/bin/gcc}"
export TF_NEED_MPI=0
export TF_SET_ANDROID_WORKSPACE=0
export CC_OPT_FLAGS="-march=native -Wno-sign-compare"
export PATH="$PATH:$INSTALL_DIR/bazel"
# perl -pi.bak -e 's%, CompareUFunc%, (PyUFuncGenericFunction) CompareUFunc%g' tensorflow/python/lib/core/bfloat16.cc
./configure

# Build
bazel build --config=opt --config=noaws --config=nogcp --config=nohdfs --config=nonccl \
    //tensorflow:libtensorflow_cc.so \
    //tensorflow:libtensorflow_framework.so \
    //tensorflow:install_headers

# Copy files
rm -rf "$INSTALL_DIR/tensorflow"
cp -av bazel-out/k8-opt/bin/tensorflow "$INSTALL_DIR/tensorflow"
