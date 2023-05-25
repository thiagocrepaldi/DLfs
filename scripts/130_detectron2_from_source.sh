#!/bin/bash
set -e -x

# Can be a tag, commit or branch
DETECTRON2_VERSION=${1}
unset PYTORCH_VERSION

source ${CONDA_INSTALL_DIR}/bin/activate ${DEFAULT_CONDA_ENV}
CONDA_PATH=$(which conda)
PYTHON_PATH=$(which python)

echo "Building Detectron2 ${DETECTRON2_VERSION} from source"
echo "Conda path is ${CONDA_PATH}"
echo "Python path is ${PYTHON_PATH}"

git clone https://github.com/facebookresearch/detectron2.git
cd detectron2
git checkout ${DETECTRON2_VERSION}
git submodule sync
git submodule update --init --recursive --jobs 0

python setup.py bdist_wheel