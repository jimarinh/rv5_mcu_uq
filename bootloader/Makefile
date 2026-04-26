ROOT := ../

TOOLCHAIN_PREFIX ?= riscv64-unknown-elf-

CC      := $(TOOLCHAIN_PREFIX)gcc
OBJCOPY := $(TOOLCHAIN_PREFIX)objcopy

# ---- Paths ----
FW_DIR   := $(ROOT)/firmware

# ---- ISA config ----
COMPRESSED_ISA := 
ARCH := rv32i$(subst C,c,$(COMPRESSED_ISA))

# ---- Flags ----
CFLAGS  := -Os -mabi=ilp32 -march=$(ARCH) -ffreestanding -nostdlib -I$(FW_DIR)
ASFLAGS := -mabi=ilp32 -march=$(ARCH) -x assembler-with-cpp
LDFLAGS := -Wl,--build-id=none,-Bstatic,-T,sections_boot.lds,-Map,bootloader.map,--strip-debug

BOOT_WORDS := 1024

# ---- Sources ----
BOOT_SRCS := \
	start_boot.S \
	bootloader.c 

BOOT_OBJS := \
	start_boot.o \
	bootloader.o 

# ---- Targets ----
.PHONY: all clean

all: bootloader.hex

bootloader.elf: $(BOOT_OBJS)
	$(CC) $(CFLAGS) -o $@ $^ $(LDFLAGS) -lgcc
	chmod -x $@  

bootloader.bin: bootloader.elf
	$(OBJCOPY) -O binary $< $@
	chmod -x $@
	
bootloader.hex: bootloader.bin makehex.py
	python3 makehex.py bootloader.bin $(BOOT_WORDS) 0 > $@

# ---- Compile rules ----
%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

%.o: %.S
	$(CC) $(ASFLAGS) -c $< -o $@

clean:
	rm -f *.o *.elf *.bin *.hex *.map

