#!/bin/bash
#===============================================================================
# HPC Application Run Script with PEAK Profiling
#
# This script can be run standalone or submitted via SLURM
# Configuration via config.sh file or command-line arguments
#
# Usage:
#   ./run_script.sh [options]
#
# Options:
#   --config FILE         Config file to source (default: ./config.sh)
#   --input FILE          Input file to use (overrides config)
#   --peak                Enable PEAK profiling
#   --no-peak             Disable PEAK profiling
#   --name NAME           Run name for output files
#   --help                Show this help message
#===============================================================================

#===============================================================================
# ARGUMENT PARSING
#===============================================================================

# Default values
CONFIG_FILE="./config.sh"
ENABLE_PEAK=""
INPUT_FILE=""
RUN_NAME_OVERRIDE=""
SHOW_HELP=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --config)
            CONFIG_FILE="$2"
            shift 2
            ;;
        --input)
            INPUT_FILE="$2"
            shift 2
            ;;
        --peak)
            ENABLE_PEAK="true"
            shift
            ;;
        --no-peak)
            ENABLE_PEAK="false"
            shift
            ;;
        --name)
            RUN_NAME_OVERRIDE="$2"
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

#===============================================================================
# LOAD CONFIGURATION
#===============================================================================

if [ ! -f "$CONFIG_FILE" ]; then
    echo "ERROR: Config file not found: $CONFIG_FILE"
    exit 1
fi

source "$CONFIG_FILE"

# Apply command-line overrides
if [ -n "$RUN_NAME_OVERRIDE" ]; then
    RUN_NAME="$RUN_NAME_OVERRIDE"
fi

#===============================================================================
# SETUP LOGGING
#===============================================================================

pre="[${RUN_NAME}]: "

#===============================================================================
# TIMING START
#===============================================================================

start_time=$SECONDS
start_date=$(date '+%m%d%Y-%H%M%S')

echo "${pre}======================================================================"
echo "${pre}HPC Application Run with PEAK Profiling"
echo "${pre}======================================================================"
echo "${pre}Start time: $(date)"
echo "${pre}Run name: ${RUN_NAME}"
echo "${pre}Config file: ${CONFIG_FILE}"
echo "${pre}PEAK enabled: ${ENABLE_PEAK}"
echo "${pre}======================================================================"

#===============================================================================
# CLEANUP PREVIOUS OUTPUTS (if enabled)
#===============================================================================

if [ "$CLEAN_PREVIOUS" = "TRUE" ]; then
    echo "${pre}Cleaning previous outputs..."
    rm -f peak_* ${APP_NAME}.stdout ${APP_NAME}.stderr
    # Add application-specific cleanup patterns here if needed
fi

#===============================================================================
# LOAD MODULES
#===============================================================================

echo "${pre}Loading modules..."
ml reset

for module in "${MODULES[@]}"; do
    echo "${pre}  Loading: ${module}"
    ml ${module}
done

#===============================================================================
# SETUP LIBRARY PATHS
#===============================================================================

echo "${pre}Setting up library paths..."
for lib_path in "${LIBRARY_PATHS[@]}"; do
    export LD_LIBRARY_PATH="${lib_path}:${LD_LIBRARY_PATH}"
    echo "${pre}  Added: ${lib_path}"
done

#===============================================================================
# SETUP APPLICATION ENVIRONMENT
#===============================================================================

echo "${pre}Setting application environment..."
for env_var in "${APP_ENV[@]}"; do
    export ${env_var}
    echo "${pre}  ${env_var}"
done

#===============================================================================
# SETUP MPI ENVIRONMENT
#===============================================================================

