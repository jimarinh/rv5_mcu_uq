//--------------------------------------------------------
// I2C  Native Bus Interface
//--------------------------------------------------------

module I2C_Interface
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
    //Specific i2c signals
    inout  sda,
    output scl,
    output en_i2c,
    //Interrupt lines
    output irq_i2c
);

	//Internal I2C registers
	reg  [31:0] i2c_bitrate;
	reg  [7:0]  i2c_data_out;
	wire [7:0]  i2c_data_in;
    reg  [7:0]  i2c_ctrl;
	

	assign en_i2c = i2c_ctrl[7];

	//Module connection
	//
	//... PUT HERE YOUR CONNECTION WITH i2c MODULE
	assign scl = 1'b0;
	assign irq_i2c = 1'b0;
	assign i2c_data_in = 8'b0;

	//...


	//Native Memory Interface 
	always @(posedge clk) begin
		ready <= 0;

		if (!resetn) begin
			i2c_ctrl <= 8'b0; //Values on reset
		end else if (cs) begin
			ready <= 1;

			//Write
			case (addr[3:2])
                2'b00: 
					begin
						if (wstrb[0]) i2c_bitrate[ 7: 0] <= wr_data[ 7: 0];
						if (wstrb[1]) i2c_bitrate[15: 8] <= wr_data[15: 8];
                        if (wstrb[2]) i2c_bitrate[23:16] <= wr_data[23:16];
						if (wstrb[3]) i2c_bitrate[31:24] <= wr_data[31:24];
					end
                2'b01: 
					begin
						if (wstrb[0]) i2c_data_out[ 7: 0] <= wr_data[ 7: 0];
					end
                //2'b10: I2C_DATA_IN is read-only 
                2'b11: 
					begin
						if (wstrb[0]) i2c_ctrl[ 7: 0] <= wr_data[ 7: 0];
					end
			endcase

			//Read
			if (wstrb == 0) begin
				case (addr[3:2])
					2'b00: rd_data <= i2c_bitrate;
					2'b01: rd_data <= i2c_data_out;
					2'b10: rd_data <= i2c_data_in;
					2'b11: rd_data <= i2c_ctrl;
				endcase
			end
		end
	end


endmodule