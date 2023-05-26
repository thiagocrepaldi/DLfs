#!/bin/bash
set -e -x
# Superset of requirements for all builds, including:
#   ONNX, PyTorch, TorchVision, TorchText, TorchAudio, Detectron2 and ONNXRuntime
# From time to time, update this list with all compiled from source packages deps
# Merge contents from their requirements.txt and setup.py::setup(..., install_requires=)

ONNX_VERSION=${1-"main"}
ONNXSCRIPT_VERSION=${2-"main"}
PYTORCH_VERSION=${3-"main"}
TORCHTEXT_VERSION=${4-"main"}
TORCHVISION_VERSION=${5-"main"}
TORCHAUDIO_VERSION=${6-"main"}
DETECTRON2_VERSION=${7-"main"}
ONNXRUNTIME_VERSION=${8-"main"}

ROOT_DIR=${9:-"/opt/scripts"}
TEMP_DIR=${10:-"/tmp"}
GUARD_FILE="${ROOT_DIR}/___PYTHON_DEPS_INSTALLED___"

if [ ! -f ${GUARD_FILE} ]
then
    echo "Installing Python packages from pip/conda repo"

    source ${CONDA_INSTALL_DIR}/bin/activate ${DEFAULT_CONDA_ENV}
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

    echo "Downloading PIP requirements at `pwd`"

    # ONNX
    wget -O ${TEMP_DIR}/onnx_requirements.txt https://raw.githubusercontent.com/onnx/onnx/${ONNX_VERSION}/requirements-dev.txt
    python ${ROOT_DIR}/remove_package_from_requirements_txt.py ${TEMP_DIR}/onnx_requirements.txt --no-protobuf
    # ONNX Script
    wget -O ${TEMP_DIR}/onnxscript_requirements.txt https://raw.githubusercontent.com/microsoft/onnxscript/${ONNXSCRIPT_VERSION}/requirements-dev.txt
    python ${ROOT_DIR}/remove_package_from_requirements_txt.py ${TEMP_DIR}/onnxscript_requirements.txt --no-torch --no-onnxruntime --no-onnx
    # Pytorch
    wget -O ${TEMP_DIR}/pytorch_requirements.txt https://raw.githubusercontent.com/pytorch/pytorch/${PYTORCH_VERSION}/requirements.txt
    echo beartype >> ${TEMP_DIR}/pytorch_requirements.txt
    # Torch Text
    git clone https://github.com/pytorch/text.git ${ROOT_DIR}/torchtext
    (cd ${ROOT_DIR}/torchtext && git checkout ${TORCHTEXT_VERSION})
    (cd ${ROOT_DIR}/torchtext && python ${ROOT_DIR}/requirements_from_setup_py.py setup.py ${TEMP_DIR}/torchtext_requirements.txt --include-extras --no-torch)
    rm -rf ${ROOT_DIR}/torchtext
    # Torch Vision
    # TODO: assumes torch is installed. mock it?
    git clone https://github.com/pytorch/vision.git ${ROOT_DIR}/torchvision
    (cd ${ROOT_DIR}/torchvision && git checkout ${TORCHVISION_VERSION})
    (cd ${ROOT_DIR}/torchvision && python ${ROOT_DIR}/requirements_from_setup_py.py setup.py ${TEMP_DIR}/torchvision_requirements.txt --include-extras --no-torch)
    echo Pillow >> ${TEMP_DIR}/torchvision_requirements.txt
    rm -rf ${ROOT_DIR}/torchvision
    # Torch Audio
    wget -O ${TEMP_DIR}/torchaudio_requirements.txt https://raw.githubusercontent.com/pytorch/audio/${TORCHAUDIO_VERSION}/requirements.txt
    python ${ROOT_DIR}/remove_package_from_requirements_txt.py ${TEMP_DIR}/torchaudio_requirements.txt --no-torch
    # Detectron2
    git clone https://github.com/facebookresearch/detectron2.git ${ROOT_DIR}/detectron2
    (cd ${ROOT_DIR}/detectron2 && git checkout ${DETECTRON2_VERSION})
    (cd ${ROOT_DIR}/detectron2 && python ${ROOT_DIR}/requirements_from_setup_py.py setup.py ${TEMP_DIR}/detectron2_requirements.txt --include-extras --no-torch)
    echo opencv-python-headless >> ${TEMP_DIR}/detectron2_requirements.txt
    rm -rf ${ROOT_DIR}/detectron2
    # ONNX Runtime
    wget -O ${TEMP_DIR}/onnxruntime_requirements.txt https://raw.githubusercontent.com/microsoft/onnxruntime/${ONNXRUNTIME_VERSION}/requirements-dev.txt
    python ${ROOT_DIR}/remove_package_from_requirements_txt.py ${TEMP_DIR}/onnxruntime_requirements.txt --no-onnx --no-protobuf

    # Remove with any pre-installed package that will be compiled from source
    pip uninstall -y onnx torch torchtext torchvision torchaudio detectron2 onnxruntime onnxruntime-training
    conda list

    # Install consolidated requirements
    echo "Installing consolidated PIP dependencies"
    pip install --upgrade-strategy only-if-needed -r <(sort -u ${TEMP_DIR}/*_requirements.txt)

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

    touch ${GUARD_FILE}
else
    echo "Skipping Python packages from pip/conda repo"
fi

echo "Current environment:"
conda list

# conda cache cleaning
conda clean -ya
