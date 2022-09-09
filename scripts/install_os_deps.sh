#!/bin/bash
set -e -x
export DEBIAN_FRONTEND=noninteractive # Make sure apt installed packages are not interactive

# Install OS-level dependencies for all build stages
apt-get update
apt-get install -y --no-install-recommends \
    build-essential \
    cmake \
    curl \
    git \
    intel-mkl-full \
    libjpeg-dev \
    libncurses5 \
    libncurses-dev \
    libpng-dev \
    libtinfo6 \
    libtinfo-dev \
    protobuf-compiler \
    unzip \
    zip

# Clean apt cache before leave
rm -rf /var/lib/apt/lists/*
