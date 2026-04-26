
//--------------------------------------------------------
// Generic memory for the PicoRV32 native bus 
//--------------------------------------------------------

module memory_nobwe #(parameter MEM_WORDS = 1024,parameter MEM_INIT_FILE = "")    // Data width (bits per word)
(
    input clk,              // Clock signal
    input cs,               // Chip select   
    input [$clog2(MEM_WORDS)-1:0] addr, // Address input
    output reg [31:0] rd_data,  // Data output
    output reg ready
);
    (* ram_style="block" *)
    reg [31:0] mem [0:MEM_WORDS-1];


    // optional initialization
    initial begin
        if (MEM_INIT_FILE != "")
            $readmemh(MEM_INIT_FILE, mem);
    end

    always @(posedge clk) begin
        
          rd_data <= mem[addr];

        ready <= cs;          
    end

endmodule
