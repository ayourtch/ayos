/* 64-bit C example kernel for Pure64 */
/* Written by Ian Seyler (www.returninfinity.com) */

#include "printf.h"
#include <stdint.h>
#include "lua.h"


static int cx = 0;
static int cy = 0;
static int ca = 7;
unsigned int print(char *message, unsigned int line);
void clrscr(void);
void xputc(void* p, char c);
void scrollup();

typedef struct e820_t {
  uint64_t start;
  uint64_t len;
  uint32_t type;
  uint32_t pad1, pad2, pad3;
} e820_t;

int realmain();
extern void *_end;

int main() {
  char *vidmem = (char *) 0xb8000;
  void **pend = &_end;
  uint32_t calc_len = (*pend);
  uint32_t real_len = (char *)&_end - (char *)main;
  if(real_len != calc_len) {
    vidmem[0] = '#';
    vidmem[1] = 0x4e;
    asm("hlt");
  } else {
    vidmem[0] = '!';
    vidmem[1] = 0x2f;
    // asm("hlt");
  }
  asm("push    %rsp");
  asm("sub    $16,%rsp");
  asm("and    $-0x10,%rsp");
  realmain();
  asm("pop %rsp");
}

void dump(void *p, int n) {
  unsigned char *pc = p;
  int i = 0;
  printf("%04x : ", 0);
  for(i=0; i < n; i++) { 
    printf("%02X ", *pc++);
    if (i % 16 == 15) {
      printf("\n");
      if(i+1 < n) {
        printf("%04x : ", i+1);
      }
    }
  }
}

void kbd() {
  uint32_t c;
  asm("mov %%eax, %0\n" : "=m"(c));
  printf("%x\n", c);
}

#define KBD_QUEUE_SIZE 32
int kbd_head = 0;
int kbd_tail = 0;
char kbd_buf[KBD_QUEUE_SIZE];

int kbd_ready() {
  return (kbd_head != kbd_tail);
}

int getc() {
  int c = -1;
  while(!kbd_ready()) { asm("hlt"); }
  c = kbd_buf[kbd_tail++];
  kbd_tail = kbd_tail % KBD_QUEUE_SIZE;
  return c;
}

void keyboard_intr(void) __attribute__((aligned(16)));
void keyboard_intr(void) {
  uint32_t c;
  asm("push %rdi");
  asm("push %rax");
  asm("push %rdx");
  asm("xor %rax, %rax");
  // Get the scan code
  asm("mov $0x60, %dx");
  asm("in     (%dx),%al");
  // extract it into a variable      
  asm("mov %%eax, %0\n" : "=m"(c));
  if((kbd_head+1) % KBD_QUEUE_SIZE != kbd_tail) {
    kbd_buf[kbd_head++] = c;
    kbd_head = kbd_head % KBD_QUEUE_SIZE;
  }
  // put it into screen memory for debugging
  asm("mov %al, 0x000B8088");

  // inform the APIC
  asm("mov 0x5060, %rdi"); // [os_LocalAPICAddress]
  asm("add $0xB0, %rdi");
  asm("xor %rax, %rax");
  asm("stos   %rax,%es:(%rdi)");

  asm("pop %rdx");
  asm("pop %rax");
  asm("pop %rdi");
  // We are restoring this as this was pushed by the prologue
  asm("pop %rbp");
  asm("iretq");
  // Never reached
}

uint64_t timer_tick = 0;

