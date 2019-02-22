all: dumper
	gcc -Wall -o selflove selflove.c

g:
	gcc -Wall -g -o selflove-g selflove.c

o3:
	gcc -Wall -O3 -o selflove-o3 selflove.c

dumper:
	gcc -Wall -O3 -o dumper dumper.c

clean:
	-rm selflove
	-rm selflove-g
	-rm selflove-o3
	-rm dumper

.PHONY=clean
