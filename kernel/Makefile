CFLAGS=-nostdlib -nostartfiles -nodefaultlibs
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
	lib/ctype/isalnum.o \
	lib/ctype/isspace.o \
	lib/ctype/isalpha.o \
	lib/ctype/iscntrl.o \
	lib/locale/strcoll.o \
	lib.o



XXX= \
	lua-5.1.4/src/luac.o \
	lua-5.1.4/src/loadlib.o \
	lua-5.1.4/src/lstrlib.o \
	lua-5.1.4/src/loslib.o \
	lua-5.1.4/src/lbaselib.o \
	lua-5.1.4/src/liolib.o \
	lua-5.1.4/src/linit.o \
	lua-5.1.4/src/lua.o \
	lua-5.1.4/src/lmathlib.o \
	lua-5.1.4/src/ldblib.o \
	lua-5.1.4/src/print.o 


%.o: %.c $(DEPS)
	$(CC) -c -o $@ $< $(CFLAGS)

kernel64.sys: kernel64.o printf.o kernel64.ld $(LUAOBJS) $(LIBS)
	ld -T kernel64.ld -o kernel64.sys --print-map kernel64.o printf.o $(LUAOBJS) $(LIBS) >symbols.map

clean:
	rm -f *.o
	rm -f $(LIBS)
	rm -f kernel64.sys
