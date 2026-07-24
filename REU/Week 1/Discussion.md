
# Discussion 1

## PEAK Understanding

PEAK is a performace analysis kit built for HPC systems.

PEAK uses the Frida-Gum toolkit for injecing monitering code into running binaries
and dynamically attaches and deattaches to stay below a specified level of overhead.

## PEAK purpose

PEAK was made to address the shortcomings of similiar tools that use static monitering
cutoffs or other means of reducing overhead that reduce accuracy.

## Components

### cuda_interceptor.cpp

- Profiles Nvidai Gpu Kernels
- gets the human readable name of kernels

### dlopen_interceptor.c

- this allows PEAK to profile functions from libraries loaded later on in the programs operation
- dlopen() is intercepted and used to catch these functions

### general_listener.c

- Main workings of PEAK, uses and manages the Frida-Gum engine
- uses the heartbeat to dynamically attach and reattach moniters
- Collects data from the interceptors and takes into account effects
from multiple threads

### malloc_interceptor.c

- intercepts memory actions such as malloc, calloc, freem etc and logs them

### malloc_otf2.c

- Converts raw memory events into otf2 traces

### mpi_interceptor.c

- Determines if the program is running in an mpi enviroment
- highjacks the mpi shutdown signal and logic of the mpi enviroment
- ensures data can be and is gathered from this enviroment

### peak.c

- Main manager.
- Is the entry and exit.
- Enviroment Parsing
- Starts and attaches interceptors
- Starts the heartbeat thread
- Ensures proper attachments and bypasses things like wrapper scripts
- Gracefully shutdowns all components

### pthread_listener.c

- PEAKS thread utitlies
- Handles the pausing of threads when attaching and deattaching interceptors
- Helps process data when multiple threads present so that output is accurate and readable

### syscall_interceptor.c

- some programs will close the standard error stream during their shutdown,
PEAK uses this stream so it needs to be protected
- Whenever a close signal to STDERR is sent, PEAK fakes a success response and ignores the close,
protecting the stream for it to continue using

## Interesting Features

I've never really used performance moniters, so this is all very new and very interesting to me.
I find the Frida-Gum toolkit fascinating as I didnt even know you could modify code as its being run in such a way.
The fact you can modify such integral functions such as malloc at runtime is both very cool and very terrifying to me.

## Questions / Observations

Id like to learn more how this works at a program level, I was wondering if there are any recommended resources for learning this sort of programming.

