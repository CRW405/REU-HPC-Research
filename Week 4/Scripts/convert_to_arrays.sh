#!/bin/bash
#===============================================================================
# SLURM Job to Array Converter
#
# Analyzes existing job.slurm files and groups compatible jobs (same resource
# requirements) into job arrays to reduce total job count while respecting
# the 20 active / 80 total job limits.
#
# Usage:
#   ./convert_to_arrays.sh [options] [base_directory] [max_concurrent]
#
# Options:
#   -d, --dry-run     Show grouping analysis without creating files
#
# Arguments:
#   base_directory    Root directory containing test0, test1, etc.
#                     (default: current directory)
#   max_concurrent    Max concurrent jobs per array (default: 10)
#
# Output:
#   Creates job_arrays/ directory with consolidated array scripts
#===============================================================================

# Parse options
DRY_RUN=false
while [[ $# -gt 0 ]]; do
    case $1 in
        -d|--dry-run)
            DRY_RUN=true
            shift
            ;;
        *)
            break
            ;;
    esac
done

BASE_DIR="${1:-.}"
MAX_CONCURRENT="${2:-10}"

if [ ! -d "$BASE_DIR" ]; then
    echo "ERROR: Directory not found: $BASE_DIR"
    exit 1
fi

# Ensure max concurrent doesn't exceed TACC limit
if [ "$MAX_CONCURRENT" -gt 20 ]; then
    echo "WARNING: Max concurrent ($MAX_CONCURRENT) exceeds TACC limit of 20. Setting to 20."
    MAX_CONCURRENT=20
fi

ARRAY_DIR="${BASE_DIR}/job_arrays"
SUBMIT_SCRIPT="${ARRAY_DIR}/submit_all_arrays.sh"
ARRAY_LIST="${ARRAY_DIR}/array_jobs.txt"

echo "==============================================================================="
echo "SLURM Job to Array Converter"
if [ "$DRY_RUN" = true ]; then
    echo "MODE: DRY RUN (no files will be created)"
fi
echo "==============================================================================="
echo "Base directory: ${BASE_DIR}"
echo "Max concurrent per array: ${MAX_CONCURRENT}"
if [ "$DRY_RUN" = false ]; then
    echo "Output directory: ${ARRAY_DIR}"
fi
echo ""

#===============================================================================
# FUNCTION: Extract SBATCH directive value
#===============================================================================
get_sbatch_value() {
    local file=$1
    local directive=$2
    grep "^#SBATCH ${directive}" "$file" | head -n1 | awk '{print $3}'
}

#===============================================================================
# FUNCTION: Extract resource signature (for grouping)
#===============================================================================
get_resource_signature() {
    local file=$1
    local nodes=$(get_sbatch_value "$file" "-N")
    local ntasks=$(get_sbatch_value "$file" "-n")
    local time=$(get_sbatch_value "$file" "-t")
    local partition=$(get_sbatch_value "$file" "-p")
    
    # Create signature: nodes_ntasks_time_partition
    echo "${nodes}_${ntasks}_${time}_${partition}"
}

#===============================================================================
# FUNCTION: Check if job uses PEAK
#===============================================================================
uses_peak() {
    local file=$1
    grep -q "PEAK_LIB_PATH" "$file" && echo "peak" || echo "nopeak"
}

#===============================================================================
# FUNCTION: Extract test name from path
#===============================================================================
get_test_name() {
    local path=$1
    # Extract test0, test1, etc.
    echo "$path" | grep -oP 'test\d+'
}

#===============================================================================
# FUNCTION: Extract config name from path
#===============================================================================
get_config_name() {
    local path=$1
    # Extract things like n56_peak, N4_nopeak
    local dir=$(dirname "$path")
    basename "$dir"
}

#===============================================================================
# STEP 1: Find all job.slurm files and categorize
#===============================================================================

echo "Step 1: Scanning for job.slurm files..."
echo "-----------------------------------------------------------------------"

declare -A job_groups  # signature -> list of job files
declare -A job_metadata  # job_file -> test_name:config:peak
declare -A group_resources  # signature -> nodes:ntasks:time:partition (for display)

total_jobs=0

