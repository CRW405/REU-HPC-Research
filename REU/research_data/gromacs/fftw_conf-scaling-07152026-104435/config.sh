#!/bin/bash
#===============================================================================
# GROMACS Configuration
#
# This file is sourced by generate_jobs.sh
#===============================================================================

#===============================================================================
# APPLICATION SETTINGS
#===============================================================================

APP_NAME="gromacs"
APP_BINARY="/opt/apps/intel24/impi21/gromacs/2024/bin/gmx_mpi"

# Test cases - format: "name:input_path"
TEST_CASES=(
    "benchMEM:/work2/05392/cylu/share/reu_2026/2.project/2.examples/gromacs/benchMEM.tpr"
)

# No app-specific environment variables needed
APP_ENV=()

# Override the default mpirun command for GROMACS.
# NTASKS is substituted at job generation time.
# INPUT_FILE is passed via -s flag instead of positional argument.
# -nsteps 50000 : ~100ps, ~30-60s on n48, ~2min on n24 (tune if needed)
# -ntomp 1      : pure MPI, 1 OpenMP thread per rank
# -resethway    : reset perf counters halfway through for cleaner timing
# -noconfout    : skip final coordinate output to save I/O
RUN_COMMAND="LD_PRELOAD=/scratch/11603/crw405/peak/peak/lib/libpeak.so ibrun /opt/apps/intel24/impi21/gromacs/2024/bin/gmx_mpi mdrun -s /work2/05392/cylu/share/reu_2026/2.project/2.examples/gromacs/benchMEM.tpr -deffnm md -nsteps 50000 -ntomp 1 -resethway -noconfout"

# Dump command to generate human-readable summary of the .tpr input
# This runs gmx_mpi dump -s <tpr> and saves to input_dump.txt in the run dir
INPUT_DUMP_CMD="gmx_mpi dump -s"

#===============================================================================
# MODULE SETTINGS
#===============================================================================

MODULES=(
    "intel/24.0"
    "impi/21.11"
    "gromacs/2024"
)

LIBRARY_PATHS=()

#===============================================================================
# MPI SETTINGS
#===============================================================================

# ibrun handles MPI on TACC — no extra MPI env vars needed
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

# GROMACS is FFTW-heavy (PME) — try with FFTW first, drop to BLAS,LAPACK if segfault
PEAK_TARGET_GROUPS="BLAS,LAPACK,FFTW"
PEAK_TARGET_CONFIG="FFTW"
#PEAK_TARGET_GROUPS="BLAS,LAPACK,FFTW"
#PEAK_TARGET_GROUPS="BLAS,LAPACK"

PEAK_MEMORY_PROFILE="FALSE"
PEAK_TEXT_OUTPUT=0
PEAK_VERBOSITY=report
PEAK_OUTPUT_AGGREGATION=local
PEAK_MPI_REAL_FINALIZE=0

# Run PEAK on n48 — largest single-node config, most interesting for GROMACS
PEAK_SINGLE_CONFIG="n48"

#===============================================================================
# OUTPUT SETTINGS
#===============================================================================

RUN_NAME="gromacs"
OUTPUT_BASE="."
CLEAN_PREVIOUS="FALSE"
