# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is an REU (Research Experience for Undergraduates) project at TACC (Texas Advanced Computing Center) focused on profiling HPC applications using **PEAK** (Performance Evaluation Analysis Kit). The goal is to characterize which BLAS/LAPACK/FFTW/ScaLAPACK library functions are called by the top Frontera jobs, and how they scale across MPI task counts.

Target cluster: **Frontera** at TACC, SKX partition, allocation `EAR23006`.

## Key Workflow

The research pipeline runs on TACC's Frontera HPC cluster, not locally. The typical workflow is:

1. **Configure** — edit `research_scripts/config.sh` for the target application
2. **Generate SLURM jobs** — `./generate_jobs.sh -t` (test), `-tp` (test+PEAK), `-p` (peak scaling), or `-f` (full)
3. **Submit** — `while read job; do sbatch "$job"; done < <run_dir>/all_jobs.txt`
4. **Optionally consolidate** — `./convert_to_arrays.sh <run_dir>` to reduce submission count (TACC limit: 20 active / 80 total jobs)
5. **Analyze** — `python research_scripts/peak_analysis_v2.py peak_stats-pXXXXX.csv peak_mem-pXXXXX.csv`

## Scripts (`research_scripts/`)

| Script | Purpose |
|---|---|
| `config.sh` | Master config: app binary, test cases, modules, SLURM settings, PEAK settings |
| `generate_jobs.sh` | Generates per-node-count SLURM job scripts in timestamped output dirs |
| `run_script.sh` | Standalone run script (also used as SLURM job body); supports `--peak`/`--no-peak` |
| `convert_to_arrays.sh` | Groups `job.slurm` files with identical resources into SLURM job arrays |
| `peak_analysis_v2.py` | Parses PEAK CSV output → matplotlib charts + library usage text report |

### `generate_jobs.sh` modes

```bash
./generate_jobs.sh -t            # test: single n1 job, no PEAK
./generate_jobs.sh -tp           # test-peak: single n1 job with PEAK
./generate_jobs.sh -p            # full scaling with PEAK only
./generate_jobs.sh -f            # full scaling with and without PEAK
./generate_jobs.sh --config /path/to/config.sh --name myrun -t
```

### `convert_to_arrays.sh`

```bash
./convert_to_arrays.sh --dry-run <run_dir>   # preview grouping
./convert_to_arrays.sh <run_dir> 10          # create arrays, max 10 concurrent
```

Creates `<run_dir>/job_arrays/` with three submission strategies: parallel, dependency-chain, and safe (one-at-a-time).

### `peak_analysis_v2.py`

```bash
python peak_analysis_v2.py peak_stats-p12345.csv peak_mem-p12345.csv  # both
python peak_analysis_v2.py peak_stats-p12345.csv                      # stats only
python peak_analysis_v2.py peak_mem-p12345.csv                        # memory only
```

Outputs: `*_graphs.png` (matplotlib) and `*_library_report.txt` (BLAS/LAPACK/FFTW/PBLAS/ScaLAPACK breakdown by call count and time).

## Configuration (`config.sh`)

Critical fields to update per application:
- `APP_BINARY` — path to the compiled binary on Frontera scratch
- `TEST_CASES` — array of `"name:input_path"` pairs
- `APP_ENV` — app-specific env vars (e.g., pseudopotential dirs for abinit)
- `MODULES` — LMOD modules to load
- `LIBRARY_PATHS` — extra `LD_LIBRARY_PATH` entries
- `LIBPEAK_PATH` — absolute path to `libpeak.so` on scratch

## PEAK Profiling

PEAK intercepts library calls via `LD_PRELOAD`. Key env vars set by the scripts:
- `PEAK_TARGET_GROUP` — which libraries to intercept: `BLAS,LAPACK,FFTW,PBLAS,ScaLAPACK`
- `PEAK_STATSLOG_PATH` / `PEAK_MEMLOG_PATH` — output CSV prefixes (one file per MPI rank)
- `I_MPI_LD_PRELOAD` — required for Intel MPI to propagate the preload to remote nodes

PEAK output CSV formats:
- **stats**: `function,count,per_thread,per_rank,call_max_s,call_min_s,total_s,exclusive_s,...`
- **memory**: `ts_ns,delta,current,tid,op` (op: 1=alloc, 2=free, 3=realloc_old, 4=realloc_new)

## Repository Structure

- `Week N/` — weekly notes, reports, and exploratory scripts
- `research_scripts/` — production scripts (versioned; `_v1`, `_v2` suffixes)
- `research_data/` — run output (multi_node/ and single_node/ subdirs are gitignored)
- `Week 5/Programs.csv` — tracking sheet for the Frontera top-100 applications: module availability, script status, test cases, PEAK profiling status

## SLURM Scaling Configurations

Single-node configs: `n1, n2, n4, n8, n16, n32, n48` (MPI tasks on 1 SKX node, 48 cores/node)  
Multi-node configs: `N2, N4, N8, N16` (nodes × 48 tasks/node)  
Time limits: 30 min single-node, 40 min multi-node
