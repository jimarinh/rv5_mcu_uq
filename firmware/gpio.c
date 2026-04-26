#include "firmware.h"
#include "mcu_uq.h"
#include "custom_ops.S"

void pinMode(int pinNumber, int direction) {
	if ((direction==INPUT) || (direction==INPUT_PULLUP)) {
		GPIO_DIR = GPIO_DIR & (~(1<<pinNumber));
	} 
	if (direction==OUTPUT) {
		GPIO_DIR = GPIO_DIR | (1<<pinNumber);
	}
}

void digitalWrite(int pinNumber, int value) {
	GPIO_DATA_OUT = (GPIO_DATA_OUT & (~(1<<pinNumber))) | ((value&1)<<pinNumber);
}

int digitalRead(int pinNumber) {
	return (GPIO_DATA_IN & (1<<pinNumber)) != 0;
}

void attachInterrupt(int pinNumber, void (*_isr)(), int type) {
	if (pinNumber==14) {
		setInterruptHandler(ISR_INT0, _isr);
		GPIO_CTRL = (GPIO_CTRL & 0x3FFFFFFF) | (type<<30);
	}
	if (pinNumber==15) {
		setInterruptHandler(ISR_INT1, _isr);
		GPIO_CTRL = (GPIO_CTRL & 0xCFFFFFFF) | (type<<28);
	}
}

void attachPinChangeInterrupt(int pinMask, void (*_isr)()) {
	setInterruptHandler(ISR_PINCHANGE, _isr);
	GPIO_CTRL = (GPIO_CTRL & 0xFFFF0000) | pinMask;
}