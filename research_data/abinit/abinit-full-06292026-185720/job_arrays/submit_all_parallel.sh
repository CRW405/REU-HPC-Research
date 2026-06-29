#!/bin/bash
#===============================================================================
# Submit All Arrays - PARALLEL MODE
#
# Submits all job arrays at once. Each array respects its own concurrency
# limit (--array=...%N), but all arrays are active simultaneously.
#
# WARNING: This may result in many jobs in the queue at once.
# Use with caution if you have strict job count limits.
#===============================================================================

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo "======================================================================="
echo "Submitting all job arrays (PARALLEL MODE)"
echo "======================================================================="
echo "All arrays will be submitted at once."
echo "Each array respects its own concurrency limit."
echo ""

submitted=0
failed=0

while IFS= read -r array_script; do
    script_path="${SCRIPT_DIR}/${array_script}"
    
    if [ ! -f "$script_path" ]; then
        echo "WARNING: Script not found: ${script_path}"
        ((failed++))
        continue
    fi
    
    echo "Submitting ${array_script}..."
    jobid=$(sbatch "$script_path" 2>&1 | tee /dev/tty | awk '/Submitted batch job/{print $NF}')
    
    if [ -n "$jobid" ] && [ "$jobid" -eq "$jobid" ] 2>/dev/null; then
        echo "  → Job ID: ${jobid}"
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
echo "Monitor with: squeue -u \$USER"
echo "======================================================================="
