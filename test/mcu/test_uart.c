#include <firmware.h>

void test() {
	print_str("UART Test\n");
	//uart_begin(9600, 8, 1, UART_PARITY_NONE);
    uart_begin(8333333, 8, 1, UART_PARITY_NONE);    //Para prueba en simulación

    print_str("Sending Hello World...\n");
    uart_write_buffer("Hello world!", 12);

    print_str("Receiving...\n");
    while(1) {
        if (uart_is_available() > 0) {  // Check if data is available
            char received = uart_read();  // Read the received character
            print_str("Received:");
            print_chr(received);
            print_chr('\n');  
            uart_write(received+2); // Encrypt the received character 
        }
    }
}