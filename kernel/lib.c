typedef struct jmp_buf {
  char x;
} jmp_buf;

typedef int size_t;

double floor(double x) {
}

double pow(double x, double y) {
}
#ifdef NOTHERE

char *strchr(const char *s, int c) {
}


void longjmp(jmp_buf env, int val) {
}

int _setjmp(jmp_buf env) {
}
#endif

void exit(int status) {
}

void * localeconv(void) {
}

double strtod(const char *nptr, char **endptr) {
}

unsigned long strtoul(const char *str, char **endptr, int base) {
}

int sprintf(char * str, const char * format, ...) {
}

char * strncpy(char * dst, const char * src, size_t n){
}

char * strcat(char * s1, const char * s2) { 
}

#ifdef NOTHERE
int strcmp(const char *s1, const char *s2) {
}

size_t strcspn(const char *s1, const char *s2) {
}

char * strncat(char * s1, const char * s2, size_t n) { 
}

void * memcpy(void * dst, const void * src, size_t n) {
}

int memcmp(const void *s1, const void *s2, size_t n) {
}

char * strstr(const char *s1, const char *s2) {
}
#endif

int isalnum(int c) {
}
int isspace(int c) {
}
int isalpha(int c) {
}
int iscntrl(int c) {
}

int strcoll(const char *s1, const char *s2) {
}

void free(void *ptr) {
}

void * realloc(void *ptr, size_t size) {
}
