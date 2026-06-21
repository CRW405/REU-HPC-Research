#!/bin/bash

start_time=$SECONDS

rm ./t00* abinit.* peak*

pre="   <test>: "

echo "${pre}setting modules"

ml reset
ml intel
ml impi
ml netcdf

echo "${pre}Setting env"

echo "${pre}setting path"

export LD_LIBRARY_PATH=/scratch/11603/crw405/2.project/1.build_scripts/2.apps/abinit/install/lib:/opt/apps/intel24/netcdf/4.9.2/lib64:$LD_LIBRARY_PATH

echo "${pre}Setting up ABINIT"

export ABI_PSPDIR=../abinit-10.4.7/tests/Pspdir/

# FIX: Intel MPI workarounds to bypass the shared memory allocation crash
export I_MPI_SHM=by_node
export FI_PROVIDER=tcp

ABINIT_BIN=../install/bin/abinit
TEST_PATH=../abinit-10.4.7/tests/v1/Input/t00.abi

echo "${pre}Setting up PEAK"

export LIBPEAK_PATH=/scratch/11603/crw405/2.project/1.build_scripts/1.peak/peak/lib/libpeak.so
export PEAK_STATSLOG_PATH=peak_stats
export PEAK_MEMLOG_PATH=peak_mem
export PEAK_TARGET_GROUP=BLAS,LAPACK,FFTW
export PEAK_MEMORY_PROFILE=TRUE
export PEAK_MEMORY_TRACK_ALL=TRUE
export PEAK_MOMLOG_CHUNK_EVENTS=10000000

# Force Intel MPI to handle the preload on the remote nodes
export I_MPI_LD_PRELOAD=${LIBPEAK_PATH}
export LD_PRELOAD=${LIBPEAK_PATH}

echo "${pre}Peaking and Running"

${ABINIT_BIN} ${TEST_PATH} > abinit.stdout 2> abinit.stderr

echo "Done, check output files"

end_time=$SECONDS

echo "Time Took: $((end_time - start_time)) seconds"
