#include "firmware.h"
#include "mcu_uq.h"


//Bit specification for SPI_CTRL register
#define SPI_ON          8
#define SPI_MODE        6
#define SPI_BIT_ORDER   5
#define SPI_DATA_LEN    3
#define SPI_FRAME_START 2
#define SPI_START       1
#define SPI_I_MSK       0


void spi_begin(int baudrate, int bitorder, int datalen, int mode)
{
    SPI_BITRATE = SPI_BAUDRATE_TO_TICKS(baudrate);

    int datalen_val;
    switch(datalen) {
        case 8: datalen_val = 0; break;
        case 16: datalen_val = 1; break;
        case 24: datalen_val = 2; break;
        case 32: datalen_val = 3; break;
        default: datalen_val = 0;
    }

    SPI_CTRL = (1<<SPI_ON) | (bitorder<<SPI_BIT_ORDER) | (datalen_val<<SPI_DATA_LEN) | (mode<<SPI_MODE);
}

void spi_disable() {
    SPI_CTRL = 0;
}

void spi_begin_transaction() {
    //Set FRAME_START flag
    SPI_CTRL |= (1<<SPI_FRAME_START);
}

uint32_t spi_transfer_word(uint32_t value) {
    //Write data
    SPI_DATA_OUT = value;
    //Set START flag to begin word transaction
    SPI_CTRL |= (1<<SPI_START);
    //Wait until SPI module sends and receives the word
    while(SPI_CTRL & (1<<SPI_START));
    //Returns received word
    return SPI_DATA_IN; 
}

void spi_end_transaction() {
    //Clears FRAM_START flag to finish transmission
    SPI_CTRL &= ~(1<<SPI_FRAME_START);
}
