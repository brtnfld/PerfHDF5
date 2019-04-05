cmake_minimum_required (VERSION 3.10.2)
project (h5perf C)

find_package (HDF5 NAMES "hdf5")
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
  # MPI checks, only do these if MPI_C_FOUND is true, otherwise they always fail
  # and once set, they are cached as false and not regenerated
  set (CMAKE_REQUIRED_LIBRARIES "${MPI_C_LIBRARIES}" )
  # Used by Fortran + MPI
  include (${CMAKE_ROOT}/Modules/CheckSymbolExists.cmake)
  CHECK_SYMBOL_EXISTS (MPI_Comm_c2f "${MPI_C_INCLUDE_DIRS}/mpi.h"  H5_HAVE_MPI_MULTI_LANG_Comm)
  CHECK_SYMBOL_EXISTS (MPI_Info_c2f "${MPI_C_INCLUDE_DIRS}/mpi.h"  H5_HAVE_MPI_MULTI_LANG_Info)
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

set (h5perf_srcs
    src/pio_engine.c
    src/pio_perf.c
    src/pio_perf.h
#    src/pio_standalone.c
#    src/pio_standalone.h
    src/pio_timer.c
    src/pio_timer.h
)

add_executable (h5perf ${h5perf_srcs})
target_link_libraries (h5perf ${LINK_LIBS})
target_include_directories(h5perf PUBLIC ${MPI_C_INCLUDE_DIRS})
set_property (TARGET h5perf
      APPEND PROPERTY COMPILE_DEFINITIONS STANDALONE
)

add_test (
   NAME CLEAR_h5perf
   COMMAND ${CMAKE_COMMAND} -E remove *.h5
)

add_test (
    NAME TEST_h5perf
    COMMAND mpiexec -n 6 $<TARGET_FILE:h5perf> -B 2 -e 8 -p 6 -P 6 -x 4 -X 4 --debug=r,t -d 4 -F 4 -i 40
)

set_tests_properties (TEST_h5perf PROPERTIES DEPENDS CLEAR_h5perf)

set (DART_TESTING_TIMEOUT 1200
    CACHE STRING
    "Timeout in seconds for each test (default 1200=20minutes)"
)
enable_testing ()
include (CTest)
include (${PROJECT_SOURCE_DIR}/CTestConfig.cmake)

