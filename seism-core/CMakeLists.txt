cmake_minimum_required (VERSION 3.10.2)
project (seism-core C CXX)
include (CheckIncludeFileCXX)
include (TestForSTDNamespace)

set (FIND_HDF_COMPONENTS C static)
find_package (HDF5 NAMES "hdf5" COMPONENTS ${FIND_HDF_COMPONENTS})
if (HDF5_FOUND)
  if (HDF5_static_C_FOUND)
    set (LINK_LIBS ${LINK_LIBS} ${HDF5_C_STATIC_LIBRARY})
  endif ()
else ()
  message (FATAL_ERROR " HDF5 is Required")
endif ()

INCLUDE_DIRECTORIES (${HDF5_INCLUDE_DIR})

#-----------------------------------------------------------------------------
# Enable MPI Parallel
#-----------------------------------------------------------------------------
find_package(MPI REQUIRED)
if (MPI_CXX_FOUND)
  set (H5_HAVE_PARALLEL 1)
else ()
  message (FATAL_ERROR "Required Parallel libraries not found")
endif ()

# Parallel IO usage requires MPI to be Linked and Included
if (H5_HAVE_PARALLEL)
  set (LINK_LIBS ${LINK_LIBS} ${MPI_CXX_LIBRARIES})
  if (MPI_CXX_LINK_FLAGS)
    set (CMAKE_EXE_LINKER_FLAGS "${MPI_CXX_LINK_FLAGS} ${CMAKE_EXE_LINKER_FLAGS}")
  endif ()
endif ()

set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wall -pedantic -O2 -std=c++0x")

set (seism-core_srcs
    src/seism-core-slice.cc
    src/seism-core-attributes.cc
    src/seism-core-attributes.hh
)

add_executable (seism-core-slice ${seism-core_srcs})
target_link_libraries (seism-core-slice ${LINK_LIBS})
target_include_directories(seism-core-slice PUBLIC ${MPI_CXX_INCLUDE_DIRS})

set (seism-core-check_srcs
    src/seism-core-check.cc
    src/seism-core-attributes.cc
    src/seism-core-attributes.hh
)

add_executable (seism-core-check ${seism-core-check_srcs})
target_link_libraries (seism-core-check ${LINK_LIBS})
target_include_directories(seism-core-check PUBLIC ${MPI_CXX_INCLUDE_DIRS})

set (TEST_nprocs 8) #processor 2 2 2

add_test (
   NAME CLEAR_seism-core-slice
   COMMAND ${CMAKE_COMMAND} -E remove *.h5
)

add_test (NAME TEST_seism-core-slice COMMAND "${CMAKE_COMMAND}"
    -D "TEST_PROGRAM=${MPIEXEC_EXECUTABLE};${MPIEXEC_NUMPROC_FLAG};${TEST_nprocs};${MPIEXEC_PREFLAGS};$<TARGET_FILE:seism-core-slice>;${MPIEXEC_POSTFLAGS}"
    -D "TEST_ARGS:STRING="
    -D "TEST_EXPECT=0"
    -D "TEST_INPUT=${PROJECT_SOURCE_DIR}/tests/check-0.in"
    -D "TEST_OUTPUT=seism-core-slice.out"
    -D "TEST_SKIP_COMPARE:BOOL=true"
    -D "TEST_FOLDER=${PROJECT_BINARY_DIR}"
    -P "${PROJECT_SOURCE_DIR}/../scripts/runTest.cmake"
)
set_tests_properties (TEST_seism-core-slice PROPERTIES DEPENDS CLEAR_seism-core-slice)

add_test (NAME TEST_seism-core-check COMMAND "${CMAKE_COMMAND}"
    -D "TEST_PROGRAM=${MPIEXEC_EXECUTABLE};${MPIEXEC_NUMPROC_FLAG};8;${MPIEXEC_PREFLAGS};$<TARGET_FILE:seism-core-check>;${MPIEXEC_POSTFLAGS}"
    -D "TEST_ARGS:STRING=seism-test.h5"
    -D "TEST_EXPECT=0"
    -D "TEST_OUTPUT=seism-core-check.out"
    -D "TEST_SKIP_COMPARE:BOOL=true"
    -D "TEST_FOLDER=${PROJECT_BINARY_DIR}"
    -P "${PROJECT_SOURCE_DIR}/../scripts/runTest.cmake"
)
set_tests_properties (TEST_seism-core-check PROPERTIES DEPENDS TEST_seism-core-slice)

set (DART_TESTING_TIMEOUT 1200
    CACHE STRING
    "Timeout in seconds for each test (default 1200=20minutes)"
)
enable_testing ()
include (CTest)
include (${PROJECT_SOURCE_DIR}/CTestConfig.cmake)

