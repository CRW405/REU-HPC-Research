
# Report

## What I worked on

### TACC Systems and HPC Workflows

- I've grown more familiar and comfortable with the general TACC HPC workflow
- I completed the test case on frontera and wrote a simple performance report last week
- I've continued to experiment with PEAK on both my personal laptop and Frontera

### PEAK profiler and package installation

- I've installed PEAK on Frontera
- I've learned how to use the module system, module load, list, spider, etc
- Im already familiar with git and have been getting more used to using make and cmake

### More

- Put together a rough draft for the projects abstract
- I have been learning about some of the popular math libraries used in HPC systems such
as BLAS, LAPACK, and FFTW in order to get a better idea of what im heading into for
Research Direction 1

## What I learned

- TACC HPC Workflow
- SLURM job submission and management
- PEAK profiler installation on Frontera
- Module management
- Abstract writing and research direction planning
- Exposure to HPC math libraries

## Questions / Issues

- Whenever I run PEAK on Frontera, I get a segfault and have been unable to figure out
why or how to fix it. I've tried installing to my home and scratch dirs, compiling
with different compilers, targeting different functions and programs, etc.

## Abstract Draft

High Performance Computing (HPC) systems and the various science, math, and machine
learning programming libraries that utilize their resources allow researchers to pursue
levels of research once thought impossible. The future of research depends on ensuring
each and every program and dependency is utilizing these amazing machines to their
fullest potential. Using the Performance Evaluation and Analysis Kit (PEAK) and usage
data gathered from the Texas Advanced Computing Center (TACC), we will profile the most
widely used science and math toolkits and libraries under the different and unique
conditions and contexts common on HPC systems. Due to the unique approach PEAK takes
with the accuracy overhead trade off, we expect to be able to gather data points that
traditional profilers would miss. The goal is to find the various bottlenecks and
ideal conditions that will allow us to build more efficient research infrastructure
and tools; if we can speed up these tools, we can speed up research for everyone.
