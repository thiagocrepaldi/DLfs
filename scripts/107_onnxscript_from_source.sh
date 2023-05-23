#!/bin/bash
set -e -x

# Can be a tag, commit or branch
ONNXSCRIPT_VERSION=${1}

CONDA_PATH=$(which conda)
PYTHON_PATH=$(which python)

echo "Building ONNX Script ${ONNXSCRIPT_VERSION} from source"
echo "Conda path is ${CONDA_PATH}"
echo "Python path is ${PYTHON_PATH}"

git clone https://github.com/microsoft/onnxscript.git
cd onnxscript
git checkout ${ONNXSCRIPT_VERSION}
git submodule sync
git submodule update --init --recursive --jobs 0

python setup.py bdist_wheel
# python -m pip install -e .