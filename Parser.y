%{
#include <stdlib.h>
#include <stdio.h>
int yylex();
%}
%token INT CONST VAR PROC CALL BEG END IF THEN WHILE DO ODD EQ KOMMA SEMIKO ASSIGN READ WRITE
		PLUS MINUS MAL DIV KLA_AUF KLA_ZU STRING FEHLER
%token<t> ZAHL IDENT RELATION
%start program
%%
program:	block CONST
			;
block:		blockvar
			| blockconst
			| blockprocedure
			| statement
			;
blockconst:	VAR subconst SEMIKO
			;
subconst:	IDENT EQ ZAHL
			| IDENT EQ KOMMA subconst
			;
blockvar:	VAR subident SEMIKO
			;
subident:	IDENT
			| IDENT KOMMA subident
			;
blockprocedure:	PROC IDENT SEMIKO block SEMIKO
			;
statement:	IDENT ASSIGN expression
			| CALL IDENT
			| BEG substatement END
			| IF condition THEN statement END
			| WHILE condition THEN statement
			;
substatement: statement
			| SEMIKO substatement
			;
condition:	ODD expression
			| expression RELATION expression
			;
expression:	preterm subterm
			| term subterm
			;
preterm:	PLUS term
			| MINUS term
			;
subterm:	preterm
			| preterm subterm
			;
term:		factor subfactor
			;
subfactor:	MAL factor subfactor
			;
factor:		IDENT
			| ZAHL
			| KLA_AUF expression KLA_ZU
			;
%%
int main() {
	int rc = yyparse();
	if (rc == 0) {
		printf("Syntax OK\n");
	} else {
		printf("Syntax nicht OK\n");
	}
	return 0;
}

int yywrap() {
	return 1;
}

int yyerror() {
	printf("Error\n");
	exit(1);
}