if [ ${#MPI_ENV[@]} -gt 0 ]; then
    echo "${pre}Setting MPI environment..."
    for env_var in "${MPI_ENV[@]}"; do
        export ${env_var}
        echo "${pre}  ${env_var}"
    done
fi

#===============================================================================
# SETUP PEAK PROFILING (if enabled)
#===============================================================================

if [ "$ENABLE_PEAK" = "true" ]; then
    echo "${pre}======================================================================"
    echo "${pre}Configuring PEAK profiling..."
    echo "${pre}======================================================================"
    
    # Check if PEAK library exists
    if [ ! -f "${LIBPEAK_PATH}" ]; then
        echo "${pre}ERROR: PEAK library not found at ${LIBPEAK_PATH}"
        exit 1
    fi
    
    # PEAK output paths
    export PEAK_STATSLOG_PATH="peak_stats"
    export PEAK_MEMLOG_PATH="peak_mem"
    
    # PEAK profiling options
    export PEAK_TARGET_GROUP="${PEAK_TARGET_GROUPS}"
    export PEAK_MEMORY_PROFILE="${PEAK_MEMORY_PROFILE}"
    export PEAK_MEMORY_TRACK_ALL="${PEAK_MEMORY_TRACK_ALL}"
    export PEAK_MEMLOG_CHUNK_EVENTS="${PEAK_MEMLOG_CHUNK_EVENTS}"
    
    # Force Intel MPI to handle the preload on remote nodes
    export I_MPI_LD_PRELOAD="${LIBPEAK_PATH}"
    export LD_PRELOAD="${LIBPEAK_PATH}"
    
    echo "${pre}  PEAK library: ${LIBPEAK_PATH}"
    echo "${pre}  Target groups: ${PEAK_TARGET_GROUPS}"
    echo "${pre}  Memory profiling: ${PEAK_MEMORY_PROFILE}"
    echo "${pre}  Stats output: ${PEAK_STATSLOG_PATH}-pXXXXX.csv"
    echo "${pre}  Memory output: ${PEAK_MEMLOG_PATH}-pXXXXX.csv"
else
    echo "${pre}PEAK profiling disabled"
fi

#===============================================================================
# DETERMINE INPUT FILE
#===============================================================================

if [ -z "$INPUT_FILE" ]; then
    # Use first test case from config if no input specified
    if [ ${#TEST_CASES[@]} -gt 0 ]; then
        IFS=':' read -r test_name test_path <<< "${TEST_CASES[0]}"
        INPUT_FILE="$test_path"
        echo "${pre}Using default input: ${INPUT_FILE}"
    else
        echo "${pre}ERROR: No input file specified and no test cases in config"
        exit 1
    fi
else
    echo "${pre}Using specified input: ${INPUT_FILE}"
fi

if [ ! -f "$INPUT_FILE" ]; then
    echo "${pre}ERROR: Input file not found: $INPUT_FILE"
    exit 1
fi

#===============================================================================
# RUN APPLICATION
#===============================================================================

echo "${pre}======================================================================"
echo "${pre}Starting application run..."
echo "${pre}======================================================================"
echo "${pre}Binary: ${APP_BINARY}"
echo "${pre}Input: ${INPUT_FILE}"

if [ -n "$SLURM_JOB_ID" ]; then
    echo "${pre}SLURM Job ID: ${SLURM_JOB_ID}"
    echo "${pre}Nodes: ${SLURM_JOB_NUM_NODES}"
    echo "${pre}Tasks: ${SLURM_NTASKS}"
    echo "${pre}CPUs per task: ${SLURM_CPUS_PER_TASK}"
fi

echo "${pre}======================================================================"

# Run the application
${APP_BINARY} ${INPUT_FILE} > ${APP_NAME}.stdout 2> ${APP_NAME}.stderr

exit_code=$?

#===============================================================================
# TIMING END & SUMMARY
#===============================================================================

end_time=$SECONDS
elapsed=$((end_time - start_time))
hours=$((elapsed / 3600))
minutes=$(((elapsed % 3600) / 60))
seconds=$((elapsed % 60))

echo "${pre}======================================================================"
echo "${pre}Run completed"
echo "${pre}======================================================================"
echo "${pre}End time: $(date)"
echo "${pre}Exit code: ${exit_code}"
echo "${pre}Elapsed time: ${elapsed} seconds (${hours}h ${minutes}m ${seconds}s)"
echo "${pre}======================================================================"

# Output file summary
echo "${pre}Output files:"
echo "${pre}  Standard output: ${APP_NAME}.stdout"
echo "${pre}  Standard error: ${APP_NAME}.stderr"

if [ "$ENABLE_PEAK" = "true" ]; then
    echo "${pre}  PEAK outputs:"
    ls -lh peak_*.csv 2>/dev/null || echo "${pre}    No PEAK CSV files found (check stderr)"
fi

echo "${pre}======================================================================"

exit ${exit_code}
