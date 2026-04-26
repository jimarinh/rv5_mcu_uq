//--------------------------------------------------------
// Generic TIMER  Native Bus Interface
//--------------------------------------------------------

module TIMER_Interface
(
	input clk,              // Clock signal
	input resetn,		    // Reset
    input cs,               // Chip select
    //Memory interface
    input [3:0] wstrb,      // Write/read enable
    input [31:0] wr_data,   // Data input
    output reg [31:0] rd_data,   // Data output
    input [7:0] addr, 		// Low-address input
    output reg ready,		// Ready
    //Specific timer signals
    input  tmr_in,
    output pwm_outa,
    output pwm_outb,
    output en_tmr_in,
    output en_pwm_outa,
    output en_pwm_outb,
    //Interrupt lines
    output irq_timer
);

	//Internal TIMER registers
	reg  [31:0] timer_cnt;
	reg  [31:0] timer_top;
	reg  [31:0] pwm_cnta;
	reg  [31:0] pwm_cntb;
    reg  [9:0]  timer_ctrl;

	//Module connection
	//
	//... PUT HERE YOUR CONNECTION WITH TIMER MODULE
	//
	assign pwm_outa = 1'b0;
	assign pwm_outb = 1'b0;
	assign irq_timer = 1'b0;
	//...


    assign en_tmr_in = 1'b0;		///CHANGE THIS ASSIGNMENT!!!
    assign en_pwm_outa = 1'b0;
    assign en_pwm_outb = 1'b0;



	//Native Memory Interface 
	always @(posedge clk) begin
		ready <= 0;

		if (!resetn) begin //Values on reset
			timer_ctrl <= 10'b0;
		end else if (cs) begin
			ready <= 1;

			//Write
			case (addr[4:2])
                3'b000: 
					begin
						if (wstrb[0]) timer_cnt[ 7: 0] <= wr_data[ 7: 0];
						if (wstrb[1]) timer_cnt[15: 8] <= wr_data[15: 8];
                        if (wstrb[2]) timer_cnt[23:16] <= wr_data[23:16];
						if (wstrb[3]) timer_cnt[31:24] <= wr_data[31:24];
					end
                3'b001: 
					begin
						if (wstrb[0]) timer_top[ 7: 0] <= wr_data[ 7: 0];
						if (wstrb[1]) timer_top[15: 8] <= wr_data[15: 8];
                        if (wstrb[2]) timer_top[23:16] <= wr_data[23:16];
						if (wstrb[3]) timer_top[31:24] <= wr_data[31:24];
					end
                3'b010: 
					begin
						if (wstrb[0]) pwm_cnta[ 7: 0] <= wr_data[ 7: 0];
						if (wstrb[1]) pwm_cnta[15: 8] <= wr_data[15: 8];
                        if (wstrb[2]) pwm_cnta[23:16] <= wr_data[23:16];
						if (wstrb[3]) pwm_cnta[31:24] <= wr_data[31:24];
					end
                3'b011: 
					begin
						if (wstrb[0]) pwm_cntb[ 7: 0] <= wr_data[ 7: 0];
						if (wstrb[1]) pwm_cntb[15: 8] <= wr_data[15: 8];
                        if (wstrb[2]) pwm_cntb[23:16] <= wr_data[23:16];
						if (wstrb[3]) pwm_cntb[31:24] <= wr_data[31:24];
					end
                3'b100: 
					begin
						if (wstrb[0]) timer_ctrl[ 7: 0] <= wr_data[ 7: 0];
						if (wstrb[1]) timer_ctrl[ 9: 8] <= wr_data[ 9: 8];
					end
			endcase

			//Read
			if (wstrb == 0) begin
				case (addr[4:2])
					3'b000: rd_data <= timer_cnt;
					3'b001: rd_data <= timer_top;
					3'b010: rd_data <= pwm_cnta;
					3'b011: rd_data <= pwm_cntb;
                    3'b100: rd_data <= timer_ctrl;
				endcase
			end
		end
	end
	
endmodule