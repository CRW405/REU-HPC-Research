#!/bin/bash
# ================================================
#
# cesm.sh
#
# CESM - Community Earth System Model
# Version: release-cesm2.2.2
# System: Stampede3, TACC
# Created by: Caleb W with help from CLAUDE
# Last modified: 7/17/26
#
# BEFORE RUNNING:
#   1. Request access to the ESCOMP GitHub org at:
#      https://github.com/ESCOMP  (free — just join)
#   2. Make sure you have an ssh key registered with
#      GitHub: ssh -T git@github.com
#   3. Run from $SCRATCH — checkout_externals pulls
#      several GB of component models
#   4. Set CASE_NAME and PROJECT below
#
# WORKFLOW OVERVIEW:
#   This script handles steps 1-3 (clone, port, fix).
#   After it finishes, run the create_newcase block
#   at the bottom manually, then case.setup/build/submit.
# ================================================

ml reset
ml intel
ml impi
ml hdf5
ml netcdf       # sets TACC_NETCDF_DIR (includes Fortran)
ml pnetcdf      # sets TACC_PNETCDF_DIR — remove if not available

# ---- USER SETTINGS ----
CASE_NAME="b1850_test_$(date +%m%d%H%M)"
PROJECT="EAR23006"                        # your allocation
CASE_DIR="${SCRATCH}/cesm_cases/${CASE_NAME}"
# -----------------------

ROOT_DIR=`pwd`
CESM_DIR=${ROOT_DIR}/cesm-2.2.2

# ================================================
# STEP 1: Clone CESM
# ================================================
if [[ 1 == 1 ]]; then
  cd ${ROOT_DIR}
  git clone -b release-cesm2.2.2 https://github.com/ESCOMP/CESM.git ${CESM_DIR}
fi

# ================================================
# STEP 2: Checkout all component models
# This pulls CAM, CLM, CICE, POP, MOM6, etc.
# Takes ~10-20 min depending on network — run in idev
# ================================================
if [[ 1 == 1 ]]; then
  cd ${CESM_DIR}
  ./manage_externals/checkout_externals
fi

# ================================================
# STEP 3: Apply jedwards4b's Stampede3 CIME port
# The official CIME repo has no Stampede3 entry;
# this branch adds one under the name "stampede2-skx"
# (the hostname regex matches stampede3 nodes too).
# ================================================
if [[ 1 == 1 ]]; then
  cd ${CESM_DIR}/cime
  git remote add jpe https://github.com/jedwards4b/cime
  git fetch jpe
  git checkout port/maint-5.6/stampede3

  # Fix: -zmuldefs is no longer supported by the Intel
  # linker in oneAPI and causes a link failure. Remove it.
  sed -i 's/ -zmuldefs//g' config/cesm/machines/config_compilers.xml
  echo "Port applied and -zmuldefs removed."
fi

# ================================================
# STEP 4: Create, set up, build, and submit a case
# Run these commands MANUALLY after this script finishes.
# ================================================
cat <<'INSTRUCTIONS'

=======================================================
NEXT STEPS — run these after this script completes:
=======================================================

# Create a test case (2-degree atmosphere + ocean, pre-industrial)
${CESM_DIR}/cime/scripts/create_newcase \
  --case ${CASE_DIR} \
  --compset B1850 \
  --res f19_g17 \
  --machine stampede2-skx \
  --compiler intel \
  --project ${PROJECT}

cd ${CASE_DIR}

# Configure the case (generates namelists and build dirs)
./case.setup

# Optional: reduce run length for a quick test
./xmlchange STOP_OPTION=ndays,STOP_N=5

# Build (compiles all components — ~20-40 min)
# Run this in an idev session or submit as a build job
./case.build

# Submit the run to SLURM
./case.submit

# Monitor:
squeue -u $USER
tail -f $CASE_DIR/run/cesm.log.*
=======================================================

CESM input data is large. If TACC has a shared cache,
set DIN_LOC_ROOT before building:
  ./xmlchange DIN_LOC_ROOT=/path/to/shared/inputdata
Ask TACC consulting if a shared CESM input data cache
exists on Stampede3 (saves downloading hundreds of GB).

INSTRUCTIONS
