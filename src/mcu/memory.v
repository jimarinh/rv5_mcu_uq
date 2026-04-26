
//--------------------------------------------------------
// Generic memory for the PicoRV32 native bus 
//--------------------------------------------------------

module memory #(parameter MEM_WORDS = 1024)    // Memory size in words
(
    input clk,              // Clock signal
    input cs,               // Chip select
    input [3:0] wstrb,      // Write/read enable
    input [31:0] wr_data,   // Data input
    input [$clog2(MEM_WORDS)-1:0] addr, // Address input
    output reg [31:0] rd_data,  // Data output
    output reg ready
);
    // Memory array
    reg [31:0] mem [0:MEM_WORDS-1];

    always @(posedge clk) begin
        ready <= 0;
        if (cs) 
            begin
                ready <= 1;
                // Write operation
                if (wstrb[0]) mem[addr >> 2][ 7: 0] <= wr_data[ 7: 0];
                if (wstrb[1]) mem[addr >> 2][15: 8] <= wr_data[15: 8];
                if (wstrb[2]) mem[addr >> 2][23:16] <= wr_data[23:16];
                if (wstrb[3]) mem[addr >> 2][31:24] <= wr_data[31:24];
                //Read operation
				if (wstrb == 0) begin
					rd_data <= mem[addr >> 2];
				end
            end
   end

endmodule