# ABINIT PEAK Profiling Pipeline — Implementation Plan

## Project Context

This is a research pipeline for an REU (Research Experience for Undergraduates) at TACC
(Texas Advanced Computing Center). The goal is to profile how scientific HPC applications
use math libraries (BLAS, LAPACK, FFTW) using PEAK (Performance Evaluation and Analysis Kit),
a lightweight LD_PRELOAD-based profiler.

The pipeline generates and submits SLURM jobs on Stampede3 to run ABINIT (a DFT physics code)
under different MPI scaling configurations, with and without PEAK profiling, then analyzes
the results.

---

## Current State

### Scripts (all bash) // old vers located in ../v1/, you should use them as a base
- `config.sh` — single source of truth: app paths, test cases, modules, SLURM settings, PEAK settings
- `generate_jobs.sh` — reads config, generates a full directory tree of individual job.slurm files
- `convert_to_arrays.sh` — consolidates job.slurm files into SLURM job arrays grouped by resource signature
```

---

## Revised Data Gathering Strategy

Previous approach (PEAK at every scaling point) produced unusable results because:
- Test cases finish in 3-6 seconds
- PEAK teardown across hundreds of MPI ranks dominates total runtime

### New approach:
1. **Scaling study (no PEAK)** — run the full MPI and node scaling matrix with PEAK disabled.
   Captures how ABINIT runtime changes with core count. Fast and clean.
2. **Library profiling (PEAK on one config only)** — run PEAK on a single mid-range
   configuration (configurable, default: n24) to capture BLAS/LAPACK call counts and timing.
   Memory profiling disabled by default in this mode.

---

## Implementation Goals

### Goal 1 — Add a new `-s` / `--scaling` mode to generate_jobs.sh

**Current modes:**
- `-t` / `--test` — single n1 nopeak job
- `-tp` / `--test-peak` — single n1 peak job
- `-p` / `--peak` — full scaling matrix, peak only
- `-f` / `--full` — full scaling matrix, peak + nopeak

**New mode to add:**
- `-s` / `--scaling` — full scaling matrix nopeak for ALL configs, PLUS one peak job for
  a single specified config. This is the primary research mode going forward.

**New config.sh variable to add:**
```bash
# Which single config to run PEAK on in --scaling mode
PEAK_SINGLE_CONFIG="n24"
```

**New flag in generate_jobs.sh:**
```bash
-s|--scaling)
    MODE="scaling"
    shift
    ;;
--peak-config)
    PEAK_SINGLE_CONFIG="$2"
    shift 2
    ;;
```

**Behavior in scaling mode:**
- For every test case in TEST_CASES:
  - Generate nopeak jobs for ALL single-node configs
  - Generate nopeak jobs for ALL multi-node configs
  - Generate exactly ONE peak job for the config named in PEAK_SINGLE_CONFIG
- All other logic (directory structure, timing CSV, job naming) stays the same as existing modes

**Keep all existing modes intact — do not remove or modify them.**

---

### Goal 2 — Copy config.sh and generate_jobs.sh into the generated run directory

**Problem:** When looking at old run directories, there is no record of what config or script
version produced them. Hard to reproduce or understand old results.

**Change:** At the end of generate_jobs.sh, after all jobs are written, copy both files
into the top-level run output directory:

```bash
cp "${CONFIG_FILE}" "${OUTPUT_DIR}/config.sh"
cp "$0" "${OUTPUT_DIR}/generate_jobs.sh"
```

Where `OUTPUT_DIR` is the top-level run directory (e.g. `abinit-full-07062026-224017/`).

This should happen for ALL modes, not just scaling mode.

---

## File Locations (on Stampede3)

```
/scratch/11603/crw405/REU-HPC-Research/
  research_data/abinit/
    <run_name>-<mode>-<timestamp>/
      config.sh                    <- copy of config used (NEW)
      generate_jobs.sh             <- copy of script used (NEW)
      timing_summary.csv
      all_jobs.txt
      <test_case>/
        single_node/
          n1_nopeak/job.slurm
          n24_peak/job.slurm       <- only one peak job in scaling mode
          ...
        multi_node/
          N2_nopeak/job.slurm
          ...
  scripts/
    config.sh
    generate_jobs.sh
    convert_to_arrays.sh
    submit_all_safe.sh
```

---

## Notes and Constraints

- Base all changes on the existing generate_jobs.sh — match its style exactly:
  heredoc-based job script generation, same variable naming conventions,
  same directory structure, same timing CSV format
- The config file path is available as `${CONFIG_FILE}` inside generate_jobs.sh
  (it is parsed from the --config flag or defaults to ./config.sh)
- `$0` gives the path to generate_jobs.sh itself for the self-copy
- Do not change convert_to_arrays.sh — it reads the generated job files and
  does not need modification for these goals
- All existing flags and behaviors must continue to work exactly as before
- Add PEAK_SINGLE_CONFIG to config.sh with a default of "n24"
- If --peak-config flag is passed on command line, it overrides PEAK_SINGLE_CONFIG from config

## Extra

for the exisisting and commented and from previous PEAK configs ive used, since ive been experimenting with different settings, Id like you to make sure those are checked for being set, that way I can comment and uncomment configs without having to go over to the generation script and delete lines every time
