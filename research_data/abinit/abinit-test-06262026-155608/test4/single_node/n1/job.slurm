#!/bin/bash
#SBATCH -J abinit_test4_n1
#SBATCH -o /scratch/11603/crw405/REU-HPC-Research/research_data/abinit/abinit-test-06262026-155608/test4/single_node/n1/slurm.out
#SBATCH -e /scratch/11603/crw405/REU-HPC-Research/research_data/abinit/abinit-test-06262026-155608/test4/single_node/n1/slurm.err
#SBATCH -p skx
#SBATCH -N 1
#SBATCH -n 1
#SBATCH -t 00:10:00
#SBATCH -A EAR23006
#SBATCH --chdir=/scratch/11603/crw405/REU-HPC-Research/research_data/abinit/abinit-test-06262026-155608/test4/single_node/n1

#===============================================================================
# SLURM Job: abinit_test4_n1
# Generated: Fri Jun 26 03:56:08 PM CDT 2026
# Configuration: n1 (1 nodes, 1 tasks)
# PEAK: nopeak
#===============================================================================

start_time=$SECONDS
pre="[n1]: "

echo "${pre}======================================================================"
echo "${pre}SLURM Job Start"
echo "${pre}======================================================================"
echo "${pre}Job ID: ${SLURM_JOB_ID}"
echo "${pre}Configuration: n1"
echo "${pre}Nodes: 1"
echo "${pre}MPI Tasks: 1"
echo "${pre}Tasks per node: $((1 / 1))"
echo "${pre}Test case: test4"
echo "${pre}PEAK profiling: nopeak"
echo "${pre}======================================================================"
echo "${pre}Working directory: /scratch/11603/crw405/REU-HPC-Research/research_data/abinit/abinit-test-06262026-155608/test4/single_node/n1"

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
INPUT_FILE="/scratch/11603/crw405/2.project/1.build_scripts/2.apps/abinit/abinit-10.4.7/tests/v1/Input/t04.abi"

echo "${pre}======================================================================"
echo "${pre}Starting application run..."
echo "${pre}======================================================================"
echo "${pre}Binary: ${APP_BIN}"
echo "${pre}Input: ${INPUT_FILE}"

# Run application
${APP_BIN} ${INPUT_FILE} > /scratch/11603/crw405/REU-HPC-Research/research_data/abinit/abinit-test-06262026-155608/test4/single_node/n1/abinit.stdout 2> /scratch/11603/crw405/REU-HPC-Research/research_data/abinit/abinit-test-06262026-155608/test4/single_node/n1/abinit.stderr

exit_code=$?
end_time=$SECONDS
elapsed=$((end_time - start_time))
hours=$((elapsed / 3600))
minutes=$(((elapsed % 3600) / 60))
seconds=$((elapsed % 60))

echo "${pre}======================================================================"
echo "${pre}Run completed"
echo "${pre}======================================================================"
echo "${pre}Exit code: ${exit_code}"
echo "${pre}Elapsed time: ${elapsed} seconds (${hours}h ${minutes}m ${seconds}s)"
echo "${pre}======================================================================"
echo "${pre}Output files:"
echo "${pre}  Standard output: /scratch/11603/crw405/REU-HPC-Research/research_data/abinit/abinit-test-06262026-155608/test4/single_node/n1/abinit.stdout"
echo "${pre}  Standard error: /scratch/11603/crw405/REU-HPC-Research/research_data/abinit/abinit-test-06262026-155608/test4/single_node/n1/abinit.stderr"
echo "${pre}======================================================================"

exit ${exit_code}
