# Simulation of MCU_UQ firmware on IcarusVerilog

To run GPIO teste please use:
    make TARGET=test_gpio

This action compiles firmware & test_gpio.c files, generates the HEX file to program
the FLASH memory, runs IcarusVerilog simulation, and generates the VCD file for
inspection in GtkWave. 

Output files are in this folder except the .o files, which are stored at ROOT/obj.

Other tests included in this folder are:

* test_gpio       : GPIO
* test_uart       : UART
* test_timers     : Timer0
* test_spi        : SPI
* test_i2c        : I2C
* test_watchdog   : Watchdog

Use:
    make clean

To remove all output files created during compilation

