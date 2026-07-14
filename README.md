
# REU HPC Research — PEAK Profiling of Frontera Applications

> Mobile repo for easier research workflow on both my local machine and TACC HPC systems.

## Abstract

High Performance Computing (HPC) systems and the science, math, and machine learning programming libraries optimized for those systems are essential for accelerating large-scale scientific research. Maximizing the performance of these libraries is critical for enabling faster scientific discovery. Using the Performance Evaluation and Analysis Kit (PEAK) and usage data gathered from the Texas Advanced Computing Center (TACC), this project profiles several widely utilized science and math toolkits, including ABINIT, DFTB+, and GROMACS, to evaluate how efficiently they utilize standard numerical libraries such as BLAS, LAPACK, and FFTW across the diverse operational contexts common to HPC environments. By employing a cost-adaptive profiling strategy that balances accuracy and overhead trade-offs via dynamic library preloading, the expected outcome is to capture critical performance data points and library invocation frequencies that traditional profilers miss. At the conclusion of testing, the expectation is to identify specific computational bottlenecks and ideal operational conditions to deliver concrete optimization recommendations. This analysis will provide a definitive framework for the future design of high-performance computing infrastructure and tools prioritizing maximum runtime efficiency, ultimately reducing core-hour expenditure and accelerating computational workflows for the broader scientific community.

## Overview

This is an REU (Research Experience for Undergraduates) project at TACC focused on profiling HPC applications using **PEAK** (Performance Evaluation Analysis Kit). The goal is to characterize which BLAS/LAPACK/FFTW/ScaLAPACK library functions are called by the top Frontera jobs, and how they scale across MPI task counts.

## Weekly Reports

| Week | Focus |
|---|---|
| [Week 1](Week%201/) | TACC orientation, PEAK theory, SLURM basics, LAMMPS scaling |
| [Week 2](Week%202/) | PEAK installation on Frontera, abstract drafting |
| [Week 3](Week%203/) | First ABINIT profile, top-100 app filtering (72 candidates) |
| [Week 4](Week%204/) | Job generation pipeline, array converter, 110 ABINIT jobs |
| [Week 5](Week%205/) | Programs.csv tracker (67 apps), overhead analysis |
| [Week 6](Week%206/) | Full profiling results for 5 applications |

## Applications Tracked

67 programs from the Frontera top-100 are tracked in [`Week 5/Programs.csv`](Week%205/Programs.csv), documenting module availability, script status, test cases, and PEAK profiling results. See the CSV for the full list.
