
`timescale 1 ns / 1 ps

module testbench;

	reg clk = 1;
	reg ext_resetn = 0;
	wire trap;
    wire ready_debugging;
    wire [7:0] debugdata;
	wire [15:0] gpio_pins;

    reg  rxd = 1;
    wire txd;

    reg  miso;
    wire mosi;
	wire sclk;
	wire ss;

	always #5 clk = ~clk;


 	// ------------------------------------------------------------
    // SIMULACIÓN DE LOS PINES GPIO 
    // ------------------------------------------------------------

    reg [15:0] gpio_dir_tb;
    reg [15:0] gpio_in_tb;

    genvar i;
    generate
        for (i = 0; i < 16; i = i + 1) begin : gpio_tristate
            assign gpio_pins[i] = gpio_dir_tb[i] ? 1'bz : gpio_in_tb[i];
        end
    endgenerate


 	// ------------------------------------------------------------
    // TAREA PARA SIMULAR RECEPCIÓN DE TRAMA UART
    // ------------------------------------------------------------
    task receive_uart_frame;
        input [7:0] data;
        input integer bits;        // 7 u 8
        input [1:0] parity_mode;   // 00 none, 01 even, 10 odd
        input parity_bit;
        
        integer i;
        begin

        // Bit de inicio
        rxd = 0;
        #120;

        // Bits de datos (LSB primero)
        for (i = 0; i < bits; i = i + 1) begin
            rxd = data[i];
            #120;
        end

        // Bit de paridad si aplica
        if (parity_mode != 2'b00) begin
            rxd = parity_bit;
            #120;
        end

        // Bit de parada
        rxd = 1;
        #120;
    end
    endtask

    // ------------------------------------------------------------
    // SIMULA RECEPCIÓN DE TRAMA SPI
    // ------------------------------------------------------------
    
	always @(negedge sclk) begin
        miso <= $random;
    end
	
    // ------------------------------------------------------------
    // SIMULA EL MICROCONTROLADOR
    // ------------------------------------------------------------

    MCU_UQ uut (
        .clk(clk),
        .ext_resetn(ext_resetn),
        .trap(trap),
		.gpio_pins(gpio_pins),
        .ready_debugging(ready_debugging),
        .debugdata(debugdata),
	    .rxd(rxd),
        .txd(txd),
        .miso(miso),
        .mosi(mosi),
		.sclk(sclk),
		.ss(ss)
    );

	//Initialize program memory with an HEX file compiled with the toolchain.
    reg [1023:0] firmware_flash_file;
	initial begin
		firmware_flash_file = "flash.hex";
		$readmemh(firmware_flash_file, uut.prog_memory.mem);
	end

	//Initialize data memory with an HEX file compiled with the toolchain.
/*     reg [1023:0] firmware_sram_file;
	initial begin
		firmware_sram_file = "sram.hex";
		$readmemh(firmware_sram_file, uut.data_memory.mem);
	end */


	initial begin
		if ($test$plusargs("vcd")) begin
			$dumpfile("testbench.vcd");
			$dumpvars(0, testbench);
		end

        gpio_dir_tb = 16'b0000_0000_0001_1000; //Pin 3 & 4 como salida los demás como entradas
        gpio_in_tb  = 16'b0000_0000_0000_0000; //Valor inicial de las señales GPIO de entrada

		repeat (2) @(posedge clk);
		ext_resetn <= 1;	

		repeat (3000) @(posedge clk);
        gpio_in_tb  = 16'b1100_0000_0000_0000; //Flanco de subida en INT0 & INT1

        repeat (1500) @(posedge clk);
        gpio_in_tb  = 16'b0100_0000_0000_0000; //Flanco de bajada en INT1

        repeat (1500) @(posedge clk);
        gpio_in_tb  = 16'b0100_0100_0000_0000; //Flanco de subida en GPIO10
        receive_uart_frame(8'h49, 8, 2'b00, 1'b0);
        

        repeat (2000) @(posedge clk);

		$finish;
	end

	//--------------------------------------------------------
	// Debugging interface
	//--------------------------------------------------------

	always @(posedge clk) begin
		if (ready_debugging) 
			$write("%c", debugdata);
	end

endmodule

