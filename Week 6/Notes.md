
# Notes

## ABINIT Study

Got data, but room for improvement

The job finishes in 4-7 seconds on anything above 1 core. This means ABINIT is parallelizing so efficiently that the actual compute is done almost instantly, and what you're measuring at higher core counts is just MPI startup and coordination overhead — not real scaling behavior.
The n1 → n24 drop from 21s to 5s is real and shows good parallelism, but beyond n24 there's nothing left to parallelize — the problem is simply too small for those core counts.
You need a bigger problem. The options in order of ease:
1. Increase ngkpt in the input file — change 8 8 8 to 12 12 12. This roughly triples the k-point workload and gives more to distribute across ranks.
2. Increase ecut — change from 30 to 50. More plane waves = more FFT work per k-point.
3. Use a larger unit cell — instead of 2-atom silicon, use an 8-atom or 16-atom supercell. This is the most effective way to create a problem that scales well to hundreds of cores.
The target is n1 taking 2-5 minutes, which would make the scaling study actually meaningful. Try bumping ngkpt to 12 12 12 and ecut to 50 first — that's a one-line change in the input file and should significantly increase runtime without changing anything else.

## GROMACS

mpirun -np 24 gmx_mpi mdrun -s benchMEM.tpr -nsteps 10000 -resethway -noconfout -ntomp 1
/work2/05392/cylu/share/reu_2026/2.project/2.examples/gromacs/benchMEM.tpr
