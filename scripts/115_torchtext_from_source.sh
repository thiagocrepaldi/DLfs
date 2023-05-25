#!/bin/bash
set -e -x

# Can be a tag, commit or branch
TORCHTEXT_VERSION=${1}
INSTALL_AFTER_BUILD=${2:-0}

unset PYTORCH_VERSION

source ${CONDA_INSTALL_DIR}/bin/activate ${DEFAULT_CONDA_ENV}
CONDA_PATH=$(which conda)
PYTHON_PATH=$(which python)

echo "Uninstalling existing versions of Torch Text from pip package manager..."
pip uninstall -y torchtext

echo "Building Torch Text ${TORCHTEXT_VERSION} from source"
echo "Conda path is ${CONDA_PATH}"
echo "Python path is ${PYTHON_PATH}"

if [ ! -d torchtext ]
then
    git clone https://github.com/pytorch/text.git torchtext
fi
cd torchtext
git checkout ${TORCHTEXT_VERSION}
git submodule sync
git submodule update --init --recursive --jobs 0

python setup.py bdist_wheel
if [ "${INSTALL_AFTER_BUILD}" == "1" ]
then
    pip install dist/torchtext*.whl
fi