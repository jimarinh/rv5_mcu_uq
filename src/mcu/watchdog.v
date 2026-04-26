//--------------------------------------------------------
// Watchdog timer
//--------------------------------------------------------

module watchdog_timer
(
	input clk,              // Clock signal
	input resetn_in,		// Input reset
    input cs,               // Chip select
    input [3:0] wstrb,      // Write/read enable
    input [31:0] wr_data,   // Data input
    output [31:0] rd_data,   // Data output
    input [7:0] addr, 		// Low-address input
    output ready,		// Ready
	output resetn_out		// Output reset
);

	reg [31:0] watchdog_ctrl;	// Watchdog control (0x14)
	reg [30:0] watchdog_cnt;	// Watchdog counter (0x10)
	wire watchdog_en;			// Watchdog enable bit
    reg asynch_reset;
	reg ready_wd;

	assign ready = ready_wd;

	//State machine for watchdog
	always @(posedge clk) begin
        if (!resetn_in)
            watchdog_cnt  <= 32'b0;
        else if (asynch_reset)
            watchdog_cnt  <= 32'b0;
        else if (watchdog_en) 
            watchdog_cnt <= watchdog_cnt+1;
	end

	assign watchdog_en = watchdog_ctrl[31];
	assign resetn_out = watchdog_en & (watchdog_cnt[30:0] == watchdog_ctrl[30:0]); 

	//Native Memory Interface 
	always @(posedge clk) begin
		if (!resetn_in) begin //Set initial values on reset
			watchdog_ctrl <= 32'b0;
			ready_wd <= 0;
			asynch_reset <= 1'b0;
		end else if (cs) begin
			ready_wd <= 1;
				//Write
				case (addr[2])
					1'b0: 
						begin   //Writing any value to WATCHDOG produces a reset in the watchdog timer
							asynch_reset <= 1'b1;
						end
					1'b1: 
						begin
							if (wstrb[0]) watchdog_ctrl[ 7: 0] <= wr_data[ 7: 0];
							if (wstrb[1]) watchdog_ctrl[15: 8] <= wr_data[15: 8];
							if (wstrb[2]) watchdog_ctrl[23:16] <= wr_data[23:16];
							if (wstrb[3]) watchdog_ctrl[31:24] <= wr_data[31:24];
							asynch_reset <= 1'b1;
						end
				endcase
			end else begin 
				ready_wd <= 0;
				asynch_reset <= 1'b0;
			end
	end

	assign rd_data = watchdog_ctrl;	//Always return watchdog_ctrl on a Read cycle

endmodule