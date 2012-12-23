%{
#include "y.tab.h"
int linecount=1;
struct tree
{
	int type;		//0-integer , 1-boolean , 2-void, 3-string
	char nodetype;		/*	+,-,*,/,%,=,<,>,!
					?-if statement
					c-number,	i-identifier,	r-read,		p-print,
					n-nonterminal,	e-double equals,	l-lessthan or equals
					g-greaterthan or equals		w-while		s-string
					f-function,	u-return
					a-AND		o-OR		x-NOT
							*/
	char *name;
	int value;
	struct Gsymbol *Gentry;
	struct Lsymbol *Lentry;
	struct tree *argument;
	struct tree *ptr1,*ptr2,*ptr3;
};
void func(int, char, char*, int);
%}

%%
"if"			{
			func(2,'?',NULL,-1);
			return IF;
			}
			
"else"			{
			return ELSE;
			}
			
"then"			{
			return THEN;
			}

"endif"			{
			return ENDIF;		
			}

"while"			{
			func(2,'w',NULL,-1);
			return WHILE;
			}

"do"			{
			return DO;
			}

"endwhile"		{
			return ENDWHILE;
			}
			
"integer"		{
			return INT;				
			}

"string"		{
			return STR;
			}
			
"main"			{
			return MAIN;
			}
			
"decl"			{
			return DECL;
			}

"enddecl"		{
			return ENDDECL;
			}
			
"Create"		{
			func(0,'C',yytext,1);
			return SYSCREA;
			}

"Open"			{
			func(0,'O',yytext,2);
			return SYSOPEN;
			}

"Close"			{
			func(0,'L',yytext,3);
			return SYSCLOS;
			}

"Delete"		{
			func(0,'D',yytext,4);
			return SYSDELE;
			}

"Write"			{
			func(0,'W',yytext,5);
			return SYSWRIT;
			}
			
"Seek"			{
			func(0,'S',yytext,6);
			return SYSSEEK;
			}

"Read"			{
			func(0,'R',yytext,7);
			return SYSREAD;
			}

"Fork"			{
			func(0,'F',yytext,8);
			return SYSFORK;
			}

"Exec"			{
			func(0,'X',yytext,9);
			return SYSEXEC;
			}

"Exit"			{
			func(0,'E',yytext,10);
			return SYSEXIT;
			}

"Halt"			{
			func(0,'H',yytext,0);
			return SYSHALT;
			}

"read"			{
			func(2,'r',NULL,-1);
			return READ;
			}
			
"write"			{
			func(2,'p',NULL,-1);
			return PRINT;
			}

"break"			{
			func(2,'b',NULL,-1);
			return BREAK;
			}	

"continue"		{
			func(2,'t',NULL,-1);
			return CONTINUE;
			}		

"return"		{
			func(2,'u',NULL,-1);
			return RETURN;
			}

[0-9]+			{
			func(0,'c',NULL,atoi(yytext));
			return NUM;
			}

(=)			{
			func(2,'=',NULL,-1);
			return ASG;
			}
			
[-+]			{
			func(0,*yytext,NULL,-1);
			return OPER1;			
			}
			
[*/%]			{
			func(0,*yytext,NULL,-1);
			return OPER2;			
			}
			
[<>]			{
			func(1,*yytext,NULL,-1);
			return RELOP;
			}
			
(==)			{
			func(1,'e',NULL,-1);
			return RELOP;
			}
			
(<=)			{
			func(1,'l',NULL,-1);
			return RELOP;
			}
			
(>=)			{
			func(1,'g',NULL,-1);
			return RELOP;
			}
			
(!=)			{
			func(1,'!',NULL,-1);
			return RELOP;
			}


"&&"			{
			func(1,'a',NULL,-1);
			return LOGOP;
			}

"||"			{
			func(1,'o',NULL,-1);
			return LOGOP;
			}
"!"			{
			func(1,'x',NULL,-1);
			return NEGOP;
			}
			
			
			
[a-zA-Z][a-zA-Z0-9]*	{
			func(-1,'i',yytext,-1);
			return ID;
			}	
						
[\"].*[\"]		{func(3,'s',yytext,-1);
			return STRING;
			}
			
[(),;\[\]\{\}&]		{return *yytext;}

[/][/].*\n			{linecount++;}

[\n]			{linecount++;}

[ \t]			{}

.			{}


%%
char * makestring(char *name)
{
	char *temp=strdup(name);
	int i=0;
	temp++;
	while(temp[i]!='"')
		i++;
	temp[i]='\0';
	return temp;	
}
void func(int type,char nodetype, char *name, int value)
{
	yylval.n=malloc(sizeof(struct tree));
	yylval.n->type=type;
	yylval.n->nodetype=nodetype;
	yylval.n->name=NULL;
	if(name!=NULL)
	{
		if(nodetype=='s')
			yylval.n->name=makestring(name);
		else
			yylval.n->name=strdup(name);
	}		
	yylval.n->value=value;
	yylval.n->Gentry=NULL;
	yylval.n->Lentry=NULL;
	yylval.n->ptr1=NULL;
	yylval.n->ptr2=NULL;
	yylval.n->ptr3=NULL;

}
