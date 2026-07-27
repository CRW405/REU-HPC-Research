# Test Case Notes (for poster writeup)

One representative test case was chosen per program. The goal in each case was
the same: pick an input that's physically realistic (something a researcher
would actually run), but small/short enough to sweep across many task/node
counts in a reasonable amount of allocation time. Below is what each one
actually simulates, why it stresses the libraries we care about (BLAS, LAPACK,
FFTW), and where the file came from.

---

## ABINIT — bulk silicon, ground-state DFT

**File:** `research_data/abinit/test_case/test_case.abi` (custom-authored, not
from ABINIT's stock test suite)

- System: a 2-atom silicon diamond-cubic unit cell (`znucl 14`, `natom 2`) —
  the simplest realistic crystal you can build silicon from.
- Calculation: a plane-wave, norm-conserving pseudopotential DFT
  ground-state calculation (self-consistent field / SCF).
- Tuned to be heavier than ABINIT's built-in example inputs: cutoff energy
  raised to `ecut 50` Ry, k-point grid densified to `12x12x12` (with a
  4-shift Monkhorst-Pack scheme), `nstep 30` SCF iterations, tight
  convergence (`tolvrs 1e-10`). The file's own header notes it was designed
  to "run 30-120 seconds on moderate core counts."
- `paral_kgb 1` turns on ABINIT's k-point/band/FFT parallelization — the
  mechanism that lets this scale across MPI ranks at all.
- Why this stresses the target libraries: plane-wave DFT alternates between
  FFTs (converting the wavefunction between real and reciprocal space) and
  dense linear algebra (diagonalizing the Hamiltonian each SCF step) — so
  it's a natural fit for profiling FFTW/BLAS/LAPACK usage.

## Quantum ESPRESSO (QE) — bulk silicon, larger supercell

**File:** `research_data/qe/test_case.in` (custom, replacing QE's own smaller
`test-suite/pw_scf/scf.in` — see the commented-out line in `config.sh`)

- System: the same element and structure as the ABINIT case (bulk silicon),
  but scaled up to a 16-atom supercell (`nat = 16`) instead of the 2-atom
  primitive cell.
- Calculation: SCF ground-state DFT, plane-wave pseudopotential method
  (`Si.pz-vbc.UPF`, LDA), `4x4x4` k-point grid, `ecutwfc = 16` Ry.
- This was deliberately chosen to mirror ABINIT's physical system. Both
  codes solve "the same problem" (bulk silicon ground state) with
  different underlying implementations — QE uses its own SCF/diagonalization
  routines — so any differences in library usage or scaling behavior
  between the two are attributable to the software, not the physics.

## DFTB+ — C60 fullerene, excited-state (TD-DFTB)

**Files:** `research_data/spinlock/dftb_in.hsd` + `C-C.skf` (a shared example
case staged by the mentor team, from DFTB+'s own "spinlock" regression test)

- System: a 60-atom carbon cage cluster — Buckminsterfullerene (C60),
  isolated (non-periodic) geometry.
- Calculation: self-consistent-charge DFTB (SCC-DFTB) ground state, followed
  by a **TD-DFTB excited-state (Casida linear-response) calculation** —
  100 excitations, iterative Stratmann diagonalization. This computes an
  optical absorption spectrum, not just a static ground state.
- Why this test case specifically: DFTB+ is an approximate/tight-binding
  stand-in for full DFT, so its default ground-state runs are usually too
  cheap to generate a meaningful profiling workload. Pushing it into an
  excited-state property calculation gives it a genuinely expensive dense
  eigenproblem to solve — which is exactly why PEAK's dominant hit for
  DFTB+ is `dsyev_` (LAPACK's symmetric eigensolver) rather than BLAS/FFTW.
- Note: "spinlock" is the name of the upstream DFTB+ test case itself
  (referring to the parallel diagonalization behavior it's designed to
  exercise), not a term we coined.

## GROMACS — membrane protein in a lipid bilayer (benchMEM)

**File:** `research_data/benchMEM.tpr` (pre-compiled GROMACS run input;
`.tpr` bundles topology + coordinates + MD parameters into one binary file)

- System (confirmed by inspecting the file): four protein chains
  (`Protein_A/B/C/D` — a homotetramer) embedded in a POPE lipid bilayer
  (a common membrane phospholipid), solvated in water with ions, using the
  GROMOS96 force field.
- This is "benchMEM," one of the standard public GROMACS benchmark systems
  (membrane protein), widely used in HPC papers specifically because it's
  reproducible and representative of realistic biomolecular MD workloads.
- Run as `mdrun -nsteps 50000 -ntomp 1 -resethway -noconfout`: 50,000 MD
  steps (~100 ps), pure-MPI (no OpenMP threads, so scaling behavior is
  attributable to MPI decomposition alone), performance counters reset
  halfway through (excludes PME auto-tuning/startup from the timed region),
  and no final coordinate write-out (pure performance test, not a real
  production run).
- Why this stresses FFTW: long-range electrostatics are handled via PME
  (Particle Mesh Ewald), which relies on FFTs — this is GROMACS's
  FFTW-heavy code path, same role FFTW plays in LAMMPS's PPPM.

## LAMMPS — rhodopsin membrane protein (scaled benchmark)

**File:** `research_data/lammps/.../in.rhodo.scaled` — referenced in
`config.sh` but **not yet pulled down locally**; the notes below are from the
file name/path and LAMMPS's public benchmark documentation, not a local
inspection — flag this if precision matters for the poster.

- This points at LAMMPS's standard "rhodopsin protein" benchmark: an
  all-atom rhodopsin protein in a solvated lipid bilayer with counter-ions,
  using long-range Coulombics via PPPM (LAMMPS's FFT-based Ewald method,
  functionally the same role as GROMACS's PME).
- The `.scaled` suffix indicates a modified/replicated version of the
  stock benchmark cell, presumably sized up for this scaling study.
- Chosen as the classical-MD counterpart to GROMACS: both are all-atom
  biomolecular simulations of a membrane protein in a bilayer, but through
  two different codes' pairwise-force and FFT implementations — useful for
  comparing scaling behavior on a similar physical system, similar to how
  ABINIT/QE were paired on bulk silicon.
- Open question flagged in the paper: LAMMPS produced **zero PEAK hits**
  for BLAS/LAPACK/FFTW despite running correctly, suspected to be caused by
  how the LAMMPS module build links against those libraries (possibly
  static-linked or built without PPPM's FFTW hook enabled) rather than the
  test case itself — worth double-checking once the actual input is pulled
  down, in case the module build isn't using PPPM/FFTW at all for this case.

---

## Cross-program summary

| Program | System | Class of problem | Library it's meant to stress |
|---|---|---|---|
| ABINIT | Bulk silicon (2-atom cell) | Ground-state plane-wave DFT | FFTW + BLAS/LAPACK |
| QE | Bulk silicon (16-atom cell) | Ground-state plane-wave DFT | FFTW + BLAS/LAPACK |
| DFTB+ | C60 fullerene | TD-DFTB excited state (Casida) | LAPACK (dense diagonalization) |
| GROMACS | Membrane protein + lipid bilayer | Classical MD, PME electrostatics | FFTW |
| LAMMPS | Membrane protein + lipid bilayer (rhodopsin) | Classical MD, PPPM electrostatics | FFTW (expected, not observed) |

The pairing is intentional: ABINIT/QE share a physical system to isolate
code-vs-physics differences in the DFT codes, and GROMACS/LAMMPS share a
physical system (membrane protein in a bilayer) to do the same for the
classical MD codes. DFTB+ stands alone as the "cheaper approximate method"
comparison point, pushed into an excited-state calculation specifically to
give it a workload worth profiling.
