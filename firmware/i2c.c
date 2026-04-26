#include "firmware.h"
#include "mcu_uq.h"


//Bit specification for I2C_CTRL register
#define I2C_ON      7
#define I2C_START   6
#define I2C_STOP    5
#define I2C_WRITE   4
#define I2C_READ    3
#define I2C_ACK     2
#define I2C_I_MSK   1


void i2c_begin(int baudrate)
{
    I2C_BITRATE = I2C_BAUDRATE_TO_TICKS(baudrate);
    I2C_CTRL = (1<<I2C_ON);
}

void i2c_disable() {
    I2C_CTRL = 0;
}

int i2c_begin_transmission(unsigned char slave_addr, int rw_bit) {
    //Set START flag
    I2C_CTRL |= (1<<I2C_START);
    //Wait until I2C module sends the start condition
    while(I2C_CTRL & (1<<I2C_START));
    //Set data and WRITE flag to begin transmission
    I2C_DATA_OUT = (slave_addr<<1) | rw_bit;
    I2C_CTRL |= (1<<I2C_WRITE);
    //Wait until I2C module sends bits and receive ACK
    while(I2C_CTRL & (1<<I2C_WRITE));
    //Return 1 if ACK is received (i.e., successful transmission)
    return (I2C_CTRL & (1<<I2C_ACK)) == 0; 
}

int i2c_write(char byte) {
     //Set data and WRITE flag to begin transmission
    I2C_DATA_OUT = byte;
    I2C_CTRL |= (1<<I2C_WRITE);
    //Wait until I2C module sends bits and receive ACK
    while(I2C_CTRL & (1<<I2C_WRITE));
    //Return 1 if ACK is received (i.e., successful transmission)
    return (I2C_CTRL & (1<<I2C_ACK)) == 0;
}

char i2c_read() {
    //Set READ flag to begin transmission
    I2C_CTRL |= (1<<I2C_READ);
    //Wait until I2C module sends bits and receive ACK
    while(I2C_CTRL & (1<<I2C_READ));
    //Return received byte
    return I2C_DATA_IN;
}

void i2c_end_transmission() {
    //Send stop condition to I2C module
    I2C_CTRL |= (1<<I2C_STOP);
    //Wait until I2C module stop transmission
    while(I2C_CTRL & (1<<I2C_STOP));
}
