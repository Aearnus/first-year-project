#include <stdlib.h>
#include <stdio.h>

static void* old_malloc = malloc;

extern void* malloc(size_t size) {
  printf("mallocing %d bytes", size);
  return old_malloc(size);
}
