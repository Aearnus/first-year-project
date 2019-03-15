all: dumper
	gcc -Wall -o selflove selflove.c

g:
	gcc -Wall -g -o selflove-g selflove.c

o3:
	gcc -Wall -O3 -o selflove-o3 selflove.c

dumper:
	gcc -Wall -O3 -o dumper dumper.c

fake_malloc:
	gcc -shared -fpic -Wall -O3 -o fake_malloc.so fake_malloc.c

clean:
	-rm selflove
	-rm selflove-g
	-rm selflove-o3
	-rm dumper
	-rm fake_malloc.so

.PHONY=clean
