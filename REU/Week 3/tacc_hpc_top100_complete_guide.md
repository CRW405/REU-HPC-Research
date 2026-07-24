# TACC HPC Top 100 Executables - Complete Filtering Guide

## Summary
- Original List: 100 executables
- Filtered List: 72 unique programs/tools
- Removed: 28 entries

---

## Items Removed and Rationale

### 1. Generic/Non-descriptive Names (5 items)
These provide no actionable information about the actual software:
- main (27.4M core-hrs)
- main.out (561K core-hrs)
- exec (863K core-hrs)
- out_user_fortran (1.2M core-hrs)
- workerbee (10.6M core-hrs)

### 2. Language Interpreters & System Utilities (4 items)
Not the focus for profiling; profiling should target the actual scientific codes run through these:
- Python (9.0M core-hrs)
- perl (4.5M core-hrs)
- gawk (333K core-hrs)
- julia (1.2M core-hrs)

### 3. Duplicate/Variant Executables (19 consolidated)
Multiple executables representing the same program or suite:

NAMD variants:
- NAMD (11.8M) + namd3 (6.6M) = 18.4M total

Quantum Espresso components:
- epw.x (18.0M) → part of QE suite (already counted in 23.7M)

UFS Model variants:
- ufs_model.x (14.8M) + ufs_model (1.0M) = 15.8M total

FHI-aims variants:
- aims.241216.scalapack.mpi.x (1.8M) + aims.250320_1.scalapack.mpi.x (274K) = 2.1M total

fornax variants:
- fornax (23.6M) + fornax-3d (678K) + fornax-3d-newE (340K) + fornax-bfield (337K) = 25.0M total

LAMMPS variants:
- LAMMPS (3.0M) + lmp (623K) = 3.6M total

Tristan-MP variants:
- 20250709.tristan-mp2d... (1.7M) + 20250717.tristan-mp2d... (800K) + tristan-mp3d (1.1M) = 3.6M total

CGS (gyrokinetic) variants:
- cgs_fdm (6.1M) + cgs_vfp (1.2M) + cgs_inp (1.1M) = 8.3M total

RT (radiative transfer) variants:
- rt_twostream_driven_2x1v_envelop (1.5M) + rt_...nonuniformv (670K) + rt_vlasov_sr... (565K) = 2.7M total

MHDAM3d variants:
- MHDAM3d...IPS_newSigma2... (611K) + MHDAM3d...IPS_newSigma... (269K) = 880K total

ASPECT variants:
- aspect-release (1.3M) + aspect (288K) = 1.6M total

EPPIC variants:
- eppic.x (586K) + EPPIC (516K) = 1.1M total

Clubbed simulation variants:
- 3D_2-3clubbed_prod.x (1.8M) + 2p5D_2-3clubbed_prod.x (1.2M) = 3.0M total

gkyl/gkeyll variants:
- gkeyll (573K) + gkyl (420K) = 994K total (same program, different spelling)

---

## Filtered Programs for BLAS/LAPACK/FFTW Profiling

### Climate & Weather (3 programs)

CESM - Community Earth System Model
Core-hours: 102.8M
A comprehensive climate modeling framework developed by NCAR and the broader climate science community. Simulates Earth's climate system including atmosphere, ocean, land, sea-ice, and biogeochemical cycles. Used by climate scientists for long-term climate projections, paleoclimate studies, and understanding Earth system interactions. Heavy user of BLAS/LAPACK for linear algebra in atmospheric and ocean dynamics.

WRF - Weather Research and Forecasting Model
Core-hours: 2.8M
A mesoscale numerical weather prediction system designed for both atmospheric research and operational forecasting. Used by meteorologists, air quality modelers, and researchers for regional weather forecasting, severe storm prediction, and climate downscaling studies. Employs FFTW for spectral operations and BLAS for dynamics solvers.

SWMF - Space Weather Modeling Framework
Core-hours: 5.5M
A comprehensive physics-based model for space weather developed at University of Michigan. Simulates the Sun-Earth system including solar corona, solar wind, magnetosphere, and ionosphere. Used by space physicists and space weather forecasters to predict geomagnetic storms, satellite drag, and radiation hazards for spacecraft and astronauts.

---

### Molecular Dynamics & Chemistry (7 programs)

