# syntax = docker/dockerfile:experimental
#
# NOTE: Based on PyTorch's implementation
# NOTE: To build this you will need a docker version > 18.06 with
#       experimental enabled and DOCKER_BUILDKIT=1
#
#       If you do not use buildkit you are not going to have a good time
#
#       For reference:
#           https://docs.docker.com/develop/develop-images/build_enhancements/

ARG BASE_IMAGE=ubuntu:20.04
ARG PYTHON_VERSION=3.9
ARG CUDA_VERSION=11.3
FROM ${BASE_IMAGE} as dev-base
SHELL ["/bin/bash", "-c"] # Bash as the default Ubuntu $SHELL
ARG DEBIAN_FRONTEND=noninteractive # Make sure apt installed packages are not interactive

# Unified CUDA settings
ARG CUDA_CHANNEL
ARG TORCH_CUDA_ARCH_LIST
ARG TORCH_NVCC_FLAGS
ENV CUDA_VERSION=${CUDA_VERSION}
ENV TORCH_CUDA_ARCH_LIST=${TORCH_CUDA_ARCH_LIST:-"3.5 5.2 6.0 6.1 7.0+PTX 8.0"}
ENV TORCH_NVCC_FLAGS=${TORCH_NVCC_FLAGS:-"-Xfatbin -compress-all"}
ENV CUDA_CHANNEL ${CUDA_CHANNEL:-nvidia}

# Fix NVidia GPG signatures on Ubuntu. Thanks nvidia :-S
RUN apt-key del 7fa2af80
RUN rm -f /etc/apt/sources.list.d/cuda.list
RUN rm -f /etc/apt/sources.list.d/nvidia-ml.list
RUN apt-key adv --fetch-keys https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2004/x86_64/3bf863cc.pub
RUN echo "deb https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2004/x86_64/ /" > /etc/apt/sources.list.d/cuda.list

