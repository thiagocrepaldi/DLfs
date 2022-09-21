# syntax = docker/dockerfile:experimental
#
# NOTE: To build this you will need a docker version > 18.06 with
#       experimental enabled and DOCKER_BUILDKIT=1
#
#       For reference:
#           https://docs.docker.com/develop/develop-images/build_enhancements/

ARG BASE_IMAGE=nvidia/cuda:11.3.1-cudnn8-devel-ubuntu20.04
ARG PYTHON_VERSION=3.9
ARG CUDA_VERSION=11.3
FROM ${BASE_IMAGE} as os
SHELL ["/bin/bash", "-c"] # Bash as the default Ubuntu $SHELL

# Global (configurable) settings
ARG CUDA_CHANNEL
ARG DEBUG=0
ARG REL_WITH_DEB_INFO=0
ARG TORCH_CUDA_ARCH_LIST
ARG TORCH_NVCC_FLAGS
ARG INSTALL_OPENMPI=0

# Global (read-only) settings
ENV DEBIAN_FRONTEND="noninteractive"
ENV CUDA_CHANNEL ${CUDA_CHANNEL:-nvidia}
ENV CUDA_VERSION=${CUDA_VERSION}
ENV DEBUG=${DEBUG}
ENV TORCH_CUDA_ARCH_LIST=${TORCH_CUDA_ARCH_LIST:-"3.5 5.2 6.0 6.1 7.0+PTX 8.0"}
ENV TORCH_NVCC_FLAGS=${TORCH_NVCC_FLAGS:-"-Xfatbin -compress-all"}
ENV REL_WITH_DEB_INFO=${REL_WITH_DEB_INFO}

# Install OS-level deps, including CUDA
COPY scripts/ /tmp
RUN bash /tmp/install_os_deps.sh
RUN [ "${INSTALL_OPENMPI}" == "1" ] && bash /tmp/install_openmpi.sh
ENV CUDA_HOME=/usr/local/cuda
ENV PATH=${CUDA_HOME}/bin:${PATH}
ENV LD_LIBRARY_PATH=${CUDA_HOME}/lib64:${LD_LIBRARY_PATH}
ENV LD_LIBRARY_PATH=/usr/local/nvidia/lib:/usr/local/nvidia/lib64:${LD_LIBRARY_PATH}
# TODO: Check whether we need NVIDIA settings copied in all stages or just this common one
ENV NVIDIA_VISIBLE_DEVICES all
ENV NVIDIA_DRIVER_CAPABILITIES compute,utility
LABEL com.nvidia.volumes.needed="nvidia_driver"

# Install Python-level deps
FROM os as conda
ARG PYTHON_VERSION=3.9
RUN source /tmp/install_python_deps.sh ${PYTHON_VERSION} ${CUDA_VERSION}
SHELL ["/opt/conda/bin/conda", "run", "-n", "base", "/bin/bash", "-c"]  # Make RUN commands use conda environment
ENV CMAKE_PREFIX_PATH "$(dirname $(which conda))/../"
ENV PATH=/opt/conda/bin:${PATH}
ENV LD_LIBRARY_PATH=/opt/conda/lib:${LD_LIBRARY_PATH}

# ONNX
FROM conda as onnx
SHELL ["/opt/conda/bin/conda", "run", "-n", "base", "/bin/bash", "-c"]  # Make RUN commands use conda environment
ARG ONNX_VERSION
ENV ONNX_VERSION ${ONNX_VERSION:-main}
ENV CMAKE_ARGS "-DONNX_USE_PROTOBUF_SHARED_LIBS=ON"
WORKDIR /opt/
RUN git clone https://github.com/onnx/onnx.git onnx
WORKDIR /opt/onnx
RUN git checkout ${ONNX_VERSION}
RUN git submodule update --init --recursive --jobs 0
RUN python setup.py bdist_wheel

# PyTorch
FROM conda as torch
SHELL ["/opt/conda/bin/conda", "run", "-n", "base", "/bin/bash", "-c"]  # Make RUN commands use conda environment
ARG PYTORCH_VERSION
ENV PYTORCH_VERSION ${PYTORCH_VERSION:-master}
COPY --from=conda /opt/conda /opt/conda
WORKDIR /opt/
RUN git clone https://github.com/pytorch/pytorch.git
WORKDIR /opt/pytorch
RUN git checkout ${PYTORCH_VERSION}
RUN git submodule update --init --recursive --jobs 0
RUN python setup.py bdist_wheel

# TorchText
FROM conda as torchtext
SHELL ["/opt/conda/bin/conda", "run", "-n", "base", "/bin/bash", "-c"]  # Make RUN commands use conda environment
COPY --from=torch /opt/pytorch/dist/torch*.whl /opt
RUN pip install --no-deps /opt/torch*.whl
ARG TORCHTEXT_VERSION
ENV TORCHTEXT_VERSION ${TORCHTEXT_VERSION:-main}
WORKDIR /opt/
RUN git clone https://github.com/pytorch/text.git torchtext
WORKDIR /opt/torchtext
RUN git checkout ${TORCHTEXT_VERSION}
RUN git submodule update --init --recursive --jobs 0
RUN unset PYTORCH_VERSION && python setup.py bdist_wheel

