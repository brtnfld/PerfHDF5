// seism-core-test.c //////////////////////////////////////////////////////////
// This kernel writes a four-dimensional a chunked HDF5 dataset in parallel
// based on inputs provided on standard input. The required inputs are the
// following:
//
// 1. The dimensions (> 1) of a 3D process grid. The number of processes
//    must be equal to the MPI communicator size.
// 2. The spatial dimensions (> 1) of the HDF5 dataset chunks.
// 3. The voxel resolution (per process).
// 4. The number of time steps (>= 1) to be written.
//
// An example input script is shown below. Binary options are set by 
// presence or absence of corresponding line:
//
// mpiexec -n 8 ./seism-core << EOF
// processor 2 2 2
// chunk 180 64 64
// domain 180 64 64
// time 2
// collective_write
// precreate
// set_collective_metadata
// early_allocation
// never_fill
// DONE
// EOF
//
////////////////////////////////////////////////////////////////////////////

#include "hdf5.h"

#include <cassert>
#include <iostream>
#include <string>
#include <sstream>
#include <vector>

#include "seism-core-attributes.hh"

using namespace std;

#define CHUNKED_DSET_NAME "chunked"

////////////////////////////////////////////////////////////////////////////////
  
int main(int argc, char** argv)
{

    if (argc < 2) 
      {
        cout << "No filename specified\n" ;
        exit(1);
      }
    char *filename = argv[1];

    // open file and read the attributes
    hid_t file = H5Fopen(filename, H5F_ACC_RDONLY, H5P_DEFAULT);
    assert(file >= 0);
    cout << "creating attributes in main:" << endl;
    seismCoreAttributes attr(file);

    //cout << "attr.name: " << attr.name << endl;
    cout << "in main after declaration, attr.attributes_h5t: " << attr.attributes_h5t << endl;

    cout << attr.name << endl;
    cout << attr.processor_dims[0] << endl;
    cout << attr.processor_dims[1] << endl;
    cout << attr.processor_dims[2] << endl;
//    cout << attr.chunk_dims[0] << endl;
//    cout << attr.chunk_dims[1] << endl;
//    cout << attr.chunk_dims[2] << endl;
    cout << attr.domain_dims[0] << endl;
    cout << attr.domain_dims[1] << endl;
    cout << attr.domain_dims[2] << endl;
    cout << attr.simulation_time << endl;
    cout << attr.collective_write << endl;
    cout << attr.precreate << endl;


    // file is open, we have the attributes, etc. now get the data

    // loop over processor geom
    for (unsigned int t=0; t<attr.simulation_time; t++) {
        // create a buffer to hold one domain worth of junk
        int ***buffer = (int ***)malloc(sizeof(int) * attr.domain_dims[0] * attr.domain_dims[1] * attr.domain_dims[2]); 

        // open the dataset
        dset = H5Dopen (file, CHUNKED_DSET_NAME, H5P_DEFAULT);

        // read the dataset into the buffer
        assert( H5Dread (dset, H5T_NATIVE_INT, H5S_ALL, H5S_ALL, H5P_DEFAULT, buffer) >= 0);

        unsigned int grand_sum=0;
        for (unsigned int i=0; i<processor_dims[0]; i++)
            for (unsigned int j=0; j<processor_dims[1]; j++)
                for (unsigned int k=0; k<processor_dims[2]; k++)
                    grand_sum += 0; // expression for buffer, something like [i*domain_dims[0]*domain_dims[1] + j*domain_dims[1] + k]; 

        // compare the grand sum to what it should be.. i.e. number of elements * rank
        int mpi_rank = i*processor_dims[1]*processor_dims[2] + j * processor_dims[1] + k *pro ... gaaah!





    hid_t space = H5Dget_space (dset);
    start[0] = 0;
    start[1] = 1;
    stride[0] = 4;
    stride[1] = 4;
    count[0] = 2;
    count[1] = 2;
    block[0] = 2;
    block[1] = 3;
    status = H5Sselect_hyperslab (space, H5S_SELECT_SET, start, stride, count, block);

        // select hyperslab
        // read the data

        // loop and sum over domain dims 


    }

    /*
    unsigned int processor_dims[3];
    unsigned int chunk_dims[3];
    unsigned int domain_dims[3];
    unsigned int simulation_time;
    int collective_write;
    int precreate;
    int set_collective_metadata;
    int early_allocation;
    int never_fill;
    */

    H5Fclose(file);
}

/*

  // create the fle dataspace, time dimension first!
  hsize_t n_dims = 4;
  hsize_t dims[H5S_MAX_RANK];

  hid_t fspace = H5Screate_simple(n_dims, dims, NULL);
  assert(fspace >= 0);

  // set up chunking... NOTE: extent of time dimension is 1

  hsize_t cdims[H5S_MAX_RANK];
  cdims[0] = 1;
  cdims[1] = chunk[0];
  cdims[2] = chunk[1];
  cdims[3] = chunk[2];

  // create dcpl and set properties
  hid_t dcpl = H5Pcreate(H5P_DATASET_CREATE);
  assert(dcpl >= 0);
  assert(H5Pset_chunk(dcpl, n_dims, cdims) >= 0);
  if (never_fill) assert(H5Pset_fill_time(dcpl, H5D_FILL_TIME_NEVER ) >= 0);
  if (early_allocation) 
      assert(H5Pset_alloc_time(dcpl, H5D_ALLOC_TIME_EARLY) >= 0);

  hid_t dapl = H5Pcreate(H5P_DATASET_ACCESS);
  assert(dapl >= 0);
  //////////////////////////////////////////////////////////////////////////////
  // prepare hyperslab selection, use max dims, can ignore 4th as needed
  hsize_t start[4], block[4], count[4] = {1,1,1,1};

  //////////////////////////////////////////////////////////////////////////////
  // create in-memory dataspace
  dims[0] = 1;
  dims[1] = domain[0];
  dims[2] = domain[1];
  dims[3] = domain[2];

  hid_t mspace = H5Screate_simple(n_dims, dims, NULL);
  assert(mspace >= 0);
  assert(H5Sselect_all(mspace) >= 0);

*/
