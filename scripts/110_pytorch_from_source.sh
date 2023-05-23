#!/bin/bash
set -e -x

# Can be a tag, commit or branch
unset PYTORCH_BUILD_NUMBER
unset PYTORCH_BUILD_VERSION
PYTORCH_VERSION=${1}

CONDA_PATH=$(which conda)
PYTHON_PATH=$(which python)

echo "Building Pytorch ${PYTORCH_VERSION} from source"
echo "Conda path is ${CONDA_PATH}"
echo "Python path is ${PYTHON_PATH}"

git clone https://github.com/pytorch/pytorch.git
cd pytorch
git checkout ${PYTORCH_VERSION}
git submodule sync
git submodule update --init --recursive --jobs 0

python setup.py bdist_wheel