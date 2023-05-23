#!/bin/bash
set -e -x

INSTALL_PROTOBUF=${1:-0}
PROTOBUF_VERSION=${2:-v3.20.2}

if [ "${INSTALL_PROTOBUF}" == "1" ]
then
    echo "Installing protobuf ${PROTOBUF_VERSION} from source"
    git clone https://github.com/protocolbuffers/protobuf.git
    cd protobuf
    git checkout ${PROTOBUF_VERSION}
    git submodule sync
    git submodule update --init --recursive --jobs 0
    mkdir -p build_source
    cd build_source
    cmake ../cmake -Dprotobuf_BUILD_SHARED_LIBS=OFF -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_INSTALL_SYSCONFDIR=/etc -DCMAKE_POSITION_INDEPENDENT_CODE=ON -Dprotobuf_BUILD_TESTS=OFF -DCMAKE_BUILD_TYPE=Release
    make -j$(nproc)
    make install
else
    echo "Skipping installation of protobuf ${PROTOBUF_VERSION} from source"
fi