//Programmable SPI controller
//Supports 8, 16, 24 or 32 bits transmission
//MSB first or LSB first
//Mode 0, 1, 2 and 3

module spi_controller(
	input clk,
	input rstn,
	input start,
    input [1:0] SPI_MODE,
	input SPI_BIT_ORDER,
    input [1:0] SPI_DATA_LEN,
    input [31:0] SPI_DATA_TX,
    input [31:0] SPI_BITRATE,
    
    input MISO,
    output reg MOSI,

    output [31:0] SPI_DATA_RX,
	output SCK,
	output done
);

	//Estados de la máquina
	localparam 	IDLE 	= 3'b000,
				LOAD 	= 3'b001,
				TRANSMIT= 3'b010,
				WAIT_FRAME_END=3'b011,
				DONE 	= 3'b100;
	
	//Señales para los estados y control interno 
	reg [2:0] state;
	wire [2:0] next;
	wire spi_rst;
	reg  spi_clk;
	wire spi_load;
	wire spi_frame;

    //Generador del reloj interno (divisor de frecuencia)
    //////////////////////////////////////////////

    reg [31:0] clk_count;

    always @(posedge clk)
	begin
	    if (spi_rst) begin
	        clk_count <= SPI_BITRATE;
            spi_clk  <= 0;
	    end else if (clk_count==32'b0) begin
            clk_count <= SPI_BITRATE;
            spi_clk  <= ~spi_clk;
        end else begin
            clk_count <= clk_count-1;
	    end
	end

    //Banco de registros de desplazamiento
    //////////////////////////////////////////////

    wire [31:0] data_rx;
    wire MOSI_MSB;
	wire MOSI_d;
    wire s_in_msb0;
    wire s_in_msb1;
    wire s_in_msb2;
    wire s_in_msb3;
    wire s_in_lsb1;
    wire s_in_lsb2;
    wire s_in_lsb3;	
	reg spi_frame_d;
    
    spi_sipo8 bank0(
		.clk(spi_clk),
		.load(spi_load),
		.data_tx(SPI_DATA_TX[7:0]),
		.serial_in_msb(s_in_msb0),
		.serial_in_lsb(MISO),
		.direction(SPI_BIT_ORDER),
		.data_rx(data_rx[7:0])
	);

    assign s_in_msb0 = (SPI_DATA_LEN == 2'b00) ? MISO : data_rx[8]; 
	assign s_in_lsb1 = (SPI_DATA_LEN == 2'b00) ? 1'b0 : data_rx[7];

    spi_sipo8 bank1(
		.clk(spi_clk),
		.load(spi_load),
		.data_tx(SPI_DATA_TX[15:8]),
		.serial_in_msb(s_in_msb1),
		.serial_in_lsb(s_in_lsb1),
		.direction(SPI_BIT_ORDER),
		.data_rx(data_rx[15:8])
	);

    assign s_in_msb1 = (SPI_DATA_LEN == 2'b01) ? MISO : data_rx[16]; 
	assign s_in_lsb2 = (SPI_DATA_LEN == 2'b01) ? 1'b0 : data_rx[15];

    spi_sipo8 bank2(
		.clk(spi_clk),
		.load(spi_load),
		.data_tx(SPI_DATA_TX[23:16]),
		.serial_in_msb(s_in_msb2),
		.serial_in_lsb(s_in_lsb2),
		.direction(SPI_BIT_ORDER),
		.data_rx(data_rx[23:16])
	);

    assign s_in_msb2 = (SPI_DATA_LEN == 2'b10) ? MISO : data_rx[24]; 
	assign s_in_lsb3 = (SPI_DATA_LEN == 2'b10) ? 1'b0 : data_rx[23];
    
	spi_sipo8 bank3(
		.clk(spi_clk),
		.load(spi_load),
		.data_tx(SPI_DATA_TX[31:24]),
		.serial_in_msb(s_in_msb3),
		.serial_in_lsb(s_in_lsb3),
		.direction(SPI_BIT_ORDER),
		.data_rx(data_rx[31:24])
	);

    assign s_in_msb3 = (SPI_DATA_LEN == 2'b11) ? MISO : 1'b0;
	assign MOSI_MSB = data_rx[(SPI_DATA_LEN * 8) + 7];
    assign MOSI_d = SPI_BIT_ORDER ? MOSI_MSB : data_rx[0]; 


    //Contador de número de bits transmitidos
    //////////////////////////////////////////////

    reg [5:0] n_count;
    
    always @(posedge spi_clk)
	begin
        if (spi_load) begin
            n_count <= 0;
        end else begin 
            n_count <= n_count+1;
        end
	end

    wire [5:0] max_count = (SPI_DATA_LEN * 6'd8) + 6'd8;
 
    //Máquina de estados
    //////////////////////////////////////////////
    	
	always @(posedge clk)
	begin
        if (!rstn) begin
            state <= IDLE;
        end else begin 
            state <= next;
        end
	end
	
	assign next =
		(state == IDLE) ?
			(start ? LOAD : IDLE) :
		(state == LOAD) ?
			((spi_clk == 1'b0) ? LOAD : TRANSMIT) :
		(state == TRANSMIT) ?
			((n_count == max_count) ? WAIT_FRAME_END : TRANSMIT) :
		(state == WAIT_FRAME_END) ?
			((spi_frame_d == 1'b1) ? WAIT_FRAME_END : DONE) :
		(state == DONE) ?
			IDLE :
		IDLE; 

	assign spi_rst   = (state == IDLE) ? 1'b1 : 1'b0;
	assign spi_load  = (state == LOAD) ? 1'b1 : 1'b0;
	assign spi_frame = (state == TRANSMIT) ? 1'b1 : 1'b0;
	assign done      = (state == DONE) ? 1'b1 : 1'b0;
	assign SPI_DATA_RX = data_rx;

	/*
	always @(*) begin
		next = IDLE;
		case (state)
			IDLE:       if (start) next = LOAD; else next = IDLE;
			LOAD:       if (spi_clk==1'b0) next = LOAD; else next = TRANSMIT;
			TRANSMIT:   if (n_count == max_count) next = WAIT_FRAME_END; else next = TRANSMIT;
			WAIT_FRAME_END: if (spi_frame_d==1'b1) next = WAIT_FRAME_END; else next = DONE;
			DONE:       next = IDLE;
		endcase
	end
	
    always @(*) begin
		case (state) 
			IDLE:       begin spi_rst <= 1'b1; spi_load <= 1'b0; done <= 1'b0; spi_frame <= 1'b0; end
			LOAD:       begin spi_rst <= 1'b0; spi_load <= 1'b1; done <= 1'b0; spi_frame <= 1'b0; end
			TRANSMIT:	begin spi_rst <= 1'b0; spi_load <= 1'b0; done <= 1'b0; spi_frame <= 1'b1; end
			WAIT_FRAME_END:	begin spi_rst <= 1'b0; spi_load <= 1'b0; done <= 1'b0; spi_frame <= 1'b0; end
			DONE:       begin 
							spi_rst <= 1'b0; spi_load <= 1'b0; spi_frame <= 1'b0; done <= 1'b1;
							SPI_DATA_RX <= data_rx;  
						end
		endcase
	end
	*/
	

	// Desplaza MOSI un tiempo tbit/2 para alinear el flanco del reloj con la mitad del bit   
	////////////////////////////////////////////////////////////////////////////////////////

	wire spi_shifters_load;
	assign spi_shifters_load = (clk_count==0);

	always @(posedge clk) begin
		if (!rstn)
			MOSI <= 1'b0;
		else begin
			if (spi_shifters_load)
				MOSI <= MOSI_d;
		end
	end

	// Generación de la señal de reloj externo SCK
	//////////////////////////////////////////////

	reg spi_clk_d;	// Señal de reloj desplazada tbit/2
	always @(posedge clk) begin
		if (!rstn) 
			spi_clk_d <= 1'b0;
		else begin
			if (spi_shifters_load)
				spi_clk_d <= spi_clk;			
		end
	end

	// Señal de trama
	always @(posedge clk) begin
		if (!rstn)
			spi_frame_d <= 1'b0;
		else begin
			if (clk_count==0)
				spi_frame_d <= spi_frame;
		end
	end

	/*
 	always @(*) begin
		case (SPI_MODE) 
			2'b00: SCK = (~spi_clk_d) &   spi_frame_d;
			2'b01: SCK =   spi_clk_d  &   spi_frame_d;
			2'b10: SCK =   spi_clk_d  | (~spi_frame_d);
			2'b11: SCK = (~spi_clk_d) | (~spi_frame_d);
		endcase
	end
	*/

	assign SCK =
		(SPI_MODE == 2'b00) ? ((~spi_clk_d) &  spi_frame_d) :
		(SPI_MODE == 2'b01) ? ( spi_clk_d  &  spi_frame_d) :
		(SPI_MODE == 2'b10) ? ( spi_clk_d  | (~spi_frame_d)) :
		(SPI_MODE == 2'b11) ? ((~spi_clk_d) | (~spi_frame_d)) :
			1'b0;

endmodule
