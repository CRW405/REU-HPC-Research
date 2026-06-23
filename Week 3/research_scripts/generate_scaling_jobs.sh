#!/bin/bash
#===============================================================================
# PEAK Scaling Study Job Generator
# 
# Generates and submits SLURM jobs for node/MPI scaling studies
# Based on LAMMPS assignment methodology
#
# Usage: ./generate_scaling_jobs.sh [--submit]
#===============================================================================

#===============================================================================
# CONFIGURATION - Modify for each application
#===============================================================================

# Application Settings
APP_NAME="abinit"
APP_VERSION="10.4.7"
STUDY_NAME="scaling_study_$(date +%Y%m%d)"

# Path to your modular run script
RUN_SCRIPT_TEMPLATE="./run_peak_profile.sh"

# SLURM Account Settings
SLURM_ACCOUNT="your_account"      # Your TACC allocation
SLURM_PARTITION="normal"           # Or "development" for testing
SLURM_QUEUE="normal"               # Queue name

# Test Cases (can define multiple input files)
declare -a TEST_CASES=(
    "test0:../abinit-10.4.7/tests/v1/Input/t00.abi"
    "test1:../abinit-10.4.7/tests/v1/Input/t01.abi"
)

# Single-Node Scaling Configurations (MPI tasks per node)
# Format: "n<tasks>" where tasks = MPI tasks on 1 node
SINGLE_NODE_CONFIGS=(
    "n1"
    "n2"
    "n4"
    "n8"
    "n16"
    "n32"
    "n56"
)

# Multi-Node Scaling Configurations
# Format: "N<nodes>" where each node runs 56 tasks (full node on Frontera)
MULTI_NODE_CONFIGS=(
    "N1"
    "N2"
    "N4"
    "N8"
    "N16"
)

# Time limits (adjust based on expected runtime)
SINGLE_NODE_TIME="01:00:00"  # 1 hour for single-node tests
MULTI_NODE_TIME="02:00:00"   # 2 hours for multi-node tests

# PEAK Configuration
PEAK_TARGETS="BLAS,LAPACK,FFTW"
PEAK_MEMORY_PROFILE="TRUE"

#===============================================================================
# END CONFIGURATION
#===============================================================================

TASKS_PER_NODE=56  # Frontera standard
SUBMIT_JOBS=false

# Parse command line arguments
if [[ "$1" == "--submit" ]]; then
    SUBMIT_JOBS=true
fi

# Create base directory structure
BASE_DIR="${APP_NAME}_${STUDY_NAME}"
mkdir -p "${BASE_DIR}"

echo "==============================================================================="
echo "PEAK Scaling Study Job Generator"
echo "==============================================================================="
echo "Application: ${APP_NAME}"
echo "Study name: ${STUDY_NAME}"
echo "Base directory: ${BASE_DIR}"
echo "Submit jobs: ${SUBMIT_JOBS}"
echo ""

