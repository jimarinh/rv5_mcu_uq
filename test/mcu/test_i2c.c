#include <firmware.h>


void test() {
	char cad[5];

    print_str("I2C Test\n");
	
    i2c_begin(100000);  // Initialize I2C as master at 100kHz 
    
    print_str("Sending Hello\n");

    i2c_begin_transmission(8, I2C_WRITE_OP); // Start writing on slave device #8
    i2c_write('H'); // Send data
    i2c_write('E'); 
    i2c_write('L'); 
    i2c_write('L'); 
    i2c_write('O'); 
    i2c_end_transmission();

    print_str("Receiving...\n");
    i2c_begin_transmission(8, I2C_READ_OP); // Start reading on slave device #8
    cad[0] = i2c_read();  // Read characters
    cad[1] = i2c_read(); 
    cad[2] = '\n';
    cad[3] = 0;
    i2c_end_transmission();

    print_str("Received:\n");
    print_str(cad);
}