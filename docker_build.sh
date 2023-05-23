#!/bin/bash
set -e

# Docker Builder settings
export DOCKER_BUILDKIT=1
export BUILDKIT_INLINE_CACHE=1
export BUILD_PROGRESS=auto  # Use 'plain' for verbose output

# Docker Image settings
DOCKER_REGISTRY=docker.io
DOCKER_ORG=thiagocrepaldi
DOCKER_IMAGE=dlfs
DOCKER_FULL_NAME=${DOCKER_REGISTRY}/${DOCKER_ORG}/${DOCKER_IMAGE}
BASE_IMAGE=${DOCKER_FULL_NAME}
UNIQUE_ID="$(date +%Y%m%d)"
BUILD_TARGET=""
DOCKERFILE="Dockerfile"
PUSH_IMAGE=1

# Packages compiled from source
PYTHON_VERSION=3.8
CUDA_VERSION=11.7.0
ONNX_VERSION=main
ONNXSCRIPT_VERSION=main
PYTORCH_VERSION=main
TORCHVISION_VERSION=main
TORCHTEXT_VERSION=main
TORCHAUDIO_VERSION=main
DETECTRON2_VERSION=main
ONNXRUNTIME_VERSION=main
INSTALL_PROTOBUF=0
INSTALL_OPENMPI=0

# Input parsing
help()
{
    echo "Usage: docker_build.sh
                [ -a | --torchaudio ]   # github.com/pytorch/audio commit/branch/tag (default is main)
                [ -b | --base_os ]      # Docker image (default is ptebic.azurecr.io/internal/azureml/aifx/nightly-ubuntu2004-cu117-py38-torch210dev:latest)
                [ -c | --cuda ]         # CUDA version (default is 11.7.0)
                [ -d | --detectron2 ]   # github.com/facebookresearch/detectron2 commit/branch/tag (default is main)
                [ -e | --torchtext ]    # github.com/pytorch/text commit/branch/tag (default is main)
                [ -f | --dockerfile ]   # Dockerfile name within root folder (default is Dockerfile)
                [ -g | --target ]       # Docker build target (default is __ALL__)
                                        # One of (__ALL__, __LAST__, os, conda, onnx, torch, torchtext, torchaudio, torchvision, detectron2, onnxruntime)
                                        #         __ALL__ must be set to build all targets available (only for multi-stage Dockerfile)
                                        #         __LAST__ must be set to build the last stage which combines all previous (only for multi-stage Dockerfile)
                [ -i | --id ]           # Unique ID to be added to the resulting Docker image name (default is YYYYMMDD)
                [ -m | --openmpi ]      # Builds open MPI 4.0 from source (tarball) (default is 1)
                [ -l | --protobuf ]     # Builds Protobuf from source (tarball) (default is 1)
                [ -o | --onnx ]         # github.com/onnx/onnx commit/branch/tag (default is main)
                [ -p | --python ]       # python version (default is 3.8)
                [ -r | --onnxruntime ]  # github.com/microsoft/onnxruntime commit/branch/tag (default is main)
                [ -t | --torch ]        # github.com/pytorch/torch commit/branch/tag (default is main)
                [ -u | --push ]         # Push image after it is built (default is 1)
                [ -v | --torchvision ]  # github.com/pytorch/torchvision commit/branch/tag (default is main)
                [ -x | --onnxscript ]   # github.com/microsoft/onnxscript commit/branch/tag (default is main)
                [ -h | --help  ]        # This message :)

        IMPORTANT: ALL parameters, but -h, MUST be specified. If you know how to getopts to play nice with optional arguments, please fix this :)

        EXAMPLE: Build all stages of Dockerfile and push them to docker.io/thiagocrepaldi/dlfs:devel-ID-<build_stage>
            ./docker_build.sh -a main -b ptebic.azurecr.io/internal/azureml/aifx/nightly-ubuntu2004-cu117-py38-torch210dev:latest -c 11.7.0 -d main -e main -f Dockerfile -g __ALL__ -i 20230518 -l 1 -m 0 -o main -p 3.8 -r main -t main -u 0 -v main -x main
        "
    exit 2
}
SHORT=a:,b:,c:,d:,e:,f:,g:,i:,l:,m:,o:,p:,r:,t:,u:,v:,x:,h
LONG=torchaudio:,base_os:,cuda:,detectron2:,torchtext:,dockerfile:,target:,id:,protobuf:,openmpi:,onnx:,python:,onnxruntime:,torch:,push:,torchvision:,onnxscript:,help
OPTS=$(getopt -a -n build --options $SHORT --longoptions $LONG -- "$@")
VALID_ARGUMENTS=$#  # Returns the count of arguments that are in short or long options
if [ ! "$VALID_ARGUMENTS" -eq 34 ]
then
    help
