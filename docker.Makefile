# TODO(thiagofc): create runtime image
# TODO(thiagofc): migrate to cmake?

# Example call:
#	make -f docker.Makefile \
#		DOCKER_ORG=thiagocrepaldi \
#		DOCKER_IMAGE=dlfs \
# 		DOCKER_SUFFIX_TAG="$(date +%Y%m%d-%H%M%S)-ubuntu2004-cu113-cudnn8-py39-onnx-torch-vision-text-audio-detectron2-onnxruntime" \
#		BASE_RUNTIME=ubuntu:20.04 \
#		CUDA_VERSION=11.3.1 \
#		PYTHON_VERSION=3.9 \
#		ONNX_VERSION=main \
#		PYTORCH_VERSION=master \
#		TORCHVISION_VERSION=main \
#		TORCHTEXT_VERSION=main \
#		TORCHAUDIO_VERSION=main \
#		DETECTRON2_VERSION=main \
#		ONNXRUNTIME_VERSION=thiagofc/add-col2im-contrib-op


DOCKER_REGISTRY           = docker.io
DOCKER_ORG                = $(shell docker info 2>/dev/null | sed '/Username:/!d;s/.* //')
DOCKER_IMAGE              = dlfs
DOCKER_FULL_NAME          = $(DOCKER_REGISTRY)/$(DOCKER_ORG)/$(DOCKER_IMAGE)
DOCKER_SUFFIX_TAG         = $(shell date +%Y%m%d-%H%M%S)

ifeq ("$(DOCKER_ORG)","")
$(warning WARNING: No docker user found using results from whoami)
DOCKER_ORG                = $(shell whoami)
endif

CUDA_VERSION              = 11.3
CUDNN_VERSION             = 8
BASE_RUNTIME              = ubuntu:20.04
_BASE_RUNTIME_ESCAPED := $(subst $e:,,$(BASE_RUNTIME))
BASE_DEVEL                = nvidia/cuda:$(CUDA_VERSION)-cudnn$(CUDNN_VERSION)-devel-$(_BASE_RUNTIME_ESCAPED)

CUDA_CHANNEL              = nvidia  # Conda channel used to install cudatoolkit
PYTHON_VERSION            = 3.9
ONNX_VERSION              = main
PYTORCH_VERSION           = master
TORCHTEXT_VERSION         = main
TORCHAUDIO_VERSION        = main
TORCHVISION_VERSION       = main
DETECTRON2_VERSION        = main
ONNXRUNTIME_VERSION       = master

# Can be either official / dev
BUILD_TYPE                = dev
BUILD_PROGRESS            = auto
BUILD_ARGS                = --build-arg BASE_IMAGE=$(BASE_IMAGE) \
							--build-arg PYTHON_VERSION=$(PYTHON_VERSION) \
							--build-arg CUDA_VERSION=$(CUDA_VERSION) \
							--build-arg CUDA_CHANNEL=$(CUDA_CHANNEL) \
							--build-arg ONNX_VERSION=$(ONNX_VERSION) \
							--build-arg PYTORCH_VERSION=$(PYTORCH_VERSION) \
							--build-arg TORCHVISION_VERSION=$(TORCHVISION_VERSION) \
							--build-arg TORCHTEXT_VERSION=$(TORCHTEXT_VERSION) \
							--build-arg TORCHAUDIO_VERSION=$(TORCHAUDIO_VERSION) \
							--build-arg DETECTRON2_VERSION=$(DETECTRON2_VERSION) \
							--build-arg ONNXRUNTIME_VERSION=$(ONNXRUNTIME_VERSION)
DOCKER_BUILDKIT           = 1
EXTRA_DOCKER_BUILD_FLAGS ?=
DOCKER_BUILD              = DOCKER_BUILDKIT=$(DOCKER_BUILDKIT) \
							docker build \
								--progress=$(BUILD_PROGRESS) \
								$(EXTRA_DOCKER_BUILD_FLAGS) \
								--target $(BUILD_TYPE) \
								-t $(DOCKER_FULL_NAME):$(DOCKER_TAG) \
								$(BUILD_ARGS) .
DOCKER_PUSH               = docker push $(DOCKER_FULL_NAME):$(DOCKER_TAG)

.PHONY: all
all: devel-image

.PHONY: devel-image
devel-image: BASE_IMAGE := $(BASE_DEVEL)
devel-image: DOCKER_TAG := devel-$(DOCKER_SUFFIX_TAG)
devel-image:
	$(DOCKER_BUILD)

.PHONY: devel-image
devel-push: BASE_IMAGE := $(BASE_DEVEL)
devel-push: DOCKER_TAG := devel-$(DOCKER_SUFFIX_TAG)
devel-push:
	$(DOCKER_PUSH)

.PHONY: runtime-image
runtime-image: BASE_IMAGE := $(BASE_RUNTIME)
runtime-image: DOCKER_TAG := runtime-$(DOCKER_SUFFIX_TAG)
runtime-image:
	$(DOCKER_BUILD)

.PHONY: runtime-image
runtime-push: BASE_IMAGE := $(BASE_RUNTIME)
runtime-push: DOCKER_TAG := runtime-$(DOCKER_SUFFIX_TAG)
runtime-push:
	$(DOCKER_PUSH)

.PHONY: clean
clean:
	-docker rmi -f $(shell docker images -q $(DOCKER_FULL_NAME))
