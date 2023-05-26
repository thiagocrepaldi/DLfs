#!/bin/bash
set -e -x

# Can be a tag, commit or branch
ONNXSCRIPT_VERSION=${1}
INSTALL_AFTER_BUILD=${2:-0}
ROOT_DIR=${3:-"/opt"}
cd ${ROOT_DIR}

source ${CONDA_INSTALL_DIR}/bin/activate ${DEFAULT_CONDA_ENV}
CONDA_PATH=$(which conda)
PYTHON_PATH=$(which python)

echo "Uninstalling existing versions of ONNX Script from pip package manager..."
pip uninstall -y onnxscript

echo "Building ONNX Script ${ONNXSCRIPT_VERSION} from source"
echo "Conda path is ${CONDA_PATH}"
echo "Python path is ${PYTHON_PATH}"

if [ ! -d onnxscript ]
then
    git clone https://github.com/microsoft/onnxscript.git
fi
cd onnxscript
git checkout ${ONNXSCRIPT_VERSION}
git submodule sync
git submodule update --init --recursive --jobs 0

python setup.py bdist_wheel
# python -m pip install -e .
if [ "${INSTALL_AFTER_BUILD}" == "1" ]
then
    pip uninstall -y onnxscript
    pip install dist/onnxscript*.whl
fi