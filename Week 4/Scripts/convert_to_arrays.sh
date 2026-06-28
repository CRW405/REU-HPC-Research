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
echo "After:  ${array_count} array submissions + ${singleton_count} individual jobs"
echo "        = $((array_count + singleton_count)) total submissions"
echo ""
if [ "$total_jobs" -gt 0 ]; then
    reduction=$(awk "BEGIN {printf \"%.1f\", ${total_jobs} / ($array_count + $singleton_count)}")
    echo "Job reduction:           ${total_jobs} → $((array_count + singleton_count))"
    echo "Reduction factor:        ${reduction}x"
fi
echo "======================================================================="
echo ""

# If dry run, stop here
if [ "$DRY_RUN" = true ]; then
    echo "Dry run complete. No files created."
    echo "Run without --dry-run to generate array scripts."
    exit 0
fi

#===============================================================================
# STEP 3: Generate array scripts
#===============================================================================

echo "Step 3: Generating array scripts..."
echo "-----------------------------------------------------------------------"

# Create output directory
mkdir -p "$ARRAY_DIR"

# Clear or create list files
> "$ARRAY_LIST"
SINGLETON_LIST="${ARRAY_DIR}/singleton_jobs.txt"
> "$SINGLETON_LIST"

array_idx=0

for sig in $sorted_sigs; do
    # Parse resource info
    IFS=':' read -r nodes ntasks time partition account <<< "${group_resources[$sig]}"
    
    # Get jobs in this group
    IFS='|' read -ra jobs <<< "${job_groups[$sig]}"
    num_jobs=${#jobs[@]}
    
    if [ "$num_jobs" -lt 2 ]; then
        # Singleton - just add to list for manual submission
        echo "${jobs[0]}" >> "$SINGLETON_LIST"
        continue
    fi
    
    ((array_idx++))
    
    # Create array script name
    array_name="array_N${nodes}_n${ntasks}"
    array_file="${ARRAY_DIR}/${array_name}.slurm"
    
    echo "Creating ${array_name}.slurm (${num_jobs} jobs)..."
    
    # Write array script header
    cat > "$array_file" <<EOF
#!/bin/bash
#SBATCH -J ${array_name}
#SBATCH -N ${nodes}
#SBATCH -n ${ntasks}
#SBATCH -t ${time}
#SBATCH -p ${partition}
#SBATCH -A ${account}
#SBATCH -o ${array_name}_%A_%a.out
#SBATCH -e ${array_name}_%A_%a.err
#SBATCH --array=0-$((num_jobs - 1))%${MAX_CONCURRENT}

#===============================================================================
# Auto-generated job array consolidating ${num_jobs} jobs
# Generated: $(date)
#===============================================================================

# Map array task ID to original job directory and script
case \${SLURM_ARRAY_TASK_ID} in
EOF
    
    # Add case entries for each job
    for idx in "${!jobs[@]}"; do
        jobfile="${jobs[$idx]}"
        jobdir=$(dirname "$jobfile")
        
        # Get the original job's working directory (relative to BASE_DIR)
        rel_jobdir=$(realpath --relative-to="$BASE_DIR" "$jobdir")
        
        cat >> "$array_file" <<EOF
  ${idx})
    echo "Running: ${rel_jobdir}"
    cd "${BASE_DIR}/${rel_jobdir}"
    # Source the original job commands
    source "./job.slurm"
    ;;
EOF
    done
    
    # Close the case statement
    cat >> "$array_file" <<EOF
  *)
    echo "ERROR: Invalid SLURM_ARRAY_TASK_ID=\${SLURM_ARRAY_TASK_ID}"
    exit 1
    ;;
esac
EOF
    
    # Add to master list
    echo "$array_file" >> "$ARRAY_LIST"
    
done

echo ""
echo "Generated ${array_idx} array scripts in ${ARRAY_DIR}/"
if [ "$singleton_count" -gt 0 ]; then
    echo "Note: ${singleton_count} singleton jobs listed in ${SINGLETON_LIST}"
fi
echo ""

