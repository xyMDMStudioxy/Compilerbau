%{

#include <stdio.h>
#include <string.h>
#include <sstream>
#include "symtab.hpp"
#include "interpreter.hpp"

using namespace std;

stringstream sstm;
symtab st;
ast_block * ast_root;
static int label =-1;

int yylex();
int yyerror(char* s);

%}
%token t_punkt t_const t_var t_proc t_call t_begin t_end t_if t_then t_while t_do t_odd t_eq  t_komma t_semiko t_assign t_read t_write t_ka t_kz t_ne  t_lt  t_leq t_gt t_geq t_plus t_minus t_mul t_div t_chs
%union{
	int _int; 
	char _text[10];
	ast_expression * _expr;
	ast_statement * _stmt;
	ast_block * _block;
	ast_con * _con;
	struct {ast_statement * start; ast_statement * end;} _list;
}

%token <_int> t_zahl
%token <_text> t_bez
%token t_error

%type <_block> 	BLOCK PROCEDURE_LIST PROCEDURE
%type <_con> 	CONST_DECL CONST_LIST CONST_ID
%type <_int>	VAR_LIST VAR_DECL
%type <_expr> 	FACTOR EXPRESSION CONDITION TERM
%type <_stmt> 	ASSIGNMENT PROC_CALL READ WRITE 
%type <_list> 	IF WHILE STATEMENT_LIST STATEMENT

%%

PROG		:	BLOCK t_punkt {ast_root = $1;};

BLOCK		: {st.level_up();} CONST_DECL VAR_DECL PROCEDURE_LIST STATEMENT
			{ast_block * block = new ast_block($2,$3,$4,$5.start); $$=block;
			st.level_down();};

CONST_DECL	: /**/ {$$=NULL;}
			| t_const CONST_LIST t_semiko {$$=$2;};

CONST_LIST	: CONST_ID t_eq t_zahl {
				$$=$1;
				$$->val=$3;
				$$->count=1;
			}
			| CONST_ID t_eq t_zahl t_komma CONST_LIST {
				$$=$1;
				$$->val=$3,$$->next=$5;
				$$->count=$5->count+1;
			};

CONST_ID	: t_bez {
				ast_con *con = new ast_con($1); 
				$$=con; 
				st.insert($$->name,st_const);
			};

VAR_DECL	: /**/ {$$=0;}
			| t_var VAR_LIST t_semiko {$$=$2;};
 
VAR_LIST	: VAR_ID {$$=1;}
			| VAR_ID t_komma VAR_LIST {$$=1+$3;};
			
VAR_ID		: t_bez {st.insert($1,st_var);}
			;	

PROCEDURE_LIST	: /**/ {$$=NULL;}
			| PROCEDURE t_semiko PROCEDURE_LIST {$$=$1, $$->next=$3;};

PROCEDURE	: t_proc t_bez {st.insert($2,st_proc);} t_semiko BLOCK {$$=$5; $$->name = $2;};


STATEMENT	: /**/ {$$.start=$$.end=NULL;}
			| ASSIGNMENT {$$.start=$$.end=$1;}
			| PROC_CALL {$$.start=$$.end=$1;}
			| READ {$$.start=$$.end=$1;}
			| WRITE {$$.start=$$.end=$1;}
			| IF {$$=$1;}
			| WHILE {$$=$1;}
			| t_begin STATEMENT_LIST t_end {$$=$2;};

ASSIGNMENT	: t_bez t_assign EXPRESSION {
				int stl,sto; 
				(st.lookup($1,st_var,stl,sto)==0)?:yyerror("Bezeichner nicht gefunden oder Zuweisung auf Konstante!");
				ast_statement *stmt = new ast_statement(stmt_assign); 
				$$=stmt;
				$$->expr=$3; 
				$$->id = $1;
				$$->stl=stl, $$->sto=sto;
			};

PROC_CALL	: t_call t_bez {
				int stl,sto; 
				st.lookup($2,st_proc,stl,sto); 
				ast_statement *stmt = new ast_statement(stmt_call); 
				$$=stmt;
				$$->id = $2;
				$$->stl=stl, $$->sto=sto;
			};

READ		: t_read t_bez {
				int stl,sto; 
				(st.lookup($2,st_var,stl,sto)==0)?:yyerror("Bezeichner nicht gefunden oder Zuweisung auf Konstante!"); 
				ast_statement *stmt = new ast_statement(stmt_read); 
				$$=stmt;
				$$->id = $2;
				$$->stl=stl, $$->sto=sto;
			};

WRITE		: t_write EXPRESSION {
				ast_statement *stmt = new ast_statement(stmt_write); 
				$$=stmt;
				$$->expr=$2;
			};

