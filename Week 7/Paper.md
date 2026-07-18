

# Paper: An Analysis of Popular Scientific Programs for Impacts of HPC Scaling and Mathematical Library Usage Using PEAK | Measuring HPC Efficiency with PEAK: How Well Do Your Tools Use HPC Resources? | ...

## Abstract

High Performance Computing (HPC) systems and the science, math, and machine learning programming libraries optimized for those systems are essential for accelerating large-scale scientific research. Maximizing the performance of these libraries is critical for enabling faster scientific discovery. Using the Performance Evaluation and Analysis Kit (PEAK) and usage data gathered from the Texas Advanced Computing Center (TACC), this project profiles several widely utilized science and math toolkits, including ABINIT, DFTB+, and GROMACS, to evaluate how efficiently they utilize standard numerical libraries such as BLAS, LAPACK, and FFTW across the diverse operational contexts common to HPC environments. By employing a cost-adaptive profiling strategy that balances accuracy and overhead trade-offs via dynamic library preloading, the expected outcome is to capture critical performance data points and library invocation frequencies that traditional profilers miss. At the conclusion of testing, the expectation is to identify specific computational bottlenecks and ideal operational conditions to deliver concrete optimization recommendations. This analysis will provide a definitive framework for the future design of high-performance computing infrastructure and tools prioritizing maximum runtime efficiency, ultimately reducing core-hour expenditure and accelerating computational workflows for the broader scientific community.

## Introduction

### Broad Context

- High Performance Computing (HPC) systems are criticl research infrastructure that allows for the large levels of data processing required by modern science.
- Due to the unique architecture of HPC systems, it is imperative for scientific applications to be specifically built such that they take full advantage of the computational resources avavailable on an HPC system.

### Problem Statement

- In order to opimize better for HPC enviroments, many things must be know about a program:
    - What other software and libraries does the program depend on.
    - Where is a majority of compute time spent.
- How different levels and methods of scaling impact the program.
    - What variables impact the programs performance in what way.

### Proposed Solution

- This study aims to get a birds eye view of a number of popular scientific software in order to better understand general trends.
- This study tests the impact of different amounts and methods of scaling on a program, as well as invocation data on popular mathematical libraries such as BLAS, LAPACK, and FFTW via the Performance Evaluation Analysis Kit (PEAK).

### Roadmap

// just explain how to read this paper

## Background / Related Work

// put the obvious here

### PEAK Papers / Repo / Wiki

### BenchPro

## Methodology

### Frontera Top 100

- My mentors provided me a list of the top 100 program names by core hour for the Frontera HPC system as well as a list of programs of importance.
- Using these lists, a master list was made with unactionable program names such as "main" or "out", language interpreters such as python, or differing versions of the same program were filtered, resulting in 67 and counting actionable program names.

### Build Scripts and Modules

- Many of the most used programs had modules available, but many required manual building in which we created custom build scripts which allowed for reproducable program binaries.

### Testing Suite Scripts

- In order to accelerate research, a script was made in order to take a program, test case, and unique constraints and automatically generate jobs for each level of scaling.
- The generated jobs also handled PEAK profiling, timing data, and general logging.

### Test Case

- Due to time contraints, the current phase of the study sticks to one test case per program meant to give a general overview of a typical run.

### Jobs

- Each test case was purpose generated in order to test different conditions and handle data gathering and logging.

### PEAK

- Each scaling study included a job which ran the base case with PEAK, gathering data on library usage and profiling overhead impact.

### Timing Summary

- At the conclusion of a job, data relating to the speed and success of a program was recorded and appended to a central timing table for easy scaling analysis.

### PEAK Results

- PEAK output allows us to get a better idea of the underlying dependencies are utilized and to what extent.

### Visualization

- A python script was used to take in gathered data and present it in intuitive and easy to understand form, allowing for quick interpretation and issue handling.

## Results

### ABINIT

