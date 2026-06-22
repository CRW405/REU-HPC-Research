
# Report

## Ordered grep:

### Case 1

case1/n1/log.lammps:Performance: 1681.917 tau/day, 3.893 timesteps/s, 1.947 Matom-step/s
case1/n2/log.lammps:Performance: 3381.467 tau/day, 7.827 timesteps/s, 3.914 Matom-step/s
case1/n4/log.lammps:Performance: 6646.325 tau/day, 15.385 timesteps/s, 7.693 Matom-step/s
case1/n8/log.lammps:Performance: 13099.915 tau/day, 30.324 timesteps/s, 15.162 Matom-step/s
case1/n16/log.lammps:Performance: 25849.479 tau/day, 59.837 timesteps/s, 29.918 Matom-step/s
case1/n32/log.lammps:Performance: 51646.119 tau/day, 119.551 timesteps/s, 59.776 Matom-step/s
case1/n56/log.lammps:Performance: 84511.712 tau/day, 195.629 timesteps/s, 97.814 Matom-step/s

### Case 1

case2/N1/log.lammps:Performance: 85951.821 tau/day, 198.963 timesteps/s, 99.481 Matom-step/s
case2/N2/log.lammps:Performance: 173067.562 tau/day, 400.619 timesteps/s, 200.310 Matom-step/s
case2/N4/log.lammps:Performance: 326564.616 tau/day, 755.937 timesteps/s, 377.968 Matom-step/s
case2/N8/log.lammps:Performance: 560079.727 tau/day, 1296.481 timesteps/s, 648.240 Matom-step/
case2/N16/log.lammps:Performance: 1033565.524 tau/day, 2392.513 timesteps/s, 1.196 Gatom-step/s

## Results

| Nodes (N) | MPI tasks (n) | Performance(steps/sec) | Parallel efficiency |
| :--- | :--- | :--- | :--- |
| 1 | 1 |    3.893    | 1.0 |
| 1 | 2 |    7.827    | 1.0052658618032366 |
| 1 | 4 |    15.385   | 0.9879912663755459 |
| 1 | 8 |    30.324   |0.9736706909838172|
| 1 | 16 |   59.837   |0.9606505265861804|
| 1 | 32 |   119.551  |0.9596631774980735|
| 1 | 56 |   195.629  |0.8973478037503211|
| 1 | 56 |   198.963  |0.9126408205203479|
| 2 | 112 |  400.619  |0.9188171993688307|
| 4 | 224 |  755.937  |0.866868417672746|
| 8 | 448 |  1296.481 |0.7433677892554401|
| 16 | 896 | 2392.513 |0.6859017214964588|

Performance gained by adding MPI tasks:
1:  +% 0.0 (baseline)
2:  +% 101.05317236064732
4:  +% 96.56317874025808
8:  +% 97.10107247318818
16: +% 97.32555071890252
32: +% 99.79444156625497
56: +% 63.636439678463574

Performance gained by adding nodes:
1:  +% 0.0 (baseline)
2:  +% 101.35351799078222
4:  +% 88.69224874506699
8:  +% 71.50648797452698
16: +% 84.53899440099778

## Questions

### Does the performance increase linearly with the number of MPI tasks?

No, as more MPI tasks are added, more overhead is introduced from coordinating them which leads to dimishing returns.

### At what point does the speedup begin to slow down?

From 1 mpi to 32 mpi on a single node, the performance almost doubles.
After 56 mpi, performance increase begins to decrease

Doubling from 1 node to 2, leads to almost double performance, but decreased gains at 4 nodes

### Is the multi-node scaling better or worse than the single-node scaling?

While node scaling leads to more performance gain, MPI scaling preserves parallel efficiency better.

### What might limit the scaling performance?

The communication between MPI Tasks seems to be less overhead than communication between different nodes.
