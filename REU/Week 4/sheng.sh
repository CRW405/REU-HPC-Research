#!/bin/bash
# ================================================
#
# build_shengbte.sh
#
# Version: ShengBTE-Multiplatform (master), Spglib v1.16.2
# System: Stampede3, TACC
# Created by: Caleb W with help from CLAUDE
# Last modified: 2026-06-30
#
# ================================================
# MODULES
ml reset
ml intel
ml impi
ml cmake

ROOT_DIR=`pwd`
INSTALL_DIR=${ROOT_DIR}/install
mkdir -p ${INSTALL_DIR}

# SPGLIB
if [[ 1 == 1 ]]; then
  VERSION_SPGLIB=v1.16.2
  cd ${ROOT_DIR}
  git clone -b ${VERSION_SPGLIB} --single-branch https://github.com/spglib/spglib.git spglib-src
  cd spglib-src
  rm -rf build
  mkdir -p build
  cd build

  cmake .. -DCMAKE_C_COMPILER=icx \
	   -DCMAKE_INSTALL_PREFIX=${INSTALL_DIR} \
	   -DBUILD_SHARED_LIBS=OFF \
	   -DCMAKE_POLICY_VERSION_MINIMUM=3.5
  make -j16
  make install
fi

# SHENGBTE
if [[ 1 == 1 ]]; then
  cd ${ROOT_DIR}
  git clone https://github.com/buaa-hipo/ShengBTE-Multiplatform.git ShengBTE-src
  cd ShengBTE-src/Src

  cat << ARCHMAKE_EOF > arch.make
MPIFC = mpif90
FFLAGS = -FR -O3 -qopenmp
MPEFLAGS = -DFFTW -D_OPENMP

# Points to the Spglib build installed above
LDFLAGS = -qmkl=cluster -I${INSTALL_DIR}/include
LIBS = ${INSTALL_DIR}/lib64/libsymspg.a
ARCHMAKE_EOF

  make clean
  make -j16
fi
