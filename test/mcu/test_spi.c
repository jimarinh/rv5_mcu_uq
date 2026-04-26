#include <firmware.h>

void test() {
	char cad[6];

    print_str("SPI Test\n");
	
    // Initialize SPI as master at 8.333MHz, 8bits, MSB first and Mode 0
    spi_begin(8333333, MSBFIRST, 8, SPI_MODE3);  
    
    print_str("Sending and receiving simultaneously\n");

    spi_begin_transaction(); // Start frame
    cad[0] = spi_transfer_word('H'); // Send data
    cad[1] = spi_transfer_word('E'); 
    cad[2] = spi_transfer_word('L'); 
    cad[3] = spi_transfer_word('L'); 
    cad[4] = spi_transfer_word('O'); 
    spi_end_transaction();

    print_str("Received:\n");
    cad[5] = 0;
    print_str(cad);
}