fi
eval set -- "$OPTS"
while :
do
  case "$1" in
    -a | --torchaudio )
      TORCHAUDIO_VERSION="$2"
      shift 2
      ;;
    -b | --base_os )
      BASE_IMAGE="$2"
      shift 2
      ;;
    -c | --cuda )
      CUDA_VERSION="$2"
      shift 2
      ;;
    -d | --detectron2 )
      DETECTRON2_VERSION="$2"
      shift 2
      ;;
    -e | --torchtext )
      TORCHTEXT_VERSION="$2"
      shift 2
      ;;
    -f | --dockerfile )
      DOCKERFILE="$2"
      shift 2
      ;;
    -g | --target )
      BUILD_TARGET="$2"
      shift 2
      ;;
    -i | --id )
      UNIQUE_ID="$2"
      shift 2
      ;;
    -l | --protobuf )
      INSTALL_PROTOBUF="$2"
      shift 2
      ;;
    -m | --openmpi )
      INSTALL_OPENMPI="$2"
      shift 2
      ;;
    -o | --onnx )
      ONNX_VERSION="$2"
      shift 2
      ;;
    -p | --python )
      PYTHON_VERSION="$2"
      shift 2
      ;;
    -r | --onnxruntime )
      ONNXRUNTIME_VERSION="$2"
      shift 2
      ;;
    -t | --torch )
      PYTORCH_VERSION="$2"
      shift 2
      ;;
    -u | --push )
      PUSH_IMAGE="$2"
      shift 2
      ;;
    -v | --torchvision )
      TORCHVISION_VERSION="$2"
      shift 2
      ;;
    -x | --onnxscript )
      ONNXSCRIPT_VERSION="$2"
      shift 2
      ;;
    -h | --help)
      help
      ;;
    --)
      shift;
      break
      ;;
    *)
      echo "Unexpected option: $1"
      help
      ;;
  esac
done

print_env(){
    BUILD_TARGET=${1}  # Docker multi-stage number/name
    UNIQUE_ID=${2}     # Unique ID to be used on images names (e.g. 20220927)
    DOCKERFILE=${3}    # Dockerfile name

    echo "Environment:"
    echo -e "\tUNIQUE_ID=${UNIQUE_ID}"
    echo -e "\tBUILD_TARGET=${BUILD_TARGET}"
    echo -e "\tBASE_IMAGE=${BASE_IMAGE}"
    echo -e "\tDOCKERFILE=${DOCKERFILE}"
    echo -e "\tPUSH_IMAGE=${PUSH_IMAGE}"
    echo -e "\tPYTHON_VERSION=${PYTHON_VERSION}"
    echo -e "\tCUDA_VERSION=${CUDA_VERSION}"
    echo -e "\tONNX_VERSION=${ONNX_VERSION}"
    echo -e "\tPYTORCH_VERSION=${PYTORCH_VERSION}"
    echo -e "\tTORCHVISION_VERSION=${TORCHVISION_VERSION}"
    echo -e "\tTORCHTEXT_VERSION=${TORCHTEXT_VERSION}"
    echo -e "\tTORCHAUDIO_VERSION=${TORCHAUDIO_VERSION}"
    echo -e "\tDETECTRON2_VERSION=${DETECTRON2_VERSION}"
    echo -e "\tONNXRUNTIME_VERSION=${ONNXRUNTIME_VERSION}"
    echo -e "\tONNXSCRIPT_VERSION=${ONNXSCRIPT_VERSION}"
    echo -e "\tINSTALL_PROTOBUF=${INSTALL_PROTOBUF}"
    echo -e "\tINSTALL_OPENMPI=${INSTALL_OPENMPI}"
}

