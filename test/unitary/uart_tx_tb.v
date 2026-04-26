`timescale 1ns/1ps

module uart_tx_tb;

    // Señales del DUT
    reg        UART_CLK;
    reg        nRST;
    reg        UART_WRITE;
    reg        UART_BITS;
    reg        UART_STOPBITS;
    reg  [1:0] UART_PARITY;
    reg  [7:0] DATA_IN_Tx;

    wire DATA_OUT_Tx;
    wire IRQ_Tx;

    // Instancia del módulo UART
    uart_tx dut (
        .UART_CLK(UART_CLK),
        .nRST(nRST),
        .UART_WRITE(UART_WRITE),
        .UART_BITS(UART_BITS),
        .UART_STOPBITS(UART_STOPBITS),
        .UART_PARITY(UART_PARITY),
        .DATA_IN_Tx(DATA_IN_Tx),
        .DATA_OUT_Tx(DATA_OUT_Tx),
        .IRQ_Tx(IRQ_Tx)
    );

    // Generación del reloj UART (un pulso por bit)
    initial UART_CLK = 0;
    always #10 UART_CLK = ~UART_CLK;   // Periodo = 20 ns

    // Generación del VCD
    initial begin
        $dumpfile("uart_tx_tb.vcd");
        $dumpvars(0, uart_tx_tb);
    end

    // Tarea para ejecutar una prueba
    task run_test;
        input [7:0] data;
        input bits;
        input stopbits;
        input [1:0] parity;
        input [8*40:1] name;   // Nombre de la prueba
    begin
        $display("\n=== Iniciando prueba: %0s ===", name);

        UART_BITS     = bits;
        UART_STOPBITS = stopbits;
        UART_PARITY   = parity;
        DATA_IN_Tx    = data;

        // Iniciar transmisión
        UART_WRITE = 1;
        //@(posedge UART_CLK);

        // Esperar a que IRQ_Tx indique fin
        wait (IRQ_Tx == 1);
        UART_WRITE = 0;
        
        //@(posedge UART_CLK);

        $display(">>> Prueba %0s completada. DATA_OUT_Tx=%b IRQ_Tx=%b", 
                  name, DATA_OUT_Tx, IRQ_Tx);
    end
    endtask

    // Secuencia de pruebas
    initial begin
        // Reset inicial
        nRST = 0;
        UART_WRITE = 0;
        //@(posedge UART_CLK);
        //@(posedge UART_CLK);
        #40;
        nRST = 1;

        // 10 pruebas solicitadas
        #40; run_test(8'hA5, 1'b1, 1'b0, 2'b00, "1) Sin paridad, 8 bits, 1 stop");
        #40; run_test(8'hA5, 1'b1, 1'b0, 2'b01, "2) Paridad par, 8 bits, 1 stop");
        #40; run_test(8'hA5, 1'b1, 1'b1, 2'b01, "3) Paridad par, 8 bits, 2 stop");
        #40; run_test(8'hA5, 1'b1, 1'b0, 2'b10, "4) Paridad impar, 8 bits, 1 stop");
        #40; run_test(8'hA5, 1'b1, 1'b1, 2'b10, "5) Paridad impar, 8 bits, 2 stop");

        #40; run_test(8'h55, 1'b0, 1'b0, 2'b00, "6) Sin paridad, 7 bits, 1 stop");
        #40; run_test(8'h55, 1'b0, 1'b0, 2'b01, "7) Paridad par, 7 bits, 1 stop");
        #40; run_test(8'h55, 1'b0, 1'b1, 2'b01, "8) Paridad par, 7 bits, 2 stop");
        #40; run_test(8'h55, 1'b0, 1'b0, 2'b10, "9) Paridad impar, 7 bits, 1 stop");
        #40; run_test(8'h55, 1'b0, 1'b1, 2'b10, "10) Paridad impar, 7 bits, 2 stop");
        #40;
        $display("\n=== TODAS LAS PRUEBAS FINALIZADAS ===\n");
        $finish;
    end

endmodule