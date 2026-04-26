module MCU_UQ_SPIMEM(
	input clk,
	input ext_resetn,
	output trap,

	output mem_valid,
	output mem_instr,
	input mem_ready,
	output [31:0] mem_addr,
	output [31:0] mem_wdata,
	output [3:0]  mem_wstrb,
	input  [31:0] mem_rdata,
	
	input [31:0] irq,
	output [31:0] eoi
);

	parameter PROG_MEM_SIZE_WORDS = 32*1024; 	//Size of the program memory in words
	parameter PROG_MEM_BASE = 32'h3000_0000;	//Base address for the program memory
	parameter PROG_MEM_END = PROG_MEM_BASE+PROG_MEM_SIZE_WORDS*4-1;

	parameter DATA_MEM_SIZE_WORDS = 32*1024; 	//Size of the data memory in words
	parameter DATA_MEM_BASE = 32'h1000_0000;	//Base address for the program memory
	parameter DATA_MEM_END = DATA_MEM_BASE+DATA_MEM_SIZE_WORDS*4-1;

	parameter DEBUG_BASE = 32'h2000_0000;


	picorv32 #(
`ifdef COMPRESSED_ISA
		.COMPRESSED_ISA(0),
`endif
		.ENABLE_MUL(0),
		.ENABLE_DIV(0),
		.ENABLE_IRQ(1),
        .ENABLE_IRQ_QREGS (0),
		.ENABLE_TRACE(0),
		.PROGADDR_RESET(PROG_MEM_BASE),
		.PROGADDR_IRQ(PROG_MEM_BASE+32'h10)
	) RISCVCore (
		.clk         (clk        ),
		.resetn      (ext_resetn     ),
		.trap        (trap       ),
		.mem_valid   (mem_valid  ),
		.mem_instr   (mem_instr  ),
		.mem_ready   (mem_ready  ),
		.mem_addr    (mem_addr   ),
		.mem_wdata   (mem_wdata  ),
		.mem_wstrb   (mem_wstrb  ),
		.mem_rdata   (mem_rdata  ),
		.irq		 (irq		 ),
		.eoi		 (eoi		 )
	);



endmodule

