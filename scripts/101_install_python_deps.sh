#!/bin/bash
set -e -x
# Superset of requirements for all builds, including:
#   ONNX, PyTorch, TorchVision, TorchText, TorchAudio, Detectron2 and ONNXRuntime
# From time to time, update this list with all compiled from source packages deps
# Merge contents from their requirements.txt and setup.py::setup(..., install_requires=)

ONNX_VERSION=${1-main}
PYTORCH_VERSION=${2-main}
TORCHTEXT_VERSION=${3-main}
TORCHVISION_VERSION=${4-main}
TORCHAUDIO_VERSION=${5-main}
DETECTRON2_VERSION=${6-main}
ONNXRUNTIME_VERSION=${7-main}

CONDA_PATH=$(which conda)
PYTHON_PATH=$(which python)

echo "Conda path is ${CONDA_PATH}"
echo "Python path is ${PYTHON_PATH}"

echo "Current environment:"
conda list

################################################################################
##################################### PIP ######################################
################################################################################

pip install --upgrade-strategy only-if-needed \
    parsesetup

echo "Downloading PIP requirements"

# ONNX
wget -O onnx_requirements.txt https://raw.githubusercontent.com/onnx/onnx/${ONNX_VERSION}/requirements-dev.txt
# ONNX Script
wget -O onnxscript_requirements.txt https://raw.githubusercontent.com/microsoft/onnxscript/${ONNXSCRIPT_VERSION}/requirements-dev.txt
python remove_package_from_requirements_txt.py onnxscript_requirements.txt --no-torch --no-onnxruntime --no-onnx
# Pytorch
wget -O pytorch_requirements.txt https://raw.githubusercontent.com/pytorch/pytorch/${PYTORCH_VERSION}/requirements.txt
echo beartype >> pytorch_requirements.txt
# Torch Text
git clone https://github.com/pytorch/text.git
(cd text && git checkout ${TORCHTEXT_VERSION})
(cd text && python ../requirements_from_setup_py.py setup.py ../torchtext_requirements.txt --include-extras --no-torch)
rm -rf ./text
# Torch Vision
# TODO: assumes torch is installed. mock it?
git clone https://github.com/pytorch/vision.git
(cd vision && git checkout ${TORCHVISION_VERSION})
(cd vision && python ../requirements_from_setup_py.py setup.py ../torchvision_requirements.txt --include-extras --no-torch)
echo Pillow >> torchvision_requirements.txt
rm -rf ./vision
# Torch Audio
wget -O torchaudio_requirements.txt https://raw.githubusercontent.com/pytorch/audio/${TORCHAUDIO_VERSION}/requirements.txt
python remove_package_from_requirements_txt.py torchaudio_requirements.txt --no-torch
# Detectron2
git clone https://github.com/facebookresearch/detectron2.git
(cd detectron2 && git checkout ${DETECTRON2_VERSION})
(cd detectron2 && python ../requirements_from_setup_py.py setup.py ../detectron2_requirements.txt --include-extras --no-torch)
echo opencv-python-headless >> detectron2_requirements.txt
rm -rf ./detectron2
# ONNX Runtime
wget -O onnxruntime_requirements.txt https://raw.githubusercontent.com/microsoft/onnxruntime/${ONNXRUNTIME_VERSION}/requirements-dev.txt
python remove_package_from_requirements_txt.py onnxruntime_requirements.txt --no-onnx

# Remove with any pre-installed package that will be compiled from source
pip uninstall -y onnx torch torchtext torchvision torchaudio detectron2 onnxruntime
conda list

# Install consolidated requirements
echo "Installing consolidated PIP dependencies"
pip install --upgrade-strategy only-if-needed -r <(sort -u *_requirements.txt)

################################################################################
#################################### CONDA #####################################
################################################################################
echo "Installing consolidated CONDA dependencies"

# Common packages for all builds (pip + conda)
conda install -y \
    conda-build \
    future \
    ninja \
    pkg-config \
    pyyaml \
    typing_extensions

# ONNX
# Pytorch
# Torch Text
# Torch Vision
conda install -y \
    jpeg \
    libpng
conda install -c conda-forge -y \
    av \
    accimage \
    ffmpeg
# Torch Audio
# Detectron2
# ONNX Runtime

echo "Updated environment:"
conda list

# conda cache cleaning
conda clean -ya
