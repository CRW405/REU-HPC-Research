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
#   Creates job_arrays/ directory with:
#     - Consolidated array scripts
#     - submit_all_parallel.sh (submit all arrays at once)
#     - submit_all_dependency.sh (chain arrays with SLURM dependencies)
#     - submit_all_safe.sh (submit one at a time, wait for completion)
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
SUBMIT_PARALLEL="${ARRAY_DIR}/submit_all_parallel.sh"
SUBMIT_DEPENDENCY="${ARRAY_DIR}/submit_all_dependency.sh"
SUBMIT_SAFE="${ARRAY_DIR}/submit_all_safe.sh"
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

echo "======================================================================"
echo "CONSOLIDATION SUMMARY"
echo "======================================================================"
echo "Total jobs found:        ${total_jobs}"
echo "Jobs in arrays:          ${total_in_arrays}"
echo "Singleton jobs:          ${singleton_count}"
echo "Number of arrays:        ${array_count}"
echo ""
echo "Before: ${total_jobs} individual job submissions"
echo "After:  ${array_count} array submissions + ${singleton_count} individual jobs"
echo "        = $((array_count + singleton_count)) total submissions"
echo ""

if [ "$total_in_arrays" -gt 0 ]; then
    reduction_factor=$(echo "scale=1; $total_jobs / ($array_count + $singleton_count)" | bc)
    echo "Job reduction:           ${total_jobs} → $((array_count + singleton_count))"
    echo "Reduction factor:        ${reduction_factor}x"
fi
echo "======================================================================"
echo ""

#===============================================================================
# Exit here if dry-run
#===============================================================================

if [ "$DRY_RUN" = true ]; then
    echo "Dry-run complete. No files were created."
    echo "Run without --dry-run to generate array scripts."
    exit 0
fi

#===============================================================================
# STEP 3: Create output directories and generate array scripts
#===============================================================================

echo "Step 3: Creating array scripts..."
echo "-----------------------------------------------------------------------"

# Create directories
mkdir -p "$ARRAY_DIR"
mkdir -p "$LOGS_DIR"

# Clear old array list
> "$ARRAY_LIST"

array_num=0

for sig in $sorted_sigs; do
    # Parse resource info
    IFS='§' read -r nodes ntasks time partition account <<< "${group_resources[$sig]}"
    
    # Get jobs in this group
    IFS='|' read -ra jobs <<< "${job_groups[$sig]}"
    num_jobs=${#jobs[@]}
    
    # Skip singletons
    if [ "$num_jobs" -lt 2 ]; then
        continue
    fi
    
    ((array_num++))
    
    # Array script name (without numeric prefix)
    array_name="array_N${nodes}_n${ntasks}"
    array_script="${ARRAY_DIR}/${array_name}.slurm"
    
    echo "Creating ${array_name}.slurm (${num_jobs} jobs)..."
    
    # Calculate array range
    max_idx=$((num_jobs - 1))
    
    # Write array script
    cat > "$array_script" << 'EOF_HEADER'
#!/bin/bash
EOF_HEADER

    # Write SBATCH directives with actual values (not variables)
    cat >> "$array_script" << EOF_SBATCH
#SBATCH -J ${array_name}
#SBATCH -N ${nodes}
#SBATCH -n ${ntasks}
#SBATCH -t ${time}
#SBATCH -p ${partition}
#SBATCH -A ${account}
#SBATCH --array=0-${max_idx}%${MAX_CONCURRENT}
#SBATCH -o ${LOGS_DIR}/${array_name}-%A_%a.out
#SBATCH -e ${LOGS_DIR}/${array_name}-%A_%a.err

#===============================================================================
# Job Array: ${array_name}
# Generated: $(date)
# Array size: ${num_jobs} jobs (indices 0-${max_idx})
# Resources: N=${nodes}, n=${ntasks}, time=${time}, partition=${partition}, account=${account}
# Max concurrent: ${MAX_CONCURRENT}
#===============================================================================

echo "======================================================================="
echo "Array Job Start: ${array_name}"
echo "======================================================================="
echo "Array Job ID: \${SLURM_ARRAY_JOB_ID}"
echo "Array Task ID: \${SLURM_ARRAY_TASK_ID}"
echo "Job ID: \${SLURM_JOB_ID}"
echo "Hostname: \$(hostname)"
echo "Start time: \$(date)"
echo "======================================================================="

# Map array task ID to original job directory
case \${SLURM_ARRAY_TASK_ID} in
EOF_SBATCH

    # Add case entries for each job
    for idx in "${!jobs[@]}"; do
        jobfile="${jobs[$idx]}"
        original_dir=$(dirname "$jobfile")
        abs_dir=$(cd "$original_dir" && pwd)
        
        metadata="${job_metadata[$jobfile]}"
        IFS=':' read -r test config peak <<< "$metadata"
        
        cat >> "$array_script" << EOF_CASE
  ${idx})
    echo "Task ${idx}: ${test}/${config} (${peak})"
    original_dir="${abs_dir}"
    ;;
