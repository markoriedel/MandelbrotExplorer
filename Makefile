
CC = gcc
CFLAGS = -Wall
LDFLAGS = -lgmp

RM = rm -f

all: mandelcmp5

mandelcmp5: mandelcmp5.c
	$(CC) $(CFLAGS) $(LDFLAGS) -o $@ $^ 

clean:
	$(RM) mandelcmp5 *.gif *~
