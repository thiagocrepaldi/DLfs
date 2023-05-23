#!/bin/bash
set -e -x

# Can be a tag, commit or branch
ONNX_VERSION=${1}

CONDA_PATH=$(which conda)
PYTHON_PATH=$(which python)

echo "Building ONNX ${ONNX_VERSION} from source"
echo "Conda path is ${CONDA_PATH}"
echo "Python path is ${PYTHON_PATH}"

git clone https://github.com/onnx/onnx.git
cd onnx
git checkout ${ONNX_VERSION}
git submodule sync
git submodule update --init --recursive --jobs 0

# Optional: prefer lite proto
#export CMAKE_ARGS=-DONNX_USE_LITE_PROTO=ON
python setup.py bdist_wheel
# python -m pip install -e .