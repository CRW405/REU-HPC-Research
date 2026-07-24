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
    #"test0:${APP_BUILD_PATH}/abinit-10.4.7/tests/v1/Input/t00.abi"
    #"test1:${APP_BUILD_PATH}/abinit-10.4.7/tests/v1/Input/t05.abi"
    #"test2:${APP_BUILD_PATH}/abinit-10.4.7/tests/v1/Input/t02.abi"
    #"test3:${APP_BUILD_PATH}/abinit-10.4.7/tests/v1/Input/t03.abi"
    #"test4:${APP_BUILD_PATH}/abinit-10.4.7/tests/v1/Input/t04.abi"
    #"test_paral_1:${APP_BUILD_PATH}/abinit-10.4.7/tests/paral/Input/t01.abi"
    "test:/scratch/11603/crw405/REU-HPC-Research/research_data/abinit/v2/test_case.abi"
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
SLURM_PARTITION="skx"

# Time limits
SINGLE_NODE_TIME="02:00:00"
MULTI_NODE_TIME="02:00:00"

# Tasks per node (48 for Stampede3 SKX)
TASKS_PER_NODE=48

#===============================================================================
# PEAK PROFILING SETTINGS
#===============================================================================

# Path to PEAK library
LIBPEAK_PATH="/scratch/11603/crw405/peak/peak/lib/libpeak.so"

# Target groups for profiling (comma-separated)
#PEAK_TARGET_GROUPS="BLAS,LAPACK,FFTW,PBLAS,ScaLAPACK"
#PEAK_TARGET_GROUPS="BLAS,LAPACK,FFTW"
PEAK_TARGET_GROUPS="BLAS,LAPACK"

# Memory profiling settings
PEAK_MEMORY_PROFILE="FALSE"
#PEAK_MEMORY_TRACK_ALL="FALSE"
#PEAK_MEMLOG_CHUNK_EVENTS=500000

# Overhead control
#PEAK_COST=60
#PEAK_OVERHEAD_RATIO=0.1

# MPI/finalization behavior
#PEAK_MPI_REAL_FINALIZE=0

# Output behavior
#PEAK_TEXT_OUTPUT=0
#PEAK_VERBOSITY=report
#PEAK_OUTPUT_AGGREGATION=local

# Instrumentation policy
#PEAK_UNSAFE_GUM_PROLOGUE_POLICY=conservative

# Config to run PEAK on in --scaling mode (single-node: n<tasks>, multi-node: N<nodes>)
PEAK_SINGLE_CONFIG="n1"

#===============================================================================
# OUTPUT SETTINGS
#===============================================================================

# Default run name (can be overridden with --name flag)
RUN_NAME="${APP_NAME}"

# Output directory base (runs will be created as subdirectories)
OUTPUT_BASE="."

# Cleanup previous outputs before running
CLEAN_PREVIOUS="FALSE"