docker_build(){
    UNIQUE_ID=${1}     # Unique ID to be used on images names (e.g. 20220927)
    DOCKERFILE=${2}    # Dockerfile name
    BUILD_TARGET=${3}  # Docker multi-stage index/name

    VALID_ARGUMENTS=$#
    if [ ! "$VALID_ARGUMENTS" -eq 3 ]; then
        echo "docker_build: Specify UNIQUE_ID, DOCKERFILE, and BUILD_TARGET"
        help
    fi

    print_env ${BUILD_TARGET} ${UNIQUE_ID} ${DOCKERFILE}

    if [ -z "${UNIQUE_ID}" ]
    then
        echo "docker_build: Specify UNIQUE_ID"
        help
    fi
    if [ -z "${DOCKERFILE}" ]
    then
        echo "docker_build: Specify DOCKERFILE"
        help
    fi
    _IMAGE_TAG=""
    if [ -z "${BUILD_TARGET}" ]
    then
        echo "docker_build: Specify BUILD_TARGET."
        help
    elif [ "${BUILD_TARGET}" == "__LAST__" ]
    then
        _IMAGE_TAG="${DOCKER_FULL_NAME}:devel-${UNIQUE_ID}"
        BUILD_TARGET_FLAG="--target devel-all"
    elif [ "${BUILD_TARGET}" == "__ALL__" ]
    then
        echo "*** docker_build: __ALL__ is not valid option in this context ***"
        exit 2
    else
        _IMAGE_TAG="${DOCKER_FULL_NAME}:devel-${UNIQUE_ID}-${BUILD_TARGET}"
        BUILD_TARGET_FLAG="--target ${BUILD_TARGET}"
    fi

    echo "*** docker_build: Building '${_IMAGE_TAG}' ***"
    docker build \
           --progress=${BUILD_PROGRESS} \
           --build-arg BUILDKIT_INLINE_CACHE=${BUILDKIT_INLINE_CACHE} \
           --cache-from ${BASE_IMAGE} \
           --cache-from ${DOCKER_FULL_NAME}:devel-${UNIQUE_ID} \
           --cache-from ${DOCKER_FULL_NAME}:devel-${UNIQUE_ID}-os \
           --cache-from ${DOCKER_FULL_NAME}:devel-${UNIQUE_ID}-conda \
           --cache-from ${DOCKER_FULL_NAME}:devel-${UNIQUE_ID}-onnx \
           --cache-from ${DOCKER_FULL_NAME}:devel-${UNIQUE_ID}-onnxscript \
           --cache-from ${DOCKER_FULL_NAME}:devel-${UNIQUE_ID}-torch \
           --cache-from ${DOCKER_FULL_NAME}:devel-${UNIQUE_ID}-torchtext \
           --cache-from ${DOCKER_FULL_NAME}:devel-${UNIQUE_ID}-torchaudio \
           --cache-from ${DOCKER_FULL_NAME}:devel-${UNIQUE_ID}-torchvision \
           --cache-from ${DOCKER_FULL_NAME}:devel-${UNIQUE_ID}-detectron2 \
           --cache-from ${DOCKER_FULL_NAME}:devel-${UNIQUE_ID}-onnxruntime \
           --cache-from ${_IMAGE_TAG} \
           ${BUILD_TARGET_FLAG} \
           --tag ${_IMAGE_TAG} \
           --build-arg BASE_IMAGE=${BASE_IMAGE} \
           --build-arg PYTHON_VERSION=${PYTHON_VERSION} \
           --build-arg CUDA_VERSION=${CUDA_VERSION} \
           --build-arg ONNX_VERSION=${ONNX_VERSION} \
           --build-arg ONNXSCRIPT_VERSION=${ONNXSCRIPT_VERSION} \
           --build-arg PYTORCH_VERSION=${PYTORCH_VERSION} \
           --build-arg TORCHVISION_VERSION=${TORCHVISION_VERSION} \
           --build-arg TORCHTEXT_VERSION=${TORCHTEXT_VERSION} \
           --build-arg TORCHAUDIO_VERSION=${TORCHAUDIO_VERSION} \
           --build-arg DETECTRON2_VERSION=${DETECTRON2_VERSION} \
           --build-arg ONNXRUNTIME_VERSION=${ONNXRUNTIME_VERSION} \
           --build-arg INSTALL_PROTOBUF=${INSTALL_PROTOBUF} \
           --build-arg INSTALL_OPENMPI=${INSTALL_OPENMPI} \
           -f ${DOCKERFILE} .
}

