// This is free and unencumbered software released into the public domain.
//
// Anyone is free to copy, modify, publish, use, compile, sell, or
// distribute this software, either in source code form or as a compiled
// binary, for any purpose, commercial or non-commercial, and by any
// means.

//Simplified version of start.S:
// - QREGS are disabled (Not part of ABI standard)
// - FASTIRQ: In the interrupt handler, save all registers except those saved by
//            the RISC-V ABI (x8-x9 (s0-s1), x18-x27(s2-s11)) 

#include "custom_ops.S"

	.section .text
	.global irq
	.global test
	
reset_vec:
	// no more than 16 bytes here !
	//picorv32_waitirq_insn(zero)
	picorv32_maskirq_insn(zero, zero)
	j start


/* Interrupt handler
 **********************************/

.balign 16
irq_vec:
	/* save registers */
	addi sp, sp, -4
	sw s0, 0(sp)
	lui s0, %hi(irq_regs)
	addi s0, s0, %lo(irq_regs)
	sw gp,   0*4(s0)
	sw x1,   1*4(s0)
	sw x2,   2*4(s0)
	sw x5,   5*4(s0)
	sw x6,   6*4(s0)
	sw x7,   7*4(s0)
	sw x10, 10*4(s0)
	sw x11, 11*4(s0)
	sw x12, 12*4(s0)
	sw x13, 13*4(s0)
	sw x14, 14*4(s0)
	sw x15, 15*4(s0)
	sw x16, 16*4(s0)
	sw x17, 17*4(s0)
	sw x28, 28*4(s0)
	sw x29, 29*4(s0)
	sw x30, 30*4(s0)
	sw x31, 31*4(s0)

	/* call interrupt handler C function */

	lui sp, %hi(irq_stack)
	addi sp, sp, %lo(irq_stack)

	// arg0 = address of regs
	lui a0, %hi(irq_regs)
	addi a0, a0, %lo(irq_regs)

	// arg1 = interrupt type
	or a1, tp, zero

	// call to C function
	jal ra, irq

	/* restore registers */
	lui s0, %hi(irq_regs)
	addi s0, s0, %lo(irq_regs)

	lw gp,   0*4(s0)
	lw x1,   1*4(s0)
	lw x2,   2*4(s0)
	lw x5,   5*4(s0)
	lw x6,   6*4(s0)
	lw x7,   7*4(s0)
	lw x10, 10*4(s0)
	lw x11, 11*4(s0)
	lw x12, 12*4(s0)
	lw x13, 13*4(s0)
	lw x14, 14*4(s0)
	lw x15, 15*4(s0)
	lw x16, 16*4(s0)
	lw x17, 17*4(s0)
	lw x28, 28*4(s0)
	lw x29, 29*4(s0)
	lw x30, 30*4(s0)
	lw x31, 31*4(s0)

	lw   s0, 0(sp)
	addi sp, sp, 4

	picorv32_retirq_insn()


/* Main program
 **********************************/

start:
	
	/* set stack pointer */
	lui sp,(0x10000000+128*1024)>>12

	/* call main C code */
	jal ra,test

	/* set stack pointer */
	lui sp,(0x10000000+128*1024)>>12

	/* set gp and tp */
	lui gp, %hi(0xdeadbeef)
	addi gp, gp, %lo(0xdeadbeef)
	addi tp, gp, 0

	/* print "DONE\n" */
	lui a0,0x20000000>>12
	addi a1,zero,'D'
	addi a2,zero,'O'
	addi a3,zero,'N'
	addi a4,zero,'E'
	addi a5,zero,'\n'
	sw a1,0(a0)
	sw a2,0(a0)
	sw a3,0(a0)
	sw a4,0(a0)
	sw a5,0(a0)

	/* trap */
	ebreak



	.section .data
irq_regs:
	// registers are saved to this memory region during interrupt handling
	// the program counter is saved as register 0
	.fill 32,4

irq_stack_start:
	// stack for the interrupt handler
	.fill 128,4
irq_stack:
