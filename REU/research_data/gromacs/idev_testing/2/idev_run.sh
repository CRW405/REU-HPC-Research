PEAK_TARGET_GROUP=BLAS,LAPACK,FFTW,PBLAS,ScaLAPACK \
PEAK_VERBOSITY=debug \
PEAK_STATSLOG_PATH=./peak_stats \
LD_PRELOAD=/scratch/11603/crw405/peak/peak/lib/libpeak.so \
PEAK_TEXT_OUTPUT=1 \
mpirun -np 1 /scratch/11603/crw405/2.project/1.build_scripts/2.apps/gromacs/gromacs_2026.2/bin/gmx_mpi mdrun \
    -s /work2/05392/cylu/share/reu_2026/2.project/2.examples/gromacs/benchMEM.tpr \
    -deffnm md_test -nsteps 100 -ntomp 1 -noconfout 2>&1 | grep -i "peak\|attach\|target\|found"
