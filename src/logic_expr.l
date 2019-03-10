%{
	#include <stdlib.h>
	#include <string.h>
	#include <stdio.h>

	#include "logic_expr.tab.h"

	void yyerror(const char *s, ...);
%}

digit [0-9]

%%

[+-]?{digit}+ { //
	inc_charno();
	yylval.node.intval = atoi(yytext);
	return T_INTEGER;
} /** Matches an integer.
   * I write this to support an integer starting with "+" or "-"
   * though it may not be required.
   */

"==" {
	inc_charno();
	return T_EQ;
} // Matches an equal operator.

"!=" {
	inc_charno();
	return T_NE;
} // Matches an unequal operator.

"<=" {
	inc_charno();
	return T_LE;
} // Matches a less equal operator.

">=" {
	inc_charno();
	return T_GE;
} // Matches a greater equal operator.

"&&" {
	inc_charno();
	return T_AND;
} // Matches an and operator.

"||" {
	inc_charno();
	return T_OR;
} // Matches an or operator.

"<" {
	inc_charno();
	return T_LT;
} // Matches a less than operator.

">" {
	inc_charno();
	return T_GT;
} // Matches a greater than operator.

"!" {
	inc_charno();
	return T_NOT;
} // Matches a not operator.

"(" {
	inc_charno();
	return T_LP;
} // Matches a left parenthesis.

")" {
	inc_charno();
	return T_RP;
} // Matches a right parenthesis.

[ \t] {
	inc_charno();
} // Matches white spaces.

\r?\n {
	inc_charno();
	return T_NEWLINE;
} // Matches a newline.

"exit" {
	inc_charno();
    return T_EXIT;
} // Matches an exit symbol (this is used for better interaction).

. {
	inc_charno();
	yyerror("invalid character '%s'", yytext);
} // Matches an unrecognized token.

%%

int yywrap(void)
{
	return 1;
}
