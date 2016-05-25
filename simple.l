%{
#include "simple.global.h"
#include "simple.tab.h"
int line_no = 1;
%}
%%
"array"                     return ARRAY;
"bool"                      return BOOL;
"if"                        return IF;
"int"                       return INT;
"of"                        return OF;
"or"                        return OR;
"then"                      return THEN;

":="                        return ASSIGN;
":"                         return COLON;
";"                         return SEMI;

"+"                         return PLUS;

"["                         return LB;
"]"                         return RB;

[0-9]+                      {
                                yylval.val = atoi(yytext);
                                return NUMBER;
                            } 
"false"                     return FALSE;
"true"                      return TRUE;

[a-zA-Z_]([a-zA-Z0-9_])*    {
                                yylval.name = (char *) malloc(yyleng + 1);
                                strcpy(yylval.name, yytext);
                                return ID;
                            }

"\n"                        line_no++;
[\t\f ]                     ;

%%
int yywrap() {
    return 1;
}