# TorchVision
FROM conda as torchvision
SHELL ["/opt/conda/bin/conda", "run", "-n", "base", "/bin/bash", "-c"]  # Make RUN commands use conda environment
COPY --from=torch /opt/pytorch/dist/torch*.whl /opt
RUN pip install --no-deps /opt/torch*.whl
ARG TORCHVISION_VERSION
ENV TORCHVISION_VERSION ${TORCHVISION_VERSION:-main}
WORKDIR /opt/
RUN git clone https://github.com/pytorch/vision.git torchvision
WORKDIR /opt/torchvision
RUN git checkout ${TORCHVISION_VERSION}
RUN git submodule update --init --recursive --jobs 0
RUN unset PYTORCH_VERSION && FORCE_CUDA=1 python setup.py bdist_wheel

# TorchAudio
FROM conda as torchaudio
SHELL ["/opt/conda/bin/conda", "run", "-n", "base", "/bin/bash", "-c"]  # Make RUN commands use conda environment
COPY --from=torch /opt/pytorch/dist/torch*.whl /opt
RUN pip install --no-deps /opt/torch*.whl
ARG TORCHAUDIO_VERSION
ENV TORCHAUDIO_VERSION ${TORCHAUDIO_VERSION:-main}
WORKDIR /opt/
RUN git clone https://github.com/pytorch/kineto
WORKDIR /opt/kineto
RUN git submodule update --init --recursive --jobs 0
RUN mkdir build && cd build && cmake ../libkineto && make  && make install
RUN rm -rf /opt/kineto
WORKDIR /opt/
RUN git clone https://github.com/pytorch/audio.git torchaudio
WORKDIR /opt/torchaudio
RUN git checkout ${TORCHAUDIO_VERSION}
RUN git submodule update --init --recursive --jobs 0
RUN unset PYTORCH_VERSION && USE_CUDA=1 BUILD_SOX=1 python setup.py bdist_wheel

# Detectron2
FROM conda as detectron2
SHELL ["/opt/conda/bin/conda", "run", "-n", "base", "/bin/bash", "-c"]  # Make RUN commands use conda environment
COPY --from=torch /opt/pytorch/dist/torch*.whl /opt
COPY --from=torchvision /opt/torchvision/dist/torchvision*.whl /opt
RUN pip install --no-deps /opt/torch*.whl
ARG DETECTRON2_VERSION
ENV DETECTRON2_VERSION ${DETECTRON2_VERSION:-main}
ENV FVCORE_CACHE="/tmp"
WORKDIR /opt/
RUN git clone https://github.com/facebookresearch/detectron2.git detectron2
WORKDIR /opt/detectron2
RUN git checkout ${DETECTRON2_VERSION}
RUN git submodule update --init --recursive --jobs 0
RUN python setup.py bdist_wheel

# ONNX Runtime
FROM conda as onnxruntime
SHELL ["/opt/conda/bin/conda", "run", "-n", "base", "/bin/bash", "-c"]  # Make RUN commands use conda environment
COPY --from=torch /opt/pytorch/dist/torch*.whl /opt
RUN pip install --no-deps /opt/torch*.whl
ARG ONNXRUNTIME_VERSION
ARG ONNXRUNTIME_BUILD_CONFIG=RelWithDebInfo
ENV ONNXRUNTIME_VERSION ${ONNXRUNTIME_VERSION:-main}
WORKDIR /opt/
RUN git clone https://github.com/microsoft/onnxruntime.git onnxruntime
WORKDIR /opt/onnxruntime
RUN git checkout ${ONNXRUNTIME_VERSION}
RUN git submodule update --init --recursive --jobs 0
RUN bash build.sh \
        --config ${ONNXRUNTIME_BUILD_CONFIG} \
        --enable_training \
        --use_cuda \
        --cuda_home /usr/local/cuda/ \
        --cudnn_home /usr/lib/x86_64-linux-gnu/ \
        --build_wheel \
        --parallel \
        --skip_tests \
        --cuda_version=${CUDA_VERSION} \
        --enable_training_torch_interop
RUN pip install build/Linux/${ONNXRUNTIME_BUILD_CONFIG}/dist/onnxruntime*.whl
WORKDIR /workspace

# Main devel image
FROM conda as devel-all
ARG ONNXRUNTIME_BUILD_CONFIG=RelWithDebInfo
SHELL ["/opt/conda/bin/conda", "run", "-n", "base", "/bin/bash", "-c"]  # Make RUN commands use conda environment
WORKDIR /workspace
COPY --from=onnx /opt/onnx /opt/onnx
COPY --from=torch /opt/pytorch /opt/pytorch
COPY --from=torchtext /opt/torchtext /opt/torchtext
COPY --from=torchaudio /opt/torchaudio /opt/torchaudio
COPY --from=torchvision /opt/torchvision /opt/torchvision
COPY --from=detectron2 /opt/detectron2 /opt/detectron2
COPY --from=onnxruntime /opt/onnxruntime /opt/onnxruntime
RUN pip install /opt/onnx/dist/onnx*.whl
RUN pip install /opt/pytorch/dist/torch*.whl
RUN pip install /opt/torchtext/dist/torchtext*.whl
RUN pip install /opt/torchaudio/dist/torchaudio*.whl
RUN pip install /opt/torchvision/dist/torchvision*.whl
RUN pip install /opt/detectron2/dist/detectron2*.whl
RUN pip install /opt/onnxruntime/build/Linux/${ONNXRUNTIME_BUILD_CONFIG}/dist/onnxruntime*.whl
RUN ONNXRUNTIME_FORCE_CUDA=1 python -m onnxruntime.training.ortmodule.torch_cpp_extensions.install
