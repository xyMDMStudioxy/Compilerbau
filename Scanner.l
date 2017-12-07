%{
#include "y.tab.h"
int yyerror();
%}
%%
"INT"		return INT;
"CONST"		return CONST;
"VAR"		return VAR;
"PROCEDURE"	return PROC;
"CALL"		return CALL;
"BEGIN"		return BEG;
"END"		return END;
"IF"		return IF;
"THEN"		return THEN;
"WHILE"		return WHILE;
"DO"		return DO;
"ODD"		return ODD;
"="			return EQ;
","			return KOMMA;
";"			return SEMIKO;
":="		return ASSIGN;
"?"			return READ;
"!"			return WRITE;
"<"			return LT;
"<="		return LEQ;
">"			return GT;
">="		return GEQ;		
"+"			return PLUS;
"-"			return MINUS;
"*"			return MAL;
"/"			return DIV;
"("			return KLA_AUF;
")"			return KLA_ZU;
[0-9]+		return ZAHL;
[a-z A-Z]+[0-9]+ return IDENT;
["=" "<=" ">=" "<" ">"] return RELATION;
("\""" .* "\""") return STRING;
[\t \n]
.			return FEHLER;
%%