Gromacs
Core-hours: 41.3M
A versatile molecular dynamics package optimized for simulating biochemical molecules like proteins, lipids, and nucleic acids. Used extensively by computational biologists, drug designers, and materials scientists to study protein folding, drug-receptor interactions, and biomolecular mechanisms. Heavy BLAS/LAPACK user for force calculations and analysis tools.

VASP - Vienna Ab initio Simulation Package
Core-hours: 25.1M
A leading plane-wave density functional theory (DFT) code for electronic structure calculations. Used by materials scientists, solid-state physicists, and chemists for studying crystal structures, electronic properties, and chemical reactions at the quantum level. One of the heaviest users of optimized BLAS/LAPACK/FFTW on HPC systems.

NAMD - Nanoscale Molecular Dynamics
Core-hours: 18.4M (combined)
A parallel molecular dynamics code designed specifically for high-performance simulation of large biomolecular systems. Developed by the Theoretical and Computational Biophysics Group at UIUC. Used by structural biologists and biophysicists to simulate viruses, cellular machinery, and membrane proteins. Optimized for scaling on large HPC systems.

LAMMPS - Large-scale Atomic/Molecular Massively Parallel Simulator
Core-hours: 3.6M (combined)
A classical molecular dynamics code with a focus on materials modeling but applicable to diverse systems. Used by materials scientists, chemical engineers, and soft matter physicists for studying metals, polymers, granular materials, and colloidal systems. Highly flexible with hundreds of community-contributed packages.

Siesta
Core-hours: 2.1M
A DFT code for electronic structure calculations using localized basis sets, making it efficient for large systems. Used by materials scientists and nanoscience researchers for studying molecules, nanostructures, and bulk materials with thousands of atoms. Popular for studying 2D materials, interfaces, and defects.

Amber
Core-hours: 700K
A suite of biomolecular simulation programs widely used in structural biology and drug discovery. Specialized for simulating proteins, nucleic acids, and carbohydrates in solution. Used by pharmaceutical researchers, structural biologists, and biochemists for studying biomolecular structure, dynamics, and interactions.

orca
Core-hours: 271K
A general-purpose quantum chemistry package with emphasis on spectroscopic properties and multi-reference methods. Used by chemists for studying reaction mechanisms, transition metal complexes, and excited states. Known for its sophisticated treatment of electron correlation and relativistic effects.

---

### Quantum/Condensed Matter Physics (11 programs)

QE - Quantum Espresso
Core-hours: 23.7M (plus 18.0M from epw.x component)
An integrated suite of open-source codes for electronic structure calculations using DFT, plane waves, and pseudopotentials. Used by condensed matter physicists and materials scientists for ground-state properties, phonons, and spectroscopy. Major consumer of BLAS/LAPACK/FFTW libraries.

Chroma
Core-hours: 25.1M
A lattice quantum chromodynamics (QCD) software system for studying the strong nuclear force. Used by high-energy physicists to calculate properties of hadrons (protons, neutrons, mesons) from first principles. Requires massive computational resources and heavily optimized linear algebra routines.

BerkeleyGW
Core-hours: 8.0M
A many-body perturbation theory code for calculating quasiparticle energies and optical properties. Used by condensed matter theorists to accurately predict band gaps, optical absorption spectra, and excited-state properties of materials. Critical for understanding semiconductors, 2D materials, and photovoltaics.

hmc_tm
Core-hours: 7.2M
A Hybrid Monte Carlo implementation with twisted mass fermions for lattice QCD calculations. Used by particle physicists to study quark dynamics, hadron structure, and fundamental properties of quantum chromodynamics. Computationally intensive with heavy linear algebra requirements.

overlap_curseq
Core-hours: 5.3M
Lattice QCD code using overlap fermion formulations with stochastic methods. Used by particle physicists for studying QCD with improved chiral symmetry properties. Critical for precision calculations of hadron properties and fundamental physics constants.

ctqmc - Continuous-Time Quantum Monte Carlo
Core-hours: 2.3M
A quantum Monte Carlo method for solving strongly correlated electron systems. Used by condensed matter theorists studying high-temperature superconductors, heavy fermion materials, and quantum phase transitions. Essential for understanding materials where traditional DFT fails.

