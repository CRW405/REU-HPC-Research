
# Feedback

## LM

```
notes
as someone who kinda understand your research please explain the following in your poster or research because this is very TACC heavy things that I don't think some people will understand if they dont know how HPC works

like the first title better Measuring HPC Efficiency with PEAK: How Well Do Your Tools Use HPC Resources?

- I got lost with the abbreviations for BLAS, LAPACK, and FFTW. Consider telling us what it stands for.
- I know what scaling means but explain to your audience what you mean by scaling.
- for methodology what are we testing for exactly? how long it takes to compute? or what slows down computation?
- what do you mean by a job
- what is a node?
```

## Sonnie

```
Notes: Great condensed HPC explanation.
“Built such that they take full advantage of”- wordy: would revisit
“HPC systems are built from many networked computers called….” - would move up a line: first explain what HPCs are, then explain program performance “issue” : maybe follow the guideline of HPC explanation, What issues arise from their usage, What is in place to combat that (PEAK), then goals
“Analyze popular scientific software…..”, be more specific: WHO is using this software and for what?
“Different scaling conditions (running…..” , remove parenthetical explanation: possibly move to methodology?
Instead of “problem statement”, maybe consider a different title like “Acceptable thresholds” or something more creative like “What Makes a “good” HPC program?”. Also, this should be after the research objectives
“Research Objectives”: this first sentence is redundant, we SHOULD already know that “this study surveys a number of popular ………” and tbh I think the rest is redundant also and is already mentioned in background information. Either consider removing it from background info and or remove research objectives
“Methodology:”, starts to become repetitive also, you shouldn’t be mentioning any sort of explanation at this point. Consider also breaking this up into condensed bulletpoints that aren’t sentences. Also remove “jobs” explanation: I think that is self-explanatory enough of a word imo
Limitations: I would remove note on limited time OR explain differently like “To expedite process…..”
```

## William

``` William's_Feedback(Somewhat_Adressed)
first bullet point not needed unless you can expand on it that differs from the second
> "Research Objectives"

What test cases? (Bullet point 3)

like you can write something like  "In various cases we implement X to see Y, and how Y works", Sometime Y is not achieveable so you can write "Instead it gave us Z"
```

// mentor
- more about build / install
- test cases
- mention ai use

// me
- mention PEAK beta testing
- try ml example pyhton

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

- High Performance Computing (HPC) systems are critical research infrastructure that allow for the large levels of data processing required by modern science. They are built from many networked computers called nodes, each with dozens of CPU cores.
- Because of this architecture, scientific applications must be specifically designed to take advantage of the resources available across nodes and cores, or performance suffers.
- The Performance Evaluation Analysis Kit (PEAK) is a tool that allows the user to analyze function calls, where compute time is spent, and how the targeted program utilizes popular mathematical libraries such as BLAS (Basic Linear Algebra Subprograms), LAPACK (Linear Algebra PACKage), and FFTW (Fastest Fourier Transform in the West).
- The goal of this study is to analyze popular scientific software used by researchers on the Frontera supercomputer for materials science, chemistry, and molecular simulation, benchmarking its performance under different scaling conditions and its reliance on popular mathematical libraries via PEAK.

### Problem Statement

- In order to optimize better for HPC environments, many things must be known about a program:
    - What other software and libraries the program depends on.
    - Where a majority of compute time is spent.
    - How different levels and methods of scaling impact the program.
    - What variables impact the program's performance in what way.

### Methodology

- Programs selected from Frontera's most-used software list.
- One representative test case chosen per program.
- Automated scripts generate scaling jobs, plus one PEAK-enabled job per program.
- Jobs run on the Stampede3 HPC system.
- Timing and PEAK data collected for analysis.

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

*Simulates how electrons and atoms behave in materials, using quantum mechanics to predict a material's structure, energy, and properties.*

![plot](./plots/abinit_fullPEAK-scaling-07102026-152428_dashboard.png)

### QE // candidate for cutting if not enough space

*Another quantum-mechanical materials simulation package, solving the same kind of problem as ABINIT with a different underlying computational method.*

![plot](./plots/qe_fftw_test-scaling-07142026-092819_dashboard.png)

### LAMMPS // candidate for cutting if not enough space

*Simulates how large numbers of atoms and molecules move and interact over time (molecular dynamics), commonly used to study materials at the atomic scale.*

![plot](./plots/lammps_5-scaling-07132026-225745_dashboard.png)

### GROMACS

*Simulates the motion and interactions of biomolecules like proteins and lipids, widely used to study biological and chemical processes.*

![plot](./plots/gromacs_2-scaling-07102026-221528_dashboard.png)

### DFTB+

*A faster, approximate alternative to full quantum-mechanical simulation, trading some accuracy for greatly reduced compute time.*

![plot](./plots/dftb_new_gen-scaling-07132026-145728_dashboard.png)

### Takeaways / Notes / Observations

- ABINIT scaled effectively from 1 → 384 tasks (119s → 6s), but got slightly worse at 768 tasks (9s). This is most likely due to inter-node communication overhead.
- QE is a similar story: scales well up to 384 tasks (636s → 20s), then degrades at 768 tasks (27s).
- LAMMPS plateaus fast (32s → 4s by 24 tasks) and stays flat through 384 tasks. The program or test case seems to impose a hard limit on what resources the program allows itself to attempt to use.
- GROMACS scaled the best out of the group, successfully taking advantage of all the resources we gave it.
- LAMMPS and GROMACS yield no BLAS/LAPACK/FFTW hits from PEAK.
- DFTB+ performed worse with more resources and outright crashed when multiple nodes were introduced.

## Section 3
// future work, references, QR code, contact info, etc

### Limitations

- To cover a broad survey of Frontera's most-used programs, a breadth-first approach was taken over deep per-program investigation, leaving room to resolve profiling issues and test more permutations for deeper insight.
- For the programs that yielded no PEAK results, it is likely due to how they were compiled. Rebuilding the programs under different configurations may yield PEAK results.

### Future Work

- Diagnose why LAMMPS/GROMACS show no BLAS/LAPACK/FFTW PEAK hits.
- Diagnose the causes of DFTB+ results.
- Add more test cases per program.
- Continue to build out a list of actionable programs.
- Continue to // ... more programs

### QR Code of references, suggestions, and contact info

// TODO: create a github repo landing place, fill with info and links, create google forms suggestion dropbox, and point a QR code at it
