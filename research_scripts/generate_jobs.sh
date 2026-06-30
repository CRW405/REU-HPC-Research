#!/bin/bash
#===============================================================================
# SLURM Job Generator for Scaling Studies
#
# Generates SLURM job scripts for node and MPI scaling analysis
# with optional PEAK profiling
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
SINGLE_NODE_CONFIGS=("n1" "n2" "n4" "n8" "n16" "n32" "n48")

# Multi-node scaling configurations (56 tasks per node)
MULTI_NODE_CONFIGS=("N2" "N4" "N8" "N16")

echo "==============================================================================="
echo "SLURM Job Generator for Scaling Studies"
echo "==============================================================================="
echo "Application: ${APP_NAME}"
echo "Run name: ${RUN_NAME}"
echo "Run mode: ${RUN_MODE}"
echo "Base directory: ${BASE_DIR}"
echo "Test cases: ${#TEST_CASES[@]}"
echo "Timestamp: ${TIMESTAMP}"
echo ""

# Create base directory
mkdir -p "${BASE_DIR}"

# Track all generated job files
JOB_LIST="${BASE_DIR}/all_jobs.txt"
> "${JOB_LIST}"  # Clear file

# Create timing log file with header
TIMING_LOG="${BASE_DIR}/timing_summary.csv"
echo "job_name,test_case,config,nodes,ntasks,peak_enabled,start_time,end_time,elapsed_seconds,exit_code,slurm_job_id" > "${TIMING_LOG}"

#===============================================================================
# FUNCTION: Generate SLURM Job Script
#===============================================================================

