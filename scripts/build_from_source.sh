#!/bin/bash
set -e -x

# Packages compiled from source
PYTHON_VERSION="3.8"
CUDA_VERSION="11.7.0"
ONNX_VERSION="main"
ONNXSCRIPT_VERSION="main"
PYTORCH_VERSION="main"
TORCHVISION_VERSION="main"
TORCHTEXT_VERSION="main"
TORCHAUDIO_VERSION="main"
DETECTRON2_VERSION="main"
ONNXRUNTIME_VERSION="main"
INSTALL_PROTOBUF="0"
INSTALL_OPENMPI="0"

# Global settings
export DEBUG="0"
export REL_WITH_DEB_INFO="0"
export CONDA_INSTALL_DIR="/opt/conda"
export GIT_REPOS_DIR="/opt"
export BUILD_SCRIPTS_DIR="/opt/scripts"
export TEMP_DIR="/tmp"
export DEFAULT_CONDA_ENV="ptca"
export DEBIAN_FRONTEND="noninteractive"
export CUDA_HOME=/usr/local/cuda
export CUDA_VERSION="${CUDA_VERSION}"
export DEBUG="${DEBUG}"
export TORCH_CUDA_ARCH_LIST="3.5 5.2 6.0 6.1 7.0+PTX 8.0"
export TORCH_NVCC_FLAGS="-Xfatbin -compress-all"
export ONNXRUNTIME_BUILD_CONFIG="RelWithDebInfo"

# Input parsing
help()
{
    echo "Usage: build_from_source.sh
                [ --torchaudio ]   # github.com/pytorch/audio commit/branch/tag (default is main)
                [ --cuda ]         # CUDA version (default is 11.7.0)
                [ --detectron2 ]   # github.com/facebookresearch/detectron2 commit/branch/tag (default is main)
                [ --torchtext ]    # github.com/pytorch/text commit/branch/tag (default is main)
                [ --target ]       # Build target (default is __ALL__)
                                        # One of (__ALL__, __LAST__, os, conda, onnx, onnxscript, torch, torchtext, torchaudio, torchvision, detectron2, onnxruntime)
                                        #         __ALL__ must be set to build all targets available
                [ --openmpi ]      # Builds open MPI 4.0 from source (tarball) (default is 1)
                [ --protobuf ]     # Builds Protobuf from source (tarball) (default is 1)
                [ --onnx ]         # github.com/onnx/onnx commit/branch/tag (default is main)
                [ --python ]       # python version (default is 3.8)
                [ --onnxruntime ]  # github.com/microsoft/onnxruntime commit/branch/tag (default is main)
                [ --torch ]        # github.com/pytorch/torch commit/branch/tag (default is main)
                [ --torchvision ]  # github.com/pytorch/torchvision commit/branch/tag (default is main)
                [ --onnxscript ]   # github.com/microsoft/onnxscript commit/branch/tag (default is main)
                [ --scripts ]      # Path to build scripts
                [ -h | --help  ]   # This message :)

        IMPORTANT: ALL parameters, but -h, MUST be specified. If you know how to getopts to play nice with optional arguments, please fix this :)
        "
    exit 2
}
SHORT=a:,c:,d:,e:,g:,l:,m:,o:,p:,r:,s:,t:,v:,x:,h
LONG=torchaudio:,cuda:,detectron2:,torchtext:,target:,protobuf:,openmpi:,onnx:,python:,onnxruntime:,scripts:,torch:,torchvision:,onnxscript:,help
OPTS=$(getopt -a -n build --options $SHORT --longoptions $LONG -- "$@")
VALID_ARGUMENTS=$#  # Returns the count of arguments that are in short or long options
if [ ! "$VALID_ARGUMENTS" -eq 28 ]
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
    -g | --target )
      BUILD_TARGET="$2"
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
    -s | --scripts )
      BUILD_SCRIPTS="$2"
      shift 2
      ;;
    -t | --torch )
      PYTORCH_VERSION="$2"
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

