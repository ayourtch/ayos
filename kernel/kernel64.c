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

int main()
{
  unsigned char *pc = (void *)0x4000;
  e820_t *pe = (void *)0x4000;
  char spinner[]="-\\|/-\\|/";
  int i = 0;
  clrscr();
  init_printf(0,xputc);
  printf("Hello from printf!\nThis is a test\n");
  for(i=0; i < 128; i++) { 
    printf("%02X ", *pc++);
    if (i % 16 == 15) {
      printf("\n");
    }
  }

  while(pe->start || pe->len || pe->type) {
    printf("%08x : %08x : %08x\n", (int)pe->start, (int)pe->type, (int)pe->len);
    pe++;
  }
  
  
  while(1) {
    asm("hlt"); // infinite loop of doing nothing
    cx = 0;
    cy = 0;
    printf("%08x\n", i++);
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
