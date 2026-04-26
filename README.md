# RISC-V based Microcontroller Unit (MCU-UQ)

_Jorge I. Marin-Hurtado, Alexander Vera-Tasama, Alexander Lopez-Parrado, L.M. Capacho-Valbuena_

_Universidad del Quindio, Colombia_

This repository describes a RISC-V-based microcontroller and its firmware. The proposed architecture is based on the PicoRV32 core (RV32I) extended with the following peripherals:

* 1 UART with programmable baudrate and frame settings: 7 or 8 bits, parity (disabled, even, or), 1 or 2 stop bits.
* 1 fullduplex master SPI with programmable clock rate and frame settings (4 modes, 8, 16, 24 or 32 bits, MSB or LSB first).  
* 1 master I2C for 7 bit addresses. 
* 2 32-bit timers supporting internal or clock, and generation of PWM signals.
* 1 16-bit dual MAC unit. 

For microcontroller specification see ``docs`` folder.

Firmware and bootloader are also included. Firmware provides bare-metal routines that make easy to write drivers for environments such as Arduino IDE.

This microcontroller has been tested on a Xilinx Arty 7000 FPGA board and synthesized on Skywater 130nm technology using OpenLane.

For unitary and firmware test see Readme files into ``test`` folder.