while IFS= read -r -d '' jobfile; do
    ((total_jobs++))
    
    sig=$(get_resource_signature "$jobfile")
    peak=$(uses_peak "$jobfile")
    test=$(get_test_name "$jobfile")
    config=$(get_config_name "$jobfile")
    
    # Store metadata
    job_metadata["$jobfile"]="${test}:${config}:${peak}"
    
    # Store resource details for display
    if [ -z "${group_resources[$sig]}" ]; then
        nodes=$(get_sbatch_value "$jobfile" "-N")
        ntasks=$(get_sbatch_value "$jobfile" "-n")
        time=$(get_sbatch_value "$jobfile" "-t")
        partition=$(get_sbatch_value "$jobfile" "-p")
        group_resources[$sig]="${nodes}:${ntasks}:${time}:${partition}"
    fi
    
    # Group by signature
    if [ -z "${job_groups[$sig]}" ]; then
        job_groups[$sig]="$jobfile"
    else
        job_groups[$sig]="${job_groups[$sig]}|$jobfile"
    fi
    
done < <(find "$BASE_DIR" -type f -name "job.slurm" -print0)

echo "Found ${total_jobs} total job files"
echo "Grouped into ${#job_groups[@]} resource signature groups"
echo ""

#===============================================================================
# STEP 2: Analyze grouping and show consolidation preview
#===============================================================================

echo "Step 2: Analyzing job grouping..."
echo "-----------------------------------------------------------------------"
echo ""

array_count=0
singleton_count=0
total_arrays=0
total_in_arrays=0

