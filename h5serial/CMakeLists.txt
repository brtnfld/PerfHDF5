cmake_minimum_required (VERSION 3.10.2)
project (efc_no C)

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

set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -Wall -O2")

set (efc_no_srcs
    src/efc_no.c
)

add_executable (efc_no ${efc_no_srcs})
target_link_libraries (efc_no ${LINK_LIBS})
target_include_directories(efc_no PUBLIC ${MPI_C_INCLUDE_DIRS})
set_property (TARGET efc_no
      APPEND PROPERTY COMPILE_DEFINITIONS STANDALONE
)

set (TEST_nprocs 6)

add_test (
   NAME CLEAR_efc_no
   COMMAND ${CMAKE_COMMAND} -E remove *.h5
)
add_test (NAME TEST_efc_no COMMAND "${CMAKE_COMMAND}"
    -D "TEST_PROGRAM=$<TARGET_FILE:efc_no>"
    -D "TEST_EXPECT=0"
    -D "TEST_SKIP_COMPARE:BOOL=true"
    -D "TEST_OUTPUT=efc_no.out"
    -D "TEST_FOLDER=${PROJECT_BINARY_DIR}"
    -P "${PROJECT_SOURCE_DIR}/../scripts/runTest.cmake"
)
set_tests_properties (TEST_efc_no PROPERTIES DEPENDS CLEAR_efc_no)

set (DART_TESTING_TIMEOUT 1200
    CACHE STRING
    "Timeout in seconds for each test (default 1200=20minutes)"
)
enable_testing ()
include (CTest)
include (${PROJECT_SOURCE_DIR}/CTestConfig.cmake)

