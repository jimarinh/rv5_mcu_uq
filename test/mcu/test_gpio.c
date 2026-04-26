#include <firmware.h>

void test() {
	print_str("GPIO Test\n");
	pinMode(0, INPUT); //GPIO0 & GPI1 as input. GPIO3 pin as output	
	pinMode(1, INPUT);
	pinMode(3, OUTPUT);
	print_str("Writting LOW at pin 3\n");
	digitalWrite(3, LOW);
	print_str("Writting HIGH at pin 3\n");
	digitalWrite(3, HIGH);
	print_str("Reading pin 0\n");
	int val = digitalRead(0);
	print_dec(val);
	print_chr('\n');
}