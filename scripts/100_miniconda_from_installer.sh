#!/bin/bash
set -e -x

# Superset of requirements for all builds, including:
#   ONNX, PyTorch, TorchVision, TorchText, TorchAudio, Detectron2 and ONNXRuntime

PYTHON_VERSION=${1}
CONDA_ENV_NAME=ptca
INSTALL_DIR=/opt/conda

HAS_CONDA=$(which conda)
if [ -z ${HAS_CONDA} ]
then
    echo "Installing Miniconda from installer"

    curl -fsSL -v -o /tmp/miniconda.sh -O  https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
    chmod +x /tmp/miniconda.sh
    /tmp/miniconda.sh -b -p ${INSTALL_DIR}
    rm /tmp/miniconda.sh

    ${INSTALL_DIR}/bin/conda init bash
    source ~/.bashrc

    ${INSTALL_DIR}/bin/conda create -n ${CONDA_ENV_NAME} -y \
        python=${PYTHON_VERSION}

    ${INSTALL_DIR}/bin/conda clean -ya
else
    echo "Skipping installation Miniconda from installer"
fi
