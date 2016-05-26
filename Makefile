CC=gcc
CXX=g++
LEX=flex
YACC=bison
CFLAGS=-g
LDFLAGS=-ly -ll

all: simplec

simple.tab.c simple.tab.h: simple.y
	$(YACC) -b simple -v -t -d $<

simple.lex.c: simple.l simple.tab.h
	$(LEX) $<
	mv lex.yy.c $@

simple.tab.o: simple.tab.c simple.global.h simple.attr.h
	$(CC) $< $(CFLAGS) -c -o $@

simple.lex.o: simple.lex.c simple.tab.h simple.global.h
	$(CC) $< $(CFLAGS) -c -o $@

simple.attr.o: simple.attr.c simple.attr.h
	$(CC) $< $(CFLAGS) -c -o $@

simplec: simple.lex.o simple.attr.o simple.tab.o
	$(CC) $^ $(LDFLAGS) -o $@

clean:
	rm -f simple.tab.c simple.tab.h simple.output simple.lex.c simple.tab.o simple.attr.o simple.lex.o simplec

