#include <stdio.h>

extern void print_string(const char *str);

int hi() {
    print_string("Hello from C!");
    return 0;
}