#!/bin/bash
set -e -x

# Can be a tag, commit or branch
ONNX_VERSION=${1}
INSTALL_AFTER_BUILD=${2:-0}

source ${CONDA_INSTALL_DIR}/bin/activate ${DEFAULT_CONDA_ENV}
CONDA_PATH=$(which conda)
PYTHON_PATH=$(which python)

echo "Uninstalling existing versions of ONNX from pip package manager..."
pip uninstall -y onnx

echo "Building ONNX ${ONNX_VERSION} from source"
echo "Conda path is ${CONDA_PATH}"
echo "Python path is ${PYTHON_PATH}"

if [ ! -d onnx ]
then
    git clone https://github.com/onnx/onnx.git
fi
cd onnx
git checkout ${ONNX_VERSION}
git submodule sync
git submodule update --init --recursive --jobs 0

# Optional: prefer lite proto
#export CMAKE_ARGS=-DONNX_USE_LITE_PROTO=ON
python setup.py bdist_wheel
if [ "${INSTALL_AFTER_BUILD}" == "1" ]
then
    pip install dist/onnx*.whl
fi
# python -m pip install -e .