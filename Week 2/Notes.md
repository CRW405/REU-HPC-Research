
# Notes

"LINPACK on such machines, given a well-tuned BLAS implementation."

"FFTW has limited support for out-of-order transforms
(using the Message Passing Interface (MPI) version).
The data reordering incurs an overhead,
which for in-place transforms of arbitrary size and dimension is non-trivial to avoid.
It is undocumented for which transforms this overhead is significant."

cmake -DCMAKE_C_COMPILER=mpicc -DCMAKE_CXX_COMPILER=mpicxx --install-prefix=$HOME ..
// or with gcc and g++
// without mpi:
cmake -DCMAKE_C_COMPILER=gcc -DCMAKE_CXX_COMPILER=g++ -DMPI_FOUND=OFF ..

3pm Tuesday

cmake -DBUILD_TESTS=ON -DCMAKE_C_COMPILER=mpicc -DCMAKE_CXX_COMPILER=mpicxx --install-prefix=$HOME ..

