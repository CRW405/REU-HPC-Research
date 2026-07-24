# ================================================
#
# warpx.sh
#
# Version: WarpX (master), CPU/Intel build, 3D, OpenMP+MPI
# System: Stampede3, TACC
# Created by: Caleb W with help from CLAUDE
# Last modified: 6/30/26
#
# ================================================
# MODULES
ml reset
ml intel
ml impi
ml cmake

ROOT_DIR=`pwd`
INSTALL_DIR=${ROOT_DIR}/install
mkdir -p ${INSTALL_DIR}

# WARPX
if [[ 1 == 1 ]]; then
  cd ${ROOT_DIR}
  rm -rf warpx-build
  git clone --recursive https://github.com/BLAST-WarpX/warpx.git warpx-src
  mkdir -p warpx-build
  cd warpx-build

  cmake ${ROOT_DIR}/warpx-src \
        -DCMAKE_C_COMPILER=icx \
        -DCMAKE_CXX_COMPILER=icpx \
        -DCMAKE_INSTALL_PREFIX=${INSTALL_DIR} \
        -DWarpX_DIMS="3" \
        -DWarpX_COMPUTE=OMP \
        -DWarpX_MPI=ON

  cmake --build . -j16
  cmake --install .
fi