# Install OS-level dependencies for all build stages
RUN --mount=type=cache,id=apt-dev,target=/var/cache/apt \
    apt-get update && apt-get install -y --no-install-recommends \
        apt-transport-https \
        apt-utils \
        build-essential \
        ca-certificates \
        ccache \
        cmake \
        curl \
        git \
        gnupg \
        libjpeg-dev \
        libpng-dev \
        libprotobuf-dev \
        pkg-config \
        protobuf-compiler \
        unzip \
        zip && \
    rm -rf /var/lib/apt/lists/*
RUN /usr/sbin/update-ccache-symlinks
RUN mkdir /opt/ccache && ccache --set-config=cache_dir=/opt/ccache
ENV PATH /opt/conda/bin:$PATH

FROM dev-base as dev-base-plus-conda
ARG PYTHON_VERSION=3.9
RUN curl -fsSL -v -o ~/miniconda.sh -O  https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh  && \
    chmod +x ~/miniconda.sh && \
    ~/miniconda.sh -b -p /opt/conda && \
    rm ~/miniconda.sh && \
    /opt/conda/bin/conda install -y python=${PYTHON_VERSION} cmake conda-build pyyaml numpy ipython ninja mkl-include && \
    /opt/conda/bin/conda clean -ya
ENV CMAKE_PREFIX_PATH "$(dirname $(which conda))/../"

FROM dev-base-plus-conda as onnx-build
ARG ONNX_VERSION
ENV ONNX_VERSION ${ONNX_VERSION:-main}
ENV CMAKE_ARGS "-DONNX_USE_PROTOBUF_SHARED_LIBS=ON"
WORKDIR /opt/
RUN git clone https://github.com/onnx/onnx.git onnx
WORKDIR /opt/onnx
RUN git checkout ${ONNX_VERSION}
RUN git submodule update --init --recursive --jobs 0
RUN /opt/conda/bin/python -mpip install --no-deps -r requirements-dev.txt && \
    /opt/conda/bin/conda clean -ya
RUN /opt/conda/bin/python setup.py develop

FROM onnx-build as torch-build
ARG PYTORCH_VERSION
ENV NVIDIA_VISIBLE_DEVICES all
ENV NVIDIA_DRIVER_CAPABILITIES compute,utility
ENV LD_LIBRARY_PATH /usr/local/nvidia/lib:/usr/local/nvidia/lib64
ENV PYTORCH_VERSION ${PYTORCH_VERSION:-master}
LABEL com.nvidia.volumes.needed="nvidia_driver"
COPY --from=dev-base-plus-conda /opt/conda /opt/conda
WORKDIR /opt/
RUN git clone https://github.com/pytorch/pytorch.git
WORKDIR /opt/pytorch
RUN git checkout ${PYTORCH_VERSION}
RUN git submodule update --init --recursive --jobs 0
RUN /opt/conda/bin/python -mpip install --no-deps -r requirements.txt && \
    /opt/conda/bin/python -mpip install --no-deps -r .circleci/docker/requirements-ci.txt && \
    /opt/conda/bin/python -mpip install --no-deps torchelastic && \
    /opt/conda/bin/conda install -y --no-deps -c ${CUDA_CHANNEL} cudatoolkit=${CUDA_VERSION} && \
    /opt/conda/bin/conda clean -ya
RUN --mount=type=cache,target=/opt/ccache \
    /opt/conda/bin/python setup.py develop

FROM torch-build as torch-text-build
ARG TORCHTEXT_VERSION
ENV TORCHTEXT_VERSION ${TORCHTEXT_VERSION:-main}
WORKDIR /opt/
RUN git clone https://github.com/pytorch/text.git torchtext
WORKDIR /opt/torchtext
RUN git checkout ${TORCHTEXT_VERSION}
RUN git submodule update --init --recursive --jobs 0
RUN /opt/conda/bin/python -mpip install --no-deps -r requirements.txt && \
    /opt/conda/bin/conda clean -ya
RUN unset PYTORCH_VERSION && /opt/conda/bin/python setup.py develop

FROM torch-text-build as torch-vision-build
ARG TORCHVISION_VERSION
ENV TORCHVISION_VERSION ${TORCHVISION_VERSION:-main}
WORKDIR /opt/
RUN git clone https://github.com/pytorch/vision.git torchvision
WORKDIR /opt/torchvision
RUN git checkout ${TORCHVISION_VERSION}
RUN git submodule update --init --recursive --jobs 0
RUN unset PYTORCH_VERSION && /opt/conda/bin/python setup.py develop

FROM torch-vision-build as torch-audio-build
ARG TORCHAUDIO_VERSION
ENV TORCHAUDIO_VERSION ${TORCHAUDIO_VERSION:-main}
WORKDIR /opt/
RUN git clone https://github.com/pytorch/audio.git torchaudio
WORKDIR /opt/torchaudio
RUN git checkout ${TORCHAUDIO_VERSION}
RUN git submodule update --init --recursive --jobs 0
RUN /opt/conda/bin/python -mpip install --no-deps -r requirements.txt && \
    /opt/conda/bin/conda clean -ya
RUN unset PYTORCH_VERSION && /opt/conda/bin/python setup.py develop

FROM torch-audio-build as detectron2-build
ARG DETECTRON2_VERSION
ENV DETECTRON2_VERSION ${DETECTRON2_VERSION:-main}
ENV FORCE_CUDA="1"
ENV FVCORE_CACHE="/tmp"
WORKDIR /opt/
RUN /opt/conda/bin/python -mpip install --no-deps git+https://github.com/facebookresearch/fvcore
RUN git clone https://github.com/facebookresearch/detectron2.git detectron2
WORKDIR /opt/detectron2
RUN git checkout ${DETECTRON2_VERSION}
RUN git submodule update --init --recursive --jobs 0
RUN /opt/conda/bin/python setup.py develop

FROM detectron2-build as onnxruntime-build
ARG ONNXRUNTIME_VERSION
ARG ONNXRUNTIME_BUILD_CONFIG=RelWithDebInfo
ENV ONNXRUNTIME_VERSION ${ONNXRUNTIME_VERSION:-master}
WORKDIR /opt/
RUN git clone https://github.com/microsoft/onnxruntime.git onnxruntime
WORKDIR /opt/onnxruntime
RUN git checkout ${ONNXRUNTIME_VERSION}
RUN git submodule update --init --recursive --jobs 0
RUN /opt/conda/bin/python -mpip install --no-deps -r requirements-dev.txt && \
    /opt/conda/bin/python -mpip install --no-deps -r requirements-training.txt && \
    /opt/conda/bin/conda clean -ya
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
ENV PYTHONPATH /opt/onnxruntime/build/Linux/${ONNXRUNTIME_BUILD_CONFIG}:${PYTHONPATH}
WORKDIR /opt
# TODO(thiagofc): Need CUDA env. For now, run this manually inside the container
#                   Check how Detectron2's FORCE_CUDA=1 works to do it here
# RUN /opt/conda/bin/python -m onnxruntime.training.ortmodule.torch_cpp_extensions.install

FROM onnxruntime-build as dev
WORKDIR /workspace
