all:	apl
lex.yy.c:	apl.l
		lex apl.l

y.tab.c:	apl.y apl.h	
		yacc -d apl.y
apl:		lex.yy.c y.tab.c	
		gcc lex.yy.c y.tab.c -lfl -o apl 
clean:
	rm -rf apl *~ y.* lex.*