#===============================================================================
# STEP 4: Generate master submit script
#===============================================================================

echo "Step 4: Generating master submit script..."
echo "-----------------------------------------------------------------------"

cat > "$SUBMIT_SCRIPT" <<'SUBMIT_EOF'
#!/bin/bash
#===============================================================================
# Master Array Submit Script
# Submits all consolidated job arrays with automatic throttling
#===============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ARRAY_LIST="${SCRIPT_DIR}/array_jobs.txt"
SINGLETON_LIST="${SCRIPT_DIR}/singleton_jobs.txt"

MAX_TOTAL_JOBS=80
WAIT_TIME=60  # seconds between checks

echo "==============================================================================="
echo "Submitting ABINIT Job Arrays"
echo "==============================================================================="
echo ""

#===============================================================================
# Function: Get current job count
#===============================================================================
get_job_count() {
    squeue -u $USER -h | wc -l
}

#===============================================================================
# Function: Wait for job slots
#===============================================================================
wait_for_slots() {
    local needed=$1
    while true; do
        current=$(get_job_count)
        available=$((MAX_TOTAL_JOBS - current))
        
        if [ "$available" -ge "$needed" ]; then
            break
        fi
        
        echo "Currently ${current}/${MAX_TOTAL_JOBS} jobs. Waiting for ${needed} slots..."
        echo "Will check again in ${WAIT_TIME} seconds."
        sleep $WAIT_TIME
    done
}

#===============================================================================
# Submit array jobs
#===============================================================================

if [ -f "$ARRAY_LIST" ]; then
    echo "Submitting array jobs from: $ARRAY_LIST"
    echo "-----------------------------------------------------------------------"
    
    while read -r array_script; do
        if [ ! -f "$array_script" ]; then
            echo "WARNING: File not found: $array_script"
            continue
        fi
        
        # Each array script counts as 1 submission (Slurm manages the elements)
        wait_for_slots 1
        
        echo "Submitting: $(basename "$array_script")"
        sbatch "$array_script"
        
        if [ $? -eq 0 ]; then
            echo "  ✓ Submitted successfully"
        else
            echo "  ✗ Submission failed"
        fi
        echo ""
        
        # Small delay to avoid overwhelming Slurm
        sleep 2
        
    done < "$ARRAY_LIST"
else
    echo "No array jobs to submit (${ARRAY_LIST} not found)"
fi

#===============================================================================
# Report on singleton jobs
#===============================================================================

if [ -f "$SINGLETON_LIST" ] && [ -s "$SINGLETON_LIST" ]; then
    num_singletons=$(wc -l < "$SINGLETON_LIST")
    echo ""
    echo "==============================================================================="
    echo "Note: ${num_singletons} singleton jobs were not grouped into arrays."
    echo "These must be submitted individually if desired:"
    echo "  ${SINGLETON_LIST}"
    echo "==============================================================================="
fi

echo ""
echo "==============================================================================="
echo "Submission complete!"
echo "==============================================================================="
echo ""
echo "Monitor your jobs with:"
echo "  squeue -u \$USER"
echo "  watch -n 30 'squeue -u \$USER'"
echo ""
SUBMIT_EOF

chmod +x "$SUBMIT_SCRIPT"

echo "Created: ${SUBMIT_SCRIPT}"
echo ""

#===============================================================================
# FINAL SUMMARY
#===============================================================================

echo "======================================================================="
echo "CONVERSION COMPLETE"
echo "======================================================================="
echo ""
echo "Output directory: ${ARRAY_DIR}/"
echo "  - ${array_idx} array scripts created"
if [ "$singleton_count" -gt 0 ]; then
    echo "  - ${singleton_count} singleton jobs listed"
fi
echo "  - Master submit script: submit_all_arrays.sh"
echo ""
echo "To submit all arrays:"
echo "  cd ${ARRAY_DIR}"
echo "  ./submit_all_arrays.sh"
echo ""
echo "Or submit individual arrays:"
echo "  sbatch ${ARRAY_DIR}/array_N1_n56.slurm"
echo ""
echo "======================================================================="
