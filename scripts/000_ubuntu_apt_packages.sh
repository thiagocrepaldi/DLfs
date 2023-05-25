#!/bin/bash
set -e -x
export DEBIAN_FRONTEND=noninteractive # Make sure apt installed packages are not interactive
GUARD_FILE="___UBUNTU_APT_PACKAGES_INSTALLED___"

if [ ! -f ${GUARD_FILE} ]
then
    echo "Installing Ubuntu packages from apt-get repo"

    # Install OS-level dependencies COMMON for all build stages
    apt-get update
    apt-get install -y --no-install-recommends \
        build-essential \
        curl \
        git \
        pkg-config \
        unzip \
        wget \
        zip

    # Install OS-level dependencies specific for ONNX

    # Install OS-level dependencies specific for PyTorch

    # Install OS-level dependencies specific for PyTorch Vision

    # Install OS-level dependencies specific for PyTorch Text

    # Install OS-level dependencies specific for PyTorch Audio

    # Install OS-level dependencies specific for Detectron2

    # Install OS-level dependencies specific for ONNX Runtime

    # Clean apt cache before leave
    rm -rf /var/lib/apt/lists/*
    touch ${GUARD_FILE}
else
    echo "Skipping Ubuntu packages from apt-get repo"
fi