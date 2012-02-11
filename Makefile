all:	a.out
lex.yy.c:	apsil.l
		lex apsil.l

y.tab.c:	apsil.y apsil.h	
		yacc -d apsil.y
a.out:		lex.yy.c y.tab.c	
		gcc lex.yy.c y.tab.c -ll 
