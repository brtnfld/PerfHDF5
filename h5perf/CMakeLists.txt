cmake_minimum_required (VERSION 3.10.2)
project (h5perf C)

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
if (MPI_C_FOUND)
  set (H5_HAVE_PARALLEL 1)
else ()
  message (FATAL_ERROR "Required Parallel libraries not found")
endif ()

# Parallel IO usage requires MPI to be Linked and Included
if (H5_HAVE_PARALLEL)
  set (LINK_LIBS ${LINK_LIBS} ${MPI_C_LIBRARIES})
  if (MPI_C_LINK_FLAGS)
    set (CMAKE_EXE_LINKER_FLAGS "${MPI_C_LINK_FLAGS} ${CMAKE_EXE_LINKER_FLAGS}")
  endif ()
endif ()

set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -Wall -O2")

set (h5perf_srcs
    src/pio_engine.c
    src/pio_perf.c
    src/pio_perf.h
    src/pio_timer.c
    src/pio_timer.h
)

add_executable (h5perf ${h5perf_srcs})
target_link_libraries (h5perf ${LINK_LIBS})
target_include_directories(h5perf PUBLIC ${MPI_C_INCLUDE_DIRS})
set_property (TARGET h5perf
      APPEND PROPERTY COMPILE_DEFINITIONS STANDALONE
)

set (TEST_nprocs 6)

add_test (
   NAME CLEAR_h5perf
   COMMAND ${CMAKE_COMMAND} -E remove *.h5
)

add_test (NAME TEST_h5perf COMMAND "${CMAKE_COMMAND}"
    -D "TEST_PROGRAM=${MPIEXEC_EXECUTABLE};${MPIEXEC_NUMPROC_FLAG};${TEST_nprocs};${MPIEXEC_PREFLAGS};$<TARGET_FILE:h5perf>;${MPIEXEC_POSTFLAGS}"
    -D "TEST_ARGS:STRING=-B;2;-e;8;-p;6;-P;6;-x;4;-X;4;--debug=r,t;-d;4;-F;4;-i;40"
    -D "TEST_EXPECT=0"
    -D "TEST_SKIP_COMPARE:BOOL=true"
    -D "TEST_OUTPUT=h5perf.out"
    -D "TEST_FOLDER=${PROJECT_BINARY_DIR}"
    -P "${PROJECT_SOURCE_DIR}/../scripts/runTest.cmake"
)
set_tests_properties (TEST_h5perf PROPERTIES DEPENDS CLEAR_h5perf)

set (DART_TESTING_TIMEOUT 1200
    CACHE STRING
    "Timeout in seconds for each test (default 1200=20minutes)"
)
enable_testing ()
include (CTest)
include (${PROJECT_SOURCE_DIR}/CTestConfig.cmake)

