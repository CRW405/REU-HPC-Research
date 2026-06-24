#!/bin/bash
#===============================================================================
# PEAK Profiling Run Script - General Template
# Usage: Modify the CONFIGURATION section for each application
#===============================================================================

#===============================================================================
# CONFIGURATION - Modify this section for each application
#===============================================================================

# Application Identification
APP_NAME="abinit"                    # Name for output files
# APP_VERSION="10.4.7"                 # Optional version tracking

# Module Setup
MODULES_TO_LOAD=(
    "intel"
    "impi"
    "netcdf"
)

# Application Paths
APP_BINARY="../install/bin/abinit"
APP_INPUT="../abinit-10.4.7/tests/v1/Input/t00.abi"
APP_WORKDIR="."                      # Working directory for run

# Application-specific Environment Variables
declare -A APP_ENV=(
    ["ABI_PSPDIR"]="../abinit-10.4.7/tests/Pspdir/"
)

# Library Paths (add all needed library directories)
CUSTOM_LIB_PATHS=(
    "/scratch/11603/crw405/2.project/1.build_scripts/2.apps/abinit/install/lib"
    "/opt/apps/intel24/netcdf/4.9.2/lib64"
)

# MPI/Runtime Settings
MPI_WORKAROUNDS=(
    ["I_MPI_SHM"]="by_node"          # Intel MPI shared memory mode
    ["FI_PROVIDER"]="tcp"            # Fabric provider
)

# PEAK Configuration
PEAK_LIB_PATH="/scratch/11603/crw405/2.project/1.build_scripts/1.peak/peak/lib/libpeak.so"
PEAK_TARGET_GROUPS="BLAS,LAPACK,FFTW"    # Comma-separated: BLAS,LAPACK,FFTW,PBLAS,ScaLAPACK
PEAK_MEMORY_PROFILE="TRUE"               # TRUE or FALSE
PEAK_MEMORY_TRACK_ALL="TRUE"             # TRUE or FALSE
PEAK_MEMLOG_CHUNK_EVENTS=10000000        # Memory log chunk size

# Output Settings
OUTPUT_PREFIX="peak"                     # Prefix for PEAK output files
CLEAN_PREVIOUS="TRUE"                    # Clean previous outputs before run

# Message Prefix for Logging
pre="[${APP_NAME}]: "

#===============================================================================
# END CONFIGURATION
#===============================================================================


#===============================================================================
# SCRIPT EXECUTION - Generally no need to modify below this line
#===============================================================================

start_time=$SECONDS

echo "==============================================================================="
echo "PEAK Profiling Run - ${APP_NAME}"
echo "==============================================================================="

#-------------------------------------------------------------------------------
# Clean previous outputs
#-------------------------------------------------------------------------------
if [[ "${CLEAN_PREVIOUS}" == "TRUE" ]]; then
    echo "${pre}Cleaning previous outputs..."
    rm -f ${OUTPUT_PREFIX}_* ${APP_NAME}.stdout ${APP_NAME}.stderr
    # Add any application-specific cleanup patterns
    rm -f ./t00* abinit.* 2>/dev/null || true
fi

#-------------------------------------------------------------------------------
# Load modules
#-------------------------------------------------------------------------------
echo "${pre}Loading modules..."
ml reset
for module in "${MODULES_TO_LOAD[@]}"; do
    echo "${pre}  Loading: ${module}"
    ml ${module}
done

#-------------------------------------------------------------------------------
# Setup library paths
#-------------------------------------------------------------------------------
echo "${pre}Setting up library paths..."
for lib_path in "${CUSTOM_LIB_PATHS[@]}"; do
    export LD_LIBRARY_PATH="${lib_path}:${LD_LIBRARY_PATH}"
done
echo "${pre}  LD_LIBRARY_PATH updated"

#-------------------------------------------------------------------------------
# Setup application environment
#-------------------------------------------------------------------------------
echo "${pre}Setting application-specific environment..."
for key in "${!APP_ENV[@]}"; do
    export ${key}="${APP_ENV[${key}]}"
    echo "${pre}  ${key}=${APP_ENV[${key}]}"
done

#-------------------------------------------------------------------------------
# Setup MPI workarounds
#-------------------------------------------------------------------------------
if [ ${#MPI_WORKAROUNDS[@]} -gt 0 ]; then
    echo "${pre}Applying MPI/runtime workarounds..."
    for key in "${!MPI_WORKAROUNDS[@]}"; do
        export ${key}="${MPI_WORKAROUNDS[${key}]}"
        echo "${pre}  ${key}=${MPI_WORKAROUNDS[${key}]}"
    done
fi

#-------------------------------------------------------------------------------
# Setup PEAK profiling
#-------------------------------------------------------------------------------
echo "${pre}Configuring PEAK profiling..."

# Check if PEAK library exists
if [ ! -f "${PEAK_LIB_PATH}" ]; then
    echo "${pre}ERROR: PEAK library not found at ${PEAK_LIB_PATH}"
    exit 1
fi

# PEAK output paths
export PEAK_STATSLOG_PATH="${OUTPUT_PREFIX}_stats"
export PEAK_MEMLOG_PATH="${OUTPUT_PREFIX}_mem"

# PEAK profiling options
export PEAK_TARGET_GROUP="${PEAK_TARGET_GROUPS}"
export PEAK_MEMORY_PROFILE="${PEAK_MEMORY_PROFILE}"
export PEAK_MEMORY_TRACK_ALL="${PEAK_MEMORY_TRACK_ALL}"
export PEAK_MEMLOG_CHUNK_EVENTS="${PEAK_MEMLOG_CHUNK_EVENTS}"

# Force Intel MPI to handle the preload on remote nodes
export I_MPI_LD_PRELOAD="${PEAK_LIB_PATH}"
export LD_PRELOAD="${PEAK_LIB_PATH}"

echo "${pre}  PEAK_TARGET_GROUP=${PEAK_TARGET_GROUPS}"
echo "${pre}  PEAK_MEMORY_PROFILE=${PEAK_MEMORY_PROFILE}"
echo "${pre}  Stats output: ${PEAK_STATSLOG_PATH}-pXXXXX.csv"
echo "${pre}  Memory output: ${PEAK_MEMLOG_PATH}-pXXXXX.csv"

#-------------------------------------------------------------------------------
# Change to working directory
#-------------------------------------------------------------------------------
if [ "${APP_WORKDIR}" != "." ]; then
    echo "${pre}Changing to working directory: ${APP_WORKDIR}"
    cd "${APP_WORKDIR}" || exit 1
fi

#-------------------------------------------------------------------------------
# Run application with PEAK profiling
#-------------------------------------------------------------------------------
echo "==============================================================================="
echo "${pre}Starting profiled run..."
echo "==============================================================================="

${APP_BINARY} ${APP_INPUT} > ${APP_NAME}.stdout 2> ${APP_NAME}.stderr

exit_code=$?

#-------------------------------------------------------------------------------
# Report results
#-------------------------------------------------------------------------------
end_time=$SECONDS
elapsed=$((end_time - start_time))

echo "==============================================================================="
echo "${pre}Run completed"
echo "==============================================================================="
echo "${pre}Exit code: ${exit_code}"
echo "${pre}Elapsed time: ${elapsed} seconds"
echo "${pre}Standard output: ${APP_NAME}.stdout"
echo "${pre}Standard error: ${APP_NAME}.stderr"
echo ""
echo "${pre}PEAK outputs:"
ls -lh ${OUTPUT_PREFIX}_*.csv 2>/dev/null || echo "${pre}  No PEAK CSV files found (check stderr)"
echo "==============================================================================="

exit ${exit_code}
