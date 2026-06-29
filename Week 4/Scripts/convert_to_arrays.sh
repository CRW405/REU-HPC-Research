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
#   -s, --sequential  Generate submit script that runs arrays one after another
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
SEQUENTIAL=false
while [[ $# -gt 0 ]]; do
    case $1 in
        -d|--dry-run)
            DRY_RUN=true
            shift
            ;;
        -s|--sequential)
            SEQUENTIAL=true
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
if [ "$SEQUENTIAL" = true ]; then
    echo "SUBMISSION MODE: Sequential (one array at a time)"
else
    echo "SUBMISSION MODE: Parallel (up to $MAX_CONCURRENT jobs per array)"
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
if [ "$singleton_count" -gt 0 ]; then
    echo "After:  ${array_count} array submissions + ${singleton_count} individual jobs"
    echo "        = $((array_count + singleton_count)) total submissions"
else
    echo "After:  ${array_count} array submissions"
fi
echo ""

if [ "$total_jobs" -gt 0 ] && [ "$array_count" -gt 0 ]; then
    reduction=$((total_jobs * 100 / (array_count + singleton_count)))
    reduction_factor=$(echo "scale=1; $total_jobs / ($array_count + $singleton_count)" | bc)
    echo "Job reduction:           ${total_jobs} → $((array_count + singleton_count))"
    echo "Reduction factor:        ${reduction_factor}x"
fi
echo "======================================================================="

if [ "$DRY_RUN" = true ]; then
    echo ""
    echo "✨ This was a dry run. No files were created."
    echo "   To generate array scripts, run without --dry-run:"
    echo "   ./convert_to_arrays.sh ${BASE_DIR} ${MAX_CONCURRENT}"
    exit 0
fi

#===============================================================================
# STEP 3: Generate array scripts
#===============================================================================

echo ""
echo "Step 3: Generating job array scripts..."
echo "-----------------------------------------------------------------------"

# Create output directories
mkdir -p "${ARRAY_DIR}"
mkdir -p "${LOGS_DIR}"

# Clear array list
> "${ARRAY_LIST}"

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
    
    array_name="array_N${nodes}_n${ntasks}"
    array_script="${ARRAY_DIR}/${array_name}.slurm"
    
    echo "Creating ${array_name}.slurm (${num_jobs} jobs)..."
    
    # Calculate array range (0-indexed)
    max_index=$((num_jobs - 1))
    
    # Write array script header
    cat > "${array_script}" << HEADER_EOF
#!/bin/bash
#SBATCH -J ${array_name}
#SBATCH -N ${nodes}
#SBATCH -n ${ntasks}
#SBATCH -t ${time}
#SBATCH -p ${partition}
#SBATCH -A ${account}
#SBATCH --array=0-${max_index}%${MAX_CONCURRENT}
#SBATCH -o ${LOGS_DIR}/${array_name}-%A_%a.out
#SBATCH -e ${LOGS_DIR}/${array_name}-%A_%a.err

#===============================================================================
# Job Array: ${array_name}
# Generated: $(date)
# Array size: ${num_jobs} jobs (indices 0-${max_index})
# Max concurrent: ${MAX_CONCURRENT}
#===============================================================================

echo "================================================================="
echo "Job Array: ${array_name}"
echo "Array Job ID: \${SLURM_ARRAY_JOB_ID}"
echo "Array Task ID: \${SLURM_ARRAY_TASK_ID}"
echo "Hostname: \$(hostname)"
echo "Start Time: \$(date)"
echo "================================================================="

# Map array task ID to original job directory
case \${SLURM_ARRAY_TASK_ID} in
HEADER_EOF

    # Add case statement entries for each job
    for idx in "${!jobs[@]}"; do
        jobfile="${jobs[$idx]}"
        jobdir=$(dirname "$jobfile")
        metadata="${job_metadata[$jobfile]}"
        IFS=':' read -r test config peak <<< "$metadata"
        
        cat >> "${array_script}" << CASE_EOF
  ${idx})
    echo "Task ${idx}: ${test}/${config} (${peak})"
    original_dir="${jobdir}"
    ;;
CASE_EOF
    done

    # Close case statement and add execution logic
    cat >> "${array_script}" << FOOTER_EOF
  *)
    echo "ERROR: Unknown array task ID \${SLURM_ARRAY_TASK_ID}"
    exit 1
    ;;