IF			: t_if CONDITION t_then STATEMENT {
				ast_statement *stmt = new ast_statement(stmt_jump_false); 
				$$.start=stmt;
				sstm << "JMP_" << ++label;
				$$.start->id=sstm.str();
				sstm.str("");
				$$.start->expr=$2; 
				$$.start->next=$4.start;
				stmt = new ast_statement(stmt_nop);
				$$.end=stmt;
				$$.end->id = $$.start->id;
				$$.start->jump =$$.end;
				$4.end->next=$$.end;
			};

WHILE		: t_while CONDITION t_do STATEMENT {
				ast_statement 
					*n1 = new ast_statement(stmt_nop),
					*n2 = new ast_statement(stmt_jump_false),
					*n3 = new ast_statement(stmt_jump),
					*n4 = new ast_statement(stmt_nop);
				sstm << "JMP_" << ++label;
				n1->id=sstm.str();
				sstm.str("");
				n3->id = n1->id;
				sstm << "JMP_" << ++label;
				n2->id=sstm.str();
				sstm.str("");
				n4->id = n2->id;
				n1->next=n2; 
				n2->jump=n4, n2->next=$4.start;
				n2->expr=$2; 
				$4.end->next=n3; 
				n3->next=n4, n3->jump=n1; 
				$$.start=n1, $$.end=n4;
			};

STATEMENT_LIST	: STATEMENT {$$=$1;}
				| STATEMENT t_semiko STATEMENT_LIST {
					$$=$1; 
					if ($3.start != NULL){
						$$.end->next=$3.start;
						$$.end = $3.end;
					}
				};
		
CONDITION 	: t_odd EXPRESSION {
				ast_expression *expr = new ast_expression(t_odd,"ODD",$2,NULL);
				$$=expr;
			}
			| EXPRESSION t_eq  EXPRESSION {
				ast_expression *expr = new ast_expression(t_eq,"=",$1,$3);
				$$=expr;
			}
			| EXPRESSION t_ne  EXPRESSION {
				ast_expression *expr = new ast_expression(t_ne,"#",$1,$3);
				$$=expr;
			}
			| EXPRESSION t_lt  EXPRESSION {
				ast_expression *expr = new ast_expression(t_lt,"<",$1,$3);
				$$=expr;
			}
			| EXPRESSION t_leq EXPRESSION {
				ast_expression *expr = new ast_expression(t_leq,"<=",$1,$3);
				$$=expr;
			}
			| EXPRESSION t_gt  EXPRESSION {
				ast_expression *expr = new ast_expression(t_gt,">",$1,$3);
				$$=expr;
			}
			| EXPRESSION t_geq EXPRESSION {
				ast_expression *expr = new ast_expression(t_geq,">=",$1,$3);
				$$=expr;
			}
			;
				
EXPRESSION	: TERM {$$=$1;}
			| EXPRESSION t_plus TERM {
				ast_expression *expr = new ast_expression(t_plus,"+",$1,$3);
				$$=expr;
			}
			| EXPRESSION t_minus TERM {
				ast_expression *expr = new ast_expression(t_minus,"-",$1,$3);
				$$=expr;
			}
			;
					
TERM		: FACTOR 
			| TERM t_mul FACTOR	{
				ast_expression *expr = new ast_expression(t_mul,"*",$1,$3);
				$$=expr;
			}
			| TERM t_div FACTOR	{
				ast_expression *expr = new ast_expression(t_div,"/",$1,$3);
				$$= expr;
			}
			;
					
FACTOR		: t_bez { 
				int  stl, sto; 
				ast_expression *expr = new ast_expression(t_bez, $1, NULL, NULL);
				$$=expr;
				st.lookup($1,st_var | st_const, stl, sto); 
				$$->stl=stl, $$->sto=sto;
			} 
			| t_zahl {
				ast_expression *expr = new ast_expression(t_zahl, "", NULL, NULL);
				$$=expr;
				$$->val=$1;
			}
			| t_ka EXPRESSION t_kz {$$=$2;}
			| t_plus FACTOR	{$$=$2;}
			| t_minus FACTOR {
				ast_expression *expr = new ast_expression(t_chs, "CHS", $2, NULL);
				$$=expr;
			}
			;


%%

#include "lex.yy.c"

int yyerror(char* s) {
	printf("%s\n", s);
}

int main(int argc, char * argv[]){
	char filename[100];
	int error;
	extern FILE * yyin;
    
	sprintf(filename, "%s", argv[1]);
	if((yyin = fopen(filename, "r")) == NULL){
        cout << "Fehler beim Einlesen!!!" << endl;
		return -1;
	}
	
	error=yyparse();
	if(error) printf("Fehler %d \n", error);
	else {
		printf("OK!!\n");
		ast_root->print();
		
		Interpreter * interpreter = new Interpreter(ast_root);
	}
	return error;
}

