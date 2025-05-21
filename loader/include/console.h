#ifndef CONSOLE_H
#define CONSOLE_H

#include <stdint.h>
#include <stdarg.h>

#define VGA_MEMORY ((volatile uint16_t*) 0xB8000)
#define MAX_COLS 80
#define MAX_ROWS 25

typedef enum {
	VGA_COLOR_BLACK = 0,
	VGA_COLOR_BLUE = 1,
	VGA_COLOR_GREEN = 2,
	VGA_COLOR_CYAN = 3,
	VGA_COLOR_RED = 4,
	VGA_COLOR_PURPLE = 5,
	VGA_COLOR_BROWN = 6,
	VGA_COLOR_GRAY = 7,
	VGA_COLOR_DARK_GRAY = 8,
	VGA_COLOR_LIGHT_BLUE = 9,
	VGA_COLOR_LIGHT_GREEN = 10,
	VGA_COLOR_LIGHT_CYAN = 11,
	VGA_COLOR_LIGHT_RED = 12,
	VGA_COLOR_LIGHT_PURPLE = 13,
	VGA_COLOR_YELLOW = 14,
	VGA_COLOR_WHITE = 15
} vga_color_t;

static inline uint8_t vga_color_attribute(vga_color_t fg, vga_color_t bg) {
	return (bg << 4) | fg;
}

static inline uint16_t vga_entry(char c, uint8_t color) {
	return (color << 8) | c;
}

void console_init(void);
void console_putchar(char c);
void console_puts(const char* str);
void console_printf(const char* fmt, ...);

#endif
