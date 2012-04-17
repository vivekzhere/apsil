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
%token NUM OPER1 OPER2 ID INT STR STRING MAIN BEGN END DECL ENDDECL ASG READ PRINT RELOP LOGOP NEGOP IF ELSE THEN ENDIF WHILE DO ENDWHILE RETURN SYSCREA SYSOPEN SYSWRIT SYSSEEK SYSREAD SYSCLOS SYSDELE SYSFORK SYSEXEC SYSEXIT SYSHALT BREAK CONTINUE
%type<n> stmtlist param stmt retstmt expr ids fID Body SysCall NUM STRING OPER1 OPER2 ID ASG READ PRINT RELOP LOGOP NEGOP IF WHILE RETURN SYSCREA SYSOPEN SYSWRIT SYSSEEK SYSREAD SYSCLOS SYSDELE SYSFORK SYSEXEC SYSEXIT SYSHALT ifpad whilepad BREAK CONTINUE
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
		
Fdef:		RType fID '(' fArgList ')' '{' Body '}'	{/*struct Lsymbol *temp=Lroot;
									while(temp!=NULL)
									{
										printf(" %s-%d-%d\n",temp->name,temp->type,temp->bind);
										temp=temp->next;
									}*/
									codegen($7);
									Lroot=NULL;
									funcid=NULL;										
									}
		;
RType:		INT					{m3=0;
							}
		|STR					{m3=3;
							}
		;
		
fID:		ID					{memcount=1;
							$1->type=m3;
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
				
Mainblock:	 INT fMAIN '(' ')' '{' Body '}'		{codegen($6);
								fprintf(fp,"OVER\n");
								fclose(fp);
								if(Droot!=NULL)
					 				filearea();						
					 			//printf("%d Lines Compiled\n",linecount);
								return(0);
								}
		;

fMAIN:		MAIN					{m3=0;
							memcount=1;
							funcid=NULL;
							fprintf(fp,"main:\nPUSH BP\nMOV BP,SP\n"); 
							}
		;

LDecl:		Type LIdList ';'			{}
		;
		
LIdList:	 LId					{}

		|LIdList ',' LId			{}
		;
		
LId:		ID					{Linstall($1,m,1);
							}
		;

Body:		stmtlist retstmt			{$$=nontermcreate("Body",$1,$2);			
							}
		|retstmt				{$$=nontermcreate("Body",$1,NULL);			
							}
		;
retstmt:	RETURN expr ';'				{$$=maketree($1,$2,NULL,NULL);
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
		
		|ifpad expr THEN stmtlist ENDIF ';'				{$$=maketree($1,$2,$4,NULL);flag_decl--;
										}
		|ifpad expr THEN stmtlist ELSE stmtlist ENDIF ';'		{$$=maketree($1,$2,$4,$6);flag_decl--;
										}
		|whilepad expr DO stmtlist ENDWHILE ';'				{$$=maketree($1,$2,$4,NULL);flag_decl--;flag_break=0;
										}
		|LDecl					{$$=NULL;
							}
		|SYSEXIT '(' ')' ';'			{$$=$1;		
							}
		|SYSHALT '(' ')' ';'			{$$=$1;		
							}
		|BREAK ';'				{if(flag_break==0)
							{
								printf("\n%d: break or continue should be used inside while!!\n",linecount);
								exit(0);								
							}
							$$=$1;
							}
		|CONTINUE ';'				{if(flag_break==0)
							{
								printf("\n%d: break or continue should be used inside while!!\n",linecount);
								exit(0);								
							}
							$$=$1;
							}					
		;

ifpad:		IF					{
								flag_decl++;
								$$=$1;
							}
		;

whilepad:	WHILE					{
								flag_decl++;
								flag_break=1;
								$$=$1;
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
		|SysCall				{$$=$1;
							}
		|NUM					{$$=$1;
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
		
SysCall:	SYSCREA '(' param ')'			{$$=syscheck($1,$3,1);
							}
		|SYSOPEN '(' param ')'			{$$=syscheck($1,$3,1);
							}
		|SYSWRIT '(' param ')'			{$$=syscheck($1,$3,2);
							}
		|SYSSEEK '(' param ')'			{$$=syscheck($1,$3,3);
							}
		|SYSREAD '(' param ')'			{$$=syscheck($1,$3,2);
							}
		|SYSCLOS '(' param ')'			{$$=syscheck($1,$3,4);
							}
		|SYSDELE '(' param ')'			{$$=syscheck($1,$3,1);
							}
		|SYSFORK '(' ')'			{$$=$1;
							}
		|SYSEXEC '(' param ')'			{$$=syscheck($1,$3,1);
							}		
		;
		
%%

int main (void)
{	
	fp=fopen("./apcode.esim","w");
	fprintf(fp,"START\n");
	fprintf(fp,"MOV SP,768\n");
	fprintf(fp,"MOV BP,768\n");	
	return yyparse();
}

int yyerror (char *msg) 
{
	return fprintf (stderr, "%d: %s\n",linecount,msg);
}
