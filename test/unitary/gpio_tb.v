`timescale 1ns/1ps

module UART_Interface_tb;

    // Clock & reset
    reg clk;
    reg resetn;

    // Bus interface
    reg         cs;
    reg [3:0]   wstrb;
    reg [31:0]  wr_data;
    wire [31:0] rd_data;
    reg [7:0]   addr;
    wire        ready;

    // Valor temporal de lectura
    reg [31:0] temp;

    //Special pins

    wire [15:0] gpio_pins;

	reg tmr_in0;
    reg pwm_outa0;
    reg pwm_outb0;

	reg tmr_in1;
    reg pwm_outa1;
    reg pwm_outb1;

 	reg sda;
    reg scl;

	reg mosi;
	reg miso;
	reg sclk;
	reg ss;
    
	reg txd;
	reg rxd;

    reg en_tmr_in0;
    reg en_pwm_outa0;
    reg en_pwm_outb0;
	reg en_tmr_in1;
    reg en_pwm_outa1;
    reg en_pwm_outb1;
	reg en_i2c;
	reg en_spi;
	reg en_uart;

    // Interrupts
    wire irq_int0;
    wire irq_int1;
    wire irq_pinchange;

    reg [15:0] gpio_dir_tb;
    reg [15:0] gpio_in_tb;

genvar i;
generate
    for (i = 0; i < 16; i = i + 1) begin : gpio_tristate
        assign gpio_pins[i] = gpio_dir_tb[i] ? 1'bz : gpio_in_tb[i];
    end
endgenerate


    // Instantiate DUT
	GPIO_Interface DUT (
		//Bus interface
		.clk(clk),
        .resetn(resetn),
        .cs(cs),
        .wstrb(wstrb),
        .wr_data(wr_data),
        .rd_data(rd_data),
        .addr(addr),
        .ready(ready),
		//External GPIO pins
		.gpio_pins(gpio_pins),
		//Special GPIO output signals
		.PWM_OUTA0(pwm_outa0), 
		.PWM_OUTB0(pwm_outb0),
		.PWM_OUTA1(pwm_outa1),
		.PWM_OUTB1(pwm_outb1),
		.SPI_SCLK(sclk), 
		.SPI_MOSI(mosi),
		.SPI_SS(ss),
		.I2C_SCL(scl),
		.UART_TXD(txd),
		//Special GPIO enablers
		.en_tmr_in0(en_tmr_in0),
		.en_pwm_outa0(en_pwm_outa0),
		.en_pwm_outb0(en_pwm_outb0),
		.en_tmr_in1(en_tmr_in1),
		.en_pwm_outa1(en_pwm_outa1),
		.en_pwm_outb1(en_pwm_outb1),
		.en_i2c(en_i2c),
		.en_spi(en_spi),
		.en_uart(en_uart),
		//Interrupt lines
		.irq_int0(irq_int0),
		.irq_int1(irq_int1),
		.irq_pinchange(irq_pinchange)		
	);

    localparam T = 5;

    // Clock generator
    initial begin
        clk = 0;
        forever #T clk = ~clk;   // 100 MHz
    end

    // Reset sequence
    initial begin
        resetn = 0;
        cs     = 0;
        wstrb  = 0;
        wr_data = 0;
        addr    = 0;

        rxd     = 1;   // UART idle
        tmr_in0 = 0;
	    tmr_in1 = 0;
        sda     = 1;
        miso    = 0;
	
        gpio_dir_tb = 16'h00;
        gpio_in_tb  = 16'h00;

        en_tmr_in0 = 0;
        en_pwm_outa0 = 0;
        en_pwm_outb0 = 0;
        en_tmr_in1 = 0;
        en_pwm_outa1 = 0;
        en_pwm_outb1 = 0;
        en_i2c = 0;
        en_spi = 0;
        en_uart = 0;

        #100;
        resetn = 1;
    end

    // Generación del VCD
    initial begin
        $dumpfile("gpio_tb.vcd");
        $dumpvars(0, UART_Interface_tb);
    end

    // ------------------------------
    // TASKS PARA ACCESO AL BUS
    // ------------------------------

    // Escritura: write(addr, data)
    task write32;
        input [7:0]   a;
        input [31:0]  d;
    begin
        @(posedge clk);
        cs     <= 1;
        wstrb  <= 4'b1111;
        addr   <= a;
        wr_data <= d;

        @(posedge clk);
        cs <= 0;
        wstrb <= 0;
    end
    endtask

    // Lectura: read(addr, data_out)
    task read32;
        input  [7:0] a;
        output [31:0] d;
    begin
        @(posedge clk);
        cs    <= 1;
        wstrb <= 0;
        addr  <= a;

        @(posedge clk);
    
        @(posedge clk);
        d = rd_data;
        cs <= 0;
    end
    endtask



    // ------------------------------
    // TEST SEQUENCE
    // ------------------------------
    initial begin
        @(posedge resetn);

        $display("=== CONFIGURA GPIO_DIR (pin 0 y 1 salida, restantes entrada) ===");

        gpio_dir_tb = 16'h0003;
        write32(8'h10, 32'h00000003);
        
        ////// Prueba 1: Escritura y lectura. Hardware especializado OFF 

        #200;
        $display("=== ESCRITURA. HW ESPECIALIZADO OFF ===");
        #55; write32(8'h14, 32'h00000000); 
        #55; write32(8'h14, 32'h00000001); 
        #55; write32(8'h14, 32'h00000002); 
        #55; write32(8'h14, 32'h00000003); 
        #55; write32(8'h14, 32'h00000555); 
        
        #200;

        $display("=== LECTURA. HW ESPECIALIZADO OFF===");
        read32(8'h18, temp);
        $display("Lectura GPIO_DATA_IN = %h", temp[15:0]);
        #55;
        
        gpio_in_tb[2] = 1'b1;
        #55; read32(8'h18, temp);
        $display("Lectura GPIO_DATA_IN = %h", temp[15:0]);
        #55;

        gpio_in_tb[3] = 1'b1;
        #55; read32(8'h18, temp);
        $display("Lectura GPIO_DATA_IN = %h", temp[15:0]);
        #200;

        ////// Prueba 2: Interrupciones. Hardware especializado OFF 
        $display("=== INT0 (Falling) INT1(OFF) PINCHANGE(OFF) HW ESPECIALIZADO OFF ===");
        write32(8'h1C, 32'h80000000);
        #55; 
        gpio_in_tb[14] = 1'b1;
        #55; 
        gpio_in_tb[14] = 1'b0;
        #200;

        $display("=== INT0 (OFF) INT1(Rising) PINCHANGE(OFF) HW ESPECIALIZADO OFF ===");
        write32(8'h1C, 32'h10000000);
        #55; 
        gpio_in_tb[15] = 1'b1;
        #55; 
        gpio_in_tb[15] = 1'b0;
        #55;

        
        $display("=== INT0 (CHANGE) INT1(CHANGE) PINCHANGE(OFF) HW ESPECIALIZADO OFF ===");
        write32(8'h1C, 32'hF0000000);
        #55; 
        gpio_in_tb[15] = 1'b1; gpio_in_tb[14] = 1'b0;
        #55; 
        gpio_in_tb[15] = 1'b1; gpio_in_tb[14] = 1'b1;
        #55;
        gpio_in_tb[15] = 1'b0; gpio_in_tb[14] = 1'b0;
        #55; 
        gpio_in_tb[15] = 1'b0; gpio_in_tb[14] = 1'b1;
        #200;

        
        $display("=== INT0 (Rising) INT1(Falling) PINCHANGE(ON) HW ESPECIALIZADO OFF ===");
        write32(8'h1C, 32'hF000000C);
        #55; 
        gpio_in_tb[15] = 1'b1; gpio_in_tb[14] = 1'b0; gpio_in_tb[3] = 1'b0; 
        #55; 
        gpio_in_tb[15] = 1'b1; gpio_in_tb[14] = 1'b1; gpio_in_tb[3] = 1'b1;
        #55;
        gpio_in_tb[15] = 1'b0; gpio_in_tb[14] = 1'b0; gpio_in_tb[3] = 1'b1;
        #55; 
        gpio_in_tb[15] = 1'b0; gpio_in_tb[14] = 1'b1; gpio_in_tb[3] = 1'b0;
        #200;

         ////// Prueba 3: Hardware especializado ON 
        $display("=== No INTs - HW ESPECIALIZADO ON ===");
        write32(8'h1C, 32'h00000000);

        gpio_dir_tb = 16'h02BA;
        en_tmr_in0 = 1;
        en_pwm_outa0 = 1;
        en_pwm_outb0 = 0;
        en_tmr_in1 = 0;
        en_pwm_outa1 = 0;
        en_pwm_outb1 = 0;
        en_i2c = 1;
        en_spi = 1;
        en_uart = 1;

        tmr_in0 = 0;
        pwm_outa0 = 1;
        pwm_outb0 = 1;

	    tmr_in1 = 1;
        pwm_outa1 = 0;
        pwm_outb1 = 1;

 	    sda = 1;
        scl = 1;

	    mosi = 1;
	    miso = 0;
	    sclk = 0;
	    ss = 1;
    
	    txd = 1;
	    rxd = 0;


        #200;
        $display("=== FIN DEL TEST ===");
        $finish;
    end

endmodule