#!/bin/bash
set -e -x
# Superset of requirements for all builds, including:
#   ONNX, PyTorch, TorchVision, TorchText, TorchAudio, Detectron2 and ONNXRuntime
# From time to time, update this list with all compiled from source packages deps
# Merge contents from their requirements.txt and setup.py::setup(..., install_requires=)


PYTHON_VERSION=${1}
CUDA_VERSION=${2}

INSTALL_DIR=/opt/conda
CUDA_VERSION_ESCAPED=$(echo ${CUDA_VERSION/./} | cut -d\. -f 1)
PYTHON_VERSION_ESCAPED=$(echo ${PYTHON_VERSION/./} | cut -d\. -f 1)
curl -fsSL -v -o /tmp/miniconda.sh -O  https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
chmod +x /tmp/miniconda.sh
/tmp/miniconda.sh -b -p ${INSTALL_DIR}
rm /tmp/miniconda.sh

${INSTALL_DIR}/bin/conda init bash
source ~/.bashrc

${INSTALL_DIR}/bin/conda install --freeze-installed -y \
    python=${PYTHON_VERSION} \
    astunparse \
    cffi \
    conda-build \
    dataclasses \
    future \
    ninja \
    numpy \
    pkg-config \
    protobuf \
    pyyaml \
    requests \
    six \
    typing_extensions

${INSTALL_DIR}/bin/conda install --freeze-installed -y -c pytorch \
    magma-cuda${CUDA_VERSION_ESCAPED}

${INSTALL_DIR}/bin/conda install --freeze-installed -y -c conda-forge \
    cmake=3.24.3  # ONNX Runtime main branch (>= 1.13) requirement

${INSTALL_DIR}/bin/python -mpip install --no-deps \
    "cerberus" \
    "cloudpickle" \
    "fairscale" \
    "ffmpeg" \
    "flatbuffers" \
    "fvcore>=0.1.5,<0.1.6" \
    "h5py" \
    "hydra-core>=1.1" \
    "iopath>=0.1.7,<0.1.10" \
    "ipython" \
    "matplotlib" \
    "mpmath" \
    "omegaconf>=2.1" \
    "onnxconverter-common>=1.7.0" \
    "onnxmltools" \
    "opencv-python-headless" \
    "packaging" \
    "pandas" \
    "parameterized>=0.8.1" \
    "Pillow>=7.1" \
    "pycocotools>=2.0.2" \
    "pyparsing" \
    "scikit-learn" \
    "scipy" \
    "setuptools>=41.4.0" \
    "skl2onnx" \
    "sympy" \
    "tabulate" \
    "tensorboard" \
    "termcolor>=1.1" \
    "timm" \
    "torchdata" \
    "tqdm>4.29.0" \
    "yacs>=0.1.8"

${INSTALL_DIR}/bin/conda clean -ya
