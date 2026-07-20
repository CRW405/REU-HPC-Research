
# Poster:

## Header

### Title

#### Possible Titles

- Measuring HPC Efficiency with PEAK: How Well Do Your Tools Use HPC Resources?
- Profiling Scaling and Library Usage in Popular HPC Applications with PEAK

### Acknowledgments

- TACC
- NSF // include award number
- Frontera
- Stampede3
- UT
- OCU

## Section 1
// Intro

### Background Information

- High Performance Computing (HPC) systems are critical research infrastructure that allows for the large levels of data processing required by modern science.
- Due to the unique architecture of HPC systems, it is imperative for scientific applications to be specifically built such that they take full advantage of the computational resources available on an HPC system.
- The Performance Evaluation Analysis Kit (PEAK) is a tool that allows the user to analyze function calls, where compute time is spent, and how the targetted program utilizes popular mathematical libraries such as BLAS, LAPACK, and FFTW.
- The goal of this study is to analyze popular scientific software and benchmark their performance under different scaling conditions, as well as see how the program relies on popular mathematical libraries via PEAK.

### Problem Statement

- In order to optimize better for HPC environments, many things must be known about a program:
    - What other software and libraries the program depends on.
    - Where a majority of compute time is spent.
    - How different levels and methods of scaling impact the program.
    - What variables impact the programs performance in what way.

### Research Objectives

- This study aims to get a birds eye view of a number of popular scientific software in order to better understand general trends.
- This study tests the impact of different amounts and methods of scaling on a program, as well as reliance on popular mathematical libraries such as BLAS, LAPACK, and FFTW via PEAK.

### Methodology

- Using a list of the most used programs on the Frontera supercomputer, we chose programs of interest to analyze.
- For each program chosen, a corresponding test case was also chosen.
- An automated testing suite would generate a series of jobs that would run the program under different scaling conditions.
- An extra job would be generated to run the program under PEAK.
- All jobs were run on the Stampede3 HPC system.
- After all jobs were completed, timing data and the PEAK results would be collected and analyzed.

## Section 2
// Main content, graphs, etc.
// ensure plots DPI >= 150

### Results Overview

| Program | Best Scaling | Dominant Function (by time) |
| --- | --- | --- |
| ABINIT | 384 Tasks (8 Nodes) | `zgemm_` |
| Quantum Expresso | 384 Tasks (8 Nodes) | `zgemm_` |
| LAMMPS | 24 Tasks (1 Node) | N/A |
| GROMACS | 768 Tasks (16 Nodes) | N/A |
| DFTB+ | 1 Task (1 Node) | `dsyev_` |

### ABINIT

![plot](./plots/abinit_fullPEAK-scaling-07102026-152428_dashboard.png)

### QE // candidate for cutting if not enough space

![plot](./plots/qe_fftw_test-scaling-07142026-092819_dashboard.png)

### LAMMPS // candidate for cutting if not enough space

![plot](./plots/lammps_5-scaling-07132026-225745_dashboard.png)

### GROMACS

![plot](./plots/gromacs_2-scaling-07102026-221528_dashboard.png)

### DFTB+

![plot](./plots/dftb_new_gen-scaling-07132026-145728_dashboard.png)

### Takeaways / Notes / Observations

- `zgemm_` is a BLAS function that performs complex matrix multiplications.
- `dsyev_` is a LAPACK function for computing eigenvalues.
- ABINIT scaled effectively from 1 → 384 tasks (119s → 6s), but got slightly worse at 768 tasks (9s). This is most likely due to inter-node communication overhead.
- QE is a similar story: scales well up to 384 tasks (636s → 20s), then degrades at 768 tasks (27s).
- LAMMPS plateaus fast (32s → 4s by 24 tasks) and stays flat through 384 tasks. The program or test case seems to impose a hard limit on what resources the program allows itself to attempt to use.
- GROMACS scaled the best out of the group, successfully taking advantage of all the resources we gave it.
- LAMMPS and GROMACS yield no BLAS/LAPACK/FFTW hits from PEAK.
- DFTB+ performed worse with more resources and outright crashed when multiple nodes were introduced.

## Section 3
// future work, references, QR code, contact info, etc

### Limitations

- This study was very limited on time, so a breadth-first approach was taken. With more time, profiling issues can be solved and more permutations can be tested, giving us deeper insights.
- For the programs that yielded no PEAK results, it is likely due to how they were compiled. Rebuilding the programs under different configurations may yield PEAK results.

### Future Work

- Diagnose why LAMMPS/GROMACS show no BLAS/LAPACK/FFTW PEAK hits.
- Diagnose the causes of DFTB+ results.
- Add more test cases per program.
- Continue to build out a list of actionable programs.

### QR Code of references, suggestions, and contact info

// TODO: create a github repo landing place, fill with info and links, create google forms suggestion dropbox, and point a QR code at it
