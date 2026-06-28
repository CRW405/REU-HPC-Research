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
    local account=$(get_sbatch_value "$file" "-A")
    
    # Create signature: nodes_ntasks_time_partition_account
    echo "${nodes}_${ntasks}_${time}_${partition}_${account}"
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
declare -A group_resources  # signature -> nodes:ntasks:time:partition:account (for display)

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
        account=$(get_sbatch_value "$jobfile" "-A")
        group_resources[$sig]="${nodes}:${ntasks}:${time}:${partition}:${account}"
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
    IFS=':' read -r nodes ntasks time partition account <<< "${group_resources[$sig]}"
    
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
if [ "$array_count" -gt 0 ]; then
    echo "After:  ${array_count} array submissions + ${singleton_count} individual jobs"
    echo "        = $((array_count + singleton_count)) total submissions"
    echo ""
    echo "Job reduction:           ${total_jobs} → $((array_count + singleton_count))"
    if [ "$total_jobs" -gt 0 ]; then
        reduction=$(awk "BEGIN {printf \"%.1f\", ${total_jobs} / ($array_count + $singleton_count)}")
        echo "Reduction factor:        ${reduction}x"
    fi
else
    echo "After:  ${singleton_count} individual jobs (no arrays possible)"
fi
echo "======================================================================="

if [ "$DRY_RUN" = true ]; then
    echo ""
    echo "This was a dry run. No files were created."
    echo "To generate array scripts, run without --dry-run flag."
    exit 0
fi

#===============================================================================
# STEP 3: Create job_arrays directory
#===============================================================================

echo ""
echo "Step 3: Creating job_arrays directory..."
echo "-----------------------------------------------------------------------"

mkdir -p "$ARRAY_DIR"
> "$ARRAY_LIST"

SINGLETON_LIST="${ARRAY_DIR}/singleton_jobs.txt"
> "$SINGLETON_LIST"

echo "Created: ${ARRAY_DIR}"

#===============================================================================
# STEP 4: Generate array scripts
#===============================================================================

echo ""
echo "Step 4: Generating array scripts..."
echo "-----------------------------------------------------------------------"

array_num=0

for sig in $sorted_sigs; do
    # Parse resource info
    IFS=':' read -r nodes ntasks time partition account <<< "${group_resources[$sig]}"
    
    # Get jobs in this group
    IFS='|' read -ra jobs <<< "${job_groups[$sig]}"
    num_jobs=${#jobs[@]}
    
    if [ "$num_jobs" -lt 2 ]; then
        # Singleton - just record path for manual submission
        echo "${jobs[0]}" >> "$SINGLETON_LIST"
        continue
    fi
    
    ((array_num++))
    
    # Array name without numeric prefix
    array_name="array_N${nodes}_n${ntasks}"
    array_script="${ARRAY_DIR}/${array_name}.slurm"
    
    echo "Creating ${array_name}.slurm (${num_jobs} jobs)..."
    
    # Write array script header with actual values
    cat > "${array_script}" << EOF
#!/bin/bash
#SBATCH -J ${array_name}
#SBATCH -N ${nodes}
#SBATCH -n ${ntasks}
#SBATCH -t ${time}
#SBATCH -p ${partition}
#SBATCH -A ${account}
#SBATCH --array=0-$((num_jobs - 1))%${MAX_CONCURRENT}

#===============================================================================
# SLURM Job Array: ${array_name}
# Generated: $(date)
# Original jobs: ${num_jobs}
# Resources: N=${nodes}, n=${ntasks}, time=${time}, partition=${partition}
#===============================================================================

echo "======================================================================="
echo "Array Job: ${array_name}"
echo "Array Task ID: \${SLURM_ARRAY_TASK_ID}"
echo "Array Job ID: \${SLURM_ARRAY_JOB_ID}"
echo "======================================================================="

# Map array index to original job directory and script
case \${SLURM_ARRAY_TASK_ID} in
EOF
    
    # Build case statements for each job in the array
    for idx in "${!jobs[@]}"; do
        jobfile="${jobs[$idx]}"
        jobdir=$(dirname "$jobfile")
        
        # Get absolute path
        abs_jobdir=$(cd "$BASE_DIR" && cd "$jobdir" && pwd)
        abs_jobfile="${abs_jobdir}/job.slurm"
        
        metadata="${job_metadata[$jobfile]}"
        IFS=':' read -r test config peak <<< "$metadata"
        
        cat >> "${array_script}" << EOF
  ${idx})
    echo "Task ${idx}: ${test}/${config} (${peak})"
    cd "${abs_jobdir}"
    source "${abs_jobfile}"
    ;;
EOF
    done
    
    # Close the case statement
    cat >> "${array_script}" << 'EOF'
  *)
    echo "ERROR: Unknown array task ID ${SLURM_ARRAY_TASK_ID}"
    exit 1
    ;;