#===============================================================================
# Function: Generate SLURM Job Script
#===============================================================================
generate_slurm_script() {
    local case_name=$1
    local config=$2
    local input_file=$3
    local output_dir=$4
    local nodes=$5
    local ntasks=$6
    local time_limit=$7
    
    local job_name="${APP_NAME}_${case_name}_${config}"
    local slurm_file="${output_dir}/job.slurm"
    
    cat > "${slurm_file}" << EOF
#!/bin/bash
#SBATCH -J ${job_name}
#SBATCH -o ${output_dir}/slurm.out
#SBATCH -e ${output_dir}/slurm.err
#SBATCH -p ${SLURM_PARTITION}
#SBATCH -N ${nodes}
#SBATCH -n ${ntasks}
#SBATCH -t ${time_limit}
#SBATCH -A ${SLURM_ACCOUNT}

#===============================================================================
# SLURM Job: ${job_name}
# Generated: $(date)
#===============================================================================

start_time=\$SECONDS
pre="[${config}]: "

echo "\${pre}======================================================================"
echo "\${pre}PEAK Scaling Study - ${APP_NAME}"
echo "\${pre}======================================================================"
echo "\${pre}Configuration: ${config}"
echo "\${pre}Nodes: ${nodes}"
echo "\${pre}MPI Tasks: ${ntasks}"
echo "\${pre}Tasks per node: \$((${ntasks} / ${nodes}))"
echo "\${pre}Test case: ${case_name}"
echo "\${pre}======================================================================"

# Change to output directory
cd ${output_dir}
echo "\${pre}Working directory: \$(pwd)"

# Load modules
echo "\${pre}Loading modules..."
ml reset
ml intel
ml impi
ml netcdf

# Setup library paths
echo "\${pre}Setting up library paths..."
export LD_LIBRARY_PATH=/scratch/11603/crw405/2.project/1.build_scripts/2.apps/${APP_NAME}/install/lib:\${LD_LIBRARY_PATH}
export LD_LIBRARY_PATH=/opt/apps/intel24/netcdf/4.9.2/lib64:\${LD_LIBRARY_PATH}

# Application-specific environment
export ABI_PSPDIR=\${SLURM_SUBMIT_DIR}/../${APP_NAME}-${APP_VERSION}/tests/Pspdir/

# MPI workarounds
export I_MPI_SHM=by_node
export FI_PROVIDER=tcp

# PEAK configuration
echo "\${pre}Configuring PEAK profiling..."
export PEAK_LIB_PATH=/scratch/11603/crw405/2.project/1.build_scripts/1.peak/peak/lib/libpeak.so
export PEAK_STATSLOG_PATH=peak_stats
export PEAK_MEMLOG_PATH=peak_mem
export PEAK_TARGET_GROUP=${PEAK_TARGETS}
export PEAK_MEMORY_PROFILE=${PEAK_MEMORY_PROFILE}
export PEAK_MEMORY_TRACK_ALL=TRUE
export PEAK_MEMLOG_CHUNK_EVENTS=10000000

export I_MPI_LD_PRELOAD=\${PEAK_LIB_PATH}
export LD_PRELOAD=\${PEAK_LIB_PATH}

# Application binary and input
APP_BIN="\${SLURM_SUBMIT_DIR}/../install/bin/${APP_NAME}"
INPUT_FILE="\${SLURM_SUBMIT_DIR}/${input_file}"

echo "\${pre}======================================================================"
echo "\${pre}Starting profiled run..."
echo "\${pre}======================================================================"

# Run application with PEAK profiling
\${APP_BIN} \${INPUT_FILE} > ${APP_NAME}.stdout 2> ${APP_NAME}.stderr

exit_code=\$?
end_time=\$SECONDS
elapsed=\$((end_time - start_time))

echo "\${pre}======================================================================"
echo "\${pre}Run completed"
echo "\${pre}======================================================================"
echo "\${pre}Exit code: \${exit_code}"
echo "\${pre}Elapsed time: \${elapsed} seconds"
echo "\${pre}Output files:"
ls -lh peak_* ${APP_NAME}.std* 2>/dev/null || echo "\${pre}  No output files found"
echo "\${pre}======================================================================"

exit \${exit_code}
EOF

    echo "  Generated: ${slurm_file}"
    echo "${slurm_file}" >> "${BASE_DIR}/all_jobs.txt"
}

#===============================================================================
# Generate Single-Node Scaling Jobs
#===============================================================================
echo ""
echo "Generating Single-Node Scaling Jobs..."
echo "---------------------------------------"

