#ifndef _SIMPLE_GLOBAL_H_
#define _SIMPLE_GLOBAL_H_

#include <stdio.h>

typedef enum {NULL_T, INT_T, BOOL_T, ARRAY_T} base_type_t;

typedef struct struct_type_t * type_t;
struct struct_type_t {
    base_type_t base_type;
    size_t array_length;
    type_t child_type;
};

typedef struct struct_symbol_t {
    int valid;
    char *name;
    type_t type;
} symbol_t;

#endif // _SIMPLE_GLOBAL_H_