docker_push(){
    UNIQUE_ID=${1}    # Unique ID to be used on images names (e.g. 20220927)
    BUILD_TARGET=${2} # Docker multi-stage name.
                      # One of: os, conda, onnx, torch, torchtext, torchaudio, torchvision, detectron2, onnxruntime, __all__
    VALID_ARGUMENTS=$#
    if [ ! "$VALID_ARGUMENTS" -eq 2 ]; then
        echo "docker_push: Specify UNIQUE_ID(${UNIQUE_ID}) and BUILD_TARGET(${BUILD_TARGET}"
        help
    fi

    print_env ${BUILD_TARGET} ${UNIQUE_ID} ${DOCKERFILE}

    if [ -z "${UNIQUE_ID}" ]
    then
        echo "docker_push: Specify UNIQUE_ID"
        exit 2
    fi
    if [ -z "${BUILD_TARGET}" ]
    then
        echo "docker_push: Specify BUILD_TARGET"
        exit 2
    elif [ "${BUILD_TARGET}" == "__ALL__" ]
    then
        set +e
        for TAG in -os -conda -onnx -torch -torchtext -torchaudio -torchvision -detectron2 -onnxruntime ""
        do
            _IMAGE_TAG=${DOCKER_FULL_NAME}:devel-${UNIQUE_ID}${TAG}
            echo "*** docker_push: Pushing __ALL__ multi-stage image: '${_IMAGE_TAG}' ***"
            docker push ${_IMAGE_TAG}
        done
        set -e
    elif [ "${BUILD_TARGET}" == "__LAST__" ]
    then
        _IMAGE_TAG=${DOCKER_FULL_NAME}:devel-${UNIQUE_ID}
        echo "*** docker_push: Pushing last multi-stage image: '${_IMAGE_TAG}' ***"
        docker push ${_IMAGE_TAG}
    else
        _IMAGE_TAG=${DOCKER_FULL_NAME}:devel-${UNIQUE_ID}-${BUILD_TARGET}
        echo "*** docker_push: Pushing multi-stage image: '${_IMAGE_TAG}' ***"
        docker push ${_IMAGE_TAG}
    fi
}

docker_build_and_push(){
    UNIQUE_ID=${1}     # Unique ID to be used on images names (e.g. 20220927)
    DOCKERFILE=${2}    # Dockerfile name
    BUILD_TARGET=${3}  # Docker multi-stage index/name
    PUSH_IMAGE=${4}    # Push image after it is built

    VALID_ARGUMENTS=$#
    if [ ! "$VALID_ARGUMENTS" -eq 4 ]; then
        echo "docker_build: Specify UNIQUE_ID, DOCKERFILE, BUILD_TARGET, and PUSH_IMAGE"
        help
    fi

    docker_build ${UNIQUE_ID} ${DOCKERFILE} ${BUILD_TARGET}
    if [ "${PUSH_IMAGE}" == "1" ]
    then
        docker_push ${UNIQUE_ID} ${BUILD_TARGET}
    fi
}

if [ "${BUILD_TARGET}" == "__ALL__" ]
then
    echo -e "WARNING: All targets will be built!\nYou have 10s to abort by hitting CTRL+C..."
    print_env ${BUILD_TARGET} ${UNIQUE_ID} ${DOCKERFILE}
    sleep 10
    docker_build_and_push ${UNIQUE_ID} ${DOCKERFILE} os ${PUSH_IMAGE}
    docker_build_and_push ${UNIQUE_ID} ${DOCKERFILE} conda ${PUSH_IMAGE}
    docker_build_and_push ${UNIQUE_ID} ${DOCKERFILE} onnx ${PUSH_IMAGE}
    docker_build_and_push ${UNIQUE_ID} ${DOCKERFILE} onnxscript ${PUSH_IMAGE}
    docker_build_and_push ${UNIQUE_ID} ${DOCKERFILE} torch ${PUSH_IMAGE}
    docker_build_and_push ${UNIQUE_ID} ${DOCKERFILE} torchtext ${PUSH_IMAGE}
    docker_build_and_push ${UNIQUE_ID} ${DOCKERFILE} torchaudio ${PUSH_IMAGE}
    docker_build_and_push ${UNIQUE_ID} ${DOCKERFILE} torchvision ${PUSH_IMAGE}
    docker_build_and_push ${UNIQUE_ID} ${DOCKERFILE} detectron2 ${PUSH_IMAGE}
    docker_build_and_push ${UNIQUE_ID} ${DOCKERFILE} onnxruntime ${PUSH_IMAGE}
    docker_build_and_push ${UNIQUE_ID} ${DOCKERFILE} __LAST__ ${PUSH_IMAGE}
else
    docker_build_and_push ${UNIQUE_ID} ${DOCKERFILE} ${BUILD_TARGET} ${PUSH_IMAGE}
fi