lapw1c
Core-hours: 1.3M
The main computational component of WIEN2k, an all-electron DFT code using the linearized augmented plane wave (LAPW) method. Used by materials scientists for high-accuracy electronic structure calculations, particularly for materials containing heavy elements where all-electron methods are crucial.

dmft2
Core-hours: 1.4M
An implementation of Dynamical Mean Field Theory for strongly correlated electron systems. Used by condensed matter physicists studying materials with strong electron-electron interactions like transition metal oxides, rare-earth compounds, and unconventional superconductors.

ShengBTE
Core-hours: 1.4M
A solver for the Boltzmann transport equation for phonons, used to calculate thermal conductivity of materials. Used by materials scientists and thermal engineers designing thermoelectric materials, thermal barrier coatings, and studying heat management in electronics.

Abinit
Core-hours: 783K
A comprehensive DFT package capable of calculating various properties including structure optimization, molecular dynamics, and linear response. Used by materials scientists for studying a wide range of systems from molecules to solids. Strong capabilities in computing vibrational and dielectric properties.

FHI-aims
Core-hours: 2.1M (combined)
Fritz Haber Institute ab initio molecular simulations - an all-electron electronic structure code with numerical atomic orbitals. Used by chemists and materials scientists requiring high accuracy for molecules, surfaces, and solids. Excellent for studying molecular adsorption and catalysis.

---

### Astrophysics & Cosmology (9 programs)

SpEC - Spectral Einstein Code
Core-hours: 30.3M
A high-accuracy code for solving Einstein's equations of general relativity using spectral methods. Used by gravitational wave physicists to simulate binary black hole and neutron star mergers. Critical for interpreting LIGO/Virgo gravitational wave detections.

Cactus
Core-hours: 16.7M
A computational framework for solving systems of partial differential equations, widely used in numerical relativity and astrophysics. Used by researchers studying black holes, neutron stars, and gravitational wave sources. Provides infrastructure for large-scale Einstein equation solvers.

rockstar-galaxies
Core-hours: 13.1M
A phase-space halo finder for cosmological simulations. Used by cosmologists to identify and track dark matter halos and galaxies in large N-body simulations. Essential for understanding galaxy formation and the large-scale structure of the universe.

GIZMO
Core-hours: 5.5M
A flexible multi-method magneto-hydrodynamics and gravity code for astrophysics. Used by astrophysicists to simulate galaxy formation, star formation, supernovae, and cosmic structure formation. Implements multiple hydrodynamic methods including SPH and mesh-free finite-volume approaches.

ENZO
Core-hours: 3.8M
An adaptive mesh refinement (AMR) code for astrophysical simulations including hydrodynamics, gravity, and radiative processes. Used by cosmologists to simulate structure formation from the early universe to present day, including the first stars and galaxies.

athena
Core-hours: 3.7M
A grid-based magnetohydrodynamics (MHD) code for astrophysical flows. Used by astrophysicists studying accretion disks, jets, turbulence, and magnetic field dynamics in various cosmic environments from stellar to galactic scales.

Gadget
Core-hours: 2.6M
A widely-used code for cosmological N-body and smoothed particle hydrodynamics (SPH) simulations. Used by cosmologists to simulate dark matter structure formation and galaxy evolution across cosmic time. One of the most popular codes for large-scale structure simulations.

Flash4
Core-hours: 2.2M
A component-based, multi-physics AMR simulation framework. Used by astrophysicists studying supernovae, gamma-ray bursts, stellar evolution, and other explosive astrophysical phenomena. Highly modular with extensive physics capabilities.

astrobear
Core-hours: 2.0M
An AMR MHD code designed for studying magnetized astrophysical flows. Used by researchers investigating stellar jets, outflows, magnetic tower formation, and other magnetically-dominated astrophysical phenomena.

---

### Plasma Physics & Fusion (7 programs)

gene_frontera
Core-hours: 6.2M
A gyrokinetic turbulence code for studying plasma turbulence in fusion devices. Used by fusion energy researchers to understand and predict anomalous transport in tokamaks and stellarators. Critical for ITER and future fusion reactor design.

