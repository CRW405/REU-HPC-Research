
# Weekly Report

## What I worked on

- Created a build script for Quantum Espresso, I didnt realize at the time it already had a module but it was good practice
- Created a build script for ShengBTE
- Creared a build script for WarpX
- Looked though and studied the provided examples, and will use them to create test suites for those programs

### Created a suite of scripts in order to generate slurm jobs for a target program

#### Job generation script

- Tests with and without PEAK
- Tests MPI scaling: 1,2,4,8,16,32,48
- Tests Node scaling: 2,4,8,16
- Test Cases, t00,t02,t03,t04,t05
- Organizes the scripts and outputted data into directories
- Diffferent flags such as test runs and a full run
- Customizable via sources config.sh so that the script can reused for multiple programs with just some configuration changes

With all the different permutations of tests, I ended up with 110 different jobs for a full run

#### Job array conversion script

Since there are so many different jobs, many with the same resources, I created a script to consolidate jobs into job arrays.
110 -> 11

- Still working on this one, i've been learning more about SLURM and talked to some TACC staff about how most efficiently to run bulk jobs
- Im still trying to figure out the most efficiently to run these jobs

- I generated the above jobs for ABINIT and am currently running it
- These scripts are still being worked on and are on my github repo

## What I learned

- How SLURM works
- SLURM job arrays
- SLURM job dependencies
- HPC best practices for running jobs and how to run many jobs
- Gathering data from program runs with and without PEAK
- Creating build script
- Creating and finding test cases

## Questions / Concerns

- putting together the test suite scripts ended up taking more time than I anticipated and I did not get to create as many build scripts as I hade hoped.
I'll use the extra time I have during the next week to work on those and get them done.
- Can or should I reduce the amount of variables? 11 scalings, 5 test cases.
I chose those numbers based off the LAMMPS assignment and an arbitrary 5 test cases but I imagine I can skip some scalings and maybe use less or one test case,
if you dont think it would affect data. After this full ABINIT suite finishes, I'll have a better idea of what is worth testing and not as well.