# Sort signatures by number of jobs (descending) for better display
declare -A group_sizes
for sig in "${!job_groups[@]}"; do
    IFS='|' read -ra jobs <<< "${job_groups[$sig]}"
    group_sizes[$sig]=${#jobs[@]}
done

# Create sorted list
sorted_sigs=$(for sig in "${!group_sizes[@]}"; do
    echo "${group_sizes[$sig]} $sig"
done | sort -rn | awk '{print $2}')

for sig in $sorted_sigs; do
    # Parse resource info
    IFS=':' read -r nodes ntasks time partition <<< "${group_resources[$sig]}"
    
    # Get jobs in this group
    IFS='|' read -ra jobs <<< "${job_groups[$sig]}"
    num_jobs=${#jobs[@]}
    
    if [ "$num_jobs" -lt 2 ]; then
        ((singleton_count++))
        if [ "$DRY_RUN" = true ]; then
            echo "❌ Singleton (N=${nodes}, n=${ntasks}, t=${time}, p=${partition}): 1 job (no consolidation)"
        fi
    else
        ((array_count++))
        ((total_in_arrays += num_jobs))
        
        array_name="array_${array_count}_N${nodes}_n${ntasks}"
        
        echo "✅ Array ${array_count}: ${array_name}"
        echo "   Resources: N=${nodes}, n=${ntasks}, time=${time}, partition=${partition}"
        echo "   Jobs: ${num_jobs} → 1 array (${num_jobs}:1 consolidation)"
        
        if [ "$DRY_RUN" = true ]; then
            echo "   Contents:"
            for idx in "${!jobs[@]}"; do
                jobfile="${jobs[$idx]}"
                metadata="${job_metadata[$jobfile]}"
                IFS=':' read -r test config peak <<< "$metadata"
                echo "      [$idx] ${test}/${config} (${peak})"
            done
        fi
        echo ""
    fi
done

echo "======================================================================="
echo "CONSOLIDATION SUMMARY"
echo "======================================================================="
echo "Total jobs found:        ${total_jobs}"
echo "Jobs in arrays:          ${total_in_arrays}"
echo "Singleton jobs:          ${singleton_count}"
echo "Number of arrays:        ${array_count}"
echo ""
echo "Before: ${total_jobs} individual job submissions"
echo "After:  ${array_count} array submissions + ${singleton_count} individual jobs"
echo "        = $((array_count + singleton_count)) total submissions"
echo ""
echo "Job reduction:           ${total_jobs} → $((array_count + singleton_count))"
echo "Reduction factor:        $(awk "BEGIN {printf \"%.1fx\", ${total_jobs}/($array_count + $singleton_count)}")"
echo "======================================================================="

if [ "$DRY_RUN" = true ]; then
    echo ""
    echo "This was a dry run. No files were created."
    echo "To generate array scripts, run without -d/--dry-run flag:"
    echo "  ./convert_to_arrays.sh ${BASE_DIR} ${MAX_CONCURRENT}"
    exit 0
fi

#===============================================================================
# STEP 3: Create job arrays for each group
#===============================================================================

echo ""
echo "Step 3: Generating job array scripts..."
echo "-----------------------------------------------------------------------"
echo ""

# Create output directory
mkdir -p "${ARRAY_DIR}"
> "${ARRAY_LIST}"

array_count=0
singleton_list="${ARRAY_DIR}/singleton_jobs.txt"
> "${singleton_list}"

for sig in "${!job_groups[@]}"; do
    # Parse signature
    IFS='_' read -r nodes ntasks time partition <<< "$sig"
    
    # Get jobs in this group
    IFS='|' read -ra jobs <<< "${job_groups[$sig]}"
    num_jobs=${#jobs[@]}
    
    # Only create array if there's more than one job
    if [ "$num_jobs" -lt 2 ]; then
        echo "Skipping group ${sig}: only 1 job (no benefit from array)"
        echo "${jobs[0]}" >> "${singleton_list}"
        continue
    fi
    
    ((array_count++))
    
    array_name="array_${array_count}_N${nodes}_n${ntasks}"
    array_script="${ARRAY_DIR}/${array_name}.slurm"
    
    echo "Creating array: ${array_name}"
    echo "  Resources: ${nodes} nodes, ${ntasks} tasks, ${time}, partition=${partition}"
    echo "  Jobs in array: ${num_jobs}"
    
    # Start building the array script
    cat > "$array_script" << EOF
#!/bin/bash
#SBATCH -J ${array_name}
#SBATCH -o ${ARRAY_DIR}/${array_name}_%a.out
#SBATCH -e ${ARRAY_DIR}/${array_name}_%a.err
#SBATCH -p ${partition}
#SBATCH -N ${nodes}
#SBATCH -n ${ntasks}
#SBATCH -t ${time}
#SBATCH --array=0-$((num_jobs - 1))%${MAX_CONCURRENT}

#===============================================================================
# Job Array: ${array_name}
# Generated: $(date)
# Total jobs: ${num_jobs}
# Max concurrent: ${MAX_CONCURRENT}
#===============================================================================

echo "==============================================================================="
echo "Array Job: ${array_name}"
echo "Array Task ID: \${SLURM_ARRAY_TASK_ID}"
echo "SLURM Job ID: \${SLURM_JOB_ID}"
echo "==============================================================================="

# Map array index to specific job configuration
case \${SLURM_ARRAY_TASK_ID} in
EOF

    # Add case entries for each job
    for idx in "${!jobs[@]}"; do
        jobfile="${jobs[$idx]}"
        metadata="${job_metadata[$jobfile]}"
        IFS=':' read -r test config peak <<< "$metadata"
        
        # Get original job directory and relevant paths
        orig_dir=$(dirname "$jobfile")
        
        echo "    ${idx})"  >> "$array_script"
        echo "        TEST_NAME=\"${test}\"" >> "$array_script"
        echo "        CONFIG=\"${config}\"" >> "$array_script"
        echo "        PEAK_ENABLED=\"${peak}\"" >> "$array_script"
        echo "        WORK_DIR=\"${orig_dir}\"" >> "$array_script"
        echo "        ;;" >> "$array_script"
        
        echo "    [${idx}] ${test}/${config} (${peak})"
    done
    
    cat >> "$array_script" << 'EOF'
    *)
        echo "ERROR: Invalid SLURM_ARRAY_TASK_ID: ${SLURM_ARRAY_TASK_ID}"
        exit 1
        ;;
esac

echo "Configuration: ${TEST_NAME} / ${CONFIG} / ${PEAK_ENABLED}"
echo "Working directory: ${WORK_DIR}"
echo "==============================================================================="

# Change to work directory
cd "${WORK_DIR}" || exit 1

# Source the original job script (skip SBATCH lines, execute the rest)
echo "Executing job from: ${WORK_DIR}/job.slurm"
echo ""

# Extract and execute non-SBATCH lines from original script
grep -v "^#SBATCH" "${WORK_DIR}/job.slurm" | grep -v "^#!/bin/bash" | bash

# Capture exit status
exit_status=$?

echo ""
echo "==============================================================================="
echo "Job completed with exit status: ${exit_status}"
echo "==============================================================================="

exit ${exit_status}
EOF

    chmod +x "$array_script"
    echo "$array_script" >> "${ARRAY_LIST}"
    echo ""
done

#===============================================================================
# STEP 4: Create master submission script
#===============================================================================

echo ""
echo "Step 4: Creating master submission script..."
echo "-----------------------------------------------------------------------"

cat > "${SUBMIT_SCRIPT}" << 'EOF'
#!/bin/bash
#===============================================================================
# Master Job Array Submission Script
#
# Submits all generated job arrays while respecting TACC limits:
#   - Max 20 active jobs
#   - Max 80 total jobs
#
# Usage:
#   ./submit_all_arrays.sh
#===============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ARRAY_LIST="${SCRIPT_DIR}/array_jobs.txt"
SINGLETON_LIST="${SCRIPT_DIR}/singleton_jobs.txt"

MAX_ACTIVE=20
MAX_TOTAL=80

echo "==============================================================================="
echo "Master Array Submission Script"
echo "==============================================================================="
echo "Starting at: $(date)"
echo ""

if [ ! -f "$ARRAY_LIST" ]; then
    echo "ERROR: Array list not found: $ARRAY_LIST"
    exit 1
fi

#===============================================================================
# FUNCTION: Count user's current jobs
#===============================================================================
count_jobs() {
    squeue -u $USER -h | wc -l
}

#===============================================================================
# FUNCTION: Wait for job count to drop below threshold
#===============================================================================
wait_for_capacity() {
    local threshold=$1
    local current=$(count_jobs)
    
    while [ "$current" -ge "$threshold" ]; do
        echo "Current jobs: ${current} / ${MAX_TOTAL} (waiting for capacity...)"
        sleep 30
        current=$(count_jobs)
    done
}

#===============================================================================
# STEP 1: Submit job arrays
#===============================================================================

echo "Step 1: Submitting job arrays..."
echo "-----------------------------------------------------------------------"

submitted_count=0
total_arrays=$(wc -l < "$ARRAY_LIST")

while IFS= read -r array_script; do
    ((submitted_count++))
    
    # Wait if we're approaching the total job limit
    # Leave some margin (e.g., MAX_TOTAL - 10) to avoid race conditions
    wait_for_capacity $((MAX_TOTAL - 10))
    
    echo "[${submitted_count}/${total_arrays}] Submitting: $(basename $array_script)"
    sbatch "$array_script"
    
    if [ $? -eq 0 ]; then
        echo "  ✓ Submitted successfully"
    else
        echo "  ✗ Submission failed"
    fi
    
    # Brief pause between submissions
    sleep 2
    
done < "$ARRAY_LIST"

echo ""
echo "Array submission complete: ${submitted_count} arrays submitted"
echo ""

#===============================================================================
# STEP 2: Submit singleton jobs (if any)
#===============================================================================

if [ -f "$SINGLETON_LIST" ] && [ -s "$SINGLETON_LIST" ]; then
    echo "Step 2: Submitting singleton jobs..."
    echo "-----------------------------------------------------------------------"
    
    singleton_count=$(wc -l < "$SINGLETON_LIST")
    submitted_singletons=0
    
    while IFS= read -r jobfile; do
        ((submitted_singletons++))
        
        # Wait for capacity
        wait_for_capacity $((MAX_TOTAL - 5))
        
        echo "[${submitted_singletons}/${singleton_count}] Submitting: ${jobfile}"
        sbatch "$jobfile"
        
        if [ $? -eq 0 ]; then
            echo "  ✓ Submitted successfully"
        else
            echo "  ✗ Submission failed"
        fi
        
        sleep 2
        
    done < "$SINGLETON_LIST"
    
    echo ""
    echo "Singleton submission complete: ${submitted_singletons} jobs submitted"
else
    echo "Step 2: No singleton jobs to submit"
fi

echo ""
echo "==============================================================================="
echo "All submissions complete"
echo "Finished at: $(date)"
echo ""
echo "Monitor your jobs with:"
echo "  squeue -u \$USER"
echo "  watch -n 10 'squeue -u \$USER'"
echo "==============================================================================="
EOF

chmod +x "${SUBMIT_SCRIPT}"

#===============================================================================
# STEP 5: Summary and next steps
#===============================================================================

echo ""
echo "==============================================================================="
echo "CONVERSION COMPLETE"
echo "==============================================================================="
echo "Created ${array_count} job array scripts in: ${ARRAY_DIR}/"
echo "Singleton jobs listed in: ${singleton_list}"
echo ""
echo "Next steps:"
echo "  1. Review the generated array scripts (optional):"
echo "     ls -lh ${ARRAY_DIR}/*.slurm"
echo ""
echo "  2. Submit all arrays automatically:"
echo "     ${SUBMIT_SCRIPT}"
echo ""
echo "  3. Or submit arrays individually:"
echo "     sbatch ${ARRAY_DIR}/array_1_*.slurm"
echo ""
echo "  4. Monitor job status:"
echo "     squeue -u \$USER"
echo "     watch -n 10 'squeue -u \$USER'"
echo "==============================================================================="
