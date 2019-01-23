#!/bin/bash -l
#BATCH -o brtnfld.o%j
#SBATCH -t 05:00:00
#SBATCH --ntasks-per-node=32 # Cori
#SBATCH -C haswell
###   1  2  4   8   16  32   64   128
###   32 64 128 256 512 1024 2048 4096
###   1  2  4   8  16  32   64  128  256   512  1024
#### 24 48 96 192 384 768 1536 3072 6144 12288 24576
#SBATCH -N 1024
#SBATCH -p regular
##SBATCH -p debug
##SBATCH -N 1
tsk=$(($SLURM_NTASKS_PER_NODE*$SLURM_JOB_NUM_NODES))

# lfs setstripe -c 124 -S 128m CGNS.*/src/ptests
./run_cgns.sh --enable-parallel --hdf5_nobuild --cgns_nobuild --ptest $tsk 201326592
#./run_cgns.sh --enable-parallel --hdf5_nobuild --cgns_nobuild --ptest $tsk 33554432