generate_job_script() {
    local test_name=$1
    local test_input=$2
    local config=$3
    local nodes=$4
    local ntasks=$5
    local time_limit=$6
    local enable_peak=$7
    local scaling_type=$8  # "single_node" or "multi_node"
    
    local job_name="${APP_NAME}_${test_name}_${config}"
    local output_dir="${BASE_DIR}/${test_name}/${scaling_type}/${config}"
    local slurm_file="${output_dir}/job.slurm"
    
    # Create output directory
    mkdir -p "${output_dir}"
    
    # Determine PEAK status string
    local peak_status="nopeak"
    if [ "$enable_peak" = "true" ]; then
        peak_status="peak"
    fi
    
    # Generate SLURM script
    cat > "${slurm_file}" << EOF
#!/bin/bash
#SBATCH -J ${job_name}
#SBATCH -o ${output_dir}/slurm.out
#SBATCH -e ${output_dir}/slurm.err
#SBATCH --chdir=${output_dir}
#SBATCH -p ${SLURM_PARTITION}
#SBATCH -N ${nodes}
#SBATCH -n ${ntasks}
#SBATCH -t ${time_limit}
#SBATCH -A ${SLURM_ACCOUNT}

#===============================================================================
# SLURM Job: ${job_name}
# Generated: $(date)
# Configuration: ${config} (${nodes} nodes, ${ntasks} tasks)
# PEAK: ${peak_status}
#===============================================================================

# Timing variables
start_epoch=\$(date +%s)
start_time=\$(date '+%Y-%m-%d %H:%M:%S')
pre="[${config}]: "

# Timing log file (absolute path)
TIMING_LOG="${TIMING_LOG}"

echo "\${pre}======================================================================"
echo "\${pre}SLURM Job Start"
echo "\${pre}======================================================================"
echo "\${pre}Job ID: \${SLURM_JOB_ID}"
echo "\${pre}Configuration: ${config}"
echo "\${pre}Nodes: ${nodes}"
echo "\${pre}MPI Tasks: ${ntasks}"
echo "\${pre}Tasks per node: \$((${ntasks} / ${nodes}))"
echo "\${pre}Test case: ${test_name}"
echo "\${pre}PEAK profiling: ${peak_status}"
echo "\${pre}Start time: \${start_time}"
echo "\${pre}======================================================================"

# Working directory
echo "\${pre}Working directory: ${output_dir}"

# Load modules
echo "\${pre}Loading modules..."
ml reset
EOF

    # Add module loading
    for module in "${MODULES[@]}"; do
        echo "ml ${module}" >> "${slurm_file}"
    done

    cat >> "${slurm_file}" << EOF

# Setup library paths
echo "\${pre}Setting up library paths..."
EOF

    for lib_path in "${LIBRARY_PATHS[@]}"; do
        echo "export LD_LIBRARY_PATH=${lib_path}:\${LD_LIBRARY_PATH}" >> "${slurm_file}"
    done

    cat >> "${slurm_file}" << EOF

# Application-specific environment
EOF

    for env_var in "${APP_ENV[@]}"; do
        echo "export ${env_var}" >> "${slurm_file}"
    done

    # Add MPI environment if exists
    if [ ${#MPI_ENV[@]} -gt 0 ]; then
        cat >> "${slurm_file}" << EOF

# MPI environment
EOF
        for env_var in "${MPI_ENV[@]}"; do
            echo "export ${env_var}" >> "${slurm_file}"
        done
    fi

    # Add PEAK configuration if enabled
    if [ "$enable_peak" = "true" ]; then
        cat >> "${slurm_file}" << EOF

# PEAK configuration
echo "\${pre}Configuring PEAK profiling..."
export PEAK_LIB_PATH=${LIBPEAK_PATH}
export PEAK_STATSLOG_PATH=${output_dir}/peak_stats
export PEAK_MEMLOG_PATH=${output_dir}/peak_mem
export PEAK_TARGET_GROUP=${PEAK_TARGET_GROUPS}
export PEAK_MEMORY_PROFILE=${PEAK_MEMORY_PROFILE}
export PEAK_MEMORY_TRACK_ALL=${PEAK_MEMORY_TRACK_ALL}
export PEAK_MEMLOG_CHUNK_EVENTS=${PEAK_MEMLOG_CHUNK_EVENTS}

export I_MPI_LD_PRELOAD=\${PEAK_LIB_PATH}
export LD_PRELOAD=\${PEAK_LIB_PATH}

echo "\${pre}  Target groups: ${PEAK_TARGET_GROUPS}"
echo "\${pre}  Memory profiling: ${PEAK_MEMORY_PROFILE}"
echo "\${pre}  Stats output: ${output_dir}/peak_stats-pXXXXX.csv"
echo "\${pre}  Memory output: ${output_dir}/peak_mem-pXXXXX.csv"
EOF
    fi

    # Add application execution
    cat >> "${slurm_file}" << EOF

# Application binary and input
APP_BIN="${APP_BINARY}"
INPUT_FILE="${test_input}"

echo "\${pre}======================================================================"
echo "\${pre}Starting application run..."
echo "\${pre}======================================================================"
echo "\${pre}Binary: \${APP_BIN}"
echo "\${pre}Input: \${INPUT_FILE}"

# Run application
mpirun -np ${ntasks} \${APP_BIN} \${INPUT_FILE} > ${output_dir}/${APP_NAME}.stdout 2> ${output_dir}/${APP_NAME}.stderr

exit_code=\$?

# Calculate timing
end_epoch=\$(date +%s)
end_time=\$(date '+%Y-%m-%d %H:%M:%S')
elapsed_seconds=\$((end_epoch - start_epoch))
hours=\$((elapsed_seconds / 3600))
minutes=\$(((elapsed_seconds % 3600) / 60))
seconds=\$((elapsed_seconds % 60))

echo "\${pre}======================================================================"
echo "\${pre}Run completed"
echo "\${pre}======================================================================"
echo "\${pre}Exit code: \${exit_code}"
echo "\${pre}End time: \${end_time}"
echo "\${pre}Elapsed time: \${elapsed_seconds} seconds (\${hours}h \${minutes}m \${seconds}s)"
echo "\${pre}======================================================================"
echo "\${pre}Output files:"
echo "\${pre}  Standard output: ${output_dir}/${APP_NAME}.stdout"
echo "\${pre}  Standard error: ${output_dir}/${APP_NAME}.stderr"
EOF

    if [ "$enable_peak" = "true" ]; then
        cat >> "${slurm_file}" << EOF
echo "\${pre}  PEAK outputs:"
ls -lh ${output_dir}/peak_*.csv 2>/dev/null || echo "\${pre}    No PEAK files found"
EOF
    fi

    cat >> "${slurm_file}" << EOF
echo "\${pre}======================================================================"

# Log timing data to CSV (append to shared timing log)
echo "${job_name},${test_name},${config},${nodes},${ntasks},${enable_peak},\${start_time},\${end_time},\${elapsed_seconds},\${exit_code},\${SLURM_JOB_ID}" >> "\${TIMING_LOG}"

# Also save individual timing file
cat > ${output_dir}/timing.txt << TIMING_EOF
Job Name: ${job_name}
Test Case: ${test_name}
Configuration: ${config}
Nodes: ${nodes}
Tasks: ${ntasks}
PEAK Enabled: ${enable_peak}
SLURM Job ID: \${SLURM_JOB_ID}
Start Time: \${start_time}
End Time: \${end_time}
Elapsed Seconds: \${elapsed_seconds}
Elapsed (formatted): \${hours}h \${minutes}m \${seconds}s
Exit Code: \${exit_code}
TIMING_EOF

exit \${exit_code}
EOF

    chmod +x "${slurm_file}"
    echo "${slurm_file}" >> "${JOB_LIST}"
    echo "  Generated: ${slurm_file}"
}

#===============================================================================
# GENERATE JOBS BASED ON MODE
#===============================================================================

case "$RUN_MODE" in
    test)
        echo ""
        echo "Generating TEST mode jobs (single n1 configuration, no PEAK)..."
        echo "-----------------------------------------------------------------------"
        
        for test_case in "${TEST_CASES[@]}"; do
            IFS=':' read -r test_name test_input <<< "$test_case"
            echo ""
            echo "Test case: ${test_name}"
            generate_job_script "${test_name}" "${test_input}" "n1" 1 1 "${SINGLE_NODE_TIME}" "false" "single_node"
        done
        ;;
    
    test-peak)
        echo ""
        echo "Generating TEST-PEAK mode jobs (single n1 configuration with PEAK)..."
        echo "-----------------------------------------------------------------------"
        
        for test_case in "${TEST_CASES[@]}"; do
            IFS=':' read -r test_name test_input <<< "$test_case"
            echo ""
            echo "Test case: ${test_name}"
            generate_job_script "${test_name}" "${test_input}" "n1_peak" 1 1 "${SINGLE_NODE_TIME}" "true" "single_node"
        done
        ;;
        
    peak)
        echo ""
        echo "Generating PEAK mode jobs (full scaling with PEAK enabled)..."
        echo "-----------------------------------------------------------------------"
        
        # Single-node scaling
        echo ""
        echo "Single-Node Scaling..."
        for test_case in "${TEST_CASES[@]}"; do
            IFS=':' read -r test_name test_input <<< "$test_case"
            echo ""
            echo "Test case: ${test_name}"
            
            for config in "${SINGLE_NODE_CONFIGS[@]}"; do
                ntasks=${config#n}
                echo "  ${config}: 1 node, ${ntasks} tasks (PEAK)"
                generate_job_script "${test_name}" "${test_input}" "${config}_peak" 1 "${ntasks}" "${SINGLE_NODE_TIME}" "true" "single_node"
            done
        done
        
        # Multi-node scaling
        echo ""
        echo "Multi-Node Scaling..."
        for test_case in "${TEST_CASES[@]}"; do
            IFS=':' read -r test_name test_input <<< "$test_case"
            echo ""
            echo "Test case: ${test_name}"
            
            for config in "${MULTI_NODE_CONFIGS[@]}"; do
                nodes=${config#N}
                ntasks=$((nodes * TASKS_PER_NODE))
                echo "  ${config}: ${nodes} nodes, ${ntasks} tasks (PEAK)"
                generate_job_script "${test_name}" "${test_input}" "${config}_peak" "${nodes}" "${ntasks}" "${MULTI_NODE_TIME}" "true" "multi_node"
            done
        done
        ;;
        
    full)
        echo ""
        echo "Generating FULL mode jobs (scaling with and without PEAK)..."
        echo "-----------------------------------------------------------------------"
        
        for enable_peak in "false" "true"; do
            peak_label="nopeak"
            if [ "$enable_peak" = "true" ]; then
                peak_label="peak"
            fi
            
            echo ""
            echo "=========================================="
            echo "Generating jobs with PEAK: ${peak_label}"
            echo "=========================================="
            
            # Single-node scaling
            echo ""
            echo "Single-Node Scaling (${peak_label})..."
            for test_case in "${TEST_CASES[@]}"; do
                IFS=':' read -r test_name test_input <<< "$test_case"
                echo ""
                echo "Test case: ${test_name}"
                
                for config in "${SINGLE_NODE_CONFIGS[@]}"; do
                    ntasks=${config#n}
                    echo "  ${config}: 1 node, ${ntasks} tasks (${peak_label})"
                    generate_job_script "${test_name}" "${test_input}" "${config}_${peak_label}" 1 "${ntasks}" "${SINGLE_NODE_TIME}" "${enable_peak}" "single_node"
                done
            done
            
            # Multi-node scaling
            echo ""
            echo "Multi-Node Scaling (${peak_label})..."
            for test_case in "${TEST_CASES[@]}"; do
                IFS=':' read -r test_name test_input <<< "$test_case"
                echo ""
                echo "Test case: ${test_name}"
                
                for config in "${MULTI_NODE_CONFIGS[@]}"; do
                    nodes=${config#N}
                    ntasks=$((nodes * TASKS_PER_NODE))
                    echo "  ${config}: ${nodes} nodes, ${ntasks} tasks (${peak_label})"
                    generate_job_script "${test_name}" "${test_input}" "${config}_${peak_label}" "${nodes}" "${ntasks}" "${MULTI_NODE_TIME}" "${enable_peak}" "multi_node"
                done
            done
        done
        ;;
esac

#===============================================================================
# SUMMARY
#===============================================================================

total_jobs=$(wc -l < "${JOB_LIST}")

echo ""
echo "==============================================================================="
echo "Job Generation Complete"
echo "==============================================================================="
echo "Total jobs generated: ${total_jobs}"
echo "Job list: ${JOB_LIST}"
echo "Timing log: ${TIMING_LOG}"
echo "Base directory: ${BASE_DIR}"
echo ""
echo "To submit jobs, run:"
echo "  while read job; do sbatch \"\$job\"; done < ${JOB_LIST}"
echo ""
echo "Or submit individually:"
echo "  sbatch ${BASE_DIR}/<test_case>/<scaling_type>/<config>/job.slurm"
echo ""
echo "After jobs complete, check timing data:"
echo "  cat ${TIMING_LOG}"
echo "  column -t -s, ${TIMING_LOG} | less -S"
echo "==============================================================================="
