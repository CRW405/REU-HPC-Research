#!/bin/bash
#SBATCH -J abinit_test1_n1_peak
#SBATCH -o /scratch/11603/crw405/REU-HPC-Research/research_data/abinit/./abinit-full-06292026-131404/test1/single_node/n1_peak/slurm.out
#SBATCH -e /scratch/11603/crw405/REU-HPC-Research/research_data/abinit/./abinit-full-06292026-131404/test1/single_node/n1_peak/slurm.err
#SBATCH --chdir=/scratch/11603/crw405/REU-HPC-Research/research_data/abinit/./abinit-full-06292026-131404/test1/single_node/n1_peak
#SBATCH -p skx
#SBATCH -N 1
#SBATCH -n 1
#SBATCH -t 00:10:00
#SBATCH -A EAR23006

#===============================================================================
# SLURM Job: abinit_test1_n1_peak
# Generated: Mon Jun 29 01:14:07 PM CDT 2026
# Configuration: n1_peak (1 nodes, 1 tasks)
# PEAK: peak
#===============================================================================

# Timing variables
start_epoch=$(date +%s)
start_time=$(date '+%Y-%m-%d %H:%M:%S')
pre="[n1_peak]: "

# Timing log file (absolute path)
TIMING_LOG="/scratch/11603/crw405/REU-HPC-Research/research_data/abinit/./abinit-full-06292026-131404/timing_summary.csv"

echo "${pre}======================================================================"
echo "${pre}SLURM Job Start"
echo "${pre}======================================================================"
echo "${pre}Job ID: ${SLURM_JOB_ID}"
echo "${pre}Configuration: n1_peak"
echo "${pre}Nodes: 1"
echo "${pre}MPI Tasks: 1"
echo "${pre}Tasks per node: $((1 / 1))"
echo "${pre}Test case: test1"
echo "${pre}PEAK profiling: peak"
echo "${pre}Start time: ${start_time}"
echo "${pre}======================================================================"

# Working directory
echo "${pre}Working directory: /scratch/11603/crw405/REU-HPC-Research/research_data/abinit/./abinit-full-06292026-131404/test1/single_node/n1_peak"

# Load modules
echo "${pre}Loading modules..."
ml reset
ml intel
ml impi
ml netcdf

# Setup library paths
echo "${pre}Setting up library paths..."
export LD_LIBRARY_PATH=/scratch/11603/crw405/2.project/1.build_scripts/2.apps/abinit/install/lib:${LD_LIBRARY_PATH}
export LD_LIBRARY_PATH=/opt/apps/intel24/netcdf/4.9.2/lib64:${LD_LIBRARY_PATH}

# Application-specific environment
export ABI_PSPDIR=/scratch/11603/crw405/2.project/1.build_scripts/2.apps/abinit/abinit-10.4.7/tests/Pspdir/

# MPI environment
export I_MPI_SHM=by_node
export FI_PROVIDER=tcp

# PEAK configuration
echo "${pre}Configuring PEAK profiling..."
export PEAK_LIB_PATH=/scratch/11603/crw405/2.project/1.build_scripts/1.peak/peak/lib/libpeak.so
export PEAK_STATSLOG_PATH=/scratch/11603/crw405/REU-HPC-Research/research_data/abinit/./abinit-full-06292026-131404/test1/single_node/n1_peak/peak_stats
export PEAK_MEMLOG_PATH=/scratch/11603/crw405/REU-HPC-Research/research_data/abinit/./abinit-full-06292026-131404/test1/single_node/n1_peak/peak_mem
export PEAK_TARGET_GROUP=BLAS,LAPACK,FFTW,PBLAS,ScaLAPACK
export PEAK_MEMORY_PROFILE=TRUE
export PEAK_MEMORY_TRACK_ALL=TRUE
export PEAK_MEMLOG_CHUNK_EVENTS=10000000

export I_MPI_LD_PRELOAD=${PEAK_LIB_PATH}
export LD_PRELOAD=${PEAK_LIB_PATH}

