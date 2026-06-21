# Parallel Scaling Test with LAMMPS on TACC Frontera

This exercise introduces how to run a basic parallel scaling test using the

LAMMPS Molecular Dynamics Simulator on TACC Frontera.

The goal is to understand how application performance changes as we increase

the number of MPI tasks and compute nodes.

## References

- TACC Frontera user guide:  

  https://docs.tacc.utexas.edu/hpc/frontera/

- SLURM job script examples:  

  https://docs.tacc.utexas.edu/hpc/frontera/#scripts

- LAMMPS Molecular Dynamics Simulator:  

  https://www.lammps.org/

## Files

The test uses the following files:

job.sub: SLURM job submission script

in.lj: LAMMPS input file

log.lammps: LAMMPS output log file generated after each run

## Objective

Run LAMMPS with different numbers of MPI tasks and collect the reported

performance.

In the LAMMPS output file, look for a line similar to:

Performance: ...., xxxx timesteps/s, ....

------------------------------------------------------------------

# Case 1: Single-Node Scaling Test

In this case, all runs are performed on one Frontera node.

Set: 
    N = 1, where N is the number of compute nodes.

Test the following numbers of MPI tasks:

    n = 1, 2, 4, 8, 16, 32, 56

where n is the total number of MPI tasks.

For each run:

1. Modify the SLURM job script job.sub.
2. Submit the job.
3. Wait for the job to finish.
4. Open log.lammps.
5. Record the reported performance in timesteps/second.

------------------------------------------------------------------

# Case 2: Multi-Node Scaling Test

In this case, each Frontera node uses 56 MPI tasks.

Run the following tests:

N =  1, n =  56
N =  2, n = 112
N =  4, n = 224
N =  8, n = 448
N = 16, n = 896

For each run:

1. Modify the number of nodes in job.sub.
2. Modify the total number of MPI tasks if needed.
3. Submit the job.
4. Wait for the job to finish.
5. Open log.lammps.
6. Record the reported performance in timesteps/second.

------------------------------------------------------------------

Use the n = 1 run as the baseline.

The speedup is: 
    Speedup(n) = Performance(n) / Performance(1)

The parallel efficiency is: 
    Parallel efficiency(n) = Speedup(n) / n 

or equivalently:
    Parallel efficiency(n) = Performance(n) / Performance(1) / n 

Summarize the result in a Table

"Nodes (N)"  "MPI tasks (n)"  "Performance(steps/sec)"  "Parallel efficiency"

    1              1                xxxxxxx                      1
    1              2                xxxxxxx                      0.99xxx
                                      ...
------------------------------------------------------------------

Questions:

* Does the performance increase linearly with the number of MPI tasks?
* At what point does the speedup begin to slow down?
* Is the multi-node scaling better or worse than the single-node scaling?
* What might limit the scaling performance?

