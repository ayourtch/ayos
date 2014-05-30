/* 64-bit C example kernel for Pure64 */
/* Written by Ian Seyler (www.returninfinity.com) */

#include "printf.h"
#include <stdint.h>

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

int main() {
  realmain();
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

int realmain()
{
  e820_t *pe = (void *)0x4000;
  int i=0;

  clrscr();
  init_printf(0,xputc);
  printf("\nHello\n");

  dump((void *)0x200, 0x9*16); 
  setirq(0x21, keyboard_intr);
  setirq(0x28, timer_intr);
  
  while(1) {
    asm("hlt"); // infinite loop of doing nothing
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
  for(i=0;i<80*22; i++) {
    vidmem[2*i] = 0;
    vidmem[1+ (2*i)] = ca; // (i / 80) * 16;
  }
}

void scrollup() {
  char *vidmem = (char *) 0xb8000;
  int i;
  for(i=0;i<80*24; i++) {
    vidmem[2*i] = vidmem[2*(i+80)];
    vidmem[1+ (2*i)] = vidmem[1+ 2*(i+80)];
  }
  for(i=0;i<80;i++) {
    vidmem[2*i + 24*80*2] = 0;
    vidmem[2*i + 1 + 24*80*2] = ca;
  }
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
