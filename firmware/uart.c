#include "firmware.h"
#include "mcu_uq.h"

//Bit specification for UART_CTRL register 
#define UART_ON         9
#define UART_BITS       8
#define UART_PARITY     6
#define UART_STOPBITS   5
#define UART_WRITE      4
#define UART_AVAIL      3
#define UART_PARITY_ERR 2
#define UART_I_MSK      0
#define UART_I_RX_MSK   0
#define UART_I_TX_MSK   1


void uart_begin(int baudrate, int nbits, int stopbits, int parity)
{
    UART_BITRATE = UART_BAUDRATE_TO_TICKS(baudrate);
    UART_CTRL = (1<<UART_ON) | ((nbits==8)<<UART_BITS) | (parity<<UART_PARITY) | (stopbits<<UART_STOPBITS);
}

void uart_disable() {
    UART_CTRL &= ~(1<<UART_ON); //Clear ON bit in control register
}

int uart_is_available() {
    return (UART_CTRL & (1<<UART_AVAIL)) != 0;  //Check avail flag in control register
}

int uart_is_parity_error() {
    return (UART_CTRL & (1<<UART_PARITY_ERR)) != 0; //Check parity error flag in register 
}

char uart_read() {
    return UART_DATA_IN;
}

void uart_write(char ch) {
    UART_DATA_OUT = ch;
    UART_CTRL |= (1<<UART_WRITE);   //Set bit to start transmission
}

int uart_is_write_finish() {
    return (UART_CTRL & (1<<UART_WRITE)) == 0;  //Check write flag in control register
}

void uart_write_buffer(const char* p, int len) {
    for(int i=0; i<len; i++) {
        uart_write(p[i]);
        while(!uart_is_write_finish());
    } 
}

void uart_set_tx_int() {
    UART_CTRL |= (1<<UART_I_TX_MSK);
}

void uart_set_rx_int() {
    UART_CTRL |= (1<<UART_I_RX_MSK); 
}

void uart_clear_ints() {
    UART_CTRL &= ~(0b11<<UART_I_MSK);
}
