#!/bin/bash
set -e -x

# Can be a tag, commit or branch
TORCHAUDIO_VERSION=${1}
INSTALL_AFTER_BUILD=${2:-0}

unset PYTORCH_VERSION
export BUILD_SOX=1
export USE_CUDA=1
export USE_FFMPEG=1

source ${CONDA_INSTALL_DIR}/bin/activate ${DEFAULT_CONDA_ENV}
CONDA_PATH=$(which conda)
PYTHON_PATH=$(which python)

echo "Uninstalling existing versions of Torch Audio from pip package manager..."
pip uninstall -y torchaudio

echo "Building Torch Audio ${TORCHAUDIO_VERSION} from source"
echo "Conda path is ${CONDA_PATH}"
echo "Python path is ${PYTHON_PATH}"

if [ ! -d torchaudio ]
then
    git clone https://github.com/pytorch/audio.git torchaudio
fi
cd torchaudio
git checkout ${TORCHAUDIO_VERSION}
git submodule sync
git submodule update --init --recursive --jobs 0

python setup.py bdist_wheel
if [ "${INSTALL_AFTER_BUILD}" == "1" ]
then
    pip install dist/torchaudio*.whl
fi