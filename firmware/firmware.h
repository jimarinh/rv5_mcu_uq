#ifndef FIRMWARE_H
#define FIRMWARE_H

#include <stdint.h>
#include <stdbool.h>

//Interrupt Handlers
// irq.c
////////////////////////
uint32_t *irq(uint32_t *regs, uint32_t irqs);
void resetInterruptHandlers();
void setInterruptHandler(int intType, void (*_isr)());  //intType takes any of the ISR_xxx values stated in mcu_uq.h

// print.c
void print_chr(char ch);
void print_str(const char *p);
void print_dec(unsigned int val);
void print_hex(unsigned int val, int digits);


// Basic Arduino and Bare Metal functions
//---------------------------------------------------

//Assumes 100MHz CPU Clock

//Macro to convert time in ms to CPU ticks
//WARNING: Replace this macro by the real equation!
#define TIME_MS_TO_TICK(time)  (time)

//Macro to convert time in us to CPU ticks
//WARNING: Replace this macro by the real equation!
#define TIME_US_TO_TICK(time)  (time)


//GPIO
////////////////////////
#define LOW     0
#define HIGH    1
#define INPUT   0
#define OUTPUT  1
#define INPUT_PULLUP 2	//Pullup not implemented

void    pinMode(int pinNumber, int direction);
void    digitalWrite(int pinNumber, int value);
int     digitalRead(int pinNumber);

#define DISABLE 0
#define RISING  1
#define FALLING 2
#define CHANGE  3

void    attachInterrupt(int pinNumber, void (*_isr)(), int type);
void    attachPinChangeInterrupt(int pinMask, void (*_isr)());

//Watchdog
////////////////////////
void    wdt_enable(uint32_t time_ms);
void    wdt_disable();
void    wdt_reset();


//TIMERS
////////////////////////
#define FAST_PWM            1
#define PHASE_CORRECT_PWM   2

//Set the timer period in microseconds (Use internal CPU clock)
void timer_initialize(int timer_id, uint32_t useconds);
//Set the timer to use external input signal (Set also top count)
void timer_initialize_extinput(int timer_id, uint32_t top_count);
//Start the timer in normal mode
void timer_start(int timer_id);
//Stop the timer
void timer_stop(int timer_id);
//Return current timer count
uint32_t timer_count(int timer_id);
//Generates PWM on a specified pin
void timer_pwm(int timer_id, int pin, int signal_shape, int dutyCycle);
//Disables PWM on a specified pin
void timer_disable_pwm(int timer_id, int pin);
//Delay in microseconds
void delay_us(int timer_id, uint32_t useconds);


//UART
////////////////////////
#define UART_BAUDRATE_TO_TICKS(baudrate) ((50000000/baudrate)-1)

#define UART_PARITY_NONE 0
#define UART_PARITY_EVEN 1
#define UART_PARITY_ODD  2

void uart_begin(int baudrate, int nbits, int stopbits, int parity);
void uart_disable();
int  uart_is_available();
int  uart_is_parity_error();
char uart_read();
void uart_write(char ch);
int  uart_is_write_finish();
void uart_write_buffer(const char* p, int len);
void uart_set_tx_int();
void uart_set_rx_int();
void uart_clear_ints();


//I2C
////////////////////////
//WARNING: Replace by the real equation
#define I2C_BAUDRATE_TO_TICKS(baudrate) (5)

//Values for the rw_bit parameter in i2c_begin_transmission
#define I2C_READ_OP  1
#define I2C_WRITE_OP 0

void i2c_begin(int baudrate);
void i2c_disable();
int  i2c_begin_transmission(unsigned char slave_addr, int rw_bit);
int  i2c_write(char byte);
char i2c_read();
void i2c_end_transmission();


//SPI
////////////////////////
#define SPI_BAUDRATE_TO_TICKS(baudrate) ((50000000/baudrate)-1)

#define SPI_MODE0   0
#define SPI_MODE1   1
#define SPI_MODE2   2
#define SPI_MODE3   3

#define LSBFIRST    0
#define MSBFIRST    1

void     spi_begin(int baudrate, int bitorder, int datalen, int mode);
void     spi_disable();
void     spi_begin_transaction();
uint32_t spi_transfer_word(uint32_t value);
void     spi_end_transaction();

#endif