CGS - Continuum Gyrokinetic Solver
Core-hours: 8.3M (combined)
A gyrokinetic code for plasma turbulence simulations in magnetic confinement fusion devices. Used by plasma physicists to study microturbulence and transport in tokamak plasmas. Heavy user of spectral methods requiring optimized FFT libraries.

Tristan-MP
Core-hours: 3.6M (combined)
A massively parallel particle-in-cell (PIC) code for simulating collisionless plasmas. Used by astrophysicists and plasma physicists studying magnetic reconnection, shock acceleration, and particle energization in space and astrophysical plasmas.

EPPIC
Core-hours: 1.1M (combined)
Eulerian Parallel PIC - a plasma simulation code using combined particle and grid methods. Used by space physicists studying ionospheric plasma turbulence, plasma waves, and instabilities relevant to space weather and radio propagation.

gkyl
Core-hours: 994K (combined)
A computational plasma physics framework implementing gyrokinetic and kinetic models. Used by fusion and space plasma researchers for studying plasma turbulence, waves, and kinetic effects. Features modern computational methods including discontinuous Galerkin schemes.

OverlapInverterAll
Core-hours: 1.2M
A lattice gauge theory code focusing on overlap fermion inversions. Used by particle physicists in lattice QCD calculations requiring chiral symmetry preservation. Computationally demanding with extreme requirements for linear algebra performance.

overlap_curseq
Core-hours: 5.3M
Lattice QCD code using overlap fermion formulations with stochastic methods. Used by particle physicists for studying QCD with improved chiral symmetry properties. Critical for precision calculations of hadron properties and fundamental physics constants.

---

### Geophysics & Earth Science (7 programs)

ADCIRC
Core-hours: 12.7M
Advanced Circulation model for coastal ocean and estuarine modeling. Used by coastal engineers, oceanographers, and emergency managers for storm surge prediction, tidal analysis, and coastal flooding assessments. Critical for hurricane preparedness and coastal infrastructure planning.

SpecFEM3D
Core-hours: 4.7M
A spectral element code for seismic wave propagation in 3D heterogeneous media. Used by seismologists for earthquake ground motion simulation, seismic hazard assessment, and full-waveform inversion. Heavy BLAS user due to spectral element methods.

CitcomS
Core-hours: 1.2M
A finite element code for modeling thermochemical convection in Earth's mantle. Used by geodynamicists studying mantle circulation, plate tectonics, and deep Earth processes. Important for understanding Earth's thermal evolution and surface tectonics.

emod3d-mpi
Core-hours: 1.9M
An earthquake modeling code for simulating 3D seismic wave propagation. Used by seismologists and earthquake engineers for physics-based ground motion prediction and seismic hazard studies. Focuses on regional earthquake scenarios.

SeisSol
Core-hours: 472K
A high-order discontinuous Galerkin code for seismic wave propagation and earthquake dynamic rupture. Used by computational seismologists for high-resolution earthquake simulations combining fault rupture physics and wave propagation. State-of-the-art in earthquake physics simulation.

RSQSim
Core-hours: 2.5M
Rate-State earthquake simulator for generating long-term synthetic earthquake catalogs. Used by seismologists to study earthquake sequences, fault interactions, and long-term seismic hazard. Bridges earthquake physics and statistical seismology.

ASPECT
Core-hours: 1.6M (combined)
Advanced Solver for Problems in Earth's ConvecTion - a mantle convection code using adaptive mesh refinement. Used by geodynamicists studying mantle dynamics, plate tectonics, and planetary interiors. Open-source and highly extensible.

---

### Computational Fluid Dynamics (6 programs)

OpenFOAM
Core-hours: 332K
Open-source Field Operation And Manipulation - a comprehensive CFD toolbox for continuum mechanics. Used by engineers and researchers across aerospace, automotive, energy, and environmental sectors for simulating fluid flow, heat transfer, and multiphysics problems.

nek5000
Core-hours: 266K
A spectral element CFD code emphasizing incompressible flows and heat transfer. Used by fluid dynamicists studying turbulence, heat exchangers, and complex flow phenomena. Known for high accuracy and efficiency on HPC systems with heavy BLAS usage.

fds_impi_intel_linux
Core-hours: 247K
Fire Dynamics Simulator - a CFD code for fire-driven fluid flow. Used by fire protection engineers, building safety researchers, and firefighting organizations for simulating fire behavior, smoke transport, and building evacuations.

