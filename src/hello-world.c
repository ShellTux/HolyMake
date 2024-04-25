#include "hello-world.h"

#include <stdio.h>

int main(void) {
	helloWorld();
	return 0;
}

void helloWorld(void) {
#ifndef DEBUG
	printf("Hello world!\n");
#else
	printf("Hello debug mode!\n");
#endif
}
