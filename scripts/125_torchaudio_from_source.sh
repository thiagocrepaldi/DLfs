#!/bin/bash
set -e -x

# Can be a tag, commit or branch
TORCHAUDIO_VERSION=${1}
unset PYTORCH_VERSION
export BUILD_SOX=1
export USE_CUDA=1
export USE_FFMPEG=1

CONDA_PATH=$(which conda)
PYTHON_PATH=$(which python)

echo "Building Torch Audio ${TORCHAUDIO_VERSION} from source"
echo "Conda path is ${CONDA_PATH}"
echo "Python path is ${PYTHON_PATH}"

git clone https://github.com/pytorch/audio.git torchaudio
cd torchaudio
git checkout ${TORCHAUDIO_VERSION}
git submodule sync
git submodule update --init --recursive --jobs 0

python setup.py bdist_wheel