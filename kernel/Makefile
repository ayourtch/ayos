.PHONY: all
CFLAGS= -g -nostdlib -nostartfiles -nodefaultlibs -Ilua-5.1.4/src/ -Ilib/stdlib -Ilib/math
XLUAOBJS= 
LUAOBJS = \
	lua-5.1.4/src/lapi.o \
	lua-5.1.4/src/lcode.o \
	lua-5.1.4/src/ldo.o \
	lua-5.1.4/src/ldump.o \
	lua-5.1.4/src/lfunc.o \
	lua-5.1.4/src/lgc.o \
	lua-5.1.4/src/llex.o \
	lua-5.1.4/src/lmem.o \
	lua-5.1.4/src/lobject.o \
	lua-5.1.4/src/lopcodes.o \
	lua-5.1.4/src/lparser.o \
	lua-5.1.4/src/lstate.o \
	lua-5.1.4/src/lstring.o \
	lua-5.1.4/src/ltable.o \
	lua-5.1.4/src/ltablib.o \
	lua-5.1.4/src/ltm.o \
	lua-5.1.4/src/lundump.o \
	lua-5.1.4/src/lvm.o \
	lua-5.1.4/src/lzio.o \
	lua-5.1.4/src/ldebug.o \
	lua-5.1.4/src/lauxlib.o \
	lua-5.1.4/src/lbaselib.o \
	lua-5.1.4/src/lstrlib.o \

LIBS = \
	lib/setjmp/setjmp.o \
	lib/setjmp/longjmp.o \
	lib/string/strchr.o \
	lib/string/strchrnul.o \
	lib/string/memcpy.o \
	lib/string/memcmp.o \
	lib/string/strstr.o \
	lib/string/memchr.o \
	lib/string/strcmp.o \
	lib/string/strcspn.o \
	lib/string/strncat.o \
	lib/string/strcat.o \
	lib/string/strcpy.o \
	lib/string/stpcpy.o \
	lib/string/strncpy.o \
	lib/string/stpncpy.o \
	lib/string/memset.o \
	lib/string/strpbrk.o \
	lib/string/tolower.o \
	lib/string/toupper.o \
	lib/ctype/isalnum.o \
	lib/ctype/isspace.o \
	lib/ctype/isalpha.o \
	lib/ctype/iscntrl.o \
	lib/ctype/__ctype_b_loc.o \
	lib/locale/strcoll.o \
	lib/locale/localeconv.o \
	lib/stdlib/strtod.o \
	lib/stdlib/floatscan.o \
	lib/stdlib/shgetc.o \
	lib/stdlib/__uflow.o \
	lib/stdlib/__toread.o \
	lib/stdlib/sprintf.o \
	lib/stdlib/vsprintf.o \
	lib/stdlib/vsnprintf.o \
	lib/stdlib/vfprintf.o \
	lib/stdlib/fwrite.o \
	lib/stdlib/__towrite.o \
	lib/math/__fpclassifyl.o \
	lib/math/__signbitl.o \
	lib/math/frexpl.o \
	lib/math/scalbn.o \
	lib/math/scalbnl.o \
	lib/math/fmodl.o \
	lib/math/floor.o \
	lib/errno/errno_location.o \
	lib/malloc.o \
	bit.o \
	hw.o \
	lib.o



XXX= \
	lua-5.1.4/src/luac.o \
	lua-5.1.4/src/loadlib.o \
	lua-5.1.4/src/loslib.o \
	lua-5.1.4/src/liolib.o \
	lua-5.1.4/src/linit.o \
	lua-5.1.4/src/lua.o \
	lua-5.1.4/src/lmathlib.o \
	lua-5.1.4/src/ldblib.o \
	lua-5.1.4/src/print.o 

all: kernel64.sys

%.o: %.c $(DEPS)
	$(CC) -c -o $@ $< $(CFLAGS)

luacode.c: luacode.lua
	xxd -i luacode.lua >luacode.c

kernel64.sys: kernel64.o printf.o luacode.o kernel64.ld $(LUAOBJS) $(LIBS)
	ld -T kernel64.ld -o kernel64.sys.debug --print-map kernel64.o printf.o luacode.o $(LUAOBJS) $(LIBS) >symbols.map
	objcopy -O binary kernel64.sys.debug kernel64.sys

clean:
	(cd lua-5.1.4; make clean)
	rm -f *.o luacode.c
	rm -f $(LIBS)
	rm -f kernel64.sys