for test_case in "${TEST_CASES[@]}"; do
    IFS=':' read -r case_name input_file <<< "$test_case"
    
    echo ""
    echo "Test Case: ${case_name}"
    
    for config in "${SINGLE_NODE_CONFIGS[@]}"; do
        # Extract number of tasks
        ntasks=${config#n}
        nodes=1
        
        # Create output directory
        output_dir="${BASE_DIR}/${case_name}/${config}"
        mkdir -p "${output_dir}"
        
        echo "  ${config}: ${nodes} node, ${ntasks} tasks"
        
        # Generate SLURM script
        generate_slurm_script "${case_name}" "${config}" "${input_file}" \
            "${output_dir}" "${nodes}" "${ntasks}" "${SINGLE_NODE_TIME}"
    done
done

#===============================================================================
# Generate Multi-Node Scaling Jobs
#===============================================================================
echo ""
echo "Generating Multi-Node Scaling Jobs..."
echo "--------------------------------------"

for test_case in "${TEST_CASES[@]}"; do
    IFS=':' read -r case_name input_file <<< "$test_case"
    
    echo ""
    echo "Test Case: ${case_name}"
    
    for config in "${MULTI_NODE_CONFIGS[@]}"; do
        # Extract number of nodes
        nodes=${config#N}
        ntasks=$((nodes * TASKS_PER_NODE))
        
        # Create output directory
        output_dir="${BASE_DIR}/${case_name}/${config}"
        mkdir -p "${output_dir}"
        
        echo "  ${config}: ${nodes} nodes, ${ntasks} tasks (${TASKS_PER_NODE} per node)"
        
        # Generate SLURM script
        generate_slurm_script "${case_name}" "${config}" "${input_file}" \
            "${output_dir}" "${nodes}" "${ntasks}" "${MULTI_NODE_TIME}"
    done
done

#===============================================================================
# Generate Analysis Script
#===============================================================================
cat > "${BASE_DIR}/analyze_all.sh" << 'ANALYZE_EOF'
#!/bin/bash
# Analyze all PEAK outputs from scaling study

ANALYSIS_SCRIPT="../../peak_analysis.py"  # Adjust path as needed

echo "Analyzing all PEAK outputs..."
echo "=============================="

find . -name "peak_stats-*.csv" | while read stats_file; do
    dir=$(dirname "$stats_file")
    mem_file="${dir}/peak_mem-*.csv"
    
    echo ""
    echo "Analyzing: ${dir}"
    
    if ls ${mem_file} 1> /dev/null 2>&1; then
        python3 ${ANALYSIS_SCRIPT} "${stats_file}" --mem ${mem_file}
    else
        python3 ${ANALYSIS_SCRIPT} "${stats_file}"
    fi
done

echo ""
echo "Analysis complete!"
ANALYZE_EOF

chmod +x "${BASE_DIR}/analyze_all.sh"

#===============================================================================
# Generate Summary Script
#===============================================================================
cat > "${BASE_DIR}/generate_summary.sh" << 'SUMMARY_EOF'
#!/bin/bash
# Generate performance summary from all runs

echo "Configuration,Nodes,Tasks,TotalTime_s,PeakMemory_MB,BLAS_Calls,LAPACK_Calls,FFTW_Calls" > summary.csv

find . -name "peak_stats-*.csv" -o -name "peak_mem-*.csv" | sort | while read file; do
    dir=$(basename $(dirname "$file"))
    case=$(basename $(dirname $(dirname "$file")))
    
    # Extract metrics (customize based on your app's output format)
    # This is a template - you'll need to adjust for your specific needs
    
    echo "Processing: ${case}/${dir}"
done

echo "Summary generated: summary.csv"
SUMMARY_EOF

chmod +x "${BASE_DIR}/generate_summary.sh"

#===============================================================================
# Submit Jobs
#===============================================================================
if [[ "${SUBMIT_JOBS}" == "true" ]]; then
    echo ""
    echo "==============================================================================="
    echo "Submitting Jobs to SLURM"
    echo "==============================================================================="
    
    job_count=0
    while read slurm_file; do
        job_dir=$(dirname "${slurm_file}")
        echo "Submitting: ${slurm_file}"
        
        cd "${job_dir}"
        sbatch job.slurm
        job_id=$?
        cd - > /dev/null
        
        ((job_count++))
        
        # Small delay to avoid overwhelming the scheduler
        sleep 0.5
    done < "${BASE_DIR}/all_jobs.txt"
    
    echo ""
    echo "Submitted ${job_count} jobs"
    echo ""
    echo "Monitor jobs with: squeue -u \$USER"
    echo "Check status: showq -u \$USER"
else
    echo ""
    echo "==============================================================================="
    echo "Jobs Generated (not submitted)"
    echo "==============================================================================="
    echo ""
    echo "To submit all jobs, run:"
    echo "  $0 --submit"
    echo ""
    echo "Or submit individual jobs with:"
    echo "  cd ${BASE_DIR}/<case>/<config>"
    echo "  sbatch job.slurm"
    echo ""
    echo "After jobs complete, analyze with:"
    echo "  cd ${BASE_DIR}"
    echo "  ./analyze_all.sh"
fi

echo ""
echo "==============================================================================="
echo "Directory Structure Created:"
echo "==============================================================================="
tree -L 3 "${BASE_DIR}" 2>/dev/null || find "${BASE_DIR}" -type d | head -20

echo ""
echo "Total jobs generated: $(wc -l < ${BASE_DIR}/all_jobs.txt)"
echo "==============================================================================="