void timer_intr(void) __attribute__((aligned(16)));
void timer_intr(void) {
  uint32_t c;
  asm("push %rdi");
  asm("push %rax");
  asm("push %rdx");
  asm("xor %rax, %rax");

  asm("mov $0x70, %dx");
  asm("mov $0x0c, %al");
  asm("out     %al,(%dx)");
  asm("mov $0x71, %dx");
  asm("in     (%dx),%al");

  // extract it into a variable      
  asm("mov %%eax, %0\n" : "=m"(c));
  // put it into screen memory for debugging
  asm("mov %al, 0x000B8090");
  timer_tick++;

  // inform the APIC
  asm("mov 0x5060, %rdi"); // [os_LocalAPICAddress]
  asm("add $0xB0, %rdi");
  asm("xor %rax, %rax");
  asm("stos   %rax,%es:(%rdi)");

  asm("pop %rdx");
  asm("pop %rax");
  asm("pop %rdi");
  // We are restoring this as this was pushed by the prologue
  asm("pop %rbp");
  asm("iretq");
  // Never reached
}


void setirq(int num, void *handler) {
  long long ptr = (long long) handler;
  uint16_t *p0_15 = (void *) (num*16);
  uint16_t *p16_31 = (void *) (num*16 + 6);
  uint32_t *p32_63 = (void *) (num*16 + 8);
  asm("cli");
  (*p0_15) = ptr & 0xffff;
  (*p16_31) = (ptr >> 16) & 0xffff;
  (*p32_63) = (ptr >> 32) & 0xffffffff;
  asm("sti");
}

static int lua_fn_cr(lua_State *L) {
  int n = lua_gettop(L);
  size_t len;
  cx = 0;
  return 0;
}
static int lua_fn_say(lua_State *L) {
  int n = lua_gettop(L);
  size_t len;
  char *str = (void *)lua_tolstring(L, 1, &len);
  printf("LUA says: '%s'\n", str);

  return 0;
}

static int lua_fn_poke(lua_State *L) {
  int n = lua_gettop(L);
  int iaddr = lua_tointeger(L, 1);
  int ival = lua_tointeger(L, 2);
  char *ptr = (char *)iaddr;
  int ret = (uint8_t)*ptr;
  *ptr = ival;
  lua_pushinteger(L, ret);
  return 1;
}

static int lua_fn_peek(lua_State *L) {
  int iaddr = lua_tointeger(L, 1);
  char *ptr = (char *)iaddr;
  int ret = (uint8_t)*ptr;
  lua_pushinteger(L, ret);
  return 1;
}


lua_State *L;
void lua_init_state(lua_State *L) {
  luaopen_base(L);
  lua_register(L, "say", lua_fn_say);
  lua_register(L, "cr", lua_fn_cr);
  lua_register(L, "poke", lua_fn_poke);
  lua_register(L, "peek", lua_fn_peek);
}

extern unsigned char luacode_lua[];
extern unsigned int luacode_lua_len;

