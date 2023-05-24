#!/bin/bash

CMAKE_VERSION=${1:-3.26.0}
CMAKE_TAR_FILE=cmake-${CMAKE_VERSION}-linux-x86_64.tar.gz
INSTALL_DIR=/usr/local

HAS_CMAKE=$(which cmake)
if [ -z ${HAS_CMAKE} ]
then
    set -e -x
    echo "Installing CMake ${CMAKE_VERSION} from source"
    wget https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/${CMAKE_TAR_FILE}
    tar xvzf ${CMAKE_TAR_FILE} --strip-components=1 -C ${INSTALL_DIR}
    rm ${CMAKE_TAR_FILE}
else
    echo "Skipping installation CMake ${CMAKE_VERSION} from source"
fi