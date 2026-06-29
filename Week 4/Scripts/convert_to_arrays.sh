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
LOGS_DIR="${ARRAY_DIR}/logs"
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
    echo "Logs directory: ${LOGS_DIR}"
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
    local account=$(get_sbatch_value "$file" "-A")
    
    # Create signature using § as delimiter (won't appear in SBATCH values)
    echo "${nodes}§${ntasks}§${time}§${partition}§${account}"
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
declare -A group_resources  # signature -> nodes§ntasks§time§partition§account (for display)

total_jobs=0

while IFS= read -r -d '' jobfile; do
    ((total_jobs++))
    
    sig=$(get_resource_signature "$jobfile")
    peak=$(uses_peak "$jobfile")
    test=$(get_test_name "$jobfile")
    config=$(get_config_name "$jobfile")
    
    # Store metadata
    job_metadata["$jobfile"]="${test}:${config}:${peak}"
    
    # Store resource details for display (use same delimiter)
    if [ -z "${group_resources[$sig]}" ]; then
        nodes=$(get_sbatch_value "$jobfile" "-N")
        ntasks=$(get_sbatch_value "$jobfile" "-n")
        time=$(get_sbatch_value "$jobfile" "-t")
        partition=$(get_sbatch_value "$jobfile" "-p")
        account=$(get_sbatch_value "$jobfile" "-A")
        group_resources[$sig]="${nodes}§${ntasks}§${time}§${partition}§${account}"
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
    # Parse resource info using § delimiter
    IFS='§' read -r nodes ntasks time partition account <<< "${group_resources[$sig]}"
    
    # Get jobs in this group
    IFS='|' read -ra jobs <<< "${job_groups[$sig]}"
    num_jobs=${#jobs[@]}
    
    if [ "$num_jobs" -lt 2 ]; then
        ((singleton_count++))
        if [ "$DRY_RUN" = true ]; then
            echo "❌ Singleton (N=${nodes}, n=${ntasks}, t=${time}, p=${partition}, A=${account}): 1 job (no consolidation)"
        fi
    else
        ((array_count++))
        ((total_in_arrays += num_jobs))
        
        array_name="array_N${nodes}_n${ntasks}"
        
        echo "✅ Array ${array_count}: ${array_name}"
        echo "   Resources: N=${nodes}, n=${ntasks}, time=${time}, partition=${partition}, account=${account}"
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
if [ $total_jobs -gt 0 ]; then
    reduction=$(awk "BEGIN {printf \"%.1f\", ${total_jobs} / ($array_count + $singleton_count)}")
    echo "Job reduction:           ${total_jobs} → $((array_count + singleton_count))"
    echo "Reduction factor:        ${reduction}x"
fi
echo "======================================================================="

if [ "$DRY_RUN" = true ]; then
    echo ""
    echo "DRY RUN complete. Run without --dry-run to generate array scripts."
    exit 0
fi

#===============================================================================
# STEP 3: Create output directory
#===============================================================================

echo ""
echo "Step 3: Creating output directories..."
echo "-----------------------------------------------------------------------"

mkdir -p "$ARRAY_DIR"
mkdir -p "$LOGS_DIR"
> "$ARRAY_LIST"

echo "Created: ${ARRAY_DIR}"
echo "Created: ${LOGS_DIR}"
echo ""

#===============================================================================
# STEP 4: Generate array scripts
#===============================================================================

echo "Step 4: Generating array job scripts..."
echo "-----------------------------------------------------------------------"

array_num=0

for sig in $sorted_sigs; do
    # Parse resource info using § delimiter
    IFS='§' read -r nodes ntasks time partition account <<< "${group_resources[$sig]}"
    
    # Get jobs in this group
    IFS='|' read -ra jobs <<< "${job_groups[$sig]}"
    num_jobs=${#jobs[@]}
    
    # Skip singletons
    if [ "$num_jobs" -lt 2 ]; then
        continue
    fi
    
    ((array_num++))
    
    # Create array name (without numeric prefix)
    array_name="array_N${nodes}_n${ntasks}"
    array_file="${ARRAY_DIR}/${array_name}.slurm"
    
    # Determine max task ID (0-indexed)
    max_task_id=$((num_jobs - 1))
    
    echo "Creating ${array_name}.slurm (${num_jobs} jobs, indices 0-${max_task_id})"
    
    # Write array script header
    cat > "$array_file" << EOF
#!/bin/bash
#SBATCH -J ${array_name}
#SBATCH -o ${LOGS_DIR}/${array_name}-%A_%a.out
#SBATCH -e ${LOGS_DIR}/${array_name}-%A_%a.err
#SBATCH -N ${nodes}
#SBATCH -n ${ntasks}
#SBATCH -t ${time}
#SBATCH -p ${partition}
#SBATCH -A ${account}
#SBATCH --array=0-${max_task_id}%${MAX_CONCURRENT}

#===============================================================================
# SLURM Job Array: ${array_name}
# Generated by convert_to_arrays.sh
#
# Array elements: ${num_jobs}
# Max concurrent: ${MAX_CONCURRENT}
# Resources per job: N=${nodes}, n=${ntasks}, t=${time}, p=${partition}, A=${account}
#
# SLURM array variables:
#   SLURM_ARRAY_JOB_ID  = master job ID
#   SLURM_ARRAY_TASK_ID = this task's index (0-${max_task_id})
#   SLURM_JOB_ID        = unique ID for this task
#===============================================================================

echo "======================================================================="
echo "Array Job: ${array_name}"
echo "Array Master ID: \${SLURM_ARRAY_JOB_ID}"
echo "Task ID: \${SLURM_ARRAY_TASK_ID}"
echo "Unique Job ID: \${SLURM_JOB_ID}"
echo "======================================================================="

# Map array task ID to original job directory
case \${SLURM_ARRAY_TASK_ID} in
EOF
    
    # Add case statements for each task
    for idx in "${!jobs[@]}"; do
        jobfile="${jobs[$idx]}"
        jobdir=$(dirname "$jobfile")
        # Get absolute path
        abs_jobdir=$(cd "$jobdir" && pwd)
        
        echo "  ${idx})" >> "$array_file"
        echo "    original_dir=\"${abs_jobdir}\"" >> "$array_file"
        echo "    ;;" >> "$array_file"
    done
    
    # Close case and run original job
    cat >> "$array_file" << 'EOF'
  *)
    echo "ERROR: Invalid SLURM_ARRAY_TASK_ID=${SLURM_ARRAY_TASK_ID}"
    exit 1
    ;;
esac

# Change to original job directory
echo "Changing to: ${original_dir}"
cd "${original_dir}" || exit 1

# Source the original job script (skipping SBATCH directives)
echo "Executing original job script..."
echo "-----------------------------------------------------------------------"

# Extract and run everything after SBATCH directives from job.slurm
sed '/^#SBATCH/d; /^#!/d' job.slurm | bash

exit_code=$?

echo "-----------------------------------------------------------------------"
echo "Task ${SLURM_ARRAY_TASK_ID} completed with exit code ${exit_code}"
echo "======================================================================="

exit ${exit_code}
EOF
    
    chmod +x "$array_file"
    echo "$array_file" >> "$ARRAY_LIST"
done

echo ""
echo "Created ${array_num} array scripts in ${ARRAY_DIR}/"
echo ""

#===============================================================================
# STEP 5: Create master submit script
#===============================================================================

echo "Step 5: Creating master submit script..."
echo "-----------------------------------------------------------------------"

cat > "$SUBMIT_SCRIPT" << 'EOF'
#!/bin/bash
#===============================================================================
# Master submit script for all job arrays
# Generated by convert_to_arrays.sh
#
# This script submits all array jobs while respecting TACC limits:
#   - Max 20 active jobs
#   - Max 80 total jobs
#
# The script waits if you approach the 80-job limit.
#===============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ARRAY_LIST="${SCRIPT_DIR}/array_jobs.txt"

if [ ! -f "$ARRAY_LIST" ]; then
    echo "ERROR: Array job list not found: $ARRAY_LIST"
    exit 1
fi

echo "======================================================================="
echo "Submitting job arrays"
echo "======================================================================="
echo ""

submitted=0
skipped=0

while read -r array_script; do
    if [ ! -f "$array_script" ]; then
        echo "WARNING: Script not found, skipping: $array_script"
        ((skipped++))
        continue
    fi
    
    # Check current job count
    current_jobs=$(squeue -u $USER -h | wc -l)
    
    # Wait if approaching limit (leave margin of 10)
    while [ "$current_jobs" -gt 70 ]; do
        echo "Current job count: ${current_jobs} (waiting for it to drop below 70...)"
        sleep 30
        current_jobs=$(squeue -u $USER -h | wc -l)
    done
    
    # Submit array
    echo "Submitting: $(basename $array_script)"
    sbatch "$array_script"
    
    if [ $? -eq 0 ]; then
        ((submitted++))
    else
        echo "ERROR: Failed to submit $array_script"
        ((skipped++))
    fi
    
    # Small delay between submissions
    sleep 2
    
done < "$ARRAY_LIST"

echo ""
echo "======================================================================="
echo "Submission complete"
echo "======================================================================="
echo "Arrays submitted: ${submitted}"
echo "Skipped/failed:   ${skipped}"
echo ""
echo "Monitor with: squeue -u \$USER"
echo "View logs in:  ${SCRIPT_DIR}/logs/"
echo "======================================================================="
EOF

chmod +x "$SUBMIT_SCRIPT"

echo "Created: ${SUBMIT_SCRIPT}"
echo ""

#===============================================================================
# STEP 6: Handle singleton jobs
#===============================================================================

if [ "$singleton_count" -gt 0 ]; then
    echo "Step 6: Listing singleton jobs (not converted to arrays)..."
    echo "-----------------------------------------------------------------------"
    
    singleton_list="${ARRAY_DIR}/singleton_jobs.txt"
    > "$singleton_list"
    
    for sig in "${!job_groups[@]}"; do
        IFS='|' read -ra jobs <<< "${job_groups[$sig]}"
        if [ "${#jobs[@]}" -eq 1 ]; then
            echo "${jobs[0]}" >> "$singleton_list"
        fi
    done
    
    echo "Found ${singleton_count} singleton jobs"
    echo "List saved to: ${singleton_list}"
    echo ""
    echo "Submit singletons individually with:"
    echo "  while read job; do sbatch \$job; done < ${singleton_list}"
    echo ""
fi

#===============================================================================
# Final summary
#===============================================================================

echo "======================================================================="
echo "CONVERSION COMPLETE"
echo "======================================================================="
echo "Array scripts:       ${array_num}"
echo "Singleton jobs:      ${singleton_count}"
echo "Output directory:    ${ARRAY_DIR}/"
echo "Logs directory:      ${LOGS_DIR}/"
echo ""
echo "Next steps:"
echo "  1. Review generated scripts in ${ARRAY_DIR}/"
echo "  2. Submit all arrays: ${SUBMIT_SCRIPT}"
echo "  3. Monitor: squeue -u \$USER"
echo "  4. Check logs: ls ${LOGS_DIR}/"
echo "======================================================================="
