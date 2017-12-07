%{
/**
* PL/0-Scan 
*
**/
#include <stdio.h>
#include <string.h>

%}
%%
"." 		return t_punkt;
"CONST"		return t_const;
"VAR"		return t_var;
"PROCEDURE"	return t_proc;
"CALL"		return t_call;
"BEGIN"		return t_begin;
"END"		return t_end;
"IF"		return t_if;
"THEN"		return t_then;
"WHILE"		return t_while;
"DO"		return t_do;
"ODD"		return t_odd;
"="			return t_eq;
","			return t_komma;
";"			return t_semiko;
":="		return t_assign;
"?"			return t_read;
"!"			return t_write;
"("			return t_ka;
")"			return t_kz;
"#"			return t_ne;
"<"			return t_lt;
"<="		return t_leq;
">"			return t_gt;
">="		return t_geq;
"+"			return t_plus;
"-"			return t_minus;
"*"			return t_mul;
"/"			return t_div ;
[0-9]+		{yylval._int = atof(yytext); return t_zahl;} //zahl
[a-z|A-Z]*	{strcpy(yylval._text, yytext); return t_bez;} //bezeichner
[ \t\n\f\r]		/* do nothing */;
%%

