#!/bin/bash
set -e -x

# Can be a tag, commit or branch
ONNXRUNTIME_VERSION=${1}
ONNXRUNTIME_BUILD_CONFIG=${2}
CUDA_VERSION=${3}

CUDA_HOME=/usr/local/cuda/
CUDNN_HOME=/usr/lib/x86_64-linux-gnu/
CMAKE_CUDA_ARCHITECTURES="37;50;52;60;61;70;75;80"

CONDA_PATH=$(which conda)
PYTHON_PATH=$(which python)

echo "Building ONNX Runtime ${ONNXRUNTIME_VERSION} from source"
echo "Conda path is ${CONDA_PATH}"
echo "Python path is ${PYTHON_PATH}"

git clone https://github.com/microsoft/onnxruntime.git
cd onnxruntime
git checkout ${ONNXRUNTIME_VERSION}
git submodule sync
git submodule update --init --recursive --jobs 0

bash build.sh \
        --config ${ONNXRUNTIME_BUILD_CONFIG} \
        --build_shared_lib \
        --allow_running_as_root \
        --enable_training \
        --use_cuda \
        --cuda_home ${CUDA_HOME} \
        --cudnn_home ${CUDNN_HOME} \
        --build_wheel \
        --parallel \
        --skip_tests \
        --cmake_extra_defines '"CMAKE_CUDA_ARCHITECTURES='${CMAKE_CUDA_ARCHITECTURES}'"' \
        --cuda_version=${CUDA_VERSION}
