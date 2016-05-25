#ifndef _SIMPLE_ATTR_H_
#define _SIMPLE_ATTR_H_

#include "simple.global.h"

#define ID_MAX 142857
#define SHIFT 7

int attribute_error_count;
extern int line_no;

type_t makeBaseNode(base_type_t type);
type_t makeArrayNode(int array_length, type_t child_type);
int matchType(type_t type1, type_t type2);

symbol_t symbol_table[ID_MAX];
void addSymbol(const char *name, type_t type);
type_t lookupSymbol(const char *name);

void attrError(const char *msg);

#endif // _SIMPLE_ATTR_H_
