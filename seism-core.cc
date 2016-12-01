////////////////////////////////////////////////////////////////////////////
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
// An example input script is shown below:
//
// mpiexec -n 8 ./seism-core << EOF
// processor 2 2 2
// chunk 180 64 64
// domain 180 64 64
// time 2
// DONE
// EOF
//
////////////////////////////////////////////////////////////////////////////

#include "hdf5.h"
#include "seism-core.hh"

#include <cassert>
#include <iostream>
#include <string>
#include <sstream>
#include <vector>

using namespace std;

void precreate(hid_t file, unsigned int simulation_time, string dname, hid_t fspace, hid_t lcpl, hid_t dcpl)
{
    for (unsigned int it = 0; it < simulation_time; ++it)
      {
        // if storing timesteps separately, create a new group for each:
        string path = "/" + padIntWithZeros(it, 6) + "/" + dname;
        // create a new dataset for each timestep
        hid_t dset = H5Dcreate(file, path.c_str(), H5T_IEEE_F32LE,
        fspace, lcpl, dcpl, H5P_DEFAULT);
        assert(dset >= 0);
        assert(H5Dclose(dset) >= 0);
      }
}

void setMPI_Info(size_t v_size, int mpi_size, hid_t fapl)
{
    MPI_Info info;
    assert(MPI_Info_create(&info) == MPI_SUCCESS);
    assert(MPI_Info_set( info, "romio_cb_write", "enable" ) == MPI_SUCCESS);
    assert(MPI_Info_set( info, "romio_ds_write", "disable" ) == MPI_SUCCESS);

    ostringstream ost;
    ost << v_size * sizeof(float);
    assert(MPI_Info_set( info, "cb_block_size", ost.str().c_str()) == MPI_SUCCESS);
    assert(MPI_Info_set( info, "cb_buf_size", ost.str().c_str()) == MPI_SUCCESS);
    ost.str("");
    ost << mpi_size;
    assert(MPI_Info_set( info, "cb_nodes", ost.str().c_str() ) == MPI_SUCCESS);
    assert(H5Pset_fapl_mpio(fapl, MPI_COMM_WORLD, info) >= 0);
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

int main(int argc, char** argv)
{
  int mpi_size, mpi_rank;
  MPI_Init(&argc, &argv);
  MPI_Comm_size(MPI_COMM_WORLD, &mpi_size);
  MPI_Comm_rank(MPI_COMM_WORLD, &mpi_rank);

  // rank 0 reads the input file, then broadcasts
  string parameter;
  string rest_of_line;
  unsigned int simulation_time, processor[3], chunk[3], domain[3];
  int mpi_collective_io_int = 0;
  int separate_timesteps = 0;
  int precreate_datasets = 0; 
  // 0 --> don't precreate; -1 --> create collectively; 1 --> only rank 1 creates

  if (mpi_rank==0)
    {
      while (true){
        cin >> parameter;
        if (parameter.at(0) == '#') continue; // ignore as comment
        if (parameter.at(0) == 0) continue; // ignore empty line
        if (!parameter.compare("DONE")) break; // exit
        if (!parameter.compare("processor"))
          cin >> processor[0] >> processor[1] >> processor[2];
        if (!parameter.compare("chunk"))
          cin >> chunk[0] >> chunk[1] >> chunk[2];
        if (!parameter.compare("domain"))
          cin >> domain[0] >> domain[1] >> domain[2];
        if (!parameter.compare("time"))
          cin >> simulation_time;
        if (!parameter.compare("use_collective"))
          mpi_collective_io_int = true;
        if (!parameter.compare("separate_timesteps"))
          separate_timesteps = true;
        if (!parameter.compare("precreate_datasets"))
            cin >> precreate_datasets; 
        getline(cin, rest_of_line); // read the rest of the line
      }
    }

  assert(MPI_Bcast(&simulation_time, 1, MPI_INT, 0, MPI_COMM_WORLD) == MPI_SUCCESS);
  assert(MPI_Bcast(&processor, 3, MPI_INT, 0, MPI_COMM_WORLD) ==
         MPI_SUCCESS);
  assert(MPI_Bcast(&chunk, 3, MPI_INT, 0, MPI_COMM_WORLD) == MPI_SUCCESS);
  assert(MPI_Bcast(&domain, 3, MPI_INT, 0, MPI_COMM_WORLD) == MPI_SUCCESS);
  assert(MPI_Bcast(&mpi_collective_io_int, 1, MPI_INT, 0, MPI_COMM_WORLD) ==
         MPI_SUCCESS);
  assert(MPI_Bcast(&separate_timesteps, 1, MPI_INT, 0, MPI_COMM_WORLD) ==
         MPI_SUCCESS);
  assert(MPI_Bcast(&precreate_datasets, 1, MPI_INT, 0, MPI_COMM_WORLD) ==
         MPI_SUCCESS);
  bool coll_flg = (bool)mpi_collective_io_int; // flg for collective I/O
  bool time_flg = (bool)separate_timesteps; // flg for collective I/O

  // check the arguments
  assert(time > 0);
  assert(processor[0]*processor[1]*processor[2] == (hsize_t) mpi_size);
  assert(processor[0] > 1 && processor[1] > 1 && processor[2] > 1);
  assert(chunk[0] > 1 && chunk[1] > 1 && chunk[2] > 1);
  assert(domain[0] > 1 && domain[1] > 1 && domain[2] > 1);

  if (mpi_rank == 0)
    {
      cout << "\nNumber of processes:\t" << mpi_size << endl;
      cout << "Process layout:\t\t" << processor[0] << " x " <<
        processor[1] << " x " << processor[2] << endl;
      cout << "Per process grid:\t" << domain[0] << " x " << domain[1] <<
        " x " << domain[2] << endl;
      cout << "Chunk dimensions:\t" << chunk[0] << " x " << chunk[1] <<
        " x " << chunk[2] << endl;
      cout << "Number of time steps:\t" << simulation_time << endl;
      cout << "Collective I/O:\t\t" << coll_flg << endl;
      cout << "Separate timesteps:\t" << time_flg << endl;
      cout << "Pre-create datasets:\t" << precreate_datasets << endl;
    }

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

  // create the fle dataspace, time dimension first!
  hsize_t n_dims = 4;
  hsize_t dims[n_dims];

  if (time_flg)
    {
      n_dims = 3;
      dims[0] = processor[0]*domain[0];
      dims[1] = processor[1]*domain[1];
      dims[2] = processor[2]*domain[2];
    }
  else
    {
      dims[0] = simulation_time;
      dims[1] = processor[0]*domain[0];
      dims[2] = processor[1]*domain[1];
      dims[3] = processor[2]*domain[2];
    }

  hid_t fspace = H5Screate_simple(n_dims, dims, NULL);
  assert(fspace >= 0);

////////////////////////////////////////////////////////////////////////////////

  // set up chunking... NOTE: extent of time dimension is 1
  hsize_t cdims[n_dims];

  if (time_flg)
    {
      cdims[0] = chunk[0];
      cdims[1] = chunk[1];
      cdims[2] = chunk[2];
    }
  else
    {
      cdims[0] = 1;
      cdims[1] = chunk[0];
      cdims[2] = chunk[1];
      cdims[3] = chunk[2];
    }

  hid_t dcpl = H5Pcreate(H5P_DATASET_CREATE);
  assert(dcpl >= 0);
  assert(H5Pset_chunk(dcpl, n_dims, cdims) >= 0);

////////////////////////////////////////////////////////////////////////////////

  // prepare hyperslab selection, use max dims, can ignore 4th as needed
  hsize_t start[4], block[4], count[4] = {1,1,1,1};

  // calculate offsets from MPI rank
  if (time_flg)
    {
      start[2] = (hsize_t) mpi_rank % processor[2];
      start[1] = (hsize_t) ((mpi_rank - start[2])/processor[2]) % processor[1];
      start[0] = (hsize_t) ((mpi_rank - start[2])/processor[2] - start[1]) /
        processor[1];
      start[0] *= domain[0];
      start[1] *= domain[1];
      start[2] *= domain[2];

      block[0] = domain[0];
      block[1] = domain[1];
      block[2] = domain[2];

      // hyperslab will be same for all datasets...
      assert(H5Sselect_hyperslab(fspace, H5S_SELECT_SET, start, NULL, count, block) >= 0);
    }
  else
    {
      start[3] = (hsize_t) mpi_rank % processor[2];
      start[2] = (hsize_t) ((mpi_rank - start[3])/processor[2]) % processor[1];
      start[1] = (hsize_t) ((mpi_rank - start[3])/processor[2] - start[2]) /
        processor[1];
      start[1] *= domain[0];
      start[2] *= domain[1];
      start[3] *= domain[2];

      block[0] = 1;
      block[1] = domain[0];
      block[2] = domain[1];
      block[3] = domain[2];
    }

////////////////////////////////////////////////////////////////////////////////

  // data transfer property list for collective I/O, if selected
  hid_t dxpl = H5P_DEFAULT;
  if (coll_flg)
    {
      dxpl = H5Pcreate(H5P_DATASET_XFER);
      assert(H5Pset_dxpl_mpio(dxpl, H5FD_MPIO_COLLECTIVE) >= 0);
    }

////////////////////////////////////////////////////////////////////////////////

  // create in-memory dataspace
  if (time_flg)
    {
      dims[0] = domain[0];
      dims[1] = domain[1];
      dims[2] = domain[2];
    }
  else
    {
      dims[0] = 1;
      dims[1] = domain[0];
      dims[2] = domain[1];
      dims[3] = domain[2];
    }

  hid_t mspace = H5Screate_simple(n_dims, dims, NULL);
  assert(mspace >= 0);
  assert(H5Sselect_all(mspace) >= 0);

////////////////////////////////////////////////////////////////////////////////

  // initialize the test data to MPI rank
  vector<float> v((size_t) domain[0]*domain[1]*domain[2], (float) mpi_rank);

  vector<double> tstamps(simulation_time + 1);

  // create the fapl
  hid_t fapl = H5Pcreate(H5P_FILE_ACCESS);
  assert(fapl >= 0);

  // use the latest file format
  assert(H5Pset_libver_bounds(fapl, H5F_LIBVER_LATEST, H5F_LIBVER_LATEST) >=
         0);

  setMPI_Info(v.size(), mpi_size, fapl); // use MPI-IO

  // file handle and name for file which will be created
  string fname = "seism-test.h5";
  hid_t file; 

  //?MPI_Barrier(MPI_COMM_WORLD);

  string dname = "seism-data";
  hid_t dset; // dataset; will be created/destroyed within time loop or outside
  string path;

  // create an lcpl
  hid_t lcpl = H5Pcreate(H5P_LINK_CREATE);
  assert(H5Pset_create_intermediate_group(lcpl, 1) >= 0);

////////////////////////////////////////////////////////////////////////////////

  // precreate datasets, as needed
  if (time_flg) 
    {
      if (precreate_datasets==1)
        {
          if (mpi_rank==0) // create with process 0, then close & re-open
            { 
              //file = H5Fcreate(fname.c_str(), H5F_ACC_TRUNC, H5P_DEFAULT, fapl);      
              file = H5Fcreate(fname.c_str(), H5F_ACC_TRUNC, H5P_DEFAULT, H5P_DEFAULT);      
              assert(file >= 0);
              precreate(file, simulation_time, dname, fspace, lcpl, dcpl);
              assert(H5Fclose(file) >= 0); 
            }
          MPI_Barrier(MPI_COMM_WORLD);
          file = H5Fopen(fname.c_str(), H5F_ACC_RDWR, fapl); // re-open collectively
          assert (file >= 0);
        }
      else if (precreate_datasets==-1) // create collectively
        { 
          file = H5Fcreate(fname.c_str(), H5F_ACC_TRUNC, H5P_DEFAULT, fapl);      
          assert(file >= 0);
          precreate(file, simulation_time, dname, fspace, lcpl, dcpl);
        }
      else // no precreate, just open the file
        {
          file = H5Fcreate(fname.c_str(), H5F_ACC_TRUNC, H5P_DEFAULT, fapl);      
          assert(file >= 0);
        } 
    }
  else // no time_flag, so create the file and just the one dataset 
    {
      file = H5Fcreate(fname.c_str(), H5F_ACC_TRUNC, H5P_DEFAULT, fapl);      
      assert(file >= 0);
      dset = H5Dcreate(file, dname.c_str(), H5T_IEEE_F32LE, fspace, H5P_DEFAULT, dcpl, H5P_DEFAULT);
      assert(dset >= 0);
    }

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

  // iterate over time
  for (size_t it = 0; it < simulation_time; ++it)
    {
      tstamps[it] = MPI_Wtime();

      // get the appropriate dataset for how we're running
      if (time_flg)
        {
          // if storing timesteps separately, create a new group for each:
          string path = "/" + padIntWithZeros(it, 6) + "/" + dname;
          if (precreate_datasets == 0) dset = H5Dcreate(file, path.c_str(), H5T_IEEE_F32LE, fspace, lcpl, dcpl, H5P_DEFAULT);
          // we've pre-created datasets and just need to open
          else dset = H5Dopen(file, path.c_str(), H5P_DEFAULT);
          assert(dset >= 0);
        }
      else  // time_flg not set, simpler case. just select the right hyperslab
        {
          start[0] = (hsize_t) it;
          assert(H5Sselect_hyperslab(fspace, H5S_SELECT_SET, start, NULL, count, block) >= 0);

        } //end else

    // $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
    // Write the dang data. 
    assert(H5Dwrite(dset, H5T_NATIVE_FLOAT, mspace, fspace, dxpl, &v[0]) >= 0);
    // $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

    //separate time steps requires closing each dataset 
    if (time_flg) assert(H5Dclose(dset) >= 0);

  } // next iteration 
  
////////////////////////////////////////////////////////////////////////////////

  // release open handles
  if (!time_flg) assert(H5Dclose(dset) >= 0);
  assert(H5Pclose(fapl) >= 0);
  assert(H5Sclose(mspace) >= 0);
  assert(H5Pclose(dxpl) >= 0);
  assert(H5Sclose(fspace) >= 0);
  assert(H5Pclose(dcpl) >= 0);
  assert(H5Pclose(lcpl) >= 0);
  assert(H5Fclose(file) >= 0);

  MPI_Barrier(MPI_COMM_WORLD);

  tstamps[simulation_time] = MPI_Wtime();

  // print timings/throughput
  size_t bytes_written = simulation_time * processor[0] * domain[0] *
    processor[1] * domain[1] *  processor[2] * domain[2] * sizeof(float);

  if (mpi_rank == 0)
    {
      cout << "Aggregate throughput:\t" << bytes_written /
        (tstamps[simulation_time] - tstamps[0]) / ((double) (1<<20)) << " MB/s" <<
        endl;
    }

  MPI_Finalize();

  return 0;
}


