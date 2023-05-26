#!/bin/bash
set -e -x

# Superset of requirements for all builds, including:
#   ONNX, PyTorch, TorchVision, TorchText, TorchAudio, Detectron2 and ONNXRuntime

PYTHON_VERSION=${1}
ROOT_DIR=${2:-"/tmp"}
cd ${ROOT_DIR}

if [ ! -f "${CONDA_INSTALL_DIR}/bin/conda" ]
then
    echo "Installing Miniconda from installer"

    curl -fsSL -v -o miniconda.sh -O  https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
    chmod +x miniconda.sh
    miniconda.sh -b -p ${CONDA_INSTALL_DIR}
    rm miniconda.sh

    ${CONDA_INSTALL_DIR}/bin/conda init bash
    source ~/.bashrc

    ${CONDA_INSTALL_DIR}/bin/conda create -n ${DEFAULT_CONDA_ENV} -y \
        python=${PYTHON_VERSION}

    ${CONDA_INSTALL_DIR}/bin/conda clean -ya
else
    echo "Skipping installation Miniconda from installer"
fi
