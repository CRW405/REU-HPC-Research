#!/bin/bash
#===============================================================================
# GROMACS Configuration
#
# This file is sourced by generate_jobs.sh
# Based on ABINIT config template, adapted for GROMACS
#
# Key differences from ABINIT:
#   - Uses system GROMACS module (gmx_mpi binary from PATH)
#   - Run command uses ibrun + gmx_mpi mdrun -s <tpr> instead of mpirun
#   - No input file positional arg — GROMACS uses -s flag
#   - No ABI_PSPDIR or netcdf dependencies
#   - OUTPUT_SUFFIX controls the -deffnm output prefix
#===============================================================================

#===============================================================================
# APPLICATION SETTINGS
#===============================================================================

APP_NAME="gromacs"

# GROMACS binary — loaded from module, set path here
# Check location with: which gmx_mpi (after ml gromacs)
APP_BINARY="/scratch/11603/crw405/scripts/gmx_wrapper.sh"

# Test cases - format: "name:input_path"
# GROMACS uses pre-compiled .tpr files as input
TEST_CASES=(
    "benchMEM:/work2/05392/cylu/share/reu_2026/2.project/2.examples/gromacs/benchMEM.tpr"
)

# No application-specific environment variables needed for GROMACS
APP_ENV=()

#===============================================================================
# MODULE SETTINGS
#===============================================================================

MODULES=(
    "intel/24.0"
    "impi/21.11"
    "gromacs/2024"
)

# No custom library paths needed — GROMACS module handles this
LIBRARY_PATHS=()

#===============================================================================
# MPI SETTINGS
#===============================================================================

# GROMACS on TACC uses ibrun instead of mpirun
# ibrun handles node/task mapping automatically from SLURM env vars
# These MPI env vars are not needed for GROMACS
MPI_ENV=()

#===============================================================================
# SLURM SETTINGS
#===============================================================================

SLURM_ACCOUNT="EAR23006"
SLURM_PARTITION="skx"

SINGLE_NODE_TIME="01:00:00"
MULTI_NODE_TIME="01:00:00"

TASKS_PER_NODE=48

#===============================================================================
# PEAK PROFILING SETTINGS
#===============================================================================

LIBPEAK_PATH="/scratch/11603/crw405/peak/peak/lib/libpeak.so"

# GROMACS uses FFTW heavily (PME electrostatics) and BLAS/LAPACK for
# linear algebra. Drop FFTW if MKL-AVX512 segfault occurs (same issue as ABINIT)
PEAK_TARGET_GROUPS="BLAS,LAPACK,FFTW"
#PEAK_TARGET_GROUPS="BLAS,LAPACK"

PEAK_MEMORY_PROFILE="FALSE"

PEAK_TEXT_OUTPUT=0
PEAK_VERBOSITY=report
PEAK_OUTPUT_AGGREGATION=local
PEAK_MPI_REAL_FINALIZE=0

# Config to run PEAK on in --scaling mode
PEAK_SINGLE_CONFIG="n48"

#===============================================================================
# OUTPUT SETTINGS
#===============================================================================

RUN_NAME="gromacs"
OUTPUT_BASE="."
CLEAN_PREVIOUS="FALSE"
