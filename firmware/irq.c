// This file is based on the original irq.c file provided by picoRV32 repository.
// It has been modified to include bare metal functions to interface the interrupts to the MCU_UQ specification.


#include "firmware.h"
#include "mcu_uq.h"


void (*_isr_pointers[16])();


uint32_t *irq(uint32_t *regs, uint32_t irqs)
{
	static unsigned int ext_irq_count = 0;
	static unsigned int timer_irq_count = 0;

	if ((irqs & (0b1111111111000)) != 0) {
		ext_irq_count++;
		//print_str("[EXT-IRQ-4]");
		int intType = ISR_INT0;
		int irqsx = irqs >> ISR_INT0;
		for(int intType=ISR_INT0; intType<=ISR_MAC; intType++) {
			if ( (irqsx & 1) && (_isr_pointers[intType]) ) _isr_pointers[intType]();
			irqsx >>= 1; 
		}
		return regs;
	}

	if ((irqs & 1) != 0) {
		timer_irq_count++;
		// print_str("[TIMER-IRQ]");
	}

	if ((irqs & 6) != 0)
	{
		uint32_t pc = (regs[0] & 1) ? regs[0] - 3 : regs[0] - 4;
		uint32_t instr = *(uint16_t*)pc;

		if ((instr & 3) == 3)
			instr = instr | (*(uint16_t*)(pc + 2)) << 16;

		print_str("\n");
		print_str("------------------------------------------------------------\n");

		if ((irqs & 2) != 0) {
			if (instr == 0x00100073 || instr == 0x9002) {
				print_str("EBREAK instruction at 0x");
				print_hex(pc, 8);
				print_str("\n");
			} else {
				print_str("Illegal Instruction at 0x");
				print_hex(pc, 8);
				print_str(": 0x");
				print_hex(instr, ((instr & 3) == 3) ? 8 : 4);
				print_str("\n");
			}
		}

		if ((irqs & 4) != 0) {
			print_str("Bus error in Instruction at 0x");
			print_hex(pc, 8);
			print_str(": 0x");
			print_hex(instr, ((instr & 3) == 3) ? 8 : 4);
			print_str("\n");
		}

		for (int i = 0; i < 8; i++)
		for (int k = 0; k < 4; k++)
		{
			int r = i + k*8;

			if (r == 0) {
				print_str("pc  ");
			} else
			if (r < 10) {
				print_chr('x');
				print_chr('0' + r);
				print_chr(' ');
				print_chr(' ');
			} else
			if (r < 20) {
				print_chr('x');
				print_chr('1');
				print_chr('0' + r - 10);
				print_chr(' ');
			} else
			if (r < 30) {
				print_chr('x');
				print_chr('2');
				print_chr('0' + r - 20);
				print_chr(' ');
			} else {
				print_chr('x');
				print_chr('3');
				print_chr('0' + r - 30);
				print_chr(' ');
			}

			print_hex(regs[r], 8);
			print_str(k == 3 ? "\n" : "    ");
		}

		print_str("------------------------------------------------------------\n");

		print_str("Number of external IRQs counted: ");
		print_dec(ext_irq_count);
		print_str("\n");

		print_str("Number of timer IRQs counted: ");
		print_dec(timer_irq_count);
		print_str("\n");

		__asm__ volatile ("ebreak");
	}
	return regs;
}

void resetInterruptHandlers() {
	for (int i=0; i<16; i++) {
		_isr_pointers[i] = 0;
	}
} 

void setInterruptHandler(int intType, void (*_isr)()) {
	_isr_pointers[intType] = _isr;
}

