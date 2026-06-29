#!/bin/bash
#SBATCH -J array_N1_n4
#SBATCH -N 1
#SBATCH -n 4
#SBATCH -t 00:10:00
#SBATCH -p skx
#SBATCH -A EAR23006
#SBATCH --array=0-9%10
#SBATCH -o abinit-full-06292026-131404/job_arrays/logs/array_N1_n4-%A_%a.out
#SBATCH -e abinit-full-06292026-131404/job_arrays/logs/array_N1_n4-%A_%a.err

#===============================================================================
# Job Array: array_N1_n4
# Generated: Mon Jun 29 01:14:31 PM CDT 2026
# Array size: 10 jobs (indices 0-9)
# Resources: N=1, n=4, time=00:10:00, partition=skx, account=EAR23006
# Max concurrent: 10
#===============================================================================

echo "======================================================================="
echo "Array Job Start: array_N1_n4"
echo "======================================================================="
echo "Array Job ID: ${SLURM_ARRAY_JOB_ID}"
echo "Array Task ID: ${SLURM_ARRAY_TASK_ID}"
echo "Job ID: ${SLURM_JOB_ID}"
echo "Hostname: $(hostname)"
echo "Start time: $(date)"
echo "======================================================================="

# Map array task ID to original job directory
case ${SLURM_ARRAY_TASK_ID} in
  0)
    echo "Task 0: test0/n4_ (nopeak)"
    original_dir="/scratch/11603/crw405/REU-HPC-Research/research_data/abinit/abinit-full-06292026-131404/test0/single_node/n4_"
    ;;
  1)
    echo "Task 1: test0/n4_peak (peak)"
    original_dir="/scratch/11603/crw405/REU-HPC-Research/research_data/abinit/abinit-full-06292026-131404/test0/single_node/n4_peak"
    ;;
  2)
    echo "Task 2: test1/n4_ (nopeak)"
    original_dir="/scratch/11603/crw405/REU-HPC-Research/research_data/abinit/abinit-full-06292026-131404/test1/single_node/n4_"
    ;;
  3)
    echo "Task 3: test1/n4_peak (peak)"
    original_dir="/scratch/11603/crw405/REU-HPC-Research/research_data/abinit/abinit-full-06292026-131404/test1/single_node/n4_peak"
    ;;
  4)
    echo "Task 4: test2/n4_ (nopeak)"
    original_dir="/scratch/11603/crw405/REU-HPC-Research/research_data/abinit/abinit-full-06292026-131404/test2/single_node/n4_"
    ;;
  5)
    echo "Task 5: test2/n4_peak (peak)"
    original_dir="/scratch/11603/crw405/REU-HPC-Research/research_data/abinit/abinit-full-06292026-131404/test2/single_node/n4_peak"
    ;;
  6)
    echo "Task 6: test3/n4_ (nopeak)"
    original_dir="/scratch/11603/crw405/REU-HPC-Research/research_data/abinit/abinit-full-06292026-131404/test3/single_node/n4_"
    ;;
  7)
    echo "Task 7: test3/n4_peak (peak)"
    original_dir="/scratch/11603/crw405/REU-HPC-Research/research_data/abinit/abinit-full-06292026-131404/test3/single_node/n4_peak"
    ;;
  8)
    echo "Task 8: test4/n4_ (nopeak)"
    original_dir="/scratch/11603/crw405/REU-HPC-Research/research_data/abinit/abinit-full-06292026-131404/test4/single_node/n4_"
    ;;
  9)
    echo "Task 9: test4/n4_peak (peak)"
    original_dir="/scratch/11603/crw405/REU-HPC-Research/research_data/abinit/abinit-full-06292026-131404/test4/single_node/n4_peak"
    ;;
  *)
    echo "ERROR: Unknown array task ID: ${SLURM_ARRAY_TASK_ID}"
    exit 1
    ;;
esac

echo "-----------------------------------------------------------------------"
echo "Changing to: ${original_dir}"
cd "${original_dir}" || exit 1

echo "Executing original job script..."
echo "-----------------------------------------------------------------------"

# Source the original job.slurm (skipping SBATCH directives)
# This executes all the module loads, environment setup, and application run
while IFS= read -r line; do
    # Skip shebang and SBATCH lines
    if [[ "$line" =~ ^#SBATCH ]] || [[ "$line" =~ ^#!/bin/bash ]]; then
        continue
    fi
    # Execute everything else
    eval "$line"
done < "${original_dir}/job.slurm"

exit_code=$?

echo "======================================================================="
echo "Array task ${SLURM_ARRAY_TASK_ID} completed with exit code: ${exit_code}"
echo "End time: $(date)"
echo "======================================================================="

exit ${exit_code}