| Job Name | Config | Nodes | Tasks | PEAK? | Elapsed (s) | Exit Code | Job ID |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `abinit_test_n1_nopeak` | `n1_nopeak` | 1 | 1 | No | **119** | 0 | 3294914 |
| `abinit_test_n24_nopeak` | `n24_nopeak` | 1 | 24 | No | **10** | 0 | 3294915 |
| `abinit_test_n48_nopeak` | `n48_nopeak` | 1 | 48 | No | **8** | 0 | 3294916 |
| `abinit_test_N2_nopeak` | `N2_nopeak` | 2 | 96 | No | **6** | 0 | 3294917 |
| `abinit_test_N8_nopeak` | `N8_nopeak` | 8 | 384 | No | **6** | 0 | 3294918 |
| `abinit_test_N16_nopeak` | `N16_nopeak` | 16 | 768 | No | **9** | 0 | 3294919 |
| `abinit_test_n1_peak` | `n1_peak` | 1 | 1 | Yes | **126** | 0 | 3294920 |

| Function | Calls | Total Time (s) | Avg Time / Call (ms) | PEAK Overhead (s) |
| --- | --- | --- | --- | --- |
| `zgemm_` | 207,990 | **4.7613** | 0.0229 | 0.4258 |
| `ddot_` | 216,544 | **0.6383** | 0.0029 | 0.4433 |
| `zcopy_` | 131,022 | **0.6081** | 0.0046 | 0.2682 |
| `dznrm2_` | 116,280 | **0.5958** | 0.0051 | 0.2380 |
| `zdotc_` | 51,588 | **0.1846** | 0.0036 | 0.1056 |

![plot](./plots/abinit_fullPEAK-scaling-07102026-152428_dashboard.png)


### Quantum Expresso

| Job Name | Config | Nodes | Tasks | PEAK? | Elapsed (s) | Exit Code | Job ID |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `qe_tc_n1_nopeak` | `n1_nopeak` | 1 | 1 | No | **636** | 0 | 3306688 |
| `qe_tc_n24_nopeak` | `n24_nopeak` | 1 | 24 | No | **63** | 0 | 3306689 |
| `qe_tc_n48_nopeak` | `n48_nopeak` | 1 | 48 | No | **34** | 0 | 3306690 |
| `qe_tc_N2_nopeak` | `N2_nopeak` | 2 | 96 | No | **28** | 0 | 3306691 |
| `qe_tc_N8_nopeak` | `N8_nopeak` | 8 | 384 | No | **20** | 0 | 3306692 |
| `qe_tc_N16_nopeak` | `N16_nopeak` | 16 | 768 | No | **27** | 0 | 3306693 |
| `qe_tc_n1_peak` | `n1_peak` | 1 | 1 | Yes | **638** | 0 | 3306694 |

| Function | Calls | Total Time (s) | Avg Time / Call (ms) | PEAK Overhead (s) |
| --- | --- | --- | --- | --- |
| `zgemm_` | 144,849 | **166.6082** | 1.1502 | 0.2227 |
| `zhegvx_` | 5,561 | **8.3896** | 1.5087 | 0.0085 |
| `zgemv_` | 1,184 | **3.7863** | 3.1979 | 0.0018 |
| `ddot_` | 57,984 | **0.3923** | 0.0068 | 0.0891 |
| `dcopy_` | 1,926 | **0.3207** | 0.1665 | 0.0030 |

![plot](./plots/qe_fftw_test-scaling-07142026-092819_dashboard.png)

### DFTB+

| Job Name | Config | Nodes | Tasks | PEAK? | Elapsed (s) | Exit Code | Job ID |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `dftb_spinlock_n1_nopeak` | `n1_nopeak` | 1 | 1 | No | **120** | 0 | 3303873 |
| `dftb_spinlock_n24_nopeak` | `n24_nopeak` | 1 | 24 | No | **144** | 0 | 3303874 |
| `dftb_spinlock_n48_nopeak` | `n48_nopeak` | 1 | 48 | No | **220** | 0 | 3303875 |
| `dftb_spinlock_n1_peak` | `n1_peak` | 1 | 1 | Yes | **121** | 0 | 3303879 |
| `dftb_spinlock_N2_nopeak` | `N2_nopeak` | 2 | 96 | No | **2** | 1 | 3303876 |
| `dftb_spinlock_N8_nopeak` | `N8_nopeak` | 8 | 384 | No | **3** | 1 | 3303877 |
| `dftb_spinlock_N16_nopeak` | `N16_nopeak` | 16 | 768 | No | **3** | 1 | 3303878 |

