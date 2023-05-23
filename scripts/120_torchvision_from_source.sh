#!/bin/bash
set -e -x

# Can be a tag, commit or branch
TORCHVISION_VERSION=${1}
unset PYTORCH_VERSION
export FORCE_CUDA=1

CONDA_PATH=$(which conda)
PYTHON_PATH=$(which python)

echo "Building Torch Vision ${TORCHVISION_VERSION} from source"
echo "Conda path is ${CONDA_PATH}"
echo "Python path is ${PYTHON_PATH}"

git clone https://github.com/pytorch/vision.git torchvision
cd torchvision
git checkout ${TORCHVISION_VERSION}
git submodule sync
git submodule update --init --recursive --jobs 0

python setup.py bdist_wheel