case ${BUILD_TARGET} in
  os)
    bash ${BUILD_SCRIPTS}/000_ubuntu_apt_packages.sh ${BUILD_SCRIPTS_DIR}
    bash ${BUILD_SCRIPTS}/005_cmake_from_tarball.sh ${GIT_REPOS_DIR}
    bash ${BUILD_SCRIPTS}/010_protobuf_from_source.sh ${INSTALL_PROTOBUF} ${GIT_REPOS_DIR}
    bash ${BUILD_SCRIPTS}/015_openmpi4_from_source.sh ${INSTALL_OPENMPI} ${GIT_REPOS_DIR}
    ;;
  conda)
    bash ${BUILD_SCRIPTS}/100_miniconda_from_installer.sh ${PYTHON_VERSION} ${TEMP_DIR}
    bash ${BUILD_SCRIPTS}/101_install_python_deps.sh ${ONNX_VERSION} ${ONNXSCRIPT_VERSION} ${PYTORCH_VERSION} ${TORCHTEXT_VERSION} ${TORCHVISION_VERSION} ${TORCHAUDIO_VERSION} ${DETECTRON2_VERSION} ${ONNXRUNTIME_VERSION}  ${BUILD_SCRIPTS_DIR} ${GIT_RETEMP_DIRPOS_DIR}
    ;;
  onnx)
    bash && ${BUILD_SCRIPTS}/105_onnx_from_source.sh ${ONNX_VERSION} 1 ${GIT_REPOS_DIR}
    ;;
  onnxscript)
    bash ${BUILD_SCRIPTS}/107_onnxscript_from_source.sh ${ONNXSCRIPT_VERSION} 1 ${GIT_REPOS_DIR}
    ;;
  pytorch)
    bash ${BUILD_SCRIPTS}/110_pytorch_from_source.sh ${PYTORCH_VERSION} 1 ${GIT_REPOS_DIR}
    ;;
  torchtext)
    bash ${BUILD_SCRIPTS}/115_torchtext_from_source.sh ${TORCHTEXT_VERSION} 1 ${GIT_REPOS_DIR}
    ;;
  torchvision)
    bash ${BUILD_SCRIPTS}/120_torchvision_from_source.sh ${TORCHVISION_VERSION} 1 ${GIT_REPOS_DIR}
    ;;
  torchaudio)
    bash ${BUILD_SCRIPTS}/125_torchaudio_from_source.sh ${TORCHAUDIO_VERSION} 1 ${GIT_REPOS_DIR}
    ;;
  detectron2)
    bash ${BUILD_SCRIPTS}/130_detectron2_from_source.sh ${DETECTRON2_VERSION} 1 ${GIT_REPOS_DIR}
    ;;
  onnxruntime)
    bash ${BUILD_SCRIPTS}/135_onnxruntime_from_source.sh ${ONNXRUNTIME_VERSION} ${ONNXRUNTIME_BUILD_CONFIG} ${CUDA_VERSION} 1 ${GIT_REPOS_DIR}
    ;;
  __ALL__)
      bash ${BUILD_SCRIPTS}/000_ubuntu_apt_packages.sh ${BUILD_SCRIPTS_DIR}
      bash ${BUILD_SCRIPTS}/005_cmake_from_tarball.sh ${GIT_REPOS_DIR}
      bash ${BUILD_SCRIPTS}/010_protobuf_from_source.sh ${INSTALL_PROTOBUF} ${GIT_REPOS_DIR}
      bash ${BUILD_SCRIPTS}/015_openmpi4_from_source.sh ${INSTALL_OPENMPI} ${GIT_REPOS_DIR}
      bash ${BUILD_SCRIPTS}/100_miniconda_from_installer.sh ${PYTHON_VERSION} ${TEMP_DIR}
      bash ${BUILD_SCRIPTS}/101_install_python_deps.sh ${ONNX_VERSION} ${ONNXSCRIPT_VERSION} ${PYTORCH_VERSION} ${TORCHTEXT_VERSION} ${TORCHVISION_VERSION} ${TORCHAUDIO_VERSION} ${DETECTRON2_VERSION} ${ONNXRUNTIME_VERSION} ${BUILD_SCRIPTS_DIR} ${TEMP_DIR}
      bash ${BUILD_SCRIPTS}/105_onnx_from_source.sh ${ONNX_VERSION} 1 ${GIT_REPOS_DIR}
      bash ${BUILD_SCRIPTS}/107_onnxscript_from_source.sh ${ONNXSCRIPT_VERSION} 1 ${GIT_REPOS_DIR}
      bash ${BUILD_SCRIPTS}/110_pytorch_from_source.sh ${PYTORCH_VERSION} 1 ${GIT_REPOS_DIR}
      bash ${BUILD_SCRIPTS}/115_torchtext_from_source.sh ${TORCHTEXT_VERSION} 1 ${GIT_REPOS_DIR}
      bash ${BUILD_SCRIPTS}/120_torchvision_from_source.sh ${TORCHVISION_VERSION} 1 ${GIT_REPOS_DIR}
      bash ${BUILD_SCRIPTS}/125_torchaudio_from_source.sh ${TORCHAUDIO_VERSION} 1 ${GIT_REPOS_DIR}
      bash ${BUILD_SCRIPTS}/130_detectron2_from_source.sh ${DETECTRON2_VERSION} 1 ${GIT_REPOS_DIR}
      bash ${BUILD_SCRIPTS}/135_onnxruntime_from_source.sh ${ONNXRUNTIME_VERSION} ${ONNXRUNTIME_BUILD_CONFIG} ${CUDA_VERSION} 1 ${GIT_REPOS_DIR}
      ;;
  *)
    echo "Unexpected build target: ${BUILD_TARGET}"
    help
    ;;
esac

print_env(){
    BUILD_TARGET=${1}  # Docker multi-stage number/name

    echo "Environment:"
    echo -e "\tBUILD_TARGET=${BUILD_TARGET}"
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
