
## Use

### Basic

```
LD_PRELOAD=/path/to/libpeak.so PEAK_TARGET=func1 func2... ./bin
```

### Built in sleep test

```
export PEAK_TARGET=my_sleep_func,main  LD_PRELOAD=/home/think/peak/build/src/libpeak.so ./test/sleep/test_sleep
```

### Job Submission

.slurm files:
``` job.slurm
#!/bin/bash
#SBATCH -J job_name
#SBATCH -o output_name.o%j # %j -> job id
#SBATCH -e error.e%j
#SBATCH -p queue_partition_name
#SBATCH -N <int> # Number of nodes
#SBATCH -n <int> # Number of mpi tasks
#SBATCH -t <hh:mm:ss> # run time
#SBATCH -A <project/allocation name> # req'd if multiple

# commands go here, example using vina:
echo "Start:"
date

module list
module use /work/03439/wallen/public/modulefiles
module load autodock_vina/1.2.3
module list

cd data/
vina --config configuration_file.txt --out ../results/output_ligands.pdbqt

echo "End:"
date
```

sbatch job.slurm # submit above job file

showq # show all jobs
showq -u <username or $USERNAME for yourself>
squeue # show all jobs
scancel <jobid> # to cancel

/share/doc/slurm/ for more scripts
the output file should be in the same dir as your slurm file, you can cat to view
in the above slurm, we made a results dir which will be in the same place

### Idev

idev -m <time in minutes> #same flags as options in slurm head
instead of making a slurm file, idev lets you do things interactively