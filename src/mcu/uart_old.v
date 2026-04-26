//--------------------------------------------------------
// UART  Native Bus Interface
//--------------------------------------------------------

module UART_Interface
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
    //Specific UART signals
    input  rxd,
    output txd,
    output en_uart,
    //Interrupt lines
    output irq_uart_rx,
    output irq_uart_tx
);

	//Internal UART registers
	reg  [31:0] uart_bitrate;
	reg  [7:0]  uart_data_out;
	wire [7:0]  uart_data_in;

	//Control register (uart_ctrl)
	reg UART_ON;
	reg UART_BITS;
	reg [1:0] UART_PARITY;
	reg UART_STOPBITS;
	reg UART_WRITE;
	reg UART_AVAIL;
	reg UART_PARITY_ERR;
	reg UART_I_MASK_TX;
	reg UART_I_MASK_RX;
	wire  [9:0]  uart_ctrl;
	assign uart_ctrl = {UART_ON, UART_BITS, UART_PARITY, UART_STOPBITS, UART_WRITE, UART_AVAIL, UART_PARITY_ERR, UART_I_MASK_TX, UART_I_MASK_RX };

	//Set initial values on reset
	always @(posedge clk) begin
		//Values on reset
		if (!resetn) begin
			UART_ON 		<= 1'b0;
			UART_BITS 		<= 1'b1;  	//8 bits
			UART_PARITY 	<= 2'b00;	//No parity
			UART_STOPBITS 	<= 1'b0;	//1 stop bit
			UART_WRITE 		<= 1'b0;
			UART_AVAIL 		<= 1'b0;
			UART_PARITY_ERR	<= 1'b0;
			UART_I_MASK_TX 	<= 1'b0;	//No interrupts
			UART_I_MASK_RX 	<= 1'b0;
		end
	end

	//Module connection
	//////////////////////////////////////////////

	wire IRQ_Tx;
	wire IRQ_Rx;
	wire uart_clock_tx;
	wire uart_clock_rx;
	reg  uart_rst_bitrate;
	reg  uart_rst4_tx;
	reg  uart_rst4_rx;
	wire parity_err;
	wire idle_rx;

	assign en_uart = UART_ON;

	// Instantación del módulo 'bitrate' para controla la velocidad de transmisión
	uart_bitrate uart_br_tx (
    	.clk(clk),
    	.rst(uart_rst_bitrate),
    	.rst_quarter(uart_rst4_tx),
    	.N_in(uart_bitrate),
    	.clk_out(uart_clock_tx)
	);

    // Instanciación del módulo 'tx' (transmisor UART) para transmitir datos
    uart_tx uart_tx_mod(
        .nRST(UART_ON),				// Reset del transmisor
        .UART_CLK(uart_clock_tx),   // Reloj generado por el módulo 'bitrate'
        .UART_WRITE(UART_WRITE),	// Señal de control de escritura de datos
        .UART_BITS(UART_BITS),  	// Longitud de los datos (por ejemplo, 8 bits)
        .UART_PARITY(UART_PARITY), 	// Control de paridad
        .DATA_IN_Tx(uart_data_out), // Datos de entrada a transmitir
        .DATA_OUT_Tx(txd), 			// Pin de salida
        .IRQ_Tx(IRQ_Tx)         	// Interrupción de finalización de transmisión
    );

	assign irq_uart_tx = UART_I_MASK_TX & IRQ_Tx;

	reg UART_WRITE_d;     			
	always @(posedge clk) begin		// Detector de flanco subida en UART_WRITE para iniciar bitrate
		UART_WRITE_d <= UART_WRITE; 
		uart_rst4_tx <= UART_WRITE & ~UART_WRITE_d; 
	end

	reg IRQ_Tx_d;     // Limpia la bandera UART_WRITE cuando la transmisión termina
	always @(posedge clk) begin
		IRQ_Tx_d <= IRQ_Tx;
		if (IRQ_Tx & ~IRQ_Tx_d) begin
			UART_WRITE <= 1'b0;      
		end 
	end

	// Instantación del módulo 'bitrate' para controla la velocidad de recepción
	uart_bitrate uart_br_rx (
    	.clk(clk),
    	.rst(uart_rst_bitrate),
    	.rst_quarter(uart_rst4_rx),
    	.N_in(uart_bitrate),
    	.clk_out(uart_clock_rx)
	);

    // Instanciación del módulo 'rx' (receptor UART) para recibir datos
    uart_rx uart_rx_mod(
        .nRST(UART_ON),				// Reset asíncrono del receptor
        .UART_CLK(uart_clock_rx),   // Reloj UART generado
        .DATA_IN_Rx(rxd),			// Pin de entrada
        .UART_BITS(UART_BITS),  	// Longitud de los datos (por ejemplo, 8 bits)
        .UART_PARITY(UART_PARITY), 	// Control de paridad		
        .IRQ_Rx(IRQ_Rx),         	// Interrupción de finalización de recepción
        .DATA_OUT_Rx(uart_data_in),	// Datos recibidos y enviados al sistema
		.UART_PARITY_ERR(parity_err),//Chequeo de Paridad
		.IDLE(idle_rx)
    );

	assign irq_uart_rx = UART_I_MASK_RX & IRQ_Rx;

	reg rxd_d;     			
	always @(posedge clk) begin		// Detector de flanco bajada en RxD para iniciar bitrate
		rxd_d <= rxd; 
		uart_rst4_rx <= (~rxd) & rxd_d & idle_rx; 
	end

	reg IRQ_Rx_d;     			
	always @(posedge clk) begin		// Detector de flanco de subida en IRQ_Rx para fijar UART_AVAIL & PARITY_ERR
		IRQ_Rx_d <= IRQ_Rx; 
		if (IRQ_Rx & ~IRQ_Rx_d) begin
			UART_AVAIL <= 1'b1;
			UART_PARITY_ERR <= parity_err;      
		end 
	end

	//Native Memory Interface 
	//////////////////////////////////////////////
	always @(posedge clk) begin
		ready <= 0;
		uart_rst_bitrate <= 0;

		if (cs) begin
			ready <= 1;
			//Write
			if (wstrb!=4'b0000) begin
				case (addr[3:2])
					2'b00: begin 
						uart_bitrate[31:0] <= wr_data[31:0]; 
						uart_rst_bitrate <= 1; 
						end
					2'b01: uart_data_out[7:0] <= wr_data[ 7:0];
					//2'b10: UART_DATA_IN is read-only 
					2'b11: begin 
						UART_ON 		<= wr_data[9];
						UART_BITS 		<= wr_data[8];
						UART_PARITY 	<= wr_data[7:6];
						UART_STOPBITS	<= wr_data[5];
						UART_WRITE 		<= wr_data[4];
						UART_I_MASK_TX 	<= wr_data[1];
						UART_I_MASK_RX 	<= wr_data[0];
						end
				endcase
			end 
			else begin 
			//Read
				case (addr[3:2])
					2'b00: rd_data <= uart_bitrate;
					2'b01: rd_data <= uart_data_out;
					2'b10: begin rd_data <= uart_data_in; UART_AVAIL <= 1'b0; end
					2'b11: rd_data <= uart_ctrl;
				endcase
			end
		end
	end

endmodule