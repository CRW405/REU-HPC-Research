#!/bin/bash
#SBATCH -J abinit_test3_N4_nopeak
#SBATCH -o /scratch/11603/crw405/REU-HPC-Research/research_data/abinit/./abinit-full-06292026-185720/test3/multi_node/N4_nopeak/slurm.out
#SBATCH -e /scratch/11603/crw405/REU-HPC-Research/research_data/abinit/./abinit-full-06292026-185720/test3/multi_node/N4_nopeak/slurm.err
#SBATCH --chdir=/scratch/11603/crw405/REU-HPC-Research/research_data/abinit/./abinit-full-06292026-185720/test3/multi_node/N4_nopeak
#SBATCH -p skx
#SBATCH -N 4
#SBATCH -n 192
#SBATCH -t 00:40:00
#SBATCH -A EAR23006

#===============================================================================
# SLURM Job: abinit_test3_N4_nopeak
# Generated: Mon Jun 29 06:57:23 PM CDT 2026
# Configuration: N4_nopeak (4 nodes, 192 tasks)
# PEAK: nopeak
#===============================================================================

# Timing variables
start_epoch=$(date +%s)
start_time=$(date '+%Y-%m-%d %H:%M:%S')
pre="[N4_nopeak]: "

# Timing log file (absolute path)
TIMING_LOG="/scratch/11603/crw405/REU-HPC-Research/research_data/abinit/./abinit-full-06292026-185720/timing_summary.csv"

echo "${pre}======================================================================"
echo "${pre}SLURM Job Start"
echo "${pre}======================================================================"
echo "${pre}Job ID: ${SLURM_JOB_ID}"
echo "${pre}Configuration: N4_nopeak"
echo "${pre}Nodes: 4"
echo "${pre}MPI Tasks: 192"
echo "${pre}Tasks per node: $((192 / 4))"
echo "${pre}Test case: test3"
echo "${pre}PEAK profiling: nopeak"
echo "${pre}Start time: ${start_time}"
echo "${pre}======================================================================"

# Working directory
echo "${pre}Working directory: /scratch/11603/crw405/REU-HPC-Research/research_data/abinit/./abinit-full-06292026-185720/test3/multi_node/N4_nopeak"

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

# Application binary and input
APP_BIN="/scratch/11603/crw405/2.project/1.build_scripts/2.apps/abinit/install/bin/abinit"
INPUT_FILE="/scratch/11603/crw405/2.project/1.build_scripts/2.apps/abinit/abinit-10.4.7/tests/v1/Input/t03.abi"

echo "${pre}======================================================================"
echo "${pre}Starting application run..."
echo "${pre}======================================================================"
echo "${pre}Binary: ${APP_BIN}"
echo "${pre}Input: ${INPUT_FILE}"

# Run application
mpirun -np 192 ${APP_BIN} ${INPUT_FILE} > /scratch/11603/crw405/REU-HPC-Research/research_data/abinit/./abinit-full-06292026-185720/test3/multi_node/N4_nopeak/abinit.stdout 2> /scratch/11603/crw405/REU-HPC-Research/research_data/abinit/./abinit-full-06292026-185720/test3/multi_node/N4_nopeak/abinit.stderr

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
echo "${pre}  Standard output: /scratch/11603/crw405/REU-HPC-Research/research_data/abinit/./abinit-full-06292026-185720/test3/multi_node/N4_nopeak/abinit.stdout"
echo "${pre}  Standard error: /scratch/11603/crw405/REU-HPC-Research/research_data/abinit/./abinit-full-06292026-185720/test3/multi_node/N4_nopeak/abinit.stderr"
echo "${pre}======================================================================"

# Log timing data to CSV (append to shared timing log)
echo "abinit_test3_N4_nopeak,test3,N4_nopeak,4,192,false,${start_time},${end_time},${elapsed_seconds},${exit_code},${SLURM_JOB_ID}" >> "${TIMING_LOG}"

# Also save individual timing file
cat > /scratch/11603/crw405/REU-HPC-Research/research_data/abinit/./abinit-full-06292026-185720/test3/multi_node/N4_nopeak/timing.txt << TIMING_EOF
Job Name: abinit_test3_N4_nopeak
Test Case: test3
Configuration: N4_nopeak
Nodes: 4
Tasks: 192
PEAK Enabled: false
SLURM Job ID: ${SLURM_JOB_ID}
Start Time: ${start_time}
End Time: ${end_time}
Elapsed Seconds: ${elapsed_seconds}
Elapsed (formatted): ${hours}h ${minutes}m ${seconds}s
Exit Code: ${exit_code}
TIMING_EOF

exit ${exit_code}
