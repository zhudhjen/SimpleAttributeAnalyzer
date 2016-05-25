%{
#define YYDEBUG 1
#include "simple.global.h"
#include "simple.attr.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>

extern int line_no;
extern int yyleng;
extern char *yytext;
extern int yylex(); 

int syntax_error_count;
extern int attribute_error_count;

%}

%token ARRAY BOOL IF INT OF OR THEN 
%token ASSIGN COLON SEMI
%token PLUS
%token LB RB
%token NUMBER FALSE TRUE
%token ID

%start program
%type <name> ID
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

var_decl : ID COLON type_exp            { addSymbol($1, $3); }
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
    | ID ASSIGN exp                     {
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
    | ID                                { $$ = lookupSymbol($1); }
    ;

%% 

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

