%{
#define YYDEBUG 1
#include "simple.global.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>

#define ID_MAX 142857
#define SHIFT 7

extern int line_no;
extern int yyleng;
extern char *yytext;
extern int yylex();

int syntax_error_count, attribute_error_count;

static type_t makeBaseNode(base_type_t type);
static type_t makeArrayNode(int array_length, type_t child_type);
static int matchType(type_t type1, type_t type2);

symbol_t symbol_table[ID_MAX];
static int strHash(const char * str);
static void addSymbol(const char *name, type_t type);
static type_t lookupSymbol(const char *name);

static void attrError(const char *msg);
%}

%token ARRAY BOOL IF INT OF OR THEN 
%token ASSIGN COLON SEMI
%token PLUS
%token LB RB
%token NUMBER FALSE TRUE
%token ID

%start program
%type <name> id ID
%type <type> BOOL INT type_exp exp
%type <val> NUMBER

%union {
    int val;
    type_t type;
    char *name;
}

%%
program : var_decls SEMI stmts
    ;

var_decls : var_decls SEMI var_decl
    | var_decl
    ;

var_decl : id COLON type_exp            { addSymbol($1, $3); }
    ;

type_exp : INT                          { $$ = makeBaseNode(INT_T); }
    | BOOL                              { $$ = makeBaseNode(BOOL_T); }
    | ARRAY LB NUMBER RB OF type_exp    { $$ = makeArrayNode($3, $6); }
    ;

stmts : stmts SEMI stmt
    | stmt
    ;

stmt : IF exp THEN stmt                 { 
        if ($2->base_type != BOOL_T) {
            attrError("Condition of if statement must be of bool type.");
        }
    }
    | id ASSIGN exp                     {
        type_t type = lookupSymbol($1);
        if (!type) {
            char error[100];
            sprintf(error, "Variable \"%s\" not found.", $1);
            attrError(error);
        } else {
            if (!type || !matchType(type, $3)) {
                attrError("Assigning type mismatch.");
            }
        }
    }
    |                                   { /* empty statement */ }
    ;

exp : exp PLUS exp                      { 
        if ($1->base_type != INT_T || $3->base_type != INT_T) {
            attrError("Operator \"+\" should have both operands be int type.");
        } 
        $$ = makeBaseNode(INT_T);
    }
    | exp OR exp                        {
        if ($1->base_type != BOOL_T || $3->base_type != BOOL_T) {
            attrError("Operator \"or\" should have both operands be bool type.");
        } 
        $$ = makeBaseNode(BOOL_T);
    }
    | exp LB exp RB                     {
        if ($1->base_type != ARRAY_T) {
            attrError("Cannot read members of a non-array variable.");
        } 
        if ($3->base_type != INT_T) {
            attrError("The index should be int type.");
        } 
        $$ = $1->child_type;
    }
    | NUMBER                            { $$ = makeBaseNode(INT_T); }
    | TRUE                              { $$ = makeBaseNode(BOOL_T); }
    | FALSE                             { $$ = makeBaseNode(BOOL_T); }
    | id                                { $$ = lookupSymbol($1); }
    ;

id : ID                                 { $$ = $1; }
    ;

%% 

static char * makeStr(const char *name) {
    char *str = (char *) malloc(sizeof(char) * (strlen(name) + 1));
    strcpy(str, name);
    return str;
}

static type_t makeBaseNode(base_type_t type) {
    // fprintf(stderr, "Making base node %d\n", type);
    type_t new_type = (type_t) malloc(sizeof(struct struct_type_t));
    new_type->base_type = type;
    new_type->array_length = 0;
    new_type->child_type = NULL;
    return new_type;
}

static type_t makeArrayNode(int array_length, type_t child_type) {
    // fprintf(stderr, "Making array node\n");
    type_t new_type = (type_t) malloc(sizeof(struct struct_type_t));
    new_type->base_type = ARRAY_T;
    new_type->array_length = array_length;
    new_type->child_type = child_type;
    return new_type;
}

static int matchType(type_t type1, type_t type2) {
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

static int strHash(const char *str) {
    int hash;
    int ptr = 0;
    while (*(str + ptr)) {
        hash = ((hash << SHIFT) + *(str + ptr)) % ID_MAX;
        ptr++;
    }
    return hash;
}

static void addSymbol(const char *name, type_t type) {
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

static type_t lookupSymbol(const char *name) {
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

static void attrError(const char *msg) {
    attribute_error_count++;
    fprintf(stderr, "Attribute error [line %d] : %s\n", line_no, msg);
}

int main () { 
    int result = yyparse();
    if (syntax_error_count == 0 && attribute_error_count == 0) {
        fprintf(stderr, "Compiling succeeded.\n");
    } else {
        fprintf(stderr, "%d syntax error(s) found.\n", syntax_error_count);
        fprintf(stderr, "%d attribute error(s) found.\n", attribute_error_count);
        fprintf(stderr, "Compiling failed.\n");
    }
    return result; 
}

/* allows for printing of an error message */
int yyerror(char *s) { 
    syntax_error_count++;
    fprintf (stderr, "%s: at or before '%s', line %d\n", s, yytext, line_no) ;
    return 0;
}

