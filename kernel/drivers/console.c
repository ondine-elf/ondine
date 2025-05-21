#include "console.h"
#include "io.h"

static uint8_t console_color;
static uint8_t cursor_x;
static uint8_t cursor_y;

static void console_update_cursor(void) {
	uint16_t pos = cursor_y * MAX_COLS + cursor_x;

	outb(0x03D4, 0x0F);
	outb(0x03D5, (uint8_t)(pos & 0xFF));

	outb(0x03D4, 0x0E);
	outb(0x03D5, (uint8_t)((pos >> 8) & 0xFF));
}

// Consider a single loop from 0 to MAX_ROWS * MAX_COLS
static void console_clear(void) {
	for (uint8_t row = 0; row < MAX_ROWS; row++) {
		for (uint8_t col = 0; col < MAX_COLS; col++) {
			VGA_MEMORY[row * MAX_COLS + col] = vga_entry(' ', console_color);
		}
	}

	cursor_x = 0;
	cursor_y = 0;
	console_update_cursor();
}

void console_init(void) {
	console_color = vga_color_attribute(VGA_COLOR_LIGHT_GREEN, VGA_COLOR_BLACK);
	console_clear();
}

void console_putchar(char c) {
	if (c == '\n') {
		cursor_x = 0;
		cursor_y++;
	} else if (c == '\r') {
		cursor_x = 0;
	} else if (c == '\b') {
		if (cursor_x > 0) {
			cursor_x--;
		} else if (cursor_y > 0) {
			cursor_y--;
			cursor_x = MAX_COLS - 1;
		}
		VGA_MEMORY[cursor_y * MAX_COLS + cursor_x] = vga_entry(' ', console_color);
	} else {
		VGA_MEMORY[cursor_y * MAX_COLS + cursor_x] = vga_entry(c, console_color);
		cursor_x++;
		if (cursor_x >= MAX_COLS){ 
			cursor_x = 0;
			cursor_y++;
		}
	}

	if (cursor_y >= MAX_ROWS) {
		for (uint8_t row = 1; row < MAX_ROWS; row++) {
			for (uint8_t col = 0; col < MAX_COLS; col++) {
				VGA_MEMORY[(row - 1) * MAX_COLS + col] = VGA_MEMORY[row * MAX_COLS + col];
			}
		}

		for (uint8_t col = 0; col < MAX_COLS; col++) {
			VGA_MEMORY[(MAX_ROWS - 1) * MAX_COLS + col] = vga_entry(' ', console_color);
		}

		cursor_y = MAX_ROWS - 1;
	}

	console_update_cursor();
}

void console_puts(const char* str) {
	while (*str) console_putchar(*str++);
}
