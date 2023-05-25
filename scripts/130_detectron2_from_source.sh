#!/bin/bash
set -e -x

# Can be a tag, commit or branch
DETECTRON2_VERSION=${1}
INSTALL_AFTER_BUILD=${2:-0}

unset PYTORCH_VERSION

source ${CONDA_INSTALL_DIR}/bin/activate ${DEFAULT_CONDA_ENV}
CONDA_PATH=$(which conda)
PYTHON_PATH=$(which python)

echo "Uninstalling existing versions of Detectron2 from pip package manager..."
pip uninstall -y detectron2

echo "Building Detectron2 ${DETECTRON2_VERSION} from source"
echo "Conda path is ${CONDA_PATH}"
echo "Python path is ${PYTHON_PATH}"

if [ ! -d detectron2 ]
then
    git clone https://github.com/facebookresearch/detectron2.git
fi
cd detectron2
git checkout ${DETECTRON2_VERSION}
git submodule sync
git submodule update --init --recursive --jobs 0

python setup.py bdist_wheel
if [ "${INSTALL_AFTER_BUILD}" == "1" ]
then
    pip install dist/detectron2*.whl
fi