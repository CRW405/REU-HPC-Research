#!/bin/bash
# ================================================
#
# qe.sh
#
# Quantum ESPRESSO
# Version: 7.5
# System: Stampede3, TACC
# Created by: Caleb W with help from CLUADE
# Last modified: 6/29/26
#
# ================================================

# MODULES
ml intel
ml impi
ml hdf5

ROOT_DIR=`pwd`
INSTALL_DIR=${ROOT_DIR}/install
mkdir -p ${INSTALL_DIR}

# QUANTUM ESPRESSO
if [[ 1 == 1 ]]; then
  VERSION_QE=7.5
  cd ${ROOT_DIR}
  wget https://gitlab.com/QEF/q-e/-/archive/qe-${VERSION_QE}/q-e-qe-${VERSION_QE}.tar.gz
  tar -xf q-e-qe-${VERSION_QE}.tar.gz
  cd q-e-qe-${VERSION_QE}

  # configure auto-detects MKL via $MKLROOT (set by the intel module)
  # and will prefer MKL's BLAS/LAPACK/ScaLAPACK/FFTW wrappers over building
  # its own internal copies, similar to ABINIT's --with-linalg-flavor=mkl
  ./configure MPIF90=mpiifort \
              F90=ifort \
              F77=ifort \
              FC=ifort \
              CC=mpiicx \
              CXX=mpiicpx \
              --enable-parallel \
              --enable-openmp \
              --with-scalapack=intel \
              --with-hdf5=${TACC_HDF5_DIR} \
              --prefix=${INSTALL_DIR}

  make -j16 pw
  make -j16 ph
  make install
fi
