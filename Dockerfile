# syntax = docker/dockerfile:experimental
#
# NOTE: To build this you will need a docker version > 18.06 with
#       experimental enabled and DOCKER_BUILDKIT=1
#
#       For reference:
#           https://docs.docker.com/develop/develop-images/build_enhancements/

# TODO: How to handle images that already define variables below
#       e.g. CUDA_VERSION may be set as env var in images, conflicting with the vars below

ARG BASE_IMAGE="ptebic.azurecr.io/internal/azureml/aifx/nightly-ubuntu2004-cu117-py38-torch210dev:latest"
ARG PYTHON_VERSION="3.8"
ARG CUDA_VERSION="11.7.0"
FROM ${BASE_IMAGE} as os
SHELL ["/bin/bash", "-c"] # Bash as the default Ubuntu $SHELL

# Global (configurable) settings
ARG DEBUG="0"
ARG REL_WITH_DEB_INFO="0"
ARG TORCH_CUDA_ARCH_LIST
ARG TORCH_NVCC_FLAGS
ARG INSTALL_OPENMPI
ARG INSTALL_PROTOBUF
ARG DOCKER_SCRIPTS="/opt/scripts/"

# Global (read-only) settings
ENV GIT_REPOS_DIR="/opt"
ENV TEMP_DIR="/opt"
ENV CONDA_INSTALL_DIR="/opt/conda"
ENV DEFAULT_CONDA_ENV="ptca"
ENV DEBIAN_FRONTEND="noninteractive"
ENV CUDA_HOME="/usr/local/cuda"
ENV CUDA_VERSION="${CUDA_VERSION}"
ENV DEBUG="${DEBUG}"
ENV TORCH_CUDA_ARCH_LIST="${TORCH_CUDA_ARCH_LIST:-3.5 5.2 6.0 6.1 7.0+PTX 8.0}"
ENV TORCH_NVCC_FLAGS="${TORCH_NVCC_FLAGS:-'-Xfatbin -compress-all'}"
ENV REL_WITH_DEB_INFO="${REL_WITH_DEB_INFO}"
ENV NVIDIA_VISIBLE_DEVICES="all"
ENV NVIDIA_DRIVER_CAPABILITIES="compute,utility"
LABEL com.nvidia.volumes.needed="nvidia_driver"

# Install OS-level deps, including CUDA
COPY scripts/ ${DOCKER_SCRIPTS}
RUN ${DOCKER_SCRIPTS}/000_ubuntu_apt_packages.sh ${DOCKER_SCRIPTS}
RUN ${DOCKER_SCRIPTS}/005_cmake_from_tarball.sh 3.26.0 ${GIT_REPOS_DIR}
RUN ${DOCKER_SCRIPTS}/010_protobuf_from_source.sh ${INSTALL_PROTOBUF} ${GIT_REPOS_DIR}
RUN ${DOCKER_SCRIPTS}/015_openmpi4_from_source.sh ${INSTALL_OPENMPI} ${GIT_REPOS_DIR}

# Install Python-level deps
FROM os as conda
ARG DOCKER_SCRIPTS
ARG PYTHON_VERSION
ARG ONNX_VERSION
ARG ONNXSCRIPT_VERSION
ARG PYTORCH_VERSION
ARG TORCHTEXT_VERSION
ARG TORCHVISION_VERSION
ARG TORCHAUDIO_VERSION
ARG DETECTRON2_VERSION
ARG ONNXRUNTIME_VERSION
WORKDIR ${DOCKER_SCRIPTS}
RUN ${DOCKER_SCRIPTS}/100_miniconda_from_installer.sh ${PYTHON_VERSION} ${TEMP_DIR}
RUN ${DOCKER_SCRIPTS}/101_install_python_deps.sh ${ONNX_VERSION} ${ONNXSCRIPT_VERSION} ${PYTORCH_VERSION} ${TORCHTEXT_VERSION} ${TORCHVISION_VERSION} ${TORCHAUDIO_VERSION} ${DETECTRON2_VERSION} ${ONNXRUNTIME_VERSION} ${DOCKER_SCRIPTS} ${GIT_REPOS_DIR}

# ONNX
FROM conda as onnx
ARG ONNX_VERSION
WORKDIR /opt/
RUN ${DOCKER_SCRIPTS}/105_onnx_from_source.sh ${ONNX_VERSION} ${GIT_REPOS_DIR}

# ONNX Script
FROM conda as onnxscript
ARG ONNXSCRIPT_VERSION
WORKDIR /opt/
RUN ${DOCKER_SCRIPTS}/107_onnxscript_from_source.sh ${ONNXSCRIPT_VERSION} ${GIT_REPOS_DIR}

# PyTorch
FROM conda as torch
ARG PYTORCH_VERSION
ENV PYTORCH_BUILD_VERSION=
ENV PYTORCH_BUILD_NUMBER=
WORKDIR /opt/
RUN ${DOCKER_SCRIPTS}/110_pytorch_from_source.sh ${PYTORCH_VERSION} ${GIT_REPOS_DIR}

