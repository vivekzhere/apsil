all:	apsil
lex.yy.c:	apsil.l
		lex apsil.l

y.tab.c:	apsil.y apsil.h	
		yacc -d apsil.y
apsil:		lex.yy.c y.tab.c	
		gcc lex.yy.c y.tab.c -lfl -o apsil 
clean:
	rm -rf apsil *~ y.* lex.*
