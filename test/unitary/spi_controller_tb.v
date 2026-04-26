`timescale 1ns/1ps

module tb_spi_controller;

    // -----------------------------
    // Señales del DUT
    // -----------------------------
    reg clk;
    reg rstn;
    reg start;
    reg [1:0] SPI_MODE;
    reg SPI_BIT_ORDER;
    reg [1:0] SPI_DATA_LEN;
    reg [31:0] SPI_DATA_TX;
    reg [31:0] SPI_BITRATE;

    reg  MISO;
    wire MOSI;
    wire SCK;
    wire done;
    wire [31:0] SPI_DATA_RX;

    // -----------------------------
    // Instanciación del DUT
    // -----------------------------
    spi_controller dut (
        .clk(clk),
        .rstn(rstn),
        .start(start),
        .SPI_MODE(SPI_MODE),
        .SPI_BIT_ORDER(SPI_BIT_ORDER),
        .SPI_DATA_LEN(SPI_DATA_LEN),
        .SPI_DATA_TX(SPI_DATA_TX),
        .SPI_BITRATE(SPI_BITRATE),
        .MISO(MISO),
        .MOSI(MOSI),
        .SPI_DATA_RX(SPI_DATA_RX),
        .SCK(SCK),
        .done(done)
    );

    // -----------------------------
    // Generación de reloj
    // -----------------------------
    localparam CLK_HALF = 5;  // 100 MHz
    always #CLK_HALF clk = ~clk;

    // -----------------------------
    // Reset inicial
    // -----------------------------
    initial begin
        clk = 0;
        rstn = 0;
        start = 0;
        MISO = 0;
        SPI_MODE = 0;       
        SPI_BIT_ORDER = 0;
        SPI_DATA_LEN = 0;
        SPI_DATA_TX = 0;
        SPI_BITRATE = 2;

        #100;
        rstn = 1;
    end

    // Generación del VCD
    initial begin
        $dumpfile("spi_controller.vcd");
        $dumpvars(0, tb_spi_controller);
    end

    // -----------------------------
    // Genera las señales de un esclavo 
    // SPI de manera aleatoria (Para modos 0 y 3 usar negedge para 1 y 2 posedge)
    // -----------------------------
    always @(posedge SCK) begin
        MISO <= $random;
    end

    // -----------------------------
    // Tarea para iniciar transferencia
    // -----------------------------
    task spi_transfer;
        input bit_order;
        input [1:0] data_len;
        input [31:0] data_in;
    begin
        @(posedge clk);
        SPI_BIT_ORDER <= bit_order;
        SPI_DATA_LEN  <= data_len;
        SPI_DATA_TX   <= data_in;

        start <= 1;
        @(posedge clk);
        start <= 0;

        // Esperar a que done se active
        wait(done == 1);
        @(posedge clk);

        $display("Transferencia completada:");
        $display("  MODE=%0d, BIT_ORDER=%0d, LEN=%0d bits", 
                  SPI_MODE, bit_order, (data_len+1)*8);
        $display("  TX=%h  RX=%h", data_in, SPI_DATA_RX);
    end
    endtask

    // -----------------------------
    // Secuencia de pruebas
    // -----------------------------

    initial begin
        
        SPI_MODE = 2'd1;    //Todo el testbench se ejecuta para un solo modo
                            //Revisar always que genera la señal MISO porque 
                            //toca cambiar el flanco dependiendo del modo a probar

        @(posedge rstn);
        #200;
        
        $display("=== INICIO DE PRUEBAS SPI ===");
        
        // MSB-first, 8 bits
        spi_transfer(1'b1, 2'd0, 32'hA5);
        #200;

        // MSB-first, 16 bits
        spi_transfer(1'b1, 2'd1, 32'h1234);
        #200;

        // MSB-first, 24 bits
        spi_transfer(1'b1, 2'd2, 32'hABCDEF);
        #200;

        //  MSB-first, 32 bits
        spi_transfer(1'b1, 2'd3, 32'hDEADBEEF);        
        #600;

        // LSB-first, 8 bits
        spi_transfer(1'b0, 2'd0, 32'hA5);
        #200;

        // LSB-first, 16 bits
        spi_transfer(1'b0, 2'd1, 32'h1234);
        #200;

        // LSB-first, 24 bits
        spi_transfer(1'b0, 2'd2, 32'hABCDEF);
        #200;

        // LSB-first, 32 bits
        spi_transfer(1'b0, 2'd3, 32'hDEADBEEF);

        $display("=== FIN DE PRUEBAS ===");
        #400;
        $finish;
    end

endmodule
