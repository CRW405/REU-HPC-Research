#!/bin/bash
#===============================================================================
# DFTB+ idev test script
#===============================================================================

ml reset
ml intel
ml impi

# 1. Path setups
DFTB_BUILD_PATH="/scratch/11603/crw405/2.project/1.build_scripts/2.apps/dftb+/dftbplus-25.1"
# Fixed to target the actual binary location consistently
DFTB_BIN="${DFTB_BUILD_PATH}/bin/dftb+"

PEAK_LIB="/scratch/11603/crw405/peak/peak/lib/libpeak.so"
EXAMPLE_DIR="/work2/05392/cylu/share/reu_2026/2.project/2.examples/dftb+/spinlock"

OUTDIR="$(pwd)/dftb_idev_test"
RUN_DIR="$(pwd)/dftb_run_workspace"
mkdir -p ${OUTDIR}
mkdir -p ${RUN_DIR}

# 2. Stage files into our writable workspace to avoid read-only aborts
echo "==> Staging input files to local workspace..."
cp -r ${EXAMPLE_DIR}/* ${RUN_DIR}/
cd ${RUN_DIR}

echo "======================================================================"
echo "Step 1: Confirm dftb+ binary exists"
echo "======================================================================"
ls -lh ${DFTB_BIN}

echo ""
echo "======================================================================"
echo "Step 2: Check shared library dependencies"
echo "======================================================================"
ldd ${DFTB_BIN} | grep -i "blas\|lapack\|fftw\|mkl"

echo ""
echo "======================================================================"
echo "Step 3: Test run WITHOUT PEAK (4 tasks)"
echo "======================================================================"
time ibrun -np 4 ${DFTB_BIN} > ${OUTDIR}/dftb_nopeak.stdout 2>&1
echo "Exit code: $?"
tail -10 ${OUTDIR}/dftb_nopeak.stdout

echo ""
echo "======================================================================"
echo "Step 4: Test run WITH PEAK (4 tasks)"
echo "======================================================================"
# Isolating to BLAS,LAPACK to ensure clean hooks past the optimized FFTW wrappers
PEAK_TARGET_GROUP=BLAS,LAPACK \
PEAK_VERBOSITY=debug \
PEAK_STATSLOG_PATH=${OUTDIR}/peak_stats \
PEAK_OUTPUT_AGGREGATION=local \
PEAK_TEXT_OUTPUT=1 \
LD_PRELOAD=${PEAK_LIB} \
ibrun -np 4 ${DFTB_BIN} > ${OUTDIR}/dftb_peak.stdout 2>${OUTDIR}/dftb_peak.stderr
echo "Exit code: $?"

echo ""
echo "======================================================================"
echo "Step 5: Check for PEAK output"
echo "======================================================================"
ls -lh ${OUTDIR}/peak_stats*.csv 2>/dev/null || echo "No PEAK CSV files found"
echo ""
echo "PEAK stderr (first 30 lines):"
head -30 ${OUTDIR}/dftb_peak.stderr
