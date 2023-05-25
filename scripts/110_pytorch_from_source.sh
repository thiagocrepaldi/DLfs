#!/bin/bash
set -e -x

# Can be a tag, commit or branch
unset PYTORCH_BUILD_NUMBER
unset PYTORCH_BUILD_VERSION
PYTORCH_VERSION=${1}
INSTALL_AFTER_BUILD=${2:-0}

source ${CONDA_INSTALL_DIR}/bin/activate ${DEFAULT_CONDA_ENV}
CONDA_PATH=$(which conda)
PYTHON_PATH=$(which python)

echo "Uninstalling existing versions of PyTorch from pip package manager..."
pip uninstall -y torch

echo "Building Pytorch ${PYTORCH_VERSION} from source"
echo "Conda path is ${CONDA_PATH}"
echo "Python path is ${PYTHON_PATH}"

if [ ! -d pytorch ]
then
    git clone https://github.com/pytorch/pytorch.git
fi
cd pytorch
git checkout ${PYTORCH_VERSION}
git submodule sync
git submodule update --init --recursive --jobs 0

python setup.py bdist_wheel
if [ "${INSTALL_AFTER_BUILD}" == "1" ]
then
    pip install dist/torch*.whl
fi