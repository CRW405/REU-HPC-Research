
# Report

## What I worked on

### Chroma build script

### Athena++ build scripts

### Other build scripts

I had claude generate build scripts for WRF, Amber
I still need to review and run them but they look good at a glance

### Experimented with my gen scripts in order to

I realized I dont have to run a full PEAK and no PEAK run on every single type of scaling in order to get library usage data
I've been experimenting with different configs and seeing the effects on the times and data gathered
I also realized that the test cases I've been using are very short, should I find a more complex test case for abinit, or is this ok?

### Updated scripts to have a run with seperate scalings for time differences then a seperate PEAK run to determine library breakdown for a quicker glance

This puts the total amout of jobs to 7 and the time it takes to run way less although it is less specific data

### Created a CSV table for program status

integrates data from the top 100, my top 100 report, the shared dir, and the spreadsheet with info about research progress and notes

### Looked into BenchPRO

## What I learned

- Start small and build up
- Profiling overhead with MPI scaling
- I looked into some of the programs on the list like CESM, SpEC although they seemed much more complicated to make a build script than others
- I learned some more about the programs in my CSV through adding notes and such

## Question / Concerns

- I feel i've fallen behind where I want to be