# TorchText
FROM conda as torchtext
ARG TORCHTEXT_VERSION
ENV PYTORCH_VERSION=
ENV BUILD_VERSION=
COPY --from=torch /opt/pytorch/dist/torch*.whl /opt
RUN pip install --no-deps /opt/torch*.whl
WORKDIR /opt/
RUN ${DOCKER_SCRIPTS}/115_torchtext_from_source.sh ${TORCHTEXT_VERSION} ${GIT_REPOS_DIR}

# TorchVision
FROM conda as torchvision
ARG TORCHVISION_VERSION
ENV PYTORCH_VERSION=
ENV BUILD_VERSION=
COPY --from=torch /opt/pytorch/dist/torch*.whl /opt
RUN pip install --no-deps /opt/torch*.whl
WORKDIR /opt/
RUN ${DOCKER_SCRIPTS}/120_torchvision_from_source.sh ${TORCHVISION_VERSION} ${GIT_REPOS_DIR}

# TorchAudio
FROM conda as torchaudio
ARG TORCHAUDIO_VERSION
ENV PYTORCH_VERSION=
ENV BUILD_VERSION=
COPY --from=torch /opt/pytorch/dist/torch*.whl /opt
RUN pip install --no-deps /opt/torch*.whl
WORKDIR /opt/
RUN ${DOCKER_SCRIPTS}/125_torchaudio_from_source.sh ${TORCHAUDIO_VERSION} ${GIT_REPOS_DIR}

# Detectron2
FROM conda as detectron2
ARG DETECTRON2_VERSION
# ENV BUILD_NIGHTLY=
COPY --from=torch /opt/pytorch/dist/torch*.whl /opt
COPY --from=torchvision /opt/torchvision/dist/torchvision-*.whl /opt
RUN pip install --no-deps /opt/torch*.whl
WORKDIR /opt/
RUN ${DOCKER_SCRIPTS}/130_detectron2_from_source.sh ${DETECTRON2_VERSION} ${GIT_REPOS_DIR}

# ONNX Runtime
FROM conda as onnxruntime
ARG ONNXRUNTIME_VERSION
ARG ONNXRUNTIME_BUILD_CONFIG=RelWithDebInfo
ARG CUDA_VERSION
COPY --from=torch /opt/pytorch/dist/torch*.whl /opt
RUN pip install --no-deps /opt/torch*.whl
WORKDIR /opt/
RUN ${DOCKER_SCRIPTS}/135_onnxruntime_from_source.sh ${ONNXRUNTIME_VERSION} ${ONNXRUNTIME_BUILD_CONFIG} ${CUDA_VERSION} ${GIT_REPOS_DIR}

# Main devel image
FROM conda as devel-all
ARG ONNXRUNTIME_BUILD_CONFIG=RelWithDebInfo
WORKDIR /workspace
ENV PYTORCH_BUILD_VERSION=
ENV PYTORCH_BUILD_NUMBER=
COPY --from=onnx ${GIT_REPOS_DIR}/onnx ${GIT_REPOS_DIR}/onnx
COPY --from=onnxscript ${GIT_REPOS_DIR}/onnxscript ${GIT_REPOS_DIR}/onnxscript
COPY --from=torch ${GIT_REPOS_DIR}/pytorch ${GIT_REPOS_DIR}/pytorch
COPY --from=torchtext ${GIT_REPOS_DIR}/torchtext ${GIT_REPOS_DIR}/torchtext
COPY --from=torchaudio ${GIT_REPOS_DIR}/torchaudio ${GIT_REPOS_DIR}/torchaudio
COPY --from=torchvision ${GIT_REPOS_DIR}/torchvision ${GIT_REPOS_DIR}/torchvision
COPY --from=detectron2 ${GIT_REPOS_DIR}/detectron2 ${GIT_REPOS_DIR}/detectron2
COPY --from=onnxruntime ${GIT_REPOS_DIR}/onnxruntime ${GIT_REPOS_DIR}/onnxruntime
RUN pip install --no-deps ${GIT_REPOS_DIR}/onnx/dist/onnx-*.whl
RUN pip install --no-deps ${GIT_REPOS_DIR}/onnxscript/dist/onnxscript-*.whl
RUN pip install --no-deps ${GIT_REPOS_DIR}/pytorch/dist/torch-*.whl
RUN pip install --no-deps ${GIT_REPOS_DIR}/torchtext/dist/torchtext-*.whl
RUN pip install --no-deps ${GIT_REPOS_DIR}/torchaudio/dist/torchaudio-*.whl
RUN pip install --no-deps ${GIT_REPOS_DIR}/torchvision/dist/torchvision-*.whl
RUN pip install --no-deps ${GIT_REPOS_DIR}/detectron2/dist/detectron2-*.whl
RUN pip install --no-deps ${GIT_REPOS_DIR}/onnxruntime/build/Linux/${ONNXRUNTIME_BUILD_CONFIG}/dist/onnxruntime*.whl
RUN ONNXRUNTIME_FORCE_CUDA=1 python -m onnxruntime.training.ortmodule.torch_cpp_extensions.install

# Main devel image
FROM devel-all as test-all
RUN pip install pytest coverage hypothesis expecttest mypy
WORKDIR ${GIT_REPOS_DIR}/pytorch
RUN make setup_lint
RUN lintrunner init
