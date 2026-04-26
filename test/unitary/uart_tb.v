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

    // UART signals
    reg  rxd;
    wire txd;
    wire en_uart;

    // Interrupts
    wire irq_uart_rx;
    wire irq_uart_tx;

    // Valor temporal de lectura
    reg [31:0] temp;

    // Instantiate DUT
    UART_Interface dut (
        .clk(clk),
        .resetn(resetn),
        .cs(cs),
        .wstrb(wstrb),
        .wr_data(wr_data),
        .rd_data(rd_data),
        .addr(addr),
        .ready(ready),
        .rxd(rxd),
        .txd(txd),
        .en_uart(en_uart),
        .irq_uart_rx(irq_uart_rx),
        .irq_uart_tx(irq_uart_tx)
    );

    localparam T = 5;
    localparam TBIT = 60;

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
        #100;
        resetn = 1;
    end

    // Generación del VCD
    initial begin
        $dumpfile("uart_tb.vcd");
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


    // ------------------------------------------------------------
    // TAREA PARA ENVIAR UNA TRAMA UART
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
        #TBIT;

        // Bits de datos (LSB primero)
        for (i = 0; i < bits; i = i + 1) begin
            rxd = data[i];
            #TBIT;
        end

        // Bit de paridad si aplica
        if (parity_mode != 2'b00) begin
            rxd = parity_bit;
            #TBIT;
        end

        // Bit de parada
        rxd = 1;
        #TBIT;
    end
    endtask


    // ------------------------------
    // TEST SEQUENCE
    // ------------------------------
    initial begin
        @(posedge resetn);

        $display("=== CONFIGURA BITRATE ===");
        write32(8'h60, 32'h00000002);
        
        ////// Prueba Configuración 1: Encendida, 8bits, sin paridad, 1 bit stop, no interrupts

        #200;
        $display("=== CONFIGURA UART (Encendida, 8bits, sin paridad, 1 bit stop, no interrupts) ===");
        write32(8'h6C, 32'h00000300); 
        
        #200;
        $display("=== ESCRIBE EN DATA_OUT ===");
        write32(8'h64, 32'h00000035);
        
        #200;
        $display("=== LEE REGISTRO DE ESTADO PARA SIMULAR BITCHANGE ===");
        read32(8'h6C, temp);
        $display("Lectura uart_ctrl = %h", temp[9:0]);

        #55;
        $display("=== ACTIVA TRANSMISION ===");
        write32(8'h6C, 32'h00000310);
        
        #200;
        $display("=== LEE REGISTRO DE ESTADO PARA REVISAR FLAG ===");
        read32(8'h6C, temp);
        $display("Lectura uart_ctrl = %h", temp[9:0]);

        #700;  
        $display("=== LEE REGISTRO DE ESTADO PARA REVISAR FLAG ===");
        read32(8'h6C, temp);
        $display("Lectura uart_ctrl = %h", temp[9:0]);

        #200;  
        $display("=== PRUEBA DE LECTURA  ===");
        receive_uart_frame(8'hA5, 8, 2'b01, 1'b0);

        #50;
        $display("=== LEE REGISTRO DE ESTADO PARA REVISAR FLAG ===");
        read32(8'h6C, temp);
        $display("Lectura uart_ctrl = %h", temp[9:0]);

        #200;
        $display("=== LEE REGISTRO DATA_IN ===");
        read32(8'h68, temp);
        $display("Lectura uart_data_in = %h", temp[9:0]);

        #200;
        $display("=== LEE REGISTRO DE ESTADO ===");
        read32(8'h6C, temp);
        $display("Lectura uart_ctrl = %h", temp[9:0]);


        ////// Prueba Configuración 2: Encendida, 8bits, paridad par, 1 bit stop, interrupciones

        #200;
        $display("=== CONFIGURA UART (Encendida, 8bits, paridad par, 1 bit stop, interrupts) ===");
        write32(8'h6C, 32'h00000343); 
        
        #200;
        $display("=== ESCRIBE EN DATA_OUT ===");
        write32(8'h64, 32'h000000CA);
        
        #215;
        $display("=== ACTIVA TRANSMISION ===");
        write32(8'h6C, 32'h00000353);
        
        #1050;
        $display("=== PRUEBA DE LECTURA  ===");
        receive_uart_frame(8'hA5, 8, 2'b01, 1'b0);

        #200;
        $display("=== LEE REGISTRO DATA_IN ===");
        read32(8'h68, temp);
        $display("Lectura uart_data_in = %h", temp[9:0]);

        #200;
        $display("=== LEE REGISTRO DE ESTADO ===");
        read32(8'h6C, temp);
        $display("Lectura uart_ctrl = %h", temp[9:0]);

        #200;
        $display("=== FIN DEL TEST ===");
        $finish;
    end

endmodule