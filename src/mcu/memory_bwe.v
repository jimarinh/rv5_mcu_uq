//--------------------------------------------------------
// PicoRV32 Native Bus Memory 
// Implemented using 4 separate BRAMs (one per byte lane)
//--------------------------------------------------------

module memory_bwe #(parameter MEM_WORDS = 1024)
(
    input  wire clk,
    input  wire cs,
    input  wire [3:0] wstrb,
    input  wire [31:0] wr_data,
    input  wire [$clog2(MEM_WORDS)-1:0] addr,
    output reg  [31:0] rd_data,
    output reg  ready
);

    // ----------------------------------------------------
    // Four 8-bit memories (BRAM inference)
    // ----------------------------------------------------
    (* ram_style = "block" *) reg [7:0] mem0 [0:MEM_WORDS-1]; // byte 0 (LSB)
    (* ram_style = "block" *) reg [7:0] mem1 [0:MEM_WORDS-1]; // byte 1
    (* ram_style = "block" *) reg [7:0] mem2 [0:MEM_WORDS-1]; // byte 2
    (* ram_style = "block" *) reg [7:0] mem3 [0:MEM_WORDS-1]; // byte 3 (MSB)

    // ----------------------------------------------------
    // Synchronous read + write 
    // 1-cycle read latency (same as original)
    // ----------------------------------------------------
    always @(posedge clk) begin
        ready <= cs;

        if (cs) begin
            // ----------------------
            // WRITE with byte enables
            // ----------------------
            if (wstrb[0]) mem0[addr] <= wr_data[7:0];
            if (wstrb[1]) mem1[addr] <= wr_data[15:8];
            if (wstrb[2]) mem2[addr] <= wr_data[23:16];
            if (wstrb[3]) mem3[addr] <= wr_data[31:24];

            // ----------------------
            // READ (sync)
            // ----------------------
            rd_data <= { mem3[addr], mem2[addr], mem1[addr], mem0[addr] };
        end
    end

endmodule