esac

# Change to original job directory
cd "\${original_dir}" || exit 1
echo "Working directory: \${original_dir}"
echo ""

# Extract and execute the commands from the original job script
# (Skip SBATCH directives, execute everything else)
echo "Executing original job commands..."
echo "================================================================="

# Source the original job.slurm, skipping SBATCH lines
grep -v "^#SBATCH" "\${original_dir}/job.slurm" | bash

exit_code=\$?

echo "================================================================="
echo "Task completed with exit code: \${exit_code}"
echo "End Time: \$(date)"
echo "================================================================="

exit \${exit_code}
FOOTER_EOF

    chmod +x "${array_script}"
    echo "${array_name}.slurm" >> "${ARRAY_LIST}"
done

#===============================================================================
# STEP 4: Generate master submission script
#===============================================================================

echo ""
echo "Step 4: Generating master submission script..."
echo "-----------------------------------------------------------------------"

if [ "$SEQUENTIAL" = true ]; then
    # Generate sequential submission script with dependencies
    cat > "${SUBMIT_SCRIPT}" << 'SUBMIT_EOF'
#!/bin/bash
#===============================================================================
# Master Array Submission Script (Sequential Mode)
#
# This script submits all job arrays ONE AT A TIME using SLURM dependencies.
# Each array will start only after the previous one completes.
#
# Usage:
#   ./submit_all_arrays.sh
#===============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ARRAY_LIST="${SCRIPT_DIR}/array_jobs.txt"

if [ ! -f "${ARRAY_LIST}" ]; then
    echo "ERROR: Array list not found: ${ARRAY_LIST}"
    exit 1
fi

echo "======================================================================="
echo "Submitting Job Arrays (Sequential Mode)"
echo "======================================================================="
echo "Submit time: $(date)"
echo ""

