#!/bin/bash
#===============================================================================
# Quantum ESPRESSO Configuration Template
#===============================================================================

#===============================================================================
# APPLICATION SETTINGS
#===============================================================================

APP_NAME="qe"
APP_BUILD_PATH="/scratch/11603/crw405/build_scripts/qe/q-e-qe-7.5"
APP_BINARY="${APP_BUILD_PATH}/bin/pw.x"

# Test cases - format: "name:input_path"
TEST_CASES=(
    #"scf:/scratch/11603/crw405/build_scripts/qe/q-e-qe-7.5/test-suite/pw_scf/scf.in"
    "tc:/scratch/11603/crw405/REU-HPC-Research/research_data/qe/test_case.in"
)

# Application-specific environment variables
APP_ENV=(
    "ESPRESSO_PSEUDO=/scratch/11603/crw405/build_scripts/qe/q-e-qe-7.5/pseudo"
)

#===============================================================================
# MODULE SETTINGS
#===============================================================================

MODULES=(
    "intel"
    "impi"
    "hdf5"
)

LIBRARY_PATHS=()

#===============================================================================
# MPI SETTINGS
#===============================================================================

MPI_ENV=(
    "I_MPI_SHM=by_node"
    "FI_PROVIDER=tcp"
)

#===============================================================================
# SLURM SETTINGS
#===============================================================================

SLURM_ACCOUNT="EAR23006"
SLURM_PARTITION="skx"

SINGLE_NODE_TIME="02:00:00"
MULTI_NODE_TIME="02:00:00"
TASKS_PER_NODE=48

#===============================================================================
# PEAK PROFILING SETTINGS
#===============================================================================

LIBPEAK_PATH="/scratch/11603/crw405/peak/peak/lib/libpeak.so"

# Restricting to BLAS,LAPACK to bypass problematic MKL return patches
PEAK_TARGET_GROUPS="BLAS,LAPACK"

PEAK_MEMORY_PROFILE="FALSE"
PEAK_SINGLE_CONFIG="n1"

#===============================================================================
# OUTPUT SETTINGS
#===============================================================================

RUN_NAME="${APP_NAME}"
OUTPUT_BASE="."
CLEAN_PREVIOUS="FALSE"
