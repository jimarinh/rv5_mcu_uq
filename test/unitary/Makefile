#Makefile for unitary tests of MCU-UQ components
# 
#	gpio:	  Test GPIO interface with picoRV32 native memory interface
# 	uart_tx:  Test standalone UART transmission module
#	uart_rx:  Test standalone UART reception module
#	uart:  	  Test UART_interface with picoRV32 native memory interface
#	spi_sipo: Test standalone SPI SIPO 
#	spi_controller: Test SPI interface with picoRV32 native memory interface
#
#*******************************************************

ROOT = ../..
ICARUS_SUFFIX =
IVERILOG = iverilog$(ICARUS_SUFFIX)
VVP = vvp$(ICARUS_SUFFIX)


VERILOG_GPIO = $(ROOT)/src/gpio/gpio_pin.v $(ROOT)/src/mcu/gpio.v gpio_tb.v

VERILOG_UART_TX = $(ROOT)/src/uart/uart_tx.v uart_tx_tb.v
VERILOG_UART_RX = $(ROOT)/src/uart/uart_rx.v uart_rx_tb.v
VERILOG_UART    = $(ROOT)/src/uart/uart_tx.v $(ROOT)/src/uart/uart_rx.v $(ROOT)/src/uart/uart_bitrate.v\
				  $(ROOT)/src/mcu/uart.v uart_tb.v

VERILOG_SPI_SIPO = $(ROOT)/src/spi/spi_sipo8.v spi_sipo8_tb.v
VERILOG_SPI_CTRL = $(ROOT)/src/spi/spi_sipo8.v $(ROOT)/src/spi/spi_controller.v spi_controller_tb.v


all: gpio uart uart_tx uart_rx spi_sipo spi_controller

gpio: gpio.vvp
	$(VVP) $<

gpio.vvp: $(VERILOG_GPIO)
	$(IVERILOG) -o $@ $^
	chmod -x $@

spi_controller: spi_controller.vvp
	$(VVP) $<

spi_controller.vvp: $(VERILOG_SPI_CTRL)
	$(IVERILOG) -o $@ $^
	chmod -x $@

spi_sipo: spi_sipo.vvp
	$(VVP) $<

spi_sipo.vvp: $(VERILOG_SPI_SIPO)
	$(IVERILOG) -o $@ $^
	chmod -x $@

uart: uart_tb.vvp
	$(VVP) $<

uart_tb.vvp: $(VERILOG_UART)
	$(IVERILOG) -o $@ $^
	chmod -x $@

uart_tx: uart_tx_tb.vvp
	$(VVP) $<

uart_tx_tb.vvp: $(VERILOG_UART_TX)
	$(IVERILOG) -o $@ $^
	chmod -x $@

uart_rx: uart_rx_tb.vvp
	$(VVP) $<

uart_rx_tb.vvp: $(VERILOG_UART_RX)
	$(IVERILOG) -o $@ $^
	chmod -x $@

clean:
	rm -vrf *.vcd
	rm -vrf *.vvp