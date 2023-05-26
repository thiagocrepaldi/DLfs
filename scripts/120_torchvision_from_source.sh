#!/bin/bash
set -e -x

# Can be a tag, commit or branch
TORCHVISION_VERSION=${1}
INSTALL_AFTER_BUILD=${2:-0}
ROOT_DIR=${3:-"/opt"}
cd ${ROOT_DIR}

unset PYTORCH_VERSION
export FORCE_CUDA=1

source ${CONDA_INSTALL_DIR}/bin/activate ${DEFAULT_CONDA_ENV}
CONDA_PATH=$(which conda)
PYTHON_PATH=$(which python)

echo "Uninstalling existing versions of Torch Vision from pip package manager..."
pip uninstall -y torchvision

echo "Building Torch Vision ${TORCHVISION_VERSION} from source"
echo "Conda path is ${CONDA_PATH}"
echo "Python path is ${PYTHON_PATH}"

if [ ! -d torchvision ]
then
    git clone https://github.com/pytorch/vision.git torchvision
fi
cd torchvision
git checkout ${TORCHVISION_VERSION}
git submodule sync
git submodule update --init --recursive --jobs 0

python setup.py bdist_wheel
if [ "${INSTALL_AFTER_BUILD}" == "1" ]
then
    pip uninstall -y torchvision
    pip install dist/torchvision*.whl
fi