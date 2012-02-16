%{
#include<stdio.h>
#include<stdlib.h>
#include "apsil.h"
%}
%union
{
	struct tree *n;
	struct ArgStruct *arg;
}
%token NUM OPER1 OPER2 ID BOOL INT STR STRING BNUM MAIN BEGN END DECL ENDDECL ASG READ PRINT RELOP LOGOP NEGOP IF ELSE THEN ENDIF WHILE DO ENDWHILE RETURN
%type<n> stmtlist param stmt expr ids fID Body NUM BNUM STRING OPER1 OPER2 ID ASG READ PRINT RELOP LOGOP NEGOP IF WHILE RETURN
%type<arg> ArgId ArgIdList ArgDecl ArgList fArgList
%left LOGOP
%left RELOP  
%left OPER1		// + and -
%left OPER2		// * , / and %
%right NEGOP
%left UMIN		// unary minus

%%
prog:		GDefblock FDefList Mainblock		{}
		;
		
GDefblock:						{}
	
		|DECL GDefList ENDDECL			{fprintf(fp,"JMP main\n");}
		;
		
GDefList:	GDecl					{}

		| GDefList GDecl			{}
		;
		
GDecl:		Type GIdList ';'			{}
		;
Type:		INT					{m=0;
							}
		|BOOL					{m=1;
							}
		|STR					{m=3;
							}
		;		
GIdList:	 GId					{}

		|GIdList ',' GId			{}
		;
		
GId:		ID					{install($1,m,1);
							}
		|ID '[' NUM ']'				{install($1,m,$3->value);
							}
		|ID '(' ArgList ')'			{finstall($1,m,$3);
							/*while($3!=NULL)
							{
								printf(" %s-%d\n",$3->name,$3->type);
								$3=$3->next;
							}*/
							}
		
		;
FDefList:						{}
		
		|FDefList Fdef				{}
		;
		
Fdef:		RType fID '(' fArgList ')' '{' LDefblock Body '}'	{/*struct Lsymbol *temp=Lroot;
									while(temp!=NULL)
									{
										printf(" %s-%d-%d\n",temp->name,temp->type,temp->bind);
										temp=temp->next;
									}*/
									codegen($8);
									memcount=1;
									Lroot=NULL;
									funcid=NULL;										
									}
		;
RType:		INT					{m3=0;
							}
		|BOOL					{m3=1;
							}
		|STR					{m3=3;
							}
		;
		
fID:		ID					{memcount=1;
							funcid=$1;
							$$=$1;
							}
		;

fArgList:	ArgList					{fdefcheck(funcid,$1,m3);
							arglistinstall(funcid);
							}
		;
				
ArgList:						{$$=NULL;
							}	
		|ArgDecl 				{$$=$1;							
							}
		|ArgList ';' ArgDecl			{$$=makeargtree($1,$3);							
							}
		;
		
ArgDecl:	ArgType ArgIdList			{$$=$2;}
		;

ArgType:	INT					{m2=0;
							}
		|BOOL					{m2=1;
							}
		|STR					{m2=3;
							}
		;
		
ArgIdList:	 ArgId					{$$=$1;
							}
		|ArgIdList ',' ArgId			{$$=makeargtree($1,$3);
							}
		;
		
ArgId:		ID					{
							$$=makearg($1->name,m2,0);
							}
		|'&' ID					{$$=makearg($2->name,m2,1);
							}
		;		
				
Mainblock:	 INT fMAIN '(' ')' '{' LDefblock Body '}'	{codegen($7);
					 			fprintf(fp,"HALT\n");
								fclose(fp);
								//evaluate($7);
								return(0);
								}
		;

fMAIN:		MAIN					{m3=0;
							funcid=NULL;
							fprintf(fp,"main:\nPUSH BP\nMOV BP,SP\n"); 
							}
		;

LDefblock:						{}

		|DECL LDefList ENDDECL			{}
		;
		
LDefList:	LDecl					{}

		| LDefList LDecl			{}
		;
		
LDecl:		Type LIdList ';'			{}
		;
		
LIdList:	 LId					{}

		|LIdList ',' LId			{}
		;
		
LId:		ID					{Linstall($1,m,1);
							}
		;

Body:		 BEGN stmtlist END			{if(chkret==-1)
							{
								printf("\n Missing return statement in function %s()\n",funcid==NULL?"main":funcid->name);
								exit(0);
							}
							else
								$$=$2;	
							chkret=-1;		
							}
		;
 	
stmtlist:	stmtlist stmt 				{$$=nontermcreate("stmtlist",$1,$2);
							}
		|stmt					{$$=$1;
							}
		;
		
stmt:		ids ASG expr ';'	 		{$$=maketree($2,$1,$3,NULL);
							}
		|READ '(' ids ')' ';'			{$$=maketree($1,$3,NULL,NULL);
							}
		|PRINT '(' expr ')' ';'			{$$=maketree($1,$3,NULL,NULL);
							}
		
		|IF expr THEN stmtlist ENDIF ';'				{$$=maketree($1,$2,$4,NULL);
										}
		|IF expr THEN stmtlist ELSE stmtlist ENDIF ';'			{$$=maketree($1,$2,$4,$6);
										}
		|WHILE expr DO stmtlist ENDWHILE ';'				{$$=maketree($1,$2,$4,NULL);
										}		
		|RETURN expr ';'						{$$=maketree($1,$2,NULL,NULL);
										chkret=1;
										}
		;
				
expr:		expr OPER1 expr				{$$=maketree($2,$1,$3,NULL);
							}
		|expr OPER2 expr			{$$=maketree($2,$1,$3,NULL);
							}
		|expr RELOP expr 			{$$=maketree($2,$1,$3,NULL);
							}
		|expr LOGOP expr			{$$=maketree($2,$1,$3,NULL);
							}
		|NEGOP expr				{$$=maketree($1,$2,NULL,NULL);
							}
		|'('expr')'				{$$=$2;
							}
		|OPER1 expr	%prec UMIN		{$$=maketree($1,$2,NULL,NULL);
							}
		|NUM					{$$=$1;
							}
		|BNUM					{$$=$1;
							}
		|STRING					{$$=makedata($1);
							}
		|ids					{$$=$1;
							}
		;
			
ids:		ID					{$$=maketree($1,NULL,NULL,NULL);
							}
		|ID '[' expr ']'			{$$=maketree($1,$3,NULL,NULL);
							}
		|ID'(' param ')'			{$$=functioncall($1,$3);
							/*while($3!=NULL)
							{
								printf(" %s - %d\n",$3->name,$3->type);
								$3=$3->ptr3;
							}*/
							}
		;
param:							{$$=NULL;
							}
		|expr					{$$=$1;
							}	
		|param ',' expr				{$$=makeparam($1,$3);
							}
		;
		

%%

int main (void)
{	
	fp=fopen("./ap.sim","w");
	fprintf(fp,"START\n");
	fprintf(fp,"MOV SP,0\n");
	fprintf(fp,"MOV BP,0\n");	
	return yyparse();
}

int yyerror (char *msg) 
{
	return fprintf (stderr, "YACC: %s\n", msg);
}
