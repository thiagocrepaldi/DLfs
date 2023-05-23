#!/bin/bash
set -e -x

INSTALL_OPENMPI=${1:-0}
OPENMPI_VERSION=${2:-4.0.4}

if [ "${INSTALL_OPENMPI}" == "1" ]
then
    # install Open MPI
    echo "Installing Open MPI ${OPENMPI_VERSION} from source"
    FILENAME=openmpi-${OPENMPI_VERSION}.tar.gz
    FOLDER_NAME=openmpi-${OPENMPI_VERSION}
    URL=https://download.open-mpi.org/release/open-mpi/v4.0/${FILENAME}
    curl -fsSL ${URL} -O
    tar zxf ${FILENAME}
    cd ${FOLDER_NAME}
    ./configure --enable-orterun-prefix-by-default
    make -j $(nproc) all
    make install
    ldconfig

    # cleanup
    cd ..
    rm -f ${FILENAME}
    rm -rf ${FOLDER_NAME}
else
    echo "Skipping installation of Open MPI ${OPENMPI_VERSION} from source"
fi