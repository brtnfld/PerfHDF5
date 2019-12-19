#!/bin/bash -l
#BSUB -P CSC300
#BSUB -W 00:30
# power 42
#BSUB -nnodes 42
#BSUB -J cgns 
#BSUB -o cgns.%J
#BSUB -e cgns.%J
##SMT1 -- 1 HW Thread per physical core
##SMT4 -- All 4 HW threads are active (Default)
##BSUB -alloc_flags smt1
# 42 physical cores, (21 each cpu), per node

##BSUB -alloc_flags maximizegpfs

## SUBMIT ME: bsub batch.summit.sh

#OpenMP settings:
#export OMP_NUM_THREADS=1
#export OMP_PLACES=threads
#export OMP_PROC_BIND=spread

#export MPICH_MPIIO_STATS=1
#export MPICH_MPIIO_HINTS_DISPLAY=1
#export MPICH_MPIIO_TIMERS=1
#export DARSHAN_DISABLE_SHARED_REDUCTION=1
#export DXT_ENABLE_IO_TRACE=1

JID=$LSB_JOBID
cd $LS_SUBCWD

tsk="1764"
#./run_cgns.sh --hdf5_nobuild --cgns_nobuild
./run_cgns.sh --enable-parallel --hdf5_nobuild --cgns_nobuild --ptest $tsk 420000000
ls -aolF

