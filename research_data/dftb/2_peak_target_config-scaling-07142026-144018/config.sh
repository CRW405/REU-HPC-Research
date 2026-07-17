#!/bin/bash
#===============================================================================
# DFTB+ Configuration Template
#===============================================================================

#===============================================================================
# APPLICATION SETTINGS
#===============================================================================

APP_NAME="dftb"
APP_BUILD_PATH="/scratch/11603/crw405/2.project/1.build_scripts/2.apps/dftb+/dftbplus-25.1"
APP_BINARY="${APP_BUILD_PATH}/bin/dftb+"

# Test cases - format: "name:input_file_path"
# NOTE: The job generation script now extracts the directory automatically
# and stages all necessary runtime dependencies (like *.skf files).
TEST_CASES=(
    "spinlock:/work2/05392/cylu/share/reu_2026/2.project/2.examples/dftb+/spinlock/dftb_in.hsd"
)

APP_ENV=()

#===============================================================================
# MODULE SETTINGS
#===============================================================================

MODULES=(
    "intel"
    "impi"
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
PEAK_TARGET_GROUPS="BLAS,LAPACK,FFTW"
PEAK_TARGET_CONFIG="FFTW"

PEAK_MEMORY_PROFILE="FALSE"
PEAK_SINGLE_CONFIG="n1"

#===============================================================================
# OUTPUT SETTINGS
#===============================================================================

RUN_NAME="${APP_NAME}"
OUTPUT_BASE="."
CLEAN_PREVIOUS="FALSE"