ns.exe
Core-hours: 1.4M
A Navier-Stokes equation solver for fluid dynamics simulations. Used by fluid mechanics researchers for studying various flow phenomena. Generic designation may represent a custom or research group-specific implementation.

psolve
Core-hours: 729K
A pressure-velocity coupled flow solver. Used by CFD researchers for incompressible and low-Mach number flows. Likely a research code for specialized flow problems.

MHDAM3d
Core-hours: 880K (combined)
A magnetohydrodynamics code for studying plasma and conducting fluid dynamics with magnetic fields. Used by astrophysicists and plasma physicists for simulating magnetized flows in space and laboratory plasmas.

---

### Radiative Transfer & Neutrino Transport (4 programs)

fornax
Core-hours: 25.0M (combined)
A multi-dimensional neutrino radiation hydrodynamics code for core-collapse supernovae. Used by astrophysicists studying supernova explosions, neutron star formation, and nucleosynthesis. Critical for understanding how massive stars die and produce heavy elements.

newt
Core-hours: 1.4M
A neutrino transport code for studying neutrino interactions in stellar environments. Used by nuclear astrophysicists studying core-collapse supernovae, neutron star mergers, and other neutrino-driven phenomena.

RT - Radiative Transfer
Core-hours: 2.7M (combined)
A radiative transfer code for studying radiation-matter interactions in various contexts. Used by astrophysicists and plasma physicists for modeling photon transport, radiation pressure effects, and spectral formation.

ks_spectrum
Core-hours: 7.8M
A spectral analysis tool, likely for Kolmogorov-Smirnov or kinetic spectral analysis. Used by researchers analyzing turbulence spectra, power spectral densities, or statistical distributions in simulation data.

---

### Other Scientific Applications (10 programs)

DNS2d
Core-hours: 12.5M
Direct Numerical Simulation code for 2D fluid dynamics. Used by turbulence researchers studying fundamental fluid dynamics without turbulence modeling. Computationally expensive as it resolves all scales of motion.

DSMC-pro
Core-hours: 3.2M
Direct Simulation Monte Carlo code for rarefied gas dynamics. Used by aerospace engineers studying hypersonic flight, vacuum systems, and gas flows where continuum assumptions break down. Important for spacecraft design and microfluidics.

ufs_model.x
Core-hours: 15.8M (combined)
Unified Forecast System - NOAA's next-generation weather prediction model. Used by meteorologists and climate scientists for weather forecasting and seasonal prediction. Aims to unify research and operational weather prediction.

drift_diffusion
Core-hours: 2.0M
A semiconductor device physics simulator solving drift-diffusion equations. Used by electrical engineers and device physicists designing transistors, solar cells, and optoelectronic devices. Models carrier transport in semiconductors.

sgw.x
Core-hours: 6.4M
Self-Gravitating Wave simulation code. Used by astrophysicists or fluid dynamicists studying wave phenomena with gravitational effects, possibly in astrophysical contexts or nonlinear wave dynamics.

mpipycitcoms
Core-hours: 2.1M
MPI-Python implementation of CitcomS for geodynamic simulations. Used by computational geodynamicists for mantle convection studies. Combines Python flexibility with parallel performance for Earth modeling.

ChaNGa
Core-hours: 915K
Charm N-body GrAvity solver - a parallel TreePM code for cosmological simulations. Used by cosmologists for dark matter and galaxy formation simulations. Leverages the Charm++ framework for dynamic load balancing.

rhea_earth
Core-hours: 1.7M
An Earth system model component, likely focused on specific geological or geophysical processes. Used by Earth scientists for studying planetary-scale processes, possibly related to mantle dynamics or crustal evolution.

arts
Core-hours: 373K
Atmospheric Radiative Transfer Simulator - for modeling electromagnetic radiation through planetary atmospheres. Used by atmospheric scientists and remote sensing specialists for interpreting satellite observations and studying atmospheric composition.

dynamics.x
Core-hours: 348K
A molecular or structural dynamics solver. Used by researchers studying time-evolution of physical systems, could be for molecular dynamics, orbital mechanics, or structural engineering applications.

---

### Specialized Utilities (10 programs)