# Read array scripts into an array
mapfile -t array_scripts < "${ARRAY_LIST}"
num_arrays=${#array_scripts[@]}

if [ "$num_arrays" -eq 0 ]; then
    echo "ERROR: No array scripts found in ${ARRAY_LIST}"
    exit 1
fi

echo "Found ${num_arrays} job arrays to submit"
echo ""

previous_jobid=""
submitted_count=0

for script in "${array_scripts[@]}"; do
    script_path="${SCRIPT_DIR}/${script}"
    
    if [ ! -f "${script_path}" ]; then
        echo "WARNING: Script not found: ${script_path}"
        continue
    fi
    
    ((submitted_count++))
    
    # Submit with dependency on previous job (if any)
    if [ -z "$previous_jobid" ]; then
        echo "[$submitted_count/${num_arrays}] Submitting ${script} (first in chain)..."
        output=$(sbatch "${script_path}" 2>&1)
    else
        echo "[$submitted_count/${num_arrays}] Submitting ${script} (depends on job ${previous_jobid})..."
        output=$(sbatch --dependency=afterany:${previous_jobid} "${script_path}" 2>&1)
    fi
    
    if [ $? -eq 0 ]; then
        # Extract job ID from sbatch output
        jobid=$(echo "$output" | grep -oP 'Submitted batch job \K\d+' || echo "$output" | grep -oP '\d+')
        echo "    ✓ Submitted as job ${jobid}"
        previous_jobid=$jobid
    else
        echo "    ✗ Submission failed:"
        echo "$output" | sed 's/^/      /'
        echo ""
        echo "ERROR: Submission failed. Stopping chain."
        exit 1
    fi
    
    echo ""
done

echo "======================================================================="
echo "Submission Complete"
echo "======================================================================="
echo "Total arrays submitted: ${submitted_count}"
echo ""
echo "Jobs will run sequentially. Monitor with:"
echo "  squeue -u \$USER"
echo "  watch -n 30 'squeue -u \$USER'"
echo ""
echo "View logs in: ${SCRIPT_DIR}/logs/"
echo "======================================================================="
SUBMIT_EOF

else
    # Generate parallel submission script (original behavior)
    cat > "${SUBMIT_SCRIPT}" << 'SUBMIT_EOF'
#!/bin/bash
#===============================================================================
# Master Array Submission Script (Parallel Mode)
#
# This script submits all job arrays with automatic throttling to respect
# TACC job limits (20 active, 80 total).
#
# Usage:
#   ./submit_all_arrays.sh
#===============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ARRAY_LIST="${SCRIPT_DIR}/array_jobs.txt"

MAX_TOTAL_JOBS=80
MAX_ACTIVE_JOBS=20

if [ ! -f "${ARRAY_LIST}" ]; then
    echo "ERROR: Array list not found: ${ARRAY_LIST}"
    exit 1
fi

echo "======================================================================="
echo "Submitting Job Arrays (Parallel Mode)"
echo "======================================================================="
echo "Submit time: $(date)"
echo "TACC Limits: ${MAX_ACTIVE_JOBS} active / ${MAX_TOTAL_JOBS} total"
echo ""

# Function to count current jobs
count_jobs() {
    squeue -u $USER -h | wc -l
}

submitted_count=0
skipped_count=0

while IFS= read -r script; do
    script_path="${SCRIPT_DIR}/${script}"
    
    if [ ! -f "${script_path}" ]; then
        echo "WARNING: Script not found: ${script_path}"
        ((skipped_count++))
        continue
    fi
    
    # Check current job count
    current_jobs=$(count_jobs)
    
    # Wait if we're at the limit
    while [ "$current_jobs" -ge "$MAX_TOTAL_JOBS" ]; do
        echo "At job limit (${current_jobs}/${MAX_TOTAL_JOBS}). Waiting 60s..."
        sleep 60
        current_jobs=$(count_jobs)
    done
    
    echo "Submitting ${script} (current jobs: ${current_jobs}/${MAX_TOTAL_JOBS})..."
    sbatch "${script_path}"
    
    if [ $? -eq 0 ]; then
        ((submitted_count++))
    else
        echo "  WARNING: Submission failed for ${script}"
        ((skipped_count++))
    fi
    
    # Brief pause between submissions
    sleep 2
    
done < "${ARRAY_LIST}"

echo ""
echo "======================================================================="
echo "Submission Complete"
echo "======================================================================="
echo "Arrays submitted: ${submitted_count}"
if [ "$skipped_count" -gt 0 ]; then
    echo "Skipped/failed:   ${skipped_count}"
fi
echo ""
echo "Monitor jobs with:"
echo "  squeue -u \$USER"
echo "  watch -n 30 'squeue -u \$USER'"
echo ""
echo "View logs in: ${SCRIPT_DIR}/logs/"
echo "======================================================================="
SUBMIT_EOF

fi

chmod +x "${SUBMIT_SCRIPT}"

#===============================================================================
# STEP 5: Handle singleton jobs
#===============================================================================

if [ "$singleton_count" -gt 0 ]; then
    echo ""
    echo "Step 5: Documenting singleton jobs..."
    echo "-----------------------------------------------------------------------"
    
    singleton_list="${ARRAY_DIR}/singleton_jobs.txt"
    > "${singleton_list}"
    
    for sig in "${!job_groups[@]}"; do
        IFS='|' read -ra jobs <<< "${job_groups[$sig]}"
        if [ "${#jobs[@]}" -eq 1 ]; then
            echo "${jobs[0]}" >> "${singleton_list}"
        fi
    done
    
    echo "Singleton jobs listed in: ${singleton_list}"
    echo "These must be submitted individually."
fi

#===============================================================================
# Done
#===============================================================================

echo ""
echo "======================================================================="
echo "✅ Conversion Complete!"
echo "======================================================================="
echo "Output directory: ${ARRAY_DIR}"
echo "Array scripts:    ${array_count}"
echo "Logs directory:   ${LOGS_DIR}"
echo ""
echo "Next steps:"
echo "  1. Review generated scripts in ${ARRAY_DIR}/"
echo "  2. Submit all arrays:"
if [ "$SEQUENTIAL" = true ]; then
    echo "       cd ${ARRAY_DIR} && ./submit_all_arrays.sh"
    echo "     (Jobs will run one after another)"
else
    echo "       cd ${ARRAY_DIR} && ./submit_all_arrays.sh"
    echo "     (Jobs will run with max ${MAX_CONCURRENT} concurrent per array)"
fi
echo "  3. Monitor:"
echo "       squeue -u \$USER"
echo "       watch -n 30 'squeue -u \$USER'"
echo "======================================================================="