| Function | Calls | Total Time (s) | Avg Time / Call (s) | PEAK Overhead (s) |
| --- | --- | --- | --- | --- |
| `dsyev_` | 4 | **94.1030** | 23.5258 | 0.0000 |
| `dgemm_` | 442 | **10.5098** | 0.0238 | 0.0007 |
| `dsymm_` | 4 | **10.0370** | 2.5092 | 0.0000 |
| `dlarrv_` | 4 | **0.1037** | 0.0259 | 0.0000 |
| `dcopy_` | 34,760 | **0.0280** | 0.0008 | 0.0541 |

![plot](./plots/dftb_new_gen-scaling-07132026-145728_dashboard.png)

### LAMMPS

| Job Name | Config | Nodes | Tasks | PEAK? | Elapsed (s) | Exit Code | Job ID |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `lammps_rhodo_n1_nopeak` | `n1_nopeak` | 1 | 1 | No | **32** | 0 | 3305579 |
| `lammps_rhodo_n24_nopeak` | `n24_nopeak` | 1 | 24 | No | **4** | 0 | 3305580 |
| `lammps_rhodo_n48_nopeak` | `n48_nopeak` | 1 | 48 | No | **4** | 0 | 3305581 |
| `lammps_rhodo_N2_nopeak` | `N2_nopeak` | 2 | 96 | No | **4** | 0 | 3305582 |
| `lammps_rhodo_N8_nopeak` | `N8_nopeak` | 8 | 384 | No | **4** | 0 | 3305583 |
| `lammps_rhodo_N16_nopeak` | `N16_nopeak` | 16 | 768 | No | **8** | 255 | 3305584 |
| `lammps_rhodo_n1_peak` | `n1_peak` | 1 | 1 | Yes | **32** | 0 | 3305585 |

![plot](./plots/lammps_5-scaling-07132026-225745_dashboard.png)

> LAMMPS did not yield PEAK hits

### GROMACS

| Job Name | Config | Nodes | Tasks | PEAK? | Elapsed (s) | Exit Code | Job ID |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `gromacs_benchMEM_n24_nopeak` | `n24_nopeak` | 1 | 24 | No | **213** | 0 | 3295859 |
| `gromacs_benchMEM_n48_nopeak` | `n48_nopeak` | 1 | 48 | No | **125** | 0 | 3295860 |
| `gromacs_benchMEM_n48_peak` | `n48_peak` | 1 | 48 | Yes | **126** | 0 | 3295864 |
| `gromacs_benchMEM_N2_nopeak` | `N2_nopeak` | 2 | 96 | No | **75** | 0 | 3295861 |
| `gromacs_benchMEM_N8_nopeak` | `N8_nopeak` | 8 | 384 | No | **37** | 0 | 3295862 |
| `gromacs_benchMEM_N16_nopeak` | `N16_nopeak` | 16 | 768 | No | **36** | 0 | 3295863 |

![plot](./plots/gromacs_2-scaling-07102026-221528_dashboard.png)

> GROMACS did not yiekd PEAK hits

// SW4 if time

// CESM if time

## Discussion / Analysis

### ABINIT

- ABINIT effectively scaled from 1 to 96 tasks but performs worse when scaled further on this test case.
- As you can see, as more reources are allocated, speedup drops off, at the high end of scaling, it even becomes less efficient.

### Quantum Expresso

- Similiar story to ABINIT

### DFTB+

// figure out why DFTB+ is doing this

### LAMMPS

- LAMMPS seems to limit itself to using only the resources it is optimized for, resulting in a speedup plateau
- Did not produce PEAK hits

### GROMACS

- GROMACS takes great advantage of HPC scaling.
- Did not produce PEAK hits.

// SW4

// CESM

## Conclusion / Future Work

---

## Notes

- Amdahls Law
- 4 - 8 pages for paper
