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
if [ "$array_count" -gt 0 ]; then
    reduction=$(awk "BEGIN {printf \"%.1f\", ${total_jobs} / (${array_count} + ${singleton_count})}")
    echo "Job reduction:           ${total_jobs} → $((array_count + singleton_count))"
    echo "Reduction factor:        ${reduction}x"
fi
echo "======================================================================="

if [ "$DRY_RUN" = true ]; then
    echo ""
    echo "This was a dry run. To generate the array scripts, run:"
    echo "  ./convert_to_arrays.sh ${BASE_DIR} ${MAX_CONCURRENT}"
    exit 0
fi

#===============================================================================
# STEP 3: Generate array scripts
#===============================================================================

echo ""
echo "Step 3: Generating array scripts..."
echo "-----------------------------------------------------------------------"

# Create output directory
mkdir -p "$ARRAY_DIR"

# Initialize list files
> "$ARRAY_LIST"
singleton_list="${ARRAY_DIR}/singleton_jobs.txt"
> "$singleton_list"

array_num=0

for sig in $sorted_sigs; do
    # Parse resource info
    IFS='§' read -r nodes ntasks time partition account <<< "${group_resources[$sig]}"
    
    # Get jobs in this group
    IFS='|' read -ra jobs <<< "${job_groups[$sig]}"
    num_jobs=${#jobs[@]}
    
    if [ "$num_jobs" -lt 2 ]; then
        # Singleton - just record it
        echo "${jobs[0]}" >> "$singleton_list"
        continue
    fi
    
    ((array_num++))
    
    # Create array script name
    array_name="array_N${nodes}_n${ntasks}"
    array_script="${ARRAY_DIR}/${array_name}.slurm"
    
    echo "Creating: ${array_name}.slurm (${num_jobs} jobs)"
    
    # Write array script header directly with actual values
    cat > "$array_script" << 'HEADER_END'
#!/bin/bash
HEADER_END
    
    # Write SBATCH directives with actual values (not variables)
    cat >> "$array_script" << SBATCH_END
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
# Resources: N=${nodes}, n=${ntasks}, time=${time}, partition=${partition}, account=${account}
# Jobs consolidated: ${num_jobs}
#===============================================================================

# Map array task ID to original job directory and script
case \${SLURM_ARRAY_TASK_ID} in
SBATCH_END
    
    # Add case entries for each job
    for idx in "${!jobs[@]}"; do
        jobfile="${jobs[$idx]}"
        jobdir=$(dirname "$jobfile")
        metadata="${job_metadata[$jobfile]}"
        IFS=':' read -r test config peak <<< "$metadata"
        
        cat >> "$array_script" << CASE_END
  ${idx})
    # ${test}/${config} (${peak})
    JOB_DIR="${jobdir}"
    JOB_SCRIPT="${jobfile}"
    ;;
CASE_END
    done
    
    # Close case and add execution logic
    cat >> "$array_script" << 'FOOTER_END'
  *)
    echo "ERROR: Invalid SLURM_ARRAY_TASK_ID=${SLURM_ARRAY_TASK_ID}"
    exit 1
    ;;
esac

echo "======================================================================="
echo "Array task ${SLURM_ARRAY_TASK_ID} starting"
echo "Job directory: ${JOB_DIR}"
echo "Job script: ${JOB_SCRIPT}"
echo "======================================================================="

# Change to job directory and source the original script
cd "${JOB_DIR}" || exit 1

# Execute the original job script content (skip SBATCH headers)
bash -c "$(grep -v '^#SBATCH' "${JOB_SCRIPT}")"

exit_code=$?

echo "======================================================================="
echo "Array task ${SLURM_ARRAY_TASK_ID} completed with exit code ${exit_code}"
echo "======================================================================="

exit ${exit_code}
FOOTER_END
    
    chmod +x "$array_script"
    echo "$array_script" >> "$ARRAY_LIST"
done

echo ""
echo "Generated ${array_num} array scripts"

#===============================================================================
# STEP 4: Generate master submit script
#===============================================================================

echo ""
echo "Step 4: Generating master submit script..."
echo "-----------------------------------------------------------------------"

cat > "$SUBMIT_SCRIPT" << 'SUBMIT_END'
#!/bin/bash
#===============================================================================
# Master submit script for all job arrays
# Generated by convert_to_arrays.sh
#
# This script submits all arrays while respecting TACC job limits:
#   - Max 20 active jobs
#   - Max 80 total jobs
#
# Usage:
#   ./submit_all_arrays.sh
#===============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ARRAY_LIST="${SCRIPT_DIR}/array_jobs.txt"

if [ ! -f "$ARRAY_LIST" ]; then
    echo "ERROR: Array list not found: $ARRAY_LIST"
    exit 1
fi

echo "======================================================================="
echo "Submitting all job arrays"
echo "======================================================================="
echo ""

submitted=0
failed=0

while IFS= read -r array_script; do
    if [ ! -f "$array_script" ]; then
        echo "WARNING: Script not found: $array_script"
        ((failed++))
        continue
    fi
    
    script_name=$(basename "$array_script")
    echo "Submitting: $script_name"
    
    # Check current job count before submitting
    current_jobs=$(squeue -u $USER -h | wc -l)
    
    # Wait if approaching the 80-job limit (leave buffer of 10)
    while [ "$current_jobs" -ge 70 ]; do
        echo "  Waiting... (current jobs: ${current_jobs}, limit: 80)"
        sleep 30
        current_jobs=$(squeue -u $USER -h | wc -l)
    done
    
    # Submit the array
    if output=$(sbatch "$array_script" 2>&1); then
        job_id=$(echo "$output" | grep -oP '\d+')
        echo "  ✓ Submitted: Job ID ${job_id}"
        ((submitted++))
    else
        echo "  ✗ Failed: $output"
        ((failed++))
    fi
    
    # Small delay to avoid overwhelming scheduler
    sleep 1
    
done < "$ARRAY_LIST"

echo ""
echo "======================================================================="
echo "Submission complete"
echo "======================================================================="
echo "Arrays submitted:  ${submitted}"
echo "Failed:            ${failed}"
echo ""
echo "Monitor your jobs with:"
echo "  squeue -u \$USER"
echo "  watch -n 30 'squeue -u \$USER'"
echo "======================================================================="
SUBMIT_END

chmod +x "$SUBMIT_SCRIPT"

echo "Created: $(basename "$SUBMIT_SCRIPT")"

#===============================================================================
# STEP 5: Summary
#===============================================================================

echo ""
echo "======================================================================="
echo "CONVERSION COMPLETE"
echo "======================================================================="
echo "Output directory: ${ARRAY_DIR}"
echo ""
echo "Files created:"
echo "  - ${array_num} array scripts (*.slurm)"
echo "  - ${ARRAY_LIST}"
if [ "$singleton_count" -gt 0 ]; then
    echo "  - ${singleton_list} (${singleton_count} jobs that couldn't be grouped)"
fi
echo "  - ${SUBMIT_SCRIPT}"
echo ""
echo "Next steps:"
echo "  1. Review the generated scripts in ${ARRAY_DIR}/"
echo "  2. Submit all arrays:"
echo "       cd ${ARRAY_DIR}"
echo "       ./$(basename "$SUBMIT_SCRIPT")"
echo ""
if [ "$singleton_count" -gt 0 ]; then
    echo "  3. Submit singleton jobs manually (listed in singleton_jobs.txt)"
    echo ""
fi
echo "Monitor your jobs:"
echo "  squeue -u \$USER"
echo "  watch -n 30 'squeue -u \$USER'"
echo "======================================================================="
