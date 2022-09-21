#!/bin/bash

set -e

# install Open MPI
echo "Installing Open MPI"
FILENAME=openmpi-4.0.4.tar.gz
FOLDER_NAME=openmpi-4.0.4
URL=https://download.open-mpi.org/release/open-mpi/v4.0/${FILENAME}
MPI_SHA256_SUM=dca264f420411f540a496bdd131bffd83e325fc9006286b39dd19b62d7368233
curl -fsSL ${URL} -O
echo "$MPI_SHA256_SUM  openmpi-4.0.4.tar.gz" | sha256sum -c -
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
