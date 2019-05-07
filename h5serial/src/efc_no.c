/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 * Copyright by The HDF Group.                                               *
 * Copyright by the Board of Trustees of the University of Illinois.         *
 * All rights reserved.                                                      *
 *                                                                           *
 * This file is part of HDF5.  The full HDF5 copyright notice, including     *
 * terms governing use, modification, and redistribution, is contained in    *
 * the files COPYING and Copyright.html.  COPYING can be found at the root   *
 * of the source code distribution tree; Copyright.html can be found at the  *
 * root level of an installed copy of the electronic HDF5 document set and   *
 * is linked from the top-level documents page.  It can also be found at     *
 * http://hdfgroup.org/HDF5/doc/Copyright.html.  If you do not have          *
 * access to either file, you may request a copy from help@hdfgroup.org.     *
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

/*
 * This program tests the performance of the library when writing a 5000 X 5000
 * chunked character dataset by columns and reading by rows.  The chunk cache
 * size is set large enough to hold a row/column of chunks, but not large enough
 * to hold the entire dataset.  Columns/rows are written/read in linear order.
 *
 * 
 * Programmer:  Neil Fortner <nfortne2@hdfgroup.org>
 *              5 February 2009
 */

#include "hdf5.h"
#include <sys/time.h>
#include <time.h>

const char *FILENAME[] = {
    "efc.h5",
    "ext_file0.h5",
    "ext_file1.h5",
    "ext_file2.h5",
    "ext_file3.h5",
    "ext_file4.h5",
    "ext_file5.h5",
    "ext_file6.h5",
    "ext_file7.h5",
    "ext_file8.h5",
    "ext_file9.h5",
    NULL
};

const char *ELINKNAME[] = {
    "elink0",
    "elink1",
    "elink2",
    "elink3",
    "elink4",
    "elink5",
    "elink6",
    "elink7",
    "elink8",
    "elink9",
    NULL
};

#define NFILES  10
#define NITER  1000


/*-------------------------------------------------------------------------
 * Function:    efc_gen
 *
 * Purpose:     Generate test files used by the benchmarks.
 *
 * Return:      Success:        0
 *
 *              Failure:        1
 *
 * Programmer:  Neil Fortner
 *              Tuersday, 1 February 201
 *
 * Modifications:
 *-------------------------------------------------------------------------
 */
static int
efc_gen(const char *filename)
{
    hid_t       file1;
    hid_t       file2;
    unsigned    i;

    /* Create the file for this test */
    if((file1 = H5Fcreate(filename, H5F_ACC_TRUNC, H5P_DEFAULT, H5P_DEFAULT))
            < 0)
        goto error;

    /* Create external files and links */
    for(i=0; i<NFILES; i++) {
        if((file2 = H5Fcreate(FILENAME[i+1], H5F_ACC_TRUNC, H5P_DEFAULT,
                H5P_DEFAULT)) < 0)
            goto error;
        if(H5Fclose(file2) < 0)
            goto error;

        if(H5Lcreate_external(FILENAME[i+1], "/", file1, ELINKNAME[i],
                H5P_DEFAULT, H5P_DEFAULT) < 0)
            goto error;
    } /* end for */

    if(H5Fclose(file1) < 0)
        goto error;

    return 0;

error:
    return 1;
} /* end efc_gen() */


/*-------------------------------------------------------------------------
 * Function:    t_no_efc
 *
 * Purpose:     Tests the performance of the library when opening NFILES
 *              files through external links NITER times.  Does not use
 *              the external file cache.
 *
 * Return:      Success:        0
 *
 *              Failure:        1
 *
 * Programmer:  Neil Fortner
 *              Thursday, 5 February 2009
 *
 * Modifications:
 *-------------------------------------------------------------------------
 */
static int
t_no_efc(const char *filename)
{
    hid_t       file;
    hid_t       group;
    unsigned    i, j;

    /* Open the file for this test */
    if((file = H5Fopen(filename, H5F_ACC_RDONLY, H5P_DEFAULT)) < 0)
        goto error;

    /* Loop NITER times */
    for(i=0; i<NITER; i++)
        /* Open each external link */
        for(j=0; j<NFILES; j++) {
            if((group = H5Gopen2(file, ELINKNAME[j], H5P_DEFAULT)) < 0)
                goto error;

            if(H5Gclose(group) < 0)
                goto error;
        } /* end for */

    if(H5Fclose(file) < 0)
        goto error;

    return 0;

error:
    return 1;
} /* end t_no_efc() */



/*-------------------------------------------------------------------------
 * Function:    main
 *
 * Purpose:     Test different cases of I/O for compound data and the
 *              compound optimization for the Chicago company.
 *
 * Return:      Success:         0
 *
 *              Failure:         1
 *
 * Programmer:  Neil Fortner
 *              1 February 2011
 *
 * Modifications:
 *-------------------------------------------------------------------------
 */
int
main (void)
{
    int         ret_value = 0;
    unsigned    i;

    if(efc_gen(FILENAME[0]) < 0) {
        ret_value = 1;
        goto done;
    } /* end if */

    if(t_no_efc(FILENAME[0]) < 0) {
        ret_value = 1;
        goto done;
    } /* end if */

done:
    for(i=0; FILENAME[i]; i++)
        remove(FILENAME[i]);

    printf("ret_value=%d\n", ret_value);
    return(ret_value);
}