EOF_CASE
    done

    # Close case statement and add execution logic
    cat >> "$array_script" << 'EOF_FOOTER'
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

# Run the original job.slurm, stripping shebang and SBATCH directives
bash <(grep -v '^#SBATCH\|^#!/' "${original_dir}/job.slurm")

exit_code=$?

echo "======================================================================="
echo "Array task ${SLURM_ARRAY_TASK_ID} completed with exit code: ${exit_code}"
echo "End time: $(date)"
echo "======================================================================="

exit ${exit_code}
EOF_FOOTER

    chmod +x "$array_script"
    echo "${array_name}.slurm" >> "$ARRAY_LIST"
done

echo ""
echo "Created ${array_num} array scripts in ${ARRAY_DIR}/"
echo ""

#===============================================================================
# STEP 4: Create three different submission scripts
#===============================================================================

echo "Step 4: Creating submission scripts..."
echo "-----------------------------------------------------------------------"

#-------------------------------------------------------------------------------
# 1. PARALLEL: Submit all arrays at once
#-------------------------------------------------------------------------------

cat > "$SUBMIT_PARALLEL" << 'EOF_PARALLEL'
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
EOF_PARALLEL

chmod +x "$SUBMIT_PARALLEL"

#-------------------------------------------------------------------------------
# 2. DEPENDENCY: Chain arrays with SLURM dependencies
#-------------------------------------------------------------------------------

cat > "$SUBMIT_DEPENDENCY" << 'EOF_DEPENDENCY'
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
EOF_DEPENDENCY

chmod +x "$SUBMIT_DEPENDENCY"

#-------------------------------------------------------------------------------
# 3. SAFE: Wait for each array to complete before submitting next
#-------------------------------------------------------------------------------

cat > "$SUBMIT_SAFE" << 'EOF_SAFE'
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
EOF_SAFE

chmod +x "$SUBMIT_SAFE"

echo ""
echo "Created three submission scripts:"
echo "  1. ${SUBMIT_PARALLEL}  (parallel - all at once)"
echo "  2. ${SUBMIT_DEPENDENCY} (sequential via dependencies)"
echo "  3. ${SUBMIT_SAFE}       (safe - wait for each)"
echo ""

#===============================================================================
# STEP 5: Handle singleton jobs
#===============================================================================

if [ "$singleton_count" -gt 0 ]; then
    echo "Step 5: Recording singleton jobs..."
    echo "-----------------------------------------------------------------------"
    
    singleton_file="${ARRAY_DIR}/singleton_jobs.txt"
    > "$singleton_file"
    
    for sig in "${!job_groups[@]}"; do
        IFS='|' read -ra jobs <<< "${job_groups[$sig]}"
        if [ "${#jobs[@]}" -lt 2 ]; then
            for jobfile in "${jobs[@]}"; do
                echo "$jobfile" >> "$singleton_file"
            done
        fi
    done
    
    echo "Found ${singleton_count} singleton jobs (cannot be grouped into arrays)"
    echo "List saved to: ${singleton_file}"
    echo "These must be submitted individually or modified to match other jobs."
    echo ""
fi

#===============================================================================
# Done
#===============================================================================

echo "======================================================================="
echo "Conversion complete!"
echo "======================================================================="
echo "Output directory: ${ARRAY_DIR}/"
echo "Array scripts: ${array_num}"
echo "Logs directory: ${LOGS_DIR}/"
echo ""
echo "CHOOSE YOUR SUBMISSION STRATEGY:"
echo ""
echo "1. PARALLEL (fastest, but many jobs in queue):"
echo "   cd ${ARRAY_DIR}"
echo "   ./submit_all_parallel.sh"
echo ""
echo "2. DEPENDENCY CHAIN (all submitted at once, run sequentially):"
echo "   cd ${ARRAY_DIR}"
echo "   ./submit_all_dependency.sh"
echo ""
echo "3. SAFE MODE (submit one, wait for completion, submit next):"
echo "   cd ${ARRAY_DIR}"
echo "   ./submit_all_safe.sh"
echo ""
echo "For TACC's 20 active / 80 total job limits, SAFE MODE is recommended."
echo "======================================================================="
