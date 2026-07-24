#!/bin/bash
#===============================================================================
# GROMACS Run Wrapper
#
# generate_jobs.sh calls the application as:
#   mpirun -np N ${APP_BIN} ${INPUT_FILE}
#
# For GROMACS this becomes:
#   mpirun -np N gmx_wrapper.sh benchMEM.tpr
#
# This wrapper receives the .tpr path as $1 and translates it into
# the correct gmx_mpi mdrun command using ibrun (TACC's MPI launcher).
# ibrun reads node/task counts from SLURM env vars automatically.
#
# Usage: called by generate_jobs.sh via APP_BINARY setting in config
#===============================================================================

TPR_FILE="$1"

if [ -z "$TPR_FILE" ]; then
    echo "ERROR: No .tpr file specified"
    exit 1
fi

if [ ! -f "$TPR_FILE" ]; then
    echo "ERROR: TPR file not found: $TPR_FILE"
    exit 1
fi

# Run GROMACS via ibrun (TACC's MPI launcher, equivalent to mpirun on TACC)
# -nsteps 100000  : ~200ps of MD, enough for meaningful timing (tune if too fast/slow)
# -ntomp 1        : 1 OpenMP thread per MPI rank (pure MPI mode)
# -resethway      : reset performance counters at halfway point for cleaner timing
# -noconfout      : skip writing final coordinates (saves I/O time)
# -deffnm md      : output file prefix
ibrun gmx_mpi mdrun \
    -s "${TPR_FILE}" \
    -deffnm md \
    -nsteps 100000 \
    -ntomp 1 \
    -resethway \
    -noconfout

exit $?
