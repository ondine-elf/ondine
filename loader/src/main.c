#include "console.h"

void kernel_main(void) {
    console_init();
    console_putchar('a');
    

    while (1);
}

/*
    asm volatile (
        "mov $0x0e, %%ah\n\t"
        "mov $'a', %%al\n\t"
        "int $0x10"
        :
        :
        : "ah", "al"
    );

    
*/