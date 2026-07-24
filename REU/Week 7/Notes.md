
  sw4.sh

  Follows the same pattern as qe.sh. Key notes:
  - Uses git clone -b v3.0 for the latest stable release
  - Correct CMake flags: -DUSE_HDF5=ON, -DUSE_FFTW3=OFF, -DUSE_PROJ=OFF
  - -DBLA_VENDOR=Intel10_64lp tells CMake to use MKL (set automatically by ml
  intel)
  - FFTW3 is disabled because TACC doesn't ship a FFTW3 module for the Intel
  stack on Stampede3; enable it only if you build FFTW3 from source
  - Binary ends up at install/bin/sw4

  ---
  cesm.sh + cesm_instructions.md

  CESM is too involved for a pure build script — it has a machine porting step
  and a case-management workflow. The script automates steps 1–3 (clone →
  checkout_externals → apply Stampede3 port → fix a broken linker flag), then
  prints the manual commands for steps 4–7. The markdown file is a full
  reference guide.

  The critical gotcha the research agent surfaced: the community Stampede3 port
  (from jedwards4b/cime) includes a -zmuldefs linker flag that the Intel oneAPI
  linker no longer supports. The script patches it out automatically with sed.
  You'll also need to ask TACC consulting about a shared CESM input data cache —
  without one, the model tries to auto-download hundreds of GB at runtime.
