#!/bin/bash
#===============================================================================
# LAMMPS idev test script
# Run this manually inside an idev session to confirm LAMMPS + PEAK work
# before generating the full job matrix.
#
# Usage: bash idev_test_lammps.sh
#===============================================================================

ml reset
ml intel/24.0
ml impi/21.11
ml lammps

PEAK_LIB="/scratch/11603/crw405/peak/peak/lib/libpeak.so"
RHODO_DIR="/work2/05392/cylu/share/reu_2026/2.project/2.examples/lammps/rhodo"
OUTDIR="/scratch/11603/crw405/REU-HPC-Research/research_data/lammps/idev/lammps_idev_test"
mkdir -p ${OUTDIR}

echo "======================================================================"
echo "Step 1: Confirm lmp binary is in PATH"
echo "======================================================================"
which lmp_stampede
lmp_stampede -h 2>&1 | head -5

echo ""
echo "======================================================================"
echo "Step 2: Test run WITHOUT PEAK (4 tasks, 100 steps)"
echo "======================================================================"
cd ${RHODO_DIR}
time ibrun -np 4 lmp_stampede -in in.rhodo.scaled > ${OUTDIR}/lammps_nopeak.stdout 2>&1
echo "Exit code: $?"
echo "Output: ${OUTDIR}/lammps_nopeak.stdout"

echo ""
echo "======================================================================"
echo "Step 3: Check LAMMPS shared library dependencies (for PEAK compatibility)"
echo "======================================================================"
ldd $(which lmp_stampede) | grep -i "blas\|lapack\|fftw\|mkl"

echo ""
echo "======================================================================"
echo "Step 4: Test run WITH PEAK (4 tasks, 100 steps)"
echo "======================================================================"
cd ${RHODO_DIR}
PEAK_TARGET_GROUP=BLAS,LAPACK,FFTW\
PEAK_VERBOSITY=debug \
PEAK_STATSLOG_PATH=${OUTDIR}/peak_stats \
PEAK_OUTPUT_AGGREGATION=local \
PEAK_TEXT_OUTPUT=1 \
LD_PRELOAD=${PEAK_LIB} \
ibrun -np 4 lmp_stampede -in in.rhodo.scaled > ${OUTDIR}/lammps_peak.stdout 2>${OUTDIR}/lammps_peak.stderr
echo "Exit code: $?"

echo ""
echo "======================================================================"
echo "Step 5: Check for PEAK output files"
echo "======================================================================"
ls -lh ${OUTDIR}/peak_stats*.csv 2>/dev/null || echo "No PEAK CSV files found"
echo ""
echo "PEAK stderr (first 30 lines):"
head -30 ${OUTDIR}/lammps_peak.stderr
