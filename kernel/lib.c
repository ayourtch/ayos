typedef struct jmp_buf {
  char x;
} jmp_buf;

typedef int size_t;

double floor(double x) {
}

double pow(double x, double y) {
}

void exit(int status) {
}

double strtod(const char *nptr, char **endptr) {
}

unsigned long strtoul(const char *str, char **endptr, int base) {
}

int sprintf(char * str, const char * format, ...) {
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

