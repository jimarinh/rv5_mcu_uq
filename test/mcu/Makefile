#This is a reduced version of the original picoRV32 Makefile
#**************

ROOT = ../..
OBJ_PATH = $(ROOT)/obj
SHELL = bash
PYTHON = python3
ICARUS_SUFFIX =
IVERILOG = iverilog$(ICARUS_SUFFIX)
VVP = vvp$(ICARUS_SUFFIX)
MAKEHEX = $(PYTHON) $(ROOT)/firmware/makehex.py

FIRMWARE_OBJS = $(OBJ_PATH)/start_uq.o $(OBJ_PATH)/irq.o $(OBJ_PATH)/print.o \
				$(OBJ_PATH)/gpio.o $(OBJ_PATH)/i2c.o $(OBJ_PATH)/spi.o \
				$(OBJ_PATH)/timers.o $(OBJ_PATH)/uart.o $(OBJ_PATH)/watchdog.o

TARGET = test_gpio_int
TEST_OBJS 	  =  $(OBJ_PATH)/$(TARGET).o

VERILOG_GPIO    = $(ROOT)/src/gpio/gpio_pin.v
VERILOG_UART    = $(ROOT)/src/uart/uart_tx.v $(ROOT)/src/uart/uart_rx.v $(ROOT)/src/uart/uart_bitrate.v $(ROOT)/src/mcu/uart.v 
VERILOG_SPI		= $(ROOT)/src/spi/spi_sipo8.v $(ROOT)/src/spi/spi_controller.v 
VERILOG_OBJS =  $(ROOT)/src/mcu/mcu_uq.v $(ROOT)/src/mcu/memory_bwe.v $(ROOT)/src/mcu/memory_nobwe.v $(ROOT)/src/mcu/picorv32_sky130.v \
				$(ROOT)/src/mcu/watchdog.v $(ROOT)/src/mcu/gpio.v $(ROOT)/src/mcu/timer.v \
				$(ROOT)/src/mcu/i2c.v $(ROOT)/src/mcu/spi.v $(VERILOG_GPIO) $(VERILOG_UART) $(VERILOG_SPI) \
				$(ROOT)/test/mcu/mcu_uq_uart_spi_tb.v


GCC_WARNS  = 
TOOLCHAIN_PREFIX = riscv64-unknown-elf-
COMPRESSED_ISA = 
INCLUDE_PATH = $(ROOT)/firmware

test: testbench_mcu_uq.vvp flash.hex sram.hex
	$(VVP) -N $< +vcd

testbench_mcu_uq.vvp: $(VERILOG_OBJS)
	$(IVERILOG) -o $@ $(subst C,-DCOMPRESSED_ISA,$(COMPRESSED_ISA)) $^
	chmod -x $@

flash.hex: flash.bin
	$(MAKEHEX) $< 32768 > $@

sram.hex: sram.bin
	$(MAKEHEX) $< 32768 > $@

flash.bin: firmware.elf
	$(TOOLCHAIN_PREFIX)objcopy -O binary --only-section=.flash $< $@
	chmod -x $@

sram.bin: firmware.elf
	$(TOOLCHAIN_PREFIX)objcopy -O binary --only-section=.sram $< $@
	chmod -x $@

firmware.elf: $(FIRMWARE_OBJS) $(TEST_OBJS) $(ROOT)/firmware/sections_uq.lds
	$(TOOLCHAIN_PREFIX)gcc -Os -mabi=ilp32 -march=rv32i$(subst C,c,$(COMPRESSED_ISA)) -ffreestanding -nostdlib -o $@ \
		-Wl,--build-id=none,-Bstatic,-T,$(ROOT)/firmware/sections_uq.lds,-Map,firmware.map,--strip-debug \
		$(FIRMWARE_OBJS) $(TEST_OBJS) -lgcc
	chmod -x $@

$(OBJ_PATH)/start_uq.o: $(ROOT)/firmware/start_uq.S
	$(TOOLCHAIN_PREFIX)gcc -c -mabi=ilp32 -march=rv32i$(subst C,c,$(COMPRESSED_ISA)) -o $@ $<

$(OBJ_PATH)/%.o: $(ROOT)/firmware/%.c
	$(TOOLCHAIN_PREFIX)gcc -c -mabi=ilp32 -march=rv32i$(subst C,c,$(COMPRESSED_ISA)) -Os --std=c99 $(GCC_WARNS) -ffreestanding -nostdlib -I $(INCLUDE_PATH) -o $@ $<

$(OBJ_PATH)/%.o: $(ROOT)/test/mcu/%.c
	$(TOOLCHAIN_PREFIX)gcc -c -mabi=ilp32 -march=rv32i$(subst C,c,$(COMPRESSED_ISA)) -Os --std=c99 $(GCC_WARNS) -ffreestanding -nostdlib -I $(INCLUDE_PATH) -o $@ $<


clean:
	rm -rf riscv-gnu-toolchain-riscv32i riscv-gnu-toolchain-riscv32ic \
		riscv-gnu-toolchain-riscv32im riscv-gnu-toolchain-riscv32imc
	rm -vrf $(OBJ_PATH)/*.o \
		firmware.elf flash.bin sram.bin flash.hex sram.hex firmware.map \
		testbench_mcu_uq.vvp testbench.vcd
