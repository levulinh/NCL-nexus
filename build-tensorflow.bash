    # TensorFlow 2 master
git checkout v2.4.0
export PYTHON_BIN_PATH="${PYTHON_BIN_PATH:-/usr/bin/python3.7}"
export TF_CUDA_PATHS="${TF_CUDA_PATHS:-/usr/local/cuda-11.0,/usr}"
export TF_CUDA_VERSION="11.0"
export TF_CUDNN_VERSION="8"
# perl -pi.bak -e 's%, CompareUFunc%, (PyUFuncGenericFunction) CompareUFunc%g' tensorflow/python/lib/core/bfloat16.cc