#!/bin/bash
set -e -x

# Can be a tag, commit or branch
ONNXRUNTIME_VERSION=${1}
ONNXRUNTIME_BUILD_CONFIG=${2}
CUDA_VERSION=${3}
INSTALL_AFTER_BUILD=${4:-0}
ROOT_DIR=${5:-"/opt"}
cd ${ROOT_DIR}

CUDA_HOME=/usr/local/cuda/
CUDNN_HOME=/usr/lib/x86_64-linux-gnu/
CMAKE_CUDA_ARCHITECTURES="37;50;52;60;61;70;75;80"

source ${CONDA_INSTALL_DIR}/bin/activate ${DEFAULT_CONDA_ENV}
CONDA_PATH=$(which conda)
PYTHON_PATH=$(which python)

echo "Uninstalling existing versions of ONNX Runtime from pip package manager..."
pip uninstall -y onnxruntime onnxruntime-training

echo "Building ONNX Runtime ${ONNXRUNTIME_VERSION} from source"
echo "Conda path is ${CONDA_PATH}"
echo "Python path is ${PYTHON_PATH}"

if [ ! -d onnxruntime ]
then
    git clone https://github.com/microsoft/onnxruntime.git
fi
cd onnxruntime
git checkout ${ONNXRUNTIME_VERSION}
git submodule sync
git submodule update --init --recursive --jobs 0

ONNXRUNTIME_BUILD_COMMAND="--config ${ONNXRUNTIME_BUILD_CONFIG}
--build_shared_lib
--enable_training
--use_cuda
--cuda_home ${CUDA_HOME}
--cudnn_home ${CUDNN_HOME}
--build_wheel
--parallel
--skip_tests
--cmake_extra_defines '\"CMAKE_CUDA_ARCHITECTURES='${CMAKE_CUDA_ARCHITECTURES}'\"'
--cuda_version=${CUDA_VERSION}"

bash build.sh ${ONNXRUNTIME_BUILD_COMMAND} || bash build.sh ${ONNXRUNTIME_BUILD_COMMAND} --allow_running_as_root
if [ "${INSTALL_AFTER_BUILD}" == "1" ]
then
    pip uninstall -y onnxruntime onnxruntime-training
    pip install build/Linux/${ONNXRUNTIME_BUILD_CONFIG}/dist/onnxruntime*.whl
fi