// seism-core-attributes.hh
#include "hdf5.h"

/*
typedef struct {
    char *name;
    unsigned int processor_dims[3];
    unsigned int chunk_dims[3];
    unsigned int domain_dims[3];
    unsigned int simulation_time;
    int collective_write;
    int precreate;
    int set_collective_metadata;
    int early_allocation;
    int never_fill;
} seism_core_attributes_t;
*/

class seismCoreAttributes 
{

    public:

        char *name;
        unsigned int processor_dims[3];
        unsigned int chunk_dims[3];
        unsigned int domain_dims[3];
        unsigned int simulation_time;
        int collective_write;
        int precreate;
        int set_collective_metadata;
        int early_allocation;
        int never_fill;

        // constructor to create a new attributes object from simulation
        seismCoreAttributes
        (
            char * _name,
            unsigned int *_processor_dims,
            unsigned int *_chunk_dims,
            unsigned int *_domain_dims,
            unsigned int _simulation_time,
            int _collective_write,
            int _precreate,
            int _set_collective_metadata,
            int _early_allocation,
            int _never_fill
        );

        // constructor to read attributes object from a file
        seismCoreAttributes(hid_t file_id);

        // called at end of simulation to write attributes out
        void writeAttributesToFile(hid_t file_id);

        // destructor will free H5 resources
        ~seismCoreAttributes();

//    private:

        hid_t vls_type_c_id; // compound type
        hid_t dim_h5t; // dimension type
        hid_t attributes_h5t; // attributes type
//        hid_t space_id; // dataspace
//        hid_t attr_id; // atribute

        void init(); // create H5 objects used internally

};

