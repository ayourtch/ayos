#include <setjmp.h>
#include <stdarg.h>


typedef int size_t;

double floor(double x) {
  tfp_printf("floor called, unimplemented!\n");
  return 0;
}

double pow(double x, double y) {
  tfp_printf("pow called, unimplemented!\n");
  return 0;
}

void exit(int status) {
  tfp_printf("exit called, unimplemented!\n");
}

/*
double strtod(const char *nptr, char **endptr) {
  tfp_printf("strtod called, unimplemented!\n");
  return 0;
}
*/

unsigned long strtoul(const char *str, char **endptr, int base) {
  tfp_printf("strtoul called, unimplemented!\n");
  return 0;
}

static void putcp(void* p,char c) {
  *(*((char**)p))++ = c;
} 

void sprintf(char* s,char *fmt, ...) {
        va_list va;
        va_start(va,fmt);
        tfp_format(&s,putcp,fmt,va);
        putcp(&s,0);
        va_end(va);
}

void abort(void) {
  asm("hlt");
}

/* The heap memory starts from 2MB onwards */

static char *curr_brk = 2*1024*1024;

void *sbrk(int increment) {
  char *b = curr_brk;
  curr_brk += increment;
  return b;
}

