//--------------------------------------------------------
// SPI  Native Bus Interface
//--------------------------------------------------------

module SPI_Interface
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
    //Specific SPI signals
    output mosi,
    input  miso,
    output sclk,
    output ss,
    output en_spi,
    //Interrupt lines
    output irq_spi
);

	//Internal SPI registers
	reg  [31:0] spi_bitrate;
	reg  [31:0] spi_data_out;
	wire [31:0] spi_data_in;
	
	//Control register
    reg SPI_ON;
    reg [1:0] SPI_MODE;
    reg SPI_BIT_ORDER;
    reg [1:0] SPI_DATA_LEN;
    reg SPI_FRAME_START;
    reg SPI_START;
    reg SPI_I_MASK;
    
    wire [9:0] spi_ctrl;
    assign spi_ctrl = {
        SPI_ON, SPI_MODE, SPI_BIT_ORDER, SPI_DATA_LEN,
        SPI_FRAME_START, SPI_START, SPI_I_MASK
    };

    //Contrl path
    wire done;
    reg  done_d;
    wire bus_wr     = cs && (wstrb != 4'b0000);
    wire bus_rd     = cs && (wstrb == 4'b0000);
    wire wr_ctrl    = bus_wr && (addr[3:2] == 2'b11);
    
    //Module connections
    assign en_spi = SPI_ON;
    assign irq_spi = SPI_I_MASK & done;
    assign ss = SPI_FRAME_START;

	//Set initial values on reset
	always @(posedge clk) begin
		//Values on reset
		if (!resetn) begin
			SPI_ON          <= 1'b0;
            SPI_MODE        <= 2'b00;      //Mode 0
            SPI_BIT_ORDER   <= 1'b0;  //LSB-First
            SPI_DATA_LEN    <= 2'b00;  //8-bit
            SPI_FRAME_START <= 1'b0;
            SPI_START       <= 1'b0;
            SPI_I_MASK      <= 1'b0;
		end else begin
            // Edge detector in done signal (to clear SPI_START bit)
            done_d <= done;

            //Write to the control register by native bus
            if (wr_ctrl) begin
                SPI_ON          <= wr_data[8];
                SPI_MODE        <= wr_data[7:6];
                SPI_BIT_ORDER   <= wr_data[5];
                SPI_DATA_LEN    <= wr_data[4:3];
                SPI_FRAME_START <= wr_data[2];
                SPI_START       <= wr_data[1];
                SPI_I_MASK      <= wr_data[0];
            end

            //Clear START flag when transmission is done
            if (done & ~done_d) begin
                SPI_START <= 1'b0;
            end
        end
	end

    // -----------------------------
    // SPI Module
    // -----------------------------
    spi_controller dut (
        .clk(clk),
        .rstn(SPI_ON),
        .start(SPI_START),
        .SPI_MODE(SPI_MODE),
        .SPI_BIT_ORDER(SPI_BIT_ORDER),
        .SPI_DATA_LEN(SPI_DATA_LEN),
        .SPI_DATA_TX(spi_data_out),
        .SPI_BITRATE(spi_bitrate),
        .MISO(miso),
        .MOSI(mosi),
        .SPI_DATA_RX(spi_data_in),
        .SCK(sclk),
        .done(done)
    );

	//Native Memory Interface 
	always @(posedge clk) begin
		ready <= 0;
		if (cs) begin
			ready <= 1;
			//Write
            if (wstrb[0]!=4'b0000) begin
                case (addr[3:2])
                    2'b00: spi_bitrate <= wr_data;
                    2'b01: spi_data_out <= wr_data;
                    //2'b10: spi_data_in is read-only 
                    //2'b11: write is inside ctrl always 
                    default: ;
                endcase
            end 
            //Read
            else begin
				case (addr[3:2])
					2'b00: rd_data <= spi_bitrate;
					2'b01: rd_data <= spi_data_out;
					2'b10: rd_data <= spi_data_in;
					2'b11: rd_data <= {23'b0, spi_ctrl};
				endcase
			end
		end
	end

endmodule