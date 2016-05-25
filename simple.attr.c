#include "simple.attr.h"
#include <string.h>
#include <stdlib.h>
#include <stdio.h>

static inline char * makeStr(const char *name) {
    char *str = (char *) malloc(sizeof(char) * (strlen(name) + 1));
    strcpy(str, name);
    return str;
}

type_t makeBaseNode(base_type_t type) {
    // fprintf(stderr, "Making base node %d\n", type);
    type_t new_type = (type_t) malloc(sizeof(struct struct_type_t));
    new_type->base_type = type;
    new_type->array_length = 0;
    new_type->child_type = NULL;
    return new_type;
}

type_t makeArrayNode(int array_length, type_t child_type) {
    // fprintf(stderr, "Making array node\n");
    type_t new_type = (type_t) malloc(sizeof(struct struct_type_t));
    new_type->base_type = ARRAY_T;
    new_type->array_length = array_length;
    new_type->child_type = child_type;
    return new_type;
}

int matchType(type_t type1, type_t type2) {
    // fprintf(stderr, "Matching type\n");
    if (type1->base_type != type2->base_type) {
        // fprintf(stderr, "Matching failed\n");
        return 0;
    }
    if (type1->base_type == ARRAY_T) {
        // fprintf(stderr, "Matching child type\n");
        return matchType(type1->child_type, type2->child_type);
    } else {
        // fprintf(stderr, "Matching succeeded\n");
        return 1;
    }
}

static inline int strHash(const char *str) {
    int hash;
    int ptr = 0;
    while (*(str + ptr)) {
        hash = ((hash << SHIFT) + *(str + ptr)) % ID_MAX;
        ptr++;
    }
    return hash;
}

void addSymbol(const char *name, type_t type) {
    // fprintf(stderr, "addSymbol begin\n"); 
    int hash = strHash(name);    
    int pos = hash;
    while (symbol_table[pos].valid) {
        pos = (pos + 1) % ID_MAX;
        if (pos == hash) {
            attrError("Too many variables");
            return;
        }
    }
    symbol_table[pos].valid = 1;
    symbol_table[pos].type = type;
    symbol_table[pos].name = makeStr(name);
    // fprintf(stderr, "Saving %s to position %d\n", name, hash); 
    // fprintf(stderr, "addSymbol succeeded\n"); 
}

type_t lookupSymbol(const char *name) {
    // fprintf(stderr, "lookupSymbol begin\n"); 
    int hash = strHash(name);    
    int pos = hash;
    while (1) {
        if (symbol_table[pos].valid) {
            if (strcmp(symbol_table[pos].name, name) == 0) {
                // fprintf(stderr, "lookupSymbol succeeded\n"); 
                return symbol_table[pos].type;
            }
        }
        pos = (pos + 1) % ID_MAX;
        if (pos == hash) {
            break;
        }
    }
    return NULL;
}

void attrError(const char *msg) {
    attribute_error_count++;
    fprintf(stderr, "Attribute error [line %d] : %s\n", line_no, msg);
}
