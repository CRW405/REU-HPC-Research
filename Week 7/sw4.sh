#!/bin/bash
# ================================================
#
# sw4.sh
#
# SW4 - Seismic Wave simulation code (4th order)
# Version: v3.0
# System: Stampede3, TACC
# Created by: Caleb W with help from CLAUDE
# Last modified: 7/18/26
#
# Run from $SCRATCH (not $HOME — needs disk space)
# Binary lands at: install/bin/sw4
#
# HDF5 note: SW4 uses MPI-IO (H5Pset_fapl_mpio, etc.)
# which only exists in parallel HDF5. Use "ml phdf5",
# NOT "ml hdf5" — the serial build omits those symbols.
#
# FFTW3 note: TACC does not ship a FFTW3 module for
# the Intel stack, so USE_FFTW3 is disabled here. MKL
# has its own FFTW3 wrappers but SW4 doesn't use them.
# Build FFTW3 from source if you need that code path.
#
# PROJ note: only needed for geographic coordinate
# transforms in input files. Most benchmarks don't use
# it — leaving USE_PROJ=OFF is fine.
# ================================================

ml reset
ml intel
ml impi
ml cmake
ml phdf5      # parallel HDF5 — serial HDF5 is missing MPI-IO symbols

ROOT_DIR=`pwd`
INSTALL_DIR=${ROOT_DIR}/install
mkdir -p ${INSTALL_DIR}

# SW4
if [[ 1 == 1 ]]; then
  cd ${ROOT_DIR}
  git clone -b v3.0 https://github.com/geodynamics/sw4.git sw4-src
  mkdir -p sw4-build
  cd sw4-build

  cmake ${ROOT_DIR}/sw4-src \
        -DCMAKE_C_COMPILER=mpiicx \
        -DCMAKE_CXX_COMPILER=mpiicpx \
        -DCMAKE_Fortran_COMPILER=mpiifort \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX=${INSTALL_DIR} \
        -DBLA_VENDOR=Intel10_64lp \
        -DUSE_HDF5=ON \
        -DHDF5_DIR=${TACC_PHDF5_DIR:-${TACC_HDF5_DIR}} \
        -DUSE_FFTW3=OFF \
        -DUSE_PROJ=OFF

  cmake --build . -j16
  cmake --install .
fi