esac

exit_code=$?
echo "======================================================================="
echo "Array task ${SLURM_ARRAY_TASK_ID} completed with exit code ${exit_code}"
echo "======================================================================="
exit ${exit_code}
EOF
    
    chmod +x "${array_script}"
    echo "${array_script}" >> "$ARRAY_LIST"
    
done

echo ""
echo "Created ${array_num} array scripts"

#===============================================================================
# STEP 5: Create master submit script
#===============================================================================

echo ""
echo "Step 5: Creating master submit script..."
echo "-----------------------------------------------------------------------"

cat > "${SUBMIT_SCRIPT}" << 'SUBMIT_SCRIPT_EOF'
#!/bin/bash
#===============================================================================
# Master Array Job Submission Script
#
# Submits all job arrays while respecting TACC job limits:
#   - Max 20 active jobs (running + pending)
#   - Max 80 total jobs
#
# Usage: ./submit_all_arrays.sh
#===============================================================================

# Get directory where this script lives
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ARRAY_LIST="${SCRIPT_DIR}/array_jobs.txt"

if [ ! -f "$ARRAY_LIST" ]; then
    echo "ERROR: Array job list not found: $ARRAY_LIST"
    exit 1
fi

# Count total arrays to submit
total_arrays=$(wc -l < "$ARRAY_LIST")

echo "==============================================================================="
echo "SLURM Job Array Batch Submission"
echo "==============================================================================="
echo "Total arrays to submit: ${total_arrays}"
echo "User: ${USER}"
echo ""
echo "TACC Limits:"
echo "  Max active jobs: 20"
echo "  Max total jobs: 80"
echo ""
echo "Strategy:"
echo "  - Each array has concurrency cap (e.g., %10)"
echo "  - Submit all arrays at once (they self-throttle)"
echo "  - Monitor with: squeue -u \$USER"
echo "==============================================================================="
echo ""

# Check current job count
current_jobs=$(squeue -u $USER -h | wc -l)
echo "Current jobs in queue: ${current_jobs}"

if [ "$current_jobs" -ge 60 ]; then
    echo ""
    echo "WARNING: You already have ${current_jobs} jobs queued/running."
    echo "Adding ${total_arrays} more arrays may exceed the 80-job limit."
    echo ""
    read -p "Continue anyway? [y/N] " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Aborted."
        exit 1
    fi
fi

echo ""
echo "Submitting arrays..."
echo "-----------------------------------------------------------------------"

submitted=0
failed=0

while IFS= read -r array_script; do
    array_name=$(basename "$array_script" .slurm)
    
    echo -n "Submitting ${array_name}... "
    
    if jobid=$(sbatch "$array_script" 2>&1); then
        echo "✓ ${jobid}"
        ((submitted++))
    else
        echo "✗ FAILED"
        echo "   Error: ${jobid}"
        ((failed++))
    fi
    
done < "$ARRAY_LIST"

echo ""
echo "==============================================================================="
echo "Submission Summary"
echo "==============================================================================="
echo "Submitted: ${submitted}"
echo "Failed:    ${failed}"
echo ""
echo "Monitor your jobs with:"
echo "  squeue -u \$USER"
echo "  watch -n 30 'squeue -u \$USER'"
echo "==============================================================================="

if [ -f "${SCRIPT_DIR}/singleton_jobs.txt" ] && [ -s "${SCRIPT_DIR}/singleton_jobs.txt" ]; then
    num_singletons=$(wc -l < "${SCRIPT_DIR}/singleton_jobs.txt")
    echo ""
    echo "NOTE: ${num_singletons} singleton jobs were not grouped into arrays."
    echo "      See: ${SCRIPT_DIR}/singleton_jobs.txt"
    echo "      Submit manually if needed."
fi
SUBMIT_SCRIPT_EOF

chmod +x "${SUBMIT_SCRIPT}"

echo "Created: ${SUBMIT_SCRIPT}"

#===============================================================================
# FINAL SUMMARY
#===============================================================================

echo ""
echo "==============================================================================="
echo "CONVERSION COMPLETE"
echo "==============================================================================="
echo "Output directory: ${ARRAY_DIR}"
echo ""
echo "Generated files:"
echo "  ${array_num} array scripts"
echo "  1 master submit script"
if [ -s "$SINGLETON_LIST" ]; then
    num_singletons=$(wc -l < "$SINGLETON_LIST")
    echo "  1 singleton list (${num_singletons} jobs)"
fi
echo ""
echo "Next steps:"
echo "  1. Review the array scripts in ${ARRAY_DIR}"
echo "  2. Submit all arrays: ${SUBMIT_SCRIPT}"
echo "  3. Monitor: squeue -u \$USER"
echo "==============================================================================="