Clubbed
Core-hours: 3.0M (combined)
A custom production simulation code, likely domain-specific. Used by a specialized research group for coupled or multi-physics simulations. Name suggests combined/integrated physics modules.

StochasticSandwich_3pt_Connect
Core-hours: 738K
A lattice QCD code for computing three-point correlation functions with stochastic methods. Used by particle physicists calculating hadron structure observables like form factors and parton distribution functions.

HadronsXmlRun
Core-hours: 374K
Part of the Hadrons lattice QCD analysis framework. Used by particle physicists for post-processing lattice QCD configurations and computing hadronic observables. XML-driven workflow for systematic calculations.

shock.Linux
Core-hours: 1.2M
A shock physics simulation code for studying shock waves in materials. Used by researchers in high-energy density physics, impact physics, and materials under extreme conditions. Relevant for defense and planetary science applications.

taddexp3d
Core-hours: 1.1M
A 3D solver, likely for time-dependent problems. Used by researchers solving PDEs in three dimensions, possibly for fluid dynamics or wave propagation problems.

waveqlab3d
Core-hours: 1.1M
A 3D wave equation solver for laboratory-scale problems. Used by physicists and engineers studying wave propagation, acoustics, seismic waves, or electromagnetic waves in complex 3D geometries.

harm3d
Core-hours: 717K
A 3D general relativistic magnetohydrodynamics (GRMHD) code. Used by astrophysicists studying black hole accretion, jets, and magnetized plasma in strong gravitational fields. Critical for modeling active galactic nuclei and black hole systems.

mhd_sim_driver
Core-hours: 431K
A driver code for magnetohydrodynamics simulations. Used by plasma physicists or astrophysicists coordinating MHD simulation workflows. Likely manages parameter studies or ensemble simulations.

farms-opt
Core-hours: 266K
An optimization framework, possibly for multi-objective or parameter optimization. Used by researchers performing systematic optimization studies across various scientific domains. Could be for design optimization or inverse problems.

---

## Simple Executable Name List

CESM
WRF
SWMF
Gromacs
VASP
NAMD
LAMMPS
Siesta
Amber
orca
QE
Chroma
BerkeleyGW
hmc_tm
overlap_curseq
ctqmc
lapw1c
dmft2
ShengBTE
Abinit
FHI-aims
SpEC
Cactus
rockstar-galaxies
GIZMO
ENZO
athena
Gadget
Flash4
astrobear
gene_frontera
CGS
Tristan-MP
EPPIC
gkyl
OverlapInverterAll
ADCIRC
SpecFEM3D
CitcomS
emod3d-mpi
SeisSol
RSQSim
ASPECT
OpenFOAM
nek5000
fds_impi_intel_linux
ns.exe
psolve
MHDAM3d
fornax
newt
RT
ks_spectrum
DNS2d
DSMC-pro
ufs_model.x
drift_diffusion
sgw.x
mpipycitcoms
ChaNGa
rhea_earth
arts
dynamics.x
Clubbed
StochasticSandwich_3pt_Connect
HadronsXmlRun
shock.Linux
taddexp3d
waveqlab3d
harm3d
mhd_sim_driver
farms-opt

---

## Profiling Priorities

### High Priority (Heavy BLAS/LAPACK/FFTW usage expected):
- VASP, QE, Gromacs, NAMD, BerkeleyGW, Abinit, FHI-aims, Siesta
- SpecFEM3D, SeisSol (FFTW for spectral methods)
- nek5000 (spectral element - heavy BLAS usage)
- SpEC (spectral methods - FFTW)

### Medium Priority (Moderate library usage):
- LAMMPS, CESM, WRF, Cactus, ENZO, Flash4
- OpenFOAM, ASPECT, CitcomS
- Chroma, hmc_tm, lapw1c, overlap_curseq

### Lower Priority (Domain-specific or less library-dependent):
- Particle codes (Gadget, GIZMO, rockstar-galaxies)
- Monte Carlo codes (DSMC-pro, ctqmc)
- Specialized plasma/astrophysics codes

---

## Notes
- Programs marked with asterisk in original list indicate suite/family of related tools
- Core-hour totals shown for reference only
- Combined totals calculated where variants were consolidated
- Focus profiling efforts on high-priority applications first for maximum impact
