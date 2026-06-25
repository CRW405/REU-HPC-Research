#!/bin/bash
#===============================================================================
# Application Configuration Template
#
# This file is sourced by run_script.sh and generate_jobs.sh
# All settings can be overridden by command-line flags
#===============================================================================

#===============================================================================
# APPLICATION SETTINGS
#===============================================================================

# Application name (used in job names and output directories)
APP_NAME="abinit"

APP_BUILD_PATH="/scratch/11603/crw405/2.project/1.build_scripts/2.apps/abinit"

# Application binary path
APP_BINARY="${APP_BUILD_PATH}/install/bin/abinit"

# Test cases - format: "name:input_path"
# Each test case will get its own directory structure
TEST_CASES=(
    "test0:${APP_BUILD_PATH}/abinit-10.4.7/tests/v1/Input/t00.abi"
    "test1:${APP_BUILD_PATH}/abinit-10.4.7/tests/v1/Input/t01.abi"
    "test2:${APP_BUILD_PATH}/abinit-10.4.7/tests/v1/Input/t02.abi"
    "test3:${APP_BUILD_PATH}/abinit-10.4.7/tests/v1/Input/t03.abi"
    "test4:${APP_BUILD_PATH}/abinit-10.4.7/tests/v1/Input/t04.abi"
)

# Application-specific environment variables
# Format: "VAR_NAME=value"
APP_ENV=(
    "ABI_PSPDIR=${APP_BUILD_PATH}/abinit-10.4.7/tests/Pspdir/"
)

#===============================================================================
# MODULE SETTINGS
#===============================================================================

# Modules to load (in order)
MODULES=(
    "intel"
    "impi"
    "netcdf"
)

# Custom library paths to add to LD_LIBRARY_PATH
LIBRARY_PATHS=(
    "${APP_BUILD_PATH}/install/lib"
    "/opt/apps/intel24/netcdf/4.9.2/lib64"
)

#===============================================================================
# MPI SETTINGS
#===============================================================================

# MPI workarounds (if needed)
# Format: "VAR_NAME=value"
MPI_ENV=(
    "I_MPI_SHM=by_node"
    "FI_PROVIDER=tcp"
)

#===============================================================================
# SLURM SETTINGS
#===============================================================================

# SLURM account/allocation
SLURM_ACCOUNT="EAR23006"

# SLURM partition
SLURM_PARTITION="skx-dev"

# Time limits
SINGLE_NODE_TIME="01:00:00"
MULTI_NODE_TIME="02:00:00"

# Tasks per node (Frontera default)
TASKS_PER_NODE=56

#===============================================================================
# PEAK PROFILING SETTINGS
#===============================================================================

# Path to PEAK library
LIBPEAK_PATH="/scratch/11603/crw405/2.project/1.build_scripts/1.peak/peak/lib/libpeak.so"

# Target groups for profiling (comma-separated)
PEAK_TARGET_GROUPS="BLAS,LAPACK,FFTW,PBLAS,ScaLAPACK"

# Memory profiling settings
PEAK_MEMORY_PROFILE="TRUE"
PEAK_MEMORY_TRACK_ALL="TRUE"
PEAK_MEMLOG_CHUNK_EVENTS=10000000

#===============================================================================
# OUTPUT SETTINGS
#===============================================================================

# Default run name (can be overridden with --name flag)
RUN_NAME="${APP_NAME}"

# Output directory base (runs will be created as subdirectories)
OUTPUT_BASE="."

# Cleanup previous outputs before running
CLEAN_PREVIOUS="TRUE"
