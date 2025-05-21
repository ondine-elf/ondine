BOOT_DIR   := boot
LOADER_DIR := loader
KERNEL_DIR := kernel
BUILD_DIR  := build

AS := nasm
ASFLAGS := -f elf32

CC := gcc
CFLAGS := -ffreestanding
CFLAGS += -nostdlib
CFLAGS += -fno-pic
CFLAGS += -fno-pie

LD := ld
LDFLAGS := -m elf_i386

BOOT_FLAGS := -f bin -I$(BOOT_DIR)

BOOT := $(BUILD_DIR)/boot.bin
LOADER := $(BUILD_DIR)/loader.bin
KERNEL := $(BUILD_DIR)/kernel.bin
IMAGE := $(BUILD_DIR)/os.bin

LOADER_SRC := $(wildcard $(LOADER_DIR)/src/*.asm $(LOADER_DIR)/src/*.c)
KERNEL_SRC := $(wildcard $(KERNEL_DIR)/src/*.asm $(KERNEL_DIR)/src/*.c)

LOADER_OBJ := $(patsubst $(LOADER_DIR)/src/%, build/loader/%, $(LOADER_SRC))
LOADER_OBJ := $(LOADER_OBJ:.c=.o)
LOADER_OBJ := $(LOADER_OBJ:.asm=.o)

KERNEL_OBJ := $(patsubst $(KERNEL_DIR)/src/%, build/kernel/%, $(KERNEL_SRC))
KERNEL_OBJ := $(KERNEL_OBJ:.c=.o)
KERNEL_OBJ := $(KERNEL_OBJ:.asm=.o)

$(BUILD_DIR)/$(LOADER_DIR)/%.o: $(LOADER_DIR)/src/%.asm
	@mkdir -p $(dir $@)
	$(AS) $(ASFLAGS) -I$(LOADER_DIR)/include $< -o $@

$(BUILD_DIR)/$(LOADER_DIR)/%.o: $(LOADER_DIR)/src/%.c
	@mkdir -p $(dir $@)
	$(CC) $(CFLAGS) -I$(LOADER_DIR)/include -m16 -c $< -o $@

$(BUILD_DIR)/$(KERNEL_DIR)/%.o: $(KERNEL_DIR)/src/%.asm
	@mkdir -p $(dir $@)
	$(AS) $(ASFLAGS) -I$(KERNEL_DIR)/include $< -o $@

$(BUILD_DIR)/$(KERNEL_DIR)/%.o: $(KERNEL_DIR)/src/%.c
	@mkdir -p $(dir $@)
	$(CC) $(CFLAGS -I$(KERNEL_DIR)/include -m32 -c $< -o $@)

$(BOOT): $(BOOT_DIR)/boot.asm
	@mkdir -p $(dir $@)
	$(AS) $(BOOT_FLAGS) $< -o $@

$(LOADER): $(LOADER_OBJ)
	$(LD) $(LDFLAGS) -T $(LOADER_DIR)/linker.ld $^ -o $@

$(KERNEL): $(KERNEL_OBJ)
	$(LD) $(LDFLAGS) -T $(KERNEL_DIR)/linker.ld $^ -o $@

$(IMAGE): $(BOOT) $(LOADER)
	truncate -s 16K $(LOADER)
	cat $(BOOT) $(LOADER) > $@

os: $(IMAGE)

run: $(IMAGE)
	qemu-system-i386 -drive file=$(IMAGE),format=raw

clean:
	rm -rf $(BUILD_DIR)