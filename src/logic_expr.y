%{
	#include <stdlib.h>
	#include <stdio.h>
	#include <stdarg.h>

	void yyerror(const char *s, ...);
	int yylex();

	// Flag used to decide whether to make evaluation at the
	// current symbol. It is vital for boolean short circuit.
	int eval;
	#define set_eval() \
		eval = 1
	#define unset_eval() \
		eval = 0

	// Sets the flag of whether to resume evaluation.
	#define set_resume(resume) \
		resume = 1
	#define unset_resume(resume) \
		resume = 0

	// Records the line number.
	int lineno;
	#define inc_lineno() \
		lineno++
	#define reset_lineno() \
		lineno = 1
%}

%code requires {
	// Records the char number.
	// This is genetrated to both the source file and the header
	// file because it is also used by Flex.
	int charno;
	int word_size;
	#define inc_charno() \
		charno += word_size, word_size = yyleng
	#define reset_charno() \
		charno = 1, word_size = 0
}

%define parse.error verbose

%union {
	struct {
		int intval;
		int count;
	} node;
	int resume;
}

// Terminal symbols.
%token <node> T_INTEGER
%token T_EXIT
%token T_NEWLINE
%token T_LP T_RP

%left T_OR
%left T_AND

%left T_EQ T_NE
%left T_LE T_GE T_LT T_GT

%right T_NOT

// Non-terminal symbols that need a node for farther evaluation.
%type <node> comparison_expression
%type <node> logic_expression

%start program

%%

program:
	program line_statement
	|
	;

line_statement:
	statement T_NEWLINE {
		inc_lineno();
		reset_charno();
	}
	|
	error T_NEWLINE {
		inc_lineno();
		reset_charno();
		// eval must be reset before error recovery.
		// Otherwise the evaluation may stop working due to
		// a broken logic expression.
		set_eval();
		yyerrok;
	}
	;

statement:
	logic_expression {
		// Since C doesn't have a boolean type and supports no
		// pretty printing for that. I write the following code
		// to adjust to the desired output format.
		char *pretty_bool = "false";
		if ($1.intval)
		{
			pretty_bool = "true";
		}
		printf("Output: %s, %d\n", pretty_bool, $1.count);
	}
	|
	T_EXIT {
		// My optional way to exit the program.
		// The tradition CTRL+Z method is still usable.
		YYACCEPT;
	}
	|
	;

logic_expression:
	comparison_expression {
		if (eval)
		{
			$$.intval = $1.intval;
			$$.count = 1;
		}
	}
	|
	T_NOT logic_expression {
		if (eval)
		{
			$$.intval = !$2.intval;
			$$.count = $2.count;
		}
	}
	|
	logic_expression T_AND {
		unset_resume($<resume>$);
		if (eval)
		{
			if (!$1.intval)
			{
				// Left operand is false. Make short circuit.
				unset_eval();
				set_resume($<resume>$);
			}
		}
	} logic_expression {
		if (eval)
		{
			$$.intval = $1.intval && $4.intval;
			$$.count = $1.count + $4.count;
		}
		else
		{
			if ($<resume>3)
			{
				// Resumes from the short circuit status.
				$$ = $1;
				set_eval();
			}
		}
	}
	|
	logic_expression T_OR {
		unset_resume($<resume>$);
		if (eval)
		{
			if ($1.intval)
			{
				// Left operand is true. Make short circuit.
				unset_eval();
				set_resume($<resume>$);
			}
		}
	} logic_expression {
		if (eval)
		{
			$$.intval = $1.intval || $4.intval;
			$$.count = $1.count + $4.count;
		}
		else
		{
			if ($<resume>3)
			{
				// Resumes from the short circuit status.
				$$ = $1;
				set_eval();
			}
		}
	}
	|
	T_LP logic_expression T_RP {
		if (eval)
		{
			$$ = $2;
		}
	}
	;

comparison_expression:
	T_INTEGER T_EQ T_INTEGER {
		if (eval)
		{
			$$.intval = $1.intval == $3.intval;
		}
	}
	|
	T_INTEGER T_NE T_INTEGER {
		if (eval)
		{
			$$.intval = $1.intval != $3.intval;
		}
	}
	|
	T_INTEGER T_LE T_INTEGER {
		if (eval)
		{
			$$.intval = $1.intval <= $3.intval;
		}
	}
	|
	T_INTEGER T_GE T_INTEGER {
		if (eval)
		{
			$$.intval = $1.intval >= $3.intval;
		}
	}
	|
	T_INTEGER T_LT T_INTEGER {
		if (eval)
		{
			$$.intval = $1.intval < $3.intval;
		}
	}
	|
	T_INTEGER T_GT T_INTEGER {
		if (eval)
		{
			$$.intval = $1.intval > $3.intval;
		}
	}
	;

%%

int main(int argc, char const *argv[])
{
	// Initializing global variables.
	set_eval();
	reset_lineno();
	reset_charno();
	yyparse();
	return 0;
}

void yyerror(const char *s, ...)
{
	va_list ap;
	// A more detailed error message.
	fprintf(stderr, "Line %d, Char %d: ", lineno, charno);
	va_start(ap, s);
	vfprintf(stderr, s, ap);
	va_end(ap);
	fprintf(stderr, "\n");
}