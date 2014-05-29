kernel64.sys: kernel64.c kernel64.ld
	gcc -o kernel64.o -c kernel64.c -nostdlib -nostartfiles -nodefaultlibs
	gcc -o printf.o -c printf.c -nostdlib -nostartfiles -nodefaultlibs
	ld -T kernel64.ld -o kernel64.sys kernel64.o printf.o

clean:
	rm -f *.o
	rm -f kernel64.sys
