#!/bin/bash
#===============================================================================
# Submit All Arrays - DEPENDENCY MODE
#
# Submits all job arrays with SLURM dependencies, so each array starts only
# after the previous one completes (using --dependency=afterany:JOBID).
#
# All jobs enter the queue immediately, but only one array runs at a time.
#
# NOTE: Dependency-held jobs may still count toward your total job limit
# depending on SLURM configuration.
#===============================================================================

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo "======================================================================="
echo "Submitting all job arrays (DEPENDENCY CHAIN MODE)"
echo "======================================================================="
echo "Each array will wait for the previous one to complete."
echo "All jobs will be submitted to the queue immediately."
echo ""

submitted=0
failed=0
prev_jobid=""

while IFS= read -r array_script; do
    script_path="${SCRIPT_DIR}/${array_script}"
    
    if [ ! -f "$script_path" ]; then
        echo "WARNING: Script not found: ${script_path}"
        ((failed++))
        continue
    fi
    
    echo "Submitting ${array_script}..."
    
    if [ -z "$prev_jobid" ]; then
        # First job: no dependency
        jobid=$(sbatch "$script_path" 2>&1 | tee /dev/tty | awk '/Submitted batch job/{print $NF}')
    else
        # Subsequent jobs: depend on previous
        jobid=$(sbatch --dependency=afterany:${prev_jobid} "$script_path" 2>&1 | tee /dev/tty | awk '/Submitted batch job/{print $NF}')
    fi
    
    if [ -n "$jobid" ] && [ "$jobid" -eq "$jobid" ] 2>/dev/null; then
        if [ -z "$prev_jobid" ]; then
            echo "  → Job ID: ${jobid} (will start immediately)"
        else
            echo "  → Job ID: ${jobid} (depends on ${prev_jobid})"
        fi
        prev_jobid="$jobid"
        ((submitted++))
    else
        echo "  → FAILED"
        ((failed++))
    fi
    echo ""
done < "${SCRIPT_DIR}/array_jobs.txt"

echo "======================================================================="
echo "Submission complete"
echo "======================================================================="
echo "Arrays submitted: ${submitted}"
echo "Failed: ${failed}"
echo ""
echo "All jobs are in the queue with dependency chain."
echo "Monitor with: squeue -u \$USER"
echo "======================================================================="
