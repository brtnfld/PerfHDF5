cmake_minimum_required (VERSION 3.10.2)
project (combust_io C Fortran)

set (FIND_HDF_COMPONENTS C Fortran static)
find_package (HDF5 NAMES "hdf5" COMPONENTS ${FIND_HDF_COMPONENTS})
if (HDF5_FOUND)
  if (HDF5_static_Fortran_FOUND)
    set (LINK_LIBS ${LINK_LIBS} ${HDF5_FORTRAN_STATIC_LIBRARY})
  endif ()
else ()
  message (FATAL_ERROR " HDF5 is Required")
endif ()

INCLUDE_DIRECTORIES (${HDF5_INCLUDE_DIR} ${HDF5_INCLUDE_DIR_FORTRAN})

#-----------------------------------------------------------------------------
# Enable MPI Parallel
#-----------------------------------------------------------------------------
find_package(MPI REQUIRED)
if (MPI_Fortran_FOUND)
  set (H5_HAVE_PARALLEL 1)
else ()
  message (FATAL_ERROR "Required Parallel libraries not found")
endif ()

# Parallel IO usage requires MPI to be Linked and Included
if (H5_HAVE_PARALLEL)
  set (LINK_LIBS ${LINK_LIBS} ${MPI_Fortran_LIBRARIES})
  if (MPI_C_LINK_FLAGS)
    set (CMAKE_EXE_LINKER_FLAGS "${MPI_Fortran_LINK_FLAGS} ${CMAKE_EXE_LINKER_FLAGS}")
  endif ()
endif ()

set(CMAKE_C_FLAGS "${CMAKE_Fortran_FLAGS} -O2")

set (combust_io_srcs
    src/IO.F90
    src/KERNEL.F90
)

add_executable (combust_io ${combust_io_srcs})
target_link_libraries (combust_io ${LINK_LIBS})
target_include_directories(combust_io PUBLIC ${MPI_Fortran_INCLUDE_DIRS})
set_property (TARGET combust_io
      APPEND PROPERTY COMPILE_DEFINITIONS STANDALONE
)

macro (prep_data dir_count)
  file (MAKE_DIRECTORY "${PROJECT_BINARY_DIR}/data")
  foreach(i RANGE ${dir_count})
    file (MAKE_DIRECTORY "${PROJECT_BINARY_DIR}/data/${i}")
  endforeach()
endmacro()

add_test (
   NAME CLEAR_combust_io
   COMMAND ${CMAKE_COMMAND} -E remove *.h5 *.mod
)

#input settings
#nx,ny,nz,ng
#   256,256,256,2
#iprc,jprc,kprc
#   4,4,4
#relay,relay size
#   1,32
#write flag
#   1
#chunk dims
#   -1,-1,-1
set (TEST_nprocs 64) #iprc * jprc * kprc

add_custom_command (
    TARGET     combust_io
    POST_BUILD
    COMMAND    ${CMAKE_COMMAND}
    ARGS       -E copy_if_different "${PROJECT_SOURCE_DIR}/input" "${PROJECT_BINARY_DIR}/input"
)

prep_data (4)

add_test (NAME TEST_combust_io COMMAND "${CMAKE_COMMAND}"
    -D "TEST_PROGRAM=${MPIEXEC_EXECUTABLE};${MPIEXEC_NUMPROC_FLAG};${TEST_nprocs};${MPIEXEC_PREFLAGS};$<TARGET_FILE:combust_io>;${MPIEXEC_POSTFLAGS}"
    -D "TEST_ARGS:STRING="
    -D "TEST_EXPECT=0"
    -D "TEST_SKIP_COMPARE:BOOL=true"
    -D "TEST_OUTPUT=combust_io.out"
    -D "TEST_FOLDER=${PROJECT_BINARY_DIR}"
    -P "${PROJECT_SOURCE_DIR}/../scripts/runTest.cmake"
)
set_tests_properties (TEST_combust_io PROPERTIES DEPENDS CLEAR_combust_io)

set (DART_TESTING_TIMEOUT 1200
    CACHE STRING
    "Timeout in seconds for each test (default 1200=20minutes)"
)
enable_testing ()
include (CTest)
include (${PROJECT_SOURCE_DIR}/CTestConfig.cmake)