int realmain()
{
  e820_t *pe = (void *)0x4000;
  void *endptr = &_end;
  void **endp = endptr;
  int i=0;

  //dump((void *)0x200, 0x9*16); 
  setirq(0x21, keyboard_intr);
  setirq(0x28, timer_intr);

  clrscr();
  init_printf(0,xputc);
  printf("\nHello, total len: %d\n", (char *)endptr - (char *)main);
  printf("Endptr: %x\n", *endp);
  L = lua_open();
  lua_init_state(L);
  // lua_pushinteger(L, 1234);
  lua_pushstring(L, "a1234");
  lua_pushstring(L, "b1234");
  lua_pushstring(L, "c1234");
  lua_pushstring(L, "d1234");
  lua_pushstring(L, "e1234");
  lua_pushstring(L, "f1234");
  lua_pushstring(L, "g1234");
  printf("Press ESC to continue...");
  while(1) {
    int c = getc();
    if(c == 1) {
      printf("ESC pressed, continuing\n");
      break;
    }
  }
  printf("Loading Lua bootstrap...\n");

  if(luacode_lua[luacode_lua_len-1] != 0xa) {
    printf("luacode.lua should end with an empty line\n");
  } else {
    luacode_lua[luacode_lua_len-1] = 0;
    if(luaL_loadstring(L, luacode_lua)) {
      printf("Lua load error: %s\n", lua_tostring(L,-1));
    } else {
      int err = lua_pcall(L, 0, LUA_MULTRET, 0);
      if(err) {
        printf("Lua run error: %s\n", lua_tostring(L,-1));
      }
    }
  }
#ifdef NOTNOW
  if(luaL_loadstring(L, "k={'A', 'B', 'C'}; for i=1,10 do cr(); say('Hello' .. k[(i%3)+1] .. '!'); end")) {
    printf("Lua load error: %s\n", lua_tostring(L,-1));
  } else {
    int err = lua_pcall(L, 0, LUA_MULTRET, 0);
    if(err) {
      printf("Lua run error: %s\n", lua_tostring(L,-1));
    }
    /*
    lua_getglobal(L, "request");
    lua_pushinteger(L, idx);
    int err = lua_pcall(L, 1, 0, 0);
    if (err != 0) {
     debug(0,0,"%d: LUA error %s\n",getpid(), lua_tostring(L,-1));
    }
    */
  }
#endif

  
  while(1) {
    int c = -1;
    uint64_t tick = timer_tick;
    while(!kbd_ready() && (tick == timer_tick) ) { asm("hlt"); }
    if (tick != timer_tick) {
      lua_getglobal(L, "tick");
      lua_pushinteger(L, timer_tick);
      int err = lua_pcall(L, 1, 0, 0);
    }
    if (kbd_ready()) {
      c = kbd_buf[kbd_tail++];
      kbd_tail = kbd_tail % KBD_QUEUE_SIZE;
      lua_getglobal(L, "keypress");
      lua_pushinteger(L, (uint8_t)c);
      int err = lua_pcall(L, 1, 0, 0);
      if (err != 0) {
	printf("keypress LUA error %s\n", lua_tostring(L,-1));
      }
    }
  }
  while(1) {
    if (0) {
      asm("hlt"); // infinite loop of doing nothing
      cx = 0;
      cy = 0;
      printf("%08x\n", i++);
    }
    if (1) {
      int scx = cx;
      int scy = cy;
      uint32_t *prtc = (void*)0x5a20;
      asm("cli");
      cx = 0;
      cy = 0;
      printf("%08x %08x\n", *prtc, i++);
      cx = scx; 
      cy = scy;

      asm("sti");
    }
  }
  return (0);
};

void clrscr(void) {
  char *vidmem = (char *) 0xb8000;
  int i;
  asm("cli");
  for(i=0;i<80*22; i++) {
    vidmem[2*i] = 0;
    vidmem[1+ (2*i)] = ca; // (i / 80) * 16;
  }
  asm("sti");
}

void scrollup() {
  char *vidmem = (char *) 0xb8000;
  int i;
  asm("cli");
  for(i=0;i<80*24; i++) {
    vidmem[2*i] = vidmem[2*(i+80)];
    vidmem[1+ (2*i)] = vidmem[1+ 2*(i+80)];
  }
  for(i=0;i<80;i++) {
    vidmem[2*i + 24*80*2] = 0;
    vidmem[2*i + 1 + 24*80*2] = ca;
  }
  asm("sti");
}

void crlf() {
  cx = 0;
  cy++;
  if (cy > 24) {
    cy = 24;
    scrollup();
  }
}

void pxputc( void* p, char c) {
  char *vidmem = (char *) 0xb8000;
  vidmem[2*(cx + 80*cy)] = c;
  vidmem[1+ 2*(cx + 80*cy)] = ca;
  cx++;
  if (cx > 80) {
    crlf();
  }
}

void xputc( void* p, char c) {
  switch(c) {
    case 0x0d:
    case 0x0a:
      crlf();
      break;
    default:
      pxputc(p, c);
  }
}


/* Kernel functions */

unsigned int print(char *message, unsigned int line)
{
	char *vidmem = (char *) 0xb8000;
	unsigned int i= 0;

	i=(line*80*2);

	while(*message!=0) // 24h
	{
		vidmem[i]= *message;
		*message++;
		i++;
		vidmem[i]= 0x7;
		i++;
	};

	return(1);
};