echo "${pre}  Target groups: BLAS,LAPACK,FFTW,PBLAS,ScaLAPACK"
echo "${pre}  Memory profiling: TRUE"
echo "${pre}  Stats output: /scratch/11603/crw405/REU-HPC-Research/research_data/abinit/./abinit-full-06292026-131404/test1/single_node/n1_peak/peak_stats-pXXXXX.csv"
echo "${pre}  Memory output: /scratch/11603/crw405/REU-HPC-Research/research_data/abinit/./abinit-full-06292026-131404/test1/single_node/n1_peak/peak_mem-pXXXXX.csv"

# Application binary and input
APP_BIN="/scratch/11603/crw405/2.project/1.build_scripts/2.apps/abinit/install/bin/abinit"
INPUT_FILE="/scratch/11603/crw405/2.project/1.build_scripts/2.apps/abinit/abinit-10.4.7/tests/v1/Input/t05.abi"

echo "${pre}======================================================================"
echo "${pre}Starting application run..."
echo "${pre}======================================================================"
echo "${pre}Binary: ${APP_BIN}"
echo "${pre}Input: ${INPUT_FILE}"

# Run application
${APP_BIN} ${INPUT_FILE} > /scratch/11603/crw405/REU-HPC-Research/research_data/abinit/./abinit-full-06292026-131404/test1/single_node/n1_peak/abinit.stdout 2> /scratch/11603/crw405/REU-HPC-Research/research_data/abinit/./abinit-full-06292026-131404/test1/single_node/n1_peak/abinit.stderr

exit_code=$?

# Calculate timing
end_epoch=$(date +%s)
end_time=$(date '+%Y-%m-%d %H:%M:%S')
elapsed_seconds=$((end_epoch - start_epoch))
hours=$((elapsed_seconds / 3600))
minutes=$(((elapsed_seconds % 3600) / 60))
seconds=$((elapsed_seconds % 60))

echo "${pre}======================================================================"
echo "${pre}Run completed"
echo "${pre}======================================================================"
echo "${pre}Exit code: ${exit_code}"
echo "${pre}End time: ${end_time}"
echo "${pre}Elapsed time: ${elapsed_seconds} seconds (${hours}h ${minutes}m ${seconds}s)"
echo "${pre}======================================================================"
echo "${pre}Output files:"
echo "${pre}  Standard output: /scratch/11603/crw405/REU-HPC-Research/research_data/abinit/./abinit-full-06292026-131404/test1/single_node/n1_peak/abinit.stdout"
echo "${pre}  Standard error: /scratch/11603/crw405/REU-HPC-Research/research_data/abinit/./abinit-full-06292026-131404/test1/single_node/n1_peak/abinit.stderr"
echo "${pre}  PEAK outputs:"
ls -lh /scratch/11603/crw405/REU-HPC-Research/research_data/abinit/./abinit-full-06292026-131404/test1/single_node/n1_peak/peak_*.csv 2>/dev/null || echo "${pre}    No PEAK files found"
echo "${pre}======================================================================"

# Log timing data to CSV (append to shared timing log)
echo "abinit_test1_n1_peak,test1,n1_peak,1,1,true,${start_time},${end_time},${elapsed_seconds},${exit_code},${SLURM_JOB_ID}" >> "${TIMING_LOG}"

# Also save individual timing file
cat > /scratch/11603/crw405/REU-HPC-Research/research_data/abinit/./abinit-full-06292026-131404/test1/single_node/n1_peak/timing.txt << TIMING_EOF
Job Name: abinit_test1_n1_peak
Test Case: test1
Configuration: n1_peak
Nodes: 1
Tasks: 1
PEAK Enabled: true
SLURM Job ID: ${SLURM_JOB_ID}
Start Time: ${start_time}
End Time: ${end_time}
Elapsed Seconds: ${elapsed_seconds}
Elapsed (formatted): ${hours}h ${minutes}m ${seconds}s
Exit Code: ${exit_code}
TIMING_EOF

exit ${exit_code}
