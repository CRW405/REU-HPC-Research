#!/bin/bash
# --- Environment Setup ---
echo "==> Setting up environment modules..."
module reset
module load intel impi cmake

# --- Paths ---
WORKSPACE="/scratch/11603/crw405/build_scripts/shengbte"
SPG_SRC="${WORKSPACE}/spglib-src"
SPG_INSTALL="${WORKSPACE}/install_spglib"
SHENG_SRC="${WORKSPACE}/ShengBTE-src"

# Clean up failed previous build directories to ensure a clean run
rm -rf "${SPG_SRC}/build" "${SPG_INSTALL}"

# ==========================================
# 1. Build Spglib Dependency
# ==========================================
if [ ! -d "${SPG_INSTALL}" ]; then
    echo "==> Compiling Spglib dependency with compatibility flag..."
    if [ ! -d "${SPG_SRC}" ]; then
        git clone -b v1.16.2 https://github.com/spglib/spglib.git "${SPG_SRC}"
    fi
    mkdir -p "${SPG_SRC}/build" && cd "${SPG_SRC}/build"

    # Injected -DCMAKE_POLICY_VERSION_MINIMUM=3.5 to clear the modern CMake strict policy error
    cmake .. \
        -DCMAKE_C_COMPILER=icx \
        -DCMAKE_INSTALL_PREFIX="${SPG_INSTALL}" \
        -DBUILD_SHARED_LIBS=OFF \
        -DCMAKE_POLICY_VERSION_MINIMUM=3.5
    make -j 4
    make install
fi

# ==========================================
# 2. Configure and Build ShengBTE
# ==========================================
if [ ! -d "${SHENG_SRC}" ]; then
    git clone https://github.com/buaa-hipo/ShengBTE-Multiplatform.git "${SHENG_SRC}"
fi

cd "${SHENG_SRC}/Src"

echo "==> Provisioning arch.make with Spglib pointers..."
cat << EOF > arch.make
MPIFC = mpif90
FFLAGS = -FR -O3 -qopenmp
MPEFLAGS = -DFFTW -D_OPENMP

# Explicitly point to the library we just built
LDFLAGS = -qmkl=cluster -I${SPG_INSTALL}/include
LIBS = ${SPG_INSTALL}/lib64/libsymspg.a
EOF

echo "==> Launching compilation engine..."
make clean
make

echo "==> ShengBTE compilation finalized."
