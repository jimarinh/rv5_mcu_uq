//MCU Uniquindio Project
//(c) 2024 Universidad del Quindio


#ifndef __MCU_UQ_1_0_
#define __MCU_UQ_1_0_

//I/O Register Definition

#include <stdint.h>

#define	GPIO_DIR	    (*(volatile uint16_t *)0x10)
#define	GPIO_DATA_OUT	(*(volatile uint16_t *)0x14)
#define	GPIO_DATA_IN	(*(volatile uint16_t *)0x18)
#define	GPIO_CTRL	    (*(volatile uint32_t *)0x1C)
#define	WATCHDOG	    (*(volatile uint32_t *)0x08)
#define	WATCHDOG_CTRL	(*(volatile uint32_t *)0x0C)
#define	TIMER_CNT0	    (*(volatile uint32_t *)0x20)
#define	TIMER_TOP0	    (*(volatile uint32_t *)0x24)
#define	PWM_CNTA0	    (*(volatile uint32_t *)0x28)
#define	PWM_CNTB0	    (*(volatile uint32_t *)0x2C)
#define	TIMER_CTRL0	    (*(volatile uint16_t *)0x30)
#define	TIMER_CNT1	    (*(volatile uint32_t *)0x40)
#define	TIMER_TOP1	    (*(volatile uint32_t *)0x44)
#define	PWM_CNTA1	    (*(volatile uint32_t *)0x48)
#define	PWM_CNTB1	    (*(volatile uint32_t *)0x4C)
#define	TIMER_CTRL1	    (*(volatile uint16_t *)0x50)
#define	UART_BITRATE	(*(volatile uint32_t *)0x60)
#define	UART_DATA_OUT	(*(volatile uint8_t *) 0x64)
#define	UART_DATA_IN	(*(volatile uint8_t *) 0x68)
#define	UART_CTRL	    (*(volatile uint16_t *)0x6C)
#define	I2C_BITRATE	    (*(volatile uint32_t *)0x70)
#define	I2C_DATA_OUT	(*(volatile uint8_t *) 0x74)
#define	I2C_DATA_IN	    (*(volatile uint8_t *) 0x78)
#define	I2C_CTRL	    (*(volatile uint8_t *) 0x7C)
#define	SPI_BITRATE	    (*(volatile uint32_t *)0x80)
#define	SPI_DATA_OUT	(*(volatile uint32_t *)0x84)
#define	SPI_DATA_IN	    (*(volatile uint32_t *)0x88)
#define	SPI_CTRL	    (*(volatile uint16_t *)0x8C)
#define	MAC_INA	        (*(volatile uint32_t *)0x90)
#define	MAC_INB	        (*(volatile uint32_t *)0x94)
#define	MAC_ACCL	    (*(volatile uint32_t *)0x98)
#define	MAC_ACCH	    (*(volatile uint8_t *) 0x9C)
#define	MAC_OUT	        (*(volatile uint16_t *)0xA0)
#define	MAC_CTRL	    (*(volatile uint8_t *) 0xA4)

//ISR Definition

#define	ISR_INT0	    3
#define	ISR_INT1	    4
#define	ISR_PINCHANGE	5
#define	ISR_TIMER0	    6
#define	ISR_TIMER1	    7
#define	ISR_I2C	        8
#define	ISR_SPI	        9
#define	ISR_RXD	        10
#define	ISR_TXD	        11
#define	ISR_MAC	        12

#endif