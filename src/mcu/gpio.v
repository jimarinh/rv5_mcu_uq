//--------------------------------------------------------
// GPIO Native Bus Interface
//--------------------------------------------------------

module GPIO_Interface
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
	//External GPIO pins
	inout [15:0] gpio_pins,
	//Special GPIO output signals
	input PWM_OUTA0, PWM_OUTB0,
	input PWM_OUTA1, PWM_OUTB1,
	input SPI_SCLK, SPI_MOSI, SPI_SS,
	input I2C_SCL,
	input UART_TXD,
	//Special GPIO enablers
	input en_tmr_in0,
    input en_pwm_outa0,
    input en_pwm_outb0,
	input en_tmr_in1,
    input en_pwm_outa1,
    input en_pwm_outb1,
	input en_i2c,
	input en_spi,
	input en_uart,
	 //Interrupt lines
    output reg irq_int0,
	output reg irq_int1,
	output reg irq_pinchange		
);

	//Internal GPIO registers
	reg  [15:0] gpio_dir;
	reg  [15:0] gpio_data_out;
	wire [15:0] gpio_data_in;
	reg  [31:0] gpio_ctrl;

    //Connection to GPIO pins
    //////////////////////////////////

	wire [15:0] special_out;
	wire [15:0] special_out_en;
	wire [15:0] dir_internal;
    wire [15:0] rise_det;
    wire [15:0] fall_det;

	assign special_out = {1'bx, 1'bx, 			//External interrupts
			1'bx, PWM_OUTA1, PWM_OUTB1,			//TIMER 1
			1'bx, PWM_OUTA0, PWM_OUTB0,			//TIMER 0
			SPI_SCLK, 1'bx, SPI_MOSI, SPI_SS,	//SPI
			I2C_SCL,  1'bx,						//I2C
			UART_TXD, 1'bx						//UART
			};

	assign special_out_en = {1'b0, 1'b0, 		//External interrupts
			1'b0, en_pwm_outa1, en_pwm_outb1,	//TIMER 1
			1'b0, en_pwm_outa0, en_pwm_outb0,	//TIMER 0
			en_spi, 1'b0, en_spi, en_spi,		//SPI
			en_i2c, 1'b0,						//I2C
			en_uart, 1'b0						//UART
			};

	assign dir_internal = {
		gpio_dir[15],
		gpio_dir[14],
		en_tmr_in1 	 ? 1'b0 : gpio_dir[13],
		en_pwm_outa1 ? 1'b1 : gpio_dir[12],
		en_pwm_outb1 ? 1'b1 : gpio_dir[11],
		en_tmr_in0 	 ? 1'b0 : gpio_dir[10],
		en_pwm_outa0 ? 1'b1 : gpio_dir[9],
		en_pwm_outb0 ? 1'b1 : gpio_dir[8],
		en_spi ? 1'b1 : gpio_dir[7],
		en_spi ? 1'b0 : gpio_dir[6],
		en_spi ? 1'b1 : gpio_dir[5],
		en_spi ? 1'b1 : gpio_dir[4],
		en_i2c ? 1'b1 : gpio_dir[3],
		en_i2c ? 1'b0 : gpio_dir[2],
		en_uart ? 1'b1 : gpio_dir[1],
		en_uart ? 1'b0 : gpio_dir[0]
	};
	
	genvar i;
	generate
		for (i = 0; i<16; i = i + 1) begin: GPIO_PINS
			gpio_pin GPIO_PINx (
				.clk(clk),
				.resetn(resetn),
				.gpio_in(gpio_data_out[i]),
				.dir_in(dir_internal[i]),
				.special_data(special_out[i]),
				.special_en(special_out_en[i]),
				.gpio_pin(gpio_pins[i]),
				.gpio_out(gpio_data_in[i]),
				.rise_det(rise_det[i]),
				.fall_det(fall_det[i])
			);
		end
	endgenerate


	//Native Memory Interface
    //////////////////////////////////

	always @(posedge clk) begin
	   	ready<=1'b0;
		if (resetn==1'b0) begin
			gpio_dir <= 16'b0;
			gpio_data_out <= 16'h0; 
			gpio_ctrl <= 32'b0;
			ready<=1'b0;
		end else if (cs) begin
			ready <= 1'b1;

			//Write
			case (addr[3:2])
                2'b00: 
					begin
						if (wstrb[0]) gpio_dir[ 7: 0] <= wr_data[ 7: 0];
						if (wstrb[1]) gpio_dir[15: 8] <= wr_data[15: 8];
					end
                2'b01: 
					begin
						if (wstrb[0]) gpio_data_out[ 7: 0] <= wr_data[ 7: 0];
						if (wstrb[1]) gpio_data_out[15: 8] <= wr_data[15: 8];
					end
                //2'b10: GPIO_DATA_IN is a read-only register (Writing is not allowed) 
                2'b11: 
					begin
						if (wstrb[0]) gpio_ctrl[ 7: 0] <= wr_data[ 7: 0];
						if (wstrb[1]) gpio_ctrl[15: 8] <= wr_data[15: 8];
						if (wstrb[2]) gpio_ctrl[23:16] <= wr_data[23:16];
						if (wstrb[3]) gpio_ctrl[31:24] <= wr_data[31:24];
					end
			endcase

			//Read
			if (wstrb == 0) begin
				case (addr[3:2])
					2'b00: rd_data <= gpio_dir;
					2'b01: rd_data <= gpio_data_out;
					2'b10: rd_data <= gpio_data_in;
					2'b11: rd_data <= gpio_ctrl;
				endcase
			end
		end
	end


	//Interrupts 
    //////////////////////////////////

//  assign irq_int0 = (gpio_ctrl[31] & fall_det[14]) | (gpio_ctrl[30] & rise_det[14]);
//	assign irq_int1 = (gpio_ctrl[29] & fall_det[15]) | (gpio_ctrl[28] & rise_det[15]);
//	assign irq_pinchange = |((fall_det | rise_det) & gpio_ctrl);

	always @(posedge clk) begin
		if (resetn==1'b0) begin
			irq_int0 <= 1'b0;
			irq_int1 <= 1'b0;
			irq_pinchange <= 1'b0;
		end else begin
			irq_int0 <= (gpio_ctrl[31] & fall_det[14]) | (gpio_ctrl[30] & rise_det[14]);
			irq_int1 <= (gpio_ctrl[29] & fall_det[15]) | (gpio_ctrl[28] & rise_det[15]);
			irq_pinchange <= |((fall_det | rise_det) & gpio_ctrl);
		end
	end


endmodule