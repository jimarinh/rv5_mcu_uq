# Unitary tests for the components of the MCU_UQ microcontroller 

To run all tests use:

    make

To run an specific test use:

    make gpio

This action synthetizes the Verilog files along the testbench using IcarusVerilog, and generates the VCD file for inspection in GtkWave.  

All VCD files are stored in the current folder.

Possible targets are:

* all - Run all tests
* gpio - Test GPIO interface with picoRV32 native memory interface
* uart - Test UART_interface with picoRV32 native memory interface
* uart_tx - Test standalone UART transmission module
* uart_rx - Test standalone UART reception module
* spi_sipo - Test standalone SPI SIPO
* spi_controller - Test SPI interface with picoRV32 native memory interface

Use:
    make clean

To remove all output files created during compilation
