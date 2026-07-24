#!/bin/bash
#===============================================================================
# QE idev test script
# Run this manually inside an idev session to confirm QE + PEAK work
# before generating the full job matrix.
#
# Usage: bash test.sh
#===============================================================================

ml reset
ml intel
ml impi
ml hdf5

QE_BUILD_PATH="/scratch/11603/crw405/build_scripts/qe/q-e-qe-7.5"
PEAK_LIB="/scratch/11603/crw405/peak/peak/lib/libpeak.so"
INPUT="/scratch/11603/crw405/build_scripts/qe/q-e-qe-7.5/test-suite/pw_scf/scf.in"

# Fixed to use the working pseudo path from your batch template
PSEUDO_DIR="/scratch/11603/crw405/build_scripts/qe/q-e-qe-7.5/pseudo"
OUTDIR="./qe_idev_test"
mkdir -p ${OUTDIR}

echo "======================================================================"
echo "Step 1: Confirm pw.x binary exists"
echo "======================================================================"
ls -lh ${QE_BUILD_PATH}/bin/pw.x

echo ""
echo "======================================================================"
echo "Step 2: Check shared library dependencies (for PEAK compatibility)"
echo "======================================================================"
ldd ${QE_BUILD_PATH}/bin/pw.x | grep -i "blas\|lapack\|fftw\|mkl"

echo ""
echo "======================================================================"
echo "Step 3: Test run WITHOUT PEAK (4 tasks)"
echo "======================================================================"
export ESPRESSO_PSEUDO=${PSEUDO_DIR}
# Changed from -in flag to standard input redirection (<) using ibrun
time ibrun -np 4 ${QE_BUILD_PATH}/bin/pw.x < ${INPUT} > ${OUTDIR}/qe_nopeak.stdout 2>&1
echo "Exit code: $?"
tail -5 ${OUTDIR}/qe_nopeak.stdout

echo ""
echo "======================================================================"
echo "Step 4: Test run WITH PEAK (4 tasks)"
echo "======================================================================"
export ESPRESSO_PSEUDO=${PSEUDO_DIR}
PEAK_TARGET_GROUP=BLAS,LAPACK \
PEAK_VERBOSITY=debug \
PEAK_STATSLOG_PATH=${OUTDIR}/peak_stats \
PEAK_OUTPUT_AGGREGATION=local \
PEAK_TEXT_OUTPUT=1 \
LD_PRELOAD=${PEAK_LIB} \
ibrun -np 4 ${QE_BUILD_PATH}/bin/pw.x < ${INPUT} > ${OUTDIR}/qe_peak.stdout 2>${OUTDIR}/qe_peak.stderr
echo "Exit code: $?"

echo ""
echo "======================================================================"
echo "Step 5: Check for PEAK output"
echo "======================================================================"
ls -lh ${OUTDIR}/peak_stats*.csv 2>/dev/null || echo "No PEAK CSV files found"
echo ""
echo "PEAK stderr (first 30 lines):"
head -30 ${OUTDIR}/qe_peak.stderr
