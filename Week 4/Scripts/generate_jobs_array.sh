#!/bin/bash
#===============================================================================
# SLURM Job Generator for Scaling Studies with Job Arrays
#
# Generates a job manifest and job array script for PEAK profiling
#
# Usage:
#   ./generate_jobs.sh [options]
#
# Options:
#   --config FILE         Config file to source (default: ./config.sh)
#   --name NAME           Run name (default: from config)
#   -t, --test            Test mode: single n1 job without PEAK
#   -tp, --test-peak      Test+Peak mode: single n1 job with PEAK enabled
#   -p, --peak            Peak only: full scaling with PEAK enabled
#   -f, --full            Full suite: full scaling with and without PEAK
#   --input NAME:PATH     Override/add single test case
#   --help                Show this help message
#===============================================================================

#===============================================================================
# ARGUMENT PARSING
#===============================================================================

CONFIG_FILE="./config.sh"
RUN_NAME_OVERRIDE=""
RUN_MODE=""
SHOW_HELP=false
INPUT_OVERRIDE=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --config)
            CONFIG_FILE="$2"
            shift 2
            ;;
        --name)
            RUN_NAME_OVERRIDE="$2"
            shift 2
            ;;
        -t|--test)
            RUN_MODE="test"
            shift
            ;;
        -tp|--test-peak)
            RUN_MODE="test-peak"
            shift
            ;;
        -p|--peak)
            RUN_MODE="peak"
            shift
            ;;
        -f|--full)
            RUN_MODE="full"
            shift
            ;;
        --input)
            INPUT_OVERRIDE="$2"
            shift 2
            ;;
        --help|-h)
            SHOW_HELP=true
            shift
            ;;
        *)
            echo "Unknown option: $1"
            SHOW_HELP=true
            shift
            ;;
    esac
done

if [ "$SHOW_HELP" = true ]; then
    head -n 20 "$0" | tail -n +2 | sed 's/^#//'
    exit 0
fi

if [ -z "$RUN_MODE" ]; then
    echo "ERROR: Must specify run mode: -t (test), -tp (test-peak), -p (peak), or -f (full)"
    exit 1
fi

#===============================================================================
# LOAD CONFIGURATION
#===============================================================================

if [ ! -f "$CONFIG_FILE" ]; then
    echo "ERROR: Config file not found: $CONFIG_FILE"
    exit 1
fi

source "$CONFIG_FILE"

# Apply overrides
if [ -n "$RUN_NAME_OVERRIDE" ]; then
    RUN_NAME="$RUN_NAME_OVERRIDE"
fi

# Handle input override
if [ -n "$INPUT_OVERRIDE" ]; then
    TEST_CASES=("$INPUT_OVERRIDE")
fi

#===============================================================================
# SETUP
#===============================================================================

TIMESTAMP=$(date '+%m%d%Y-%H%M%S')

