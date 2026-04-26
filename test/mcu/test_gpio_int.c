#include <firmware.h>


void isr_INT0() {
    digitalWrite(3, HIGH);
    print_str("INT0\n");
}

void isr_INT1() {
    digitalWrite(4, HIGH);
    print_str("INT1\n");
}

void isr_PINCHANGE() {
    digitalWrite(3, LOW);
    digitalWrite(4, LOW);
    print_str("PINCHANGE\n");
}

void test() {
    resetInterruptHandlers();

	print_str("GPIO INT0 INT1 Test\n");
	pinMode(0, INPUT); //GPIO0 & GPI10 as input. GPIO3 & GPIO4 as output
	pinMode(10, INPUT);
	pinMode(3, OUTPUT);
    pinMode(4, OUTPUT);
    pinMode(14, INPUT);     //INT0 as input
    pinMode(15, INPUT);     //INT1 as input
    digitalWrite(3, LOW);
    digitalWrite(4, LOW);

    print_str("Enable interrupts\n");

    attachInterrupt(14, isr_INT0, RISING);
    attachInterrupt(15, isr_INT1, FALLING);
    attachPinChangeInterrupt(0x0400, isr_PINCHANGE);
    print_str("Wait for interrupts\n");
    while(1) {
        print_chr('A');
    };
}
