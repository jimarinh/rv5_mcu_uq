
`timescale 1 ns / 1 ps

module testbench;

	reg clk = 1;
	reg ext_resetn = 0;
	wire trap;
    wire ready_debugging;
    wire [7:0] debugdata;
	wire [15:0] gpio_pins;

	always #5 clk = ~clk;

	initial begin
		if ($test$plusargs("vcd")) begin
			$dumpfile("testbench.vcd");
			$dumpvars(0, testbench);
		end
		repeat (2) @(posedge clk);
		ext_resetn <= 1;		
		repeat (8000) @(posedge clk);
		$finish;
	end

    MCU_UQ uut (
        .clk(clk),
        .ext_resetn(ext_resetn),
        .trap(trap),
		.gpio_pins(gpio_pins),
        .ready_debugging(ready_debugging),
        .debugdata(debugdata)
    );

	//Initialize program memory with an HEX file compiled with the toolchain.
    reg [1023:0] firmware_flash_file;
	initial begin
		firmware_flash_file = "firmware/flash.hex";
		$readmemh(firmware_flash_file, uut.prog_memory.mem);
	end

	//Initialize data memory with an HEX file compiled with the toolchain.
    reg [1023:0] firmware_sram_file;
	initial begin
		firmware_sram_file = "firmware/sram.hex";
		$readmemh(firmware_sram_file, uut.data_memory.mem);
	end

	//--------------------------------------------------------
	// Debugging interface
	//--------------------------------------------------------

	always @(posedge clk) begin
		if (ready_debugging) 
			$write("%c", debugdata);
	end

endmodule

