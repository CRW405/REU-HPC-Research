# CESM 2.2.2 — Build & Run Guide for Stampede3

CESM is a fully-coupled climate model (atmosphere, ocean, land, sea-ice). Building it on Stampede3 is a multi-step process because TACC does not ship an official CESM machine configuration for Stampede3. This guide uses a community-maintained port.

---

## Prerequisites

### 1. GitHub access to ESCOMP
CESM source is on GitHub under the ESCOMP organization. Request membership (free) at:
- https://github.com/ESCOMP

You also need an SSH key registered with GitHub. Test with:
```bash
ssh -T git@github.com
```

### 2. Required modules on Stampede3
```bash
ml intel
ml impi
ml hdf5
ml netcdf      # includes NetCDF-Fortran; sets TACC_NETCDF_DIR
ml pnetcdf     # parallel NetCDF; sets TACC_PNETCDF_DIR
```

### 3. Disk space
Run everything from `$SCRATCH` — not `$HOME`. The source tree plus all component models is ~5 GB. Input data can be hundreds of GB (see Step 6).

---

## Step 1: Clone CESM

```bash
cd $SCRATCH
git clone -b release-cesm2.2.2 https://github.com/ESCOMP/CESM.git cesm-2.2.2
cd cesm-2.2.2
```

---

## Step 2: Download component models

CESM uses `manage_externals` to pull all sub-models (CAM, CLM, CICE, POP, MOM6, MOSART, etc.). This can take 10–20 minutes.

```bash
./manage_externals/checkout_externals
```

If it fails partway through (network timeout), just rerun it — it skips already-complete checkouts.

---

## Step 3: Apply the Stampede3 CIME port

CIME is the build infrastructure inside CESM (`cime/`). The official CIME repo has no Stampede3 machine definition, but Jim Edwards (NCAR) maintains a port branch. It uses the machine name `stampede2-skx` with a hostname regex that matches Stampede3 nodes.

```bash
cd cesm-2.2.2/cime
git remote add jpe https://github.com/jedwards4b/cime
git fetch jpe
git checkout port/maint-5.6/stampede3
```

### Fix the broken linker flag

The port branch includes `-zmuldefs` in `config_compilers.xml`. This flag is no longer supported by the Intel oneAPI linker and **will cause a link failure**. Remove it:

```bash
sed -i 's/ -zmuldefs//g' config/cesm/machines/config_compilers.xml
# Verify it's gone:
grep zmuldefs config/cesm/machines/config_compilers.xml
# Should print nothing
```

---

## Step 4: Create a case

Go back to the CIME scripts directory and create a case. You need to choose:
- **Compset** — what model components are active and what physics they use
- **Resolution** — grid resolution for atmosphere and ocean

```bash
cd cesm-2.2.2/cime/scripts

./create_newcase \
  --case $SCRATCH/cesm_cases/b1850_test \
  --compset B1850 \
  --res f19_g17 \
  --machine stampede2-skx \
  --compiler intel \
  --project <your_allocation>
```

### Common compsets

| Compset | Description |
|---|---|
| `B1850` | Fully-coupled, pre-industrial forcing — the standard validation case |
| `B2000` | Fully-coupled, year-2000 forcing |
| `F2000climo` | Atmosphere + land only (prescribed ocean) — faster to build and run |
| `FKESSLER` | Atmosphere only with Kessler microphysics — simplest possible test |

### Common resolutions

| Resolution | Description |
|---|---|
| `f19_g17` | ~2-degree atmosphere/land, 1-degree ocean — recommended starting point |
| `f09_g17` | ~1-degree — higher fidelity, much more expensive |

---

## Step 5: Set up, build, and run

```bash
cd $SCRATCH/cesm_cases/b1850_test

# Generate namelists, run directories, and Makefile
./case.setup

# Optional: shorten the run for a quick test
./xmlchange STOP_OPTION=ndays,STOP_N=5

# Compile all model components (~20–40 minutes)
# Do this in an idev session to avoid login node limits:
#   idev -N 1 -n 48 -t 01:00:00 -A <allocation>
./case.build

# Submit to SLURM
./case.submit

# Monitor the queue
squeue -u $USER

# Watch the model output log
tail -f run/cesm.log.*
```

---

## Step 6: Input data

CESM requires large input datasets (boundary conditions, initial conditions, forcing files). By default `case.build` will set `DIN_LOC_ROOT` to a path under your `$SCRATCH`, and the model will attempt to download missing files at runtime via `svn`.

**Ask TACC consulting** whether a shared CESM input data cache exists on Stampede3. If it does, point to it before building:

```bash
./xmlchange DIN_LOC_ROOT=/path/to/shared/cesm/inputdata
```

This avoids downloading hundreds of GB.

---

## Troubleshooting

| Symptom | Fix |
|---|---|
| `undefined reference to _gfortran_*` during link | Compiler mismatch — make sure `ml intel` is loaded and `--compiler intel` was passed to `create_newcase` |
| `cannot find -lzmuldefs` or similar link error | Check that the `sed` command in Step 3 removed the flag |
| `checkout_externals` fails with SVN error | Rerun it; some repos occasionally time out |
| Model crashes at startup with NetCDF error | Verify `ml netcdf` is loaded and `TACC_NETCDF_DIR` is set |
| Input data missing | Check `DIN_LOC_ROOT` in `env_run.xml`; ensure `$SCRATCH` has space |
| `create_newcase` says machine `stampede2-skx` not found | The CIME port checkout failed — redo Step 3 |

---

## Key files after `case.setup`

| File | Purpose |
|---|---|
| `env_mach_pes.xml` | MPI task layout (how many tasks per component) |
| `env_run.xml` | Run length, restart frequency, DIN_LOC_ROOT |
| `env_build.xml` | Compiler flags, debug mode toggle |
| `CaseDocs/` | Generated namelists — inspect before running |
| `run/` | Where the model runs and writes logs/restarts |
| `bld/` | Compiled object files and executables |
