#!/bin/bash
#===============================================================================
# Submit All Arrays - SAFE MODE
#
# Submits job arrays one at a time, waiting for each to fully complete before
# submitting the next. Only one array is in the queue at any given time.
#
# This is the safest option for strict job count limits, but will take the
# longest wall-clock time (sum of all array runtimes).
#===============================================================================

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo "======================================================================="
echo "Submitting all job arrays (SAFE MODE - ONE AT A TIME)"
echo "======================================================================="
echo "Each array will be submitted only after the previous completes."
echo "Only one array will be in the queue at a time."
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
    output=$(sbatch "$script_path" 2>&1)
    jobid=$(echo "$output" | awk '/Submitted batch job/{print $NF}')
    
    echo "$output"
    
    if [ -n "$jobid" ] && [ "$jobid" -eq "$jobid" ] 2>/dev/null; then
        echo "  → Job ID: ${jobid}"
        ((submitted++))
        
        echo "  → Waiting for array to complete..."
        
        # Wait for job to appear in queue (sometimes takes a moment)
        sleep 5
        
        # Poll until job is no longer in queue
        while squeue -j "$jobid" 2>/dev/null | grep -q "$jobid"; do
            # Show status every minute
            status=$(squeue -j "$jobid" -h -o "%T" 2>/dev/null | head -n1)
            if [ -n "$status" ]; then
                echo "     Status: ${status} (checking again in 60s...)"
            fi
            sleep 60
        done
        
        echo "  → Array complete!"
        echo ""
    else
        echo "  → FAILED"
        ((failed++))
        echo ""
    fi
    
done < "${SCRIPT_DIR}/array_jobs.txt"

echo "======================================================================="
echo "All arrays complete"
echo "======================================================================="
echo "Arrays submitted: ${submitted}"
echo "Failed: ${failed}"
echo "======================================================================="
