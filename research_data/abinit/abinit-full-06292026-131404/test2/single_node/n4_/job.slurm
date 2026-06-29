#!/bin/bash
#SBATCH -J abinit_test2_n4_
#SBATCH -o /scratch/11603/crw405/REU-HPC-Research/research_data/abinit/./abinit-full-06292026-131404/test2/single_node/n4_/slurm.out
#SBATCH -e /scratch/11603/crw405/REU-HPC-Research/research_data/abinit/./abinit-full-06292026-131404/test2/single_node/n4_/slurm.err
#SBATCH --chdir=/scratch/11603/crw405/REU-HPC-Research/research_data/abinit/./abinit-full-06292026-131404/test2/single_node/n4_
#SBATCH -p skx
#SBATCH -N 1
#SBATCH -n 4
#SBATCH -t 00:10:00
#SBATCH -A EAR23006

#===============================================================================
# SLURM Job: abinit_test2_n4_
# Generated: Mon Jun 29 01:14:05 PM CDT 2026
# Configuration: n4_ (1 nodes, 4 tasks)
# PEAK: nopeak
#===============================================================================

# Timing variables
start_epoch=$(date +%s)
start_time=$(date '+%Y-%m-%d %H:%M:%S')
pre="[n4_]: "

# Timing log file (absolute path)
TIMING_LOG="/scratch/11603/crw405/REU-HPC-Research/research_data/abinit/./abinit-full-06292026-131404/timing_summary.csv"

echo "${pre}======================================================================"
echo "${pre}SLURM Job Start"
echo "${pre}======================================================================"
echo "${pre}Job ID: ${SLURM_JOB_ID}"
echo "${pre}Configuration: n4_"
echo "${pre}Nodes: 1"
echo "${pre}MPI Tasks: 4"
echo "${pre}Tasks per node: $((4 / 1))"
echo "${pre}Test case: test2"
echo "${pre}PEAK profiling: nopeak"
echo "${pre}Start time: ${start_time}"
echo "${pre}======================================================================"

# Working directory
echo "${pre}Working directory: /scratch/11603/crw405/REU-HPC-Research/research_data/abinit/./abinit-full-06292026-131404/test2/single_node/n4_"

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
INPUT_FILE="/scratch/11603/crw405/2.project/1.build_scripts/2.apps/abinit/abinit-10.4.7/tests/v1/Input/t02.abi"

echo "${pre}======================================================================"
echo "${pre}Starting application run..."
echo "${pre}======================================================================"
echo "${pre}Binary: ${APP_BIN}"
echo "${pre}Input: ${INPUT_FILE}"

# Run application
${APP_BIN} ${INPUT_FILE} > /scratch/11603/crw405/REU-HPC-Research/research_data/abinit/./abinit-full-06292026-131404/test2/single_node/n4_/abinit.stdout 2> /scratch/11603/crw405/REU-HPC-Research/research_data/abinit/./abinit-full-06292026-131404/test2/single_node/n4_/abinit.stderr

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
echo "${pre}  Standard output: /scratch/11603/crw405/REU-HPC-Research/research_data/abinit/./abinit-full-06292026-131404/test2/single_node/n4_/abinit.stdout"
echo "${pre}  Standard error: /scratch/11603/crw405/REU-HPC-Research/research_data/abinit/./abinit-full-06292026-131404/test2/single_node/n4_/abinit.stderr"
echo "${pre}======================================================================"

# Log timing data to CSV (append to shared timing log)
echo "abinit_test2_n4_,test2,n4_,1,4,false,${start_time},${end_time},${elapsed_seconds},${exit_code},${SLURM_JOB_ID}" >> "${TIMING_LOG}"

# Also save individual timing file
cat > /scratch/11603/crw405/REU-HPC-Research/research_data/abinit/./abinit-full-06292026-131404/test2/single_node/n4_/timing.txt << TIMING_EOF
Job Name: abinit_test2_n4_
Test Case: test2
Configuration: n4_
Nodes: 1
Tasks: 4
PEAK Enabled: false
SLURM Job ID: ${SLURM_JOB_ID}
Start Time: ${start_time}
End Time: ${end_time}
Elapsed Seconds: ${elapsed_seconds}
Elapsed (formatted): ${hours}h ${minutes}m ${seconds}s
Exit Code: ${exit_code}
TIMING_EOF

exit ${exit_code}
