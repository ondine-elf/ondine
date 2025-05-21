BOOT_DIR := boot
KERNEL_DIR := kernel
BUILD_DIR := build

AS := nasm

BOOT_ASFLAGS := -f bin -I$(BOOT_DIR)
KERNEL_ASFLAGS := -f elf32 -I$(KERNEL_DIR)/include

CC := gcc
CFLAGS := -ffreestanding
CFLAGS += -nostdlib
CFLAGS += -fno-pic
CFLAGS += -fno-pie
CFLAGS += -I$(KERNEL_DIR)/include
CFLAGS += -m32

LD := ld
LDFLAGS := -m elf_i386 -T $(KERNEL_DIR)/linker.ld

KERNEL_SRCS := $(shell find $(KERNEL_DIR) -name '*.asm') $(shell find $(KERNEL_DIR) -name '*.c')

OBJ := $(patsubst $(KERNEL_DIR)/%, build/%, $(KERNEL_SRCS))
OBJ := $(OBJ:.asm=.o)
OBJ := $(OBJ:.c=.o)

BOOT := $(BUILD_DIR)/boot.bin
KERNEL := $(BUILD_DIR)/kernel.bin
IMAGE := $(BUILD_DIR)/os.bin

dirs:
	@mkdir -p $(sort $(dir $(OBJ)))

$(BUILD_DIR)/%.o: $(KERNEL_DIR)/%.asm | dirs
	$(AS) $(KERNEL_ASFLAGS) $< -o $@

$(BUILD_DIR)/%.o: $(KERNEL_DIR)/%.c | dirs
	$(CC) $(CFLAGS) -c $< -o $@

$(BOOT): $(BOOT_DIR)/boot.asm | dirs
	$(AS) $(BOOT_ASFLAGS) $< -o $@

$(KERNEL): $(OBJ) | dirs
	$(LD) $(LDFLAGS) $^ -o $@

$(IMAGE): $(BOOT) $(KERNEL)
	truncate -s 16K $(KERNEL)
	cat $(BOOT) $(KERNEL) > $(IMAGE)

os: $(IMAGE)

run:
	qemu-system-i386 -drive file=$(IMAGE),format=raw

clean:
	@rm -rf build