# Convert OUTPUT_BASE to absolute path
if [[ ! "$OUTPUT_BASE" = /* ]]; then
    OUTPUT_BASE="$(cd "$(dirname "$OUTPUT_BASE")" && pwd)/$(basename "$OUTPUT_BASE")"
fi

BASE_DIR="${OUTPUT_BASE}/${RUN_NAME}-${RUN_MODE}-${TIMESTAMP}"

# Single-node MPI scaling configurations
SINGLE_NODE_CONFIGS=("n1" "n2" "n4" "n8" "n16" "n32" "n56")

# Multi-node scaling configurations (56 tasks per node)
MULTI_NODE_CONFIGS=("N1" "N2" "N4" "N8" "N16")

echo "==============================================================================="
echo "SLURM Job Array Generator for Scaling Studies"
echo "==============================================================================="
echo "Application: ${APP_NAME}"
echo "Run name: ${RUN_NAME}"
echo "Run mode: ${RUN_MODE}"
echo "Base directory: ${BASE_DIR}"
echo "Test cases: ${#TEST_CASES[@]}"
echo "Timestamp: ${TIMESTAMP}"
echo ""

# Create base directory structure
mkdir -p "${BASE_DIR}"
mkdir -p "${BASE_DIR}/logs"

# Job manifest file (CSV)
MANIFEST="${BASE_DIR}/job_manifest.csv"

# Create manifest header
echo "task_id,test_name,test_input,config,nodes,ntasks,time_limit,enable_peak,scaling_type" > "${MANIFEST}"

# Create timing log file with header
TIMING_LOG="${BASE_DIR}/timing_summary.csv"
echo "task_id,job_name,test_case,config,nodes,ntasks,peak_enabled,start_time,end_time,elapsed_seconds,exit_code,slurm_job_id" > "${TIMING_LOG}"

#===============================================================================
# BUILD JOB MANIFEST
#===============================================================================

TASK_ID=0

build_manifest_entry() {
    local test_case=$1
    local config=$2
    local nodes=$3
    local ntasks=$4
    local enable_peak=$5
    local scaling_type=$6
    
    # Parse test case
    IFS=':' read -r test_name test_input <<< "$test_case"
    
    # Convert test_input to absolute path if it's not already
    if [[ ! "$test_input" = /* ]]; then
        test_input="$(cd "$(dirname "$test_input")" 2>/dev/null && pwd)/$(basename "$test_input")"
    fi
    
    # Determine time limit based on node count
    local time_limit="02:00:00"
    if [ $nodes -ge 8 ]; then
        time_limit="04:00:00"
    fi
    
    # Write to manifest
    echo "${TASK_ID},${test_name},${test_input},${config},${nodes},${ntasks},${time_limit},${enable_peak},${scaling_type}" >> "${MANIFEST}"
    
    TASK_ID=$((TASK_ID + 1))
}

echo "Building job manifest..."

case $RUN_MODE in
    test)
        echo "  Mode: Test (single n1, no PEAK)"
        for test_case in "${TEST_CASES[@]}"; do
            build_manifest_entry "$test_case" "n1" 1 1 false "single_node"
        done
        ;;
        
    test-peak)
        echo "  Mode: Test+Peak (single n1, with PEAK)"
        for test_case in "${TEST_CASES[@]}"; do
            build_manifest_entry "$test_case" "n1" 1 1 true "single_node"
        done
        ;;
        
    peak)
        echo "  Mode: Peak only (full scaling, PEAK enabled)"
        for test_case in "${TEST_CASES[@]}"; do
            # Single-node scaling
            for config in "${SINGLE_NODE_CONFIGS[@]}"; do
                ntasks=${config#n}
                build_manifest_entry "$test_case" "$config" 1 $ntasks true "single_node"
            done
            
            # Multi-node scaling
            for config in "${MULTI_NODE_CONFIGS[@]}"; do
                nodes=${config#N}
                ntasks=$((nodes * 56))
                build_manifest_entry "$test_case" "$config" $nodes $ntasks true "multi_node"
            done
        done
        ;;
        
    full)
        echo "  Mode: Full suite (full scaling, with and without PEAK)"
        for test_case in "${TEST_CASES[@]}"; do
            # Single-node scaling - baseline and PEAK
            for config in "${SINGLE_NODE_CONFIGS[@]}"; do
                ntasks=${config#n}
                build_manifest_entry "$test_case" "$config" 1 $ntasks false "single_node"
                build_manifest_entry "$test_case" "$config" 1 $ntasks true "single_node"
            done
            
            # Multi-node scaling - baseline and PEAK
            for config in "${MULTI_NODE_CONFIGS[@]}"; do
                nodes=${config#N}
                ntasks=$((nodes * 56))
                build_manifest_entry "$test_case" "$config" $nodes $ntasks false "multi_node"
                build_manifest_entry "$test_case" "$config" $nodes $ntasks true "multi_node"
            done
        done
        ;;
esac

TOTAL_TASKS=$TASK_ID
echo "  Total tasks: ${TOTAL_TASKS}"
echo ""

#===============================================================================
# GENERATE JOB ARRAY SCRIPT
#===============================================================================

JOB_ARRAY_SCRIPT="${BASE_DIR}/job_array.slurm"

echo "Generating job array script: ${JOB_ARRAY_SCRIPT}"

cat > "${JOB_ARRAY_SCRIPT}" << 'JOBARRAY_HEADER'
#!/bin/bash
#SBATCH -J PEAK_ARRAY
#SBATCH -o LOGS_DIR/job_%A_%a.out
#SBATCH -e LOGS_DIR/job_%A_%a.err
#SBATCH -p PARTITION
#SBATCH -A ACCOUNT
#SBATCH --array=ARRAY_RANGE
#SBATCH -N 1
#SBATCH -n 1
#SBATCH -t 06:00:00

#===============================================================================
# SLURM Job Array for PEAK Profiling
# Generated: GENERATION_TIME
#
# This script reads configuration from a manifest file and executes
# the corresponding task based on $SLURM_ARRAY_TASK_ID
#===============================================================================

set -e  # Exit on error

# Configuration paths (absolute)
BASE_DIR="BASE_DIR_PLACEHOLDER"
MANIFEST="${BASE_DIR}/job_manifest.csv"
TIMING_LOG="${BASE_DIR}/timing_summary.csv"

# Validate manifest exists
if [ ! -f "${MANIFEST}" ]; then
    echo "ERROR: Manifest file not found: ${MANIFEST}"
    exit 1
fi

# Read configuration for this task (skip header, get line TASK_ID+2)
CONFIG_LINE=$(sed -n "$((SLURM_ARRAY_TASK_ID + 2))p" "${MANIFEST}")

if [ -z "${CONFIG_LINE}" ]; then
    echo "ERROR: No configuration found for task ID ${SLURM_ARRAY_TASK_ID}"
    exit 1
fi

# Parse CSV line
IFS=',' read -r task_id test_name test_input config nodes ntasks time_limit enable_peak scaling_type <<< "${CONFIG_LINE}"

# Determine PEAK status string
peak_status="nopeak"
if [ "$enable_peak" = "true" ]; then
    peak_status="peak"
fi

# Set up output directory
output_dir="${BASE_DIR}/${test_name}/${scaling_type}/${config}"
if [ "$enable_peak" = "true" ]; then
    output_dir="${output_dir}_peak"
fi

mkdir -p "${output_dir}"

# Job name
job_name="APP_NAME_${test_name}_${config}_${peak_status}"

# Timing variables
start_epoch=$(date +%s)
start_time=$(date '+%Y-%m-%d %H:%M:%S')
pre="[Task ${SLURM_ARRAY_TASK_ID}|${config}|${peak_status}]: "

echo "${pre}======================================================================"
echo "${pre}SLURM Job Array Task Start"
echo "${pre}======================================================================"
echo "${pre}Array Job ID: ${SLURM_ARRAY_JOB_ID}"
echo "${pre}Task ID: ${SLURM_ARRAY_TASK_ID}"
echo "${pre}Job ID: ${SLURM_JOB_ID}"
echo "${pre}Configuration: ${config}"
echo "${pre}Nodes: ${nodes}"
echo "${pre}MPI Tasks: ${ntasks}"
echo "${pre}Test case: ${test_name}"
echo "${pre}Test input: ${test_input}"
echo "${pre}PEAK profiling: ${peak_status}"
echo "${pre}Start time: ${start_time}"
echo "${pre}Output directory: ${output_dir}"
echo "${pre}======================================================================"

# Change to output directory
cd "${output_dir}"

# Load modules
echo "${pre}Loading modules..."
ml reset
JOBARRAY_HEADER

# Insert module loading
for module in "${MODULES[@]}"; do
    echo "ml ${module}" >> "${JOB_ARRAY_SCRIPT}"
done

cat >> "${JOB_ARRAY_SCRIPT}" << 'JOBARRAY_ENV'

# Setup library paths
echo "${pre}Setting up library paths..."
JOBARRAY_ENV

for lib_path in "${LIBRARY_PATHS[@]}"; do
    echo "export LD_LIBRARY_PATH=${lib_path}:\${LD_LIBRARY_PATH}" >> "${JOB_ARRAY_SCRIPT}"
done

cat >> "${JOB_ARRAY_SCRIPT}" << 'JOBARRAY_APPENV'

# Application-specific environment
JOBARRAY_APPENV

for env_var in "${APP_ENV[@]}"; do
    echo "export ${env_var}" >> "${JOB_ARRAY_SCRIPT}"
done

# Add MPI environment if exists
if [ ${#MPI_ENV[@]} -gt 0 ]; then
    cat >> "${JOB_ARRAY_SCRIPT}" << 'JOBARRAY_MPIENV'

# MPI environment
JOBARRAY_MPIENV
    for env_var in "${MPI_ENV[@]}"; do
        echo "export ${env_var}" >> "${JOB_ARRAY_SCRIPT}"
    done
fi

cat >> "${JOB_ARRAY_SCRIPT}" << 'JOBARRAY_PEAK'

# PEAK configuration (if enabled)
if [ "$enable_peak" = "true" ]; then
    echo "${pre}Configuring PEAK profiling..."
    export PEAK_LIB_PATH=LIBPEAK_PATH_PLACEHOLDER
    export PEAK_STATSLOG_PATH=${output_dir}/peak_stats
    export PEAK_MEMLOG_PATH=${output_dir}/peak_mem
    export PEAK_TARGET_GROUP=TARGET_GROUPS_PLACEHOLDER
    export PEAK_MEMORY_PROFILE=MEMORY_PROFILE_PLACEHOLDER
    export PEAK_MEMORY_TRACK_ALL=MEMORY_TRACK_ALL_PLACEHOLDER
    export PEAK_MEMLOG_CHUNK_EVENTS=MEMLOG_CHUNK_EVENTS_PLACEHOLDER
    
    export I_MPI_LD_PRELOAD=${PEAK_LIB_PATH}
    export LD_PRELOAD=${PEAK_LIB_PATH}
    
    echo "${pre}  Target groups: TARGET_GROUPS_PLACEHOLDER"
    echo "${pre}  Memory profiling: MEMORY_PROFILE_PLACEHOLDER"
    echo "${pre}  Stats log: ${PEAK_STATSLOG_PATH}"
    echo "${pre}  Memory log: ${PEAK_MEMLOG_PATH}"
fi

# Prepare command
APP_BINARY="APP_BINARY_PLACEHOLDER"

if [ ${ntasks} -eq 1 ]; then
    # Serial execution
    CMD="${APP_BINARY} < ${test_input}"
else
    # MPI execution
    CMD="ibrun -n ${ntasks} ${APP_BINARY} < ${test_input}"
fi

echo "${pre}======================================================================"
echo "${pre}Executing: ${CMD}"
echo "${pre}======================================================================"

# Execute application
set +e  # Don't exit on error for timing capture
${CMD} > "${output_dir}/APP_NAME_PLACEHOLDER.stdout" 2> "${output_dir}/APP_NAME_PLACEHOLDER.stderr"
exit_code=$?
set -e

# Timing
end_epoch=$(date +%s)
end_time=$(date '+%Y-%m-%d %H:%M:%S')
elapsed=$((end_epoch - start_epoch))
elapsed_formatted=$(printf '%02d:%02d:%02d' $((elapsed/3600)) $((elapsed%3600/60)) $((elapsed%60)))

echo "${pre}======================================================================"
echo "${pre}Job Completed"
echo "${pre}======================================================================"
echo "${pre}End time: ${end_time}"
echo "${pre}Elapsed: ${elapsed_formatted} (${elapsed}s)"
echo "${pre}Exit code: ${exit_code}"
echo "${pre}======================================================================"

# Write timing to individual log
cat > "${output_dir}/timing.txt" << TIMING_EOF
Job Name: ${job_name}
Task ID: ${SLURM_ARRAY_TASK_ID}
Test Case: ${test_name}
Configuration: ${config}
Nodes: ${nodes}
MPI Tasks: ${ntasks}
PEAK Enabled: ${enable_peak}
Start Time: ${start_time}
End Time: ${end_time}
Elapsed Time: ${elapsed_formatted} (${elapsed} seconds)
Exit Code: ${exit_code}
SLURM Job ID: ${SLURM_JOB_ID}
SLURM Array Job ID: ${SLURM_ARRAY_JOB_ID}
TIMING_EOF

# Append to summary CSV (with file locking)
(
    flock -x 200
    echo "${task_id},${job_name},${test_name},${config},${nodes},${ntasks},${enable_peak},${start_time},${end_time},${elapsed},${exit_code},${SLURM_JOB_ID}" >> "${TIMING_LOG}"
) 200>"${TIMING_LOG}.lock"

# PEAK post-processing (if enabled)
if [ "$enable_peak" = "true" ] && [ ${exit_code} -eq 0 ]; then
    echo "${pre}PEAK data collected successfully"
    if [ -f "${PEAK_STATSLOG_PATH}" ]; then
        echo "${pre}  Stats log size: $(du -h ${PEAK_STATSLOG_PATH} | cut -f1)"
    fi
    if [ -f "${PEAK_MEMLOG_PATH}" ]; then
        echo "${pre}  Memory log size: $(du -h ${PEAK_MEMLOG_PATH} | cut -f1)"
    fi
fi

echo "${pre}Task complete!"
exit ${exit_code}
JOBARRAY_PEAK

# Replace placeholders
sed -i "s|BASE_DIR_PLACEHOLDER|${BASE_DIR}|g" "${JOB_ARRAY_SCRIPT}"
sed -i "s|LOGS_DIR|${BASE_DIR}/logs|g" "${JOB_ARRAY_SCRIPT}"
sed -i "s|PARTITION|${SLURM_PARTITION}|g" "${JOB_ARRAY_SCRIPT}"
sed -i "s|ACCOUNT|${SLURM_ACCOUNT}|g" "${JOB_ARRAY_SCRIPT}"
sed -i "s|ARRAY_RANGE|0-$((TOTAL_TASKS - 1))|g" "${JOB_ARRAY_SCRIPT}"
sed -i "s|GENERATION_TIME|$(date)|g" "${JOB_ARRAY_SCRIPT}"
sed -i "s|APP_NAME_PLACEHOLDER|${APP_NAME}|g" "${JOB_ARRAY_SCRIPT}"
sed -i "s|APP_BINARY_PLACEHOLDER|${APP_BINARY}|g" "${JOB_ARRAY_SCRIPT}"
sed -i "s|LIBPEAK_PATH_PLACEHOLDER|${LIBPEAK_PATH}|g" "${JOB_ARRAY_SCRIPT}"
sed -i "s|TARGET_GROUPS_PLACEHOLDER|${PEAK_TARGET_GROUPS}|g" "${JOB_ARRAY_SCRIPT}"
sed -i "s|MEMORY_PROFILE_PLACEHOLDER|${PEAK_MEMORY_PROFILE}|g" "${JOB_ARRAY_SCRIPT}"
sed -i "s|MEMORY_TRACK_ALL_PLACEHOLDER|${PEAK_MEMORY_TRACK_ALL}|g" "${JOB_ARRAY_SCRIPT}"
sed -i "s|MEMLOG_CHUNK_EVENTS_PLACEHOLDER|${PEAK_MEMLOG_CHUNK_EVENTS}|g" "${JOB_ARRAY_SCRIPT}"

#===============================================================================
# SUMMARY
#===============================================================================

echo "==============================================================================="
echo "Generation Complete!"
echo "==============================================================================="
echo "Base directory: ${BASE_DIR}"
echo "Job manifest: ${MANIFEST}"
echo "Job array script: ${JOB_ARRAY_SCRIPT}"
echo "Total tasks: ${TOTAL_TASKS}"
echo ""
echo "To submit jobs:"
echo "  ./submit_jobs.sh ${BASE_DIR}"
echo ""
echo "Or manually:"
echo "  sbatch --array=0-$((TOTAL_TASKS - 1))%20 ${JOB_ARRAY_SCRIPT}"
echo ""
echo "  (The %20 limits to 20 concurrent tasks)"
echo "==============================================================================="
