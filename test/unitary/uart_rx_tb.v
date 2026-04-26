`timescale 1us/1ns

module uart_rx_tb;

    // Señales del DUT
    reg UART_CLK;
    reg nRST;
    reg DATA_IN_Rx;
    reg UART_BITS;          // 0 = 7 bits, 1 = 8 bits
    reg [1:0] UART_PARITY;  // 00 = none, 01 = even, 10 = odd

    wire IRQ_Rx;
    wire [7:0] DATA_OUT_Rx;
    wire UART_PARITY_ERR;

    // Instancia del módulo a probar
    uart_rx dut (
        .UART_CLK(UART_CLK),
        .nRST(nRST),
        .DATA_IN_Rx(DATA_IN_Rx),
        .UART_BITS(UART_BITS),
        .UART_PARITY(UART_PARITY),
        .IRQ_Rx(IRQ_Rx),
        .DATA_OUT_Rx(DATA_OUT_Rx),
        .UART_PARITY_ERR(UART_PARITY_ERR)
    );

    // Generación del reloj UART
    initial begin
        UART_CLK = 0;
        forever #5 UART_CLK = ~UART_CLK;   // Periodo = 10us
    end

    // Reset inicial
    initial begin
        nRST = 0;
        DATA_IN_Rx = 1;   // Línea en reposo
        #20;
        nRST = 1;
    end

    // Generación del VCD
    initial begin
        $dumpfile("uart_rx_tb.vcd");
        $dumpvars(0, uart_rx_tb);
    end

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
        DATA_IN_Rx = 0;
        #10;

        // Bits de datos (LSB primero)
        for (i = 0; i < bits; i = i + 1) begin
            DATA_IN_Rx = data[i];
            #10;
        end

        // Bit de paridad si aplica
        if (parity_mode != 2'b00) begin
            DATA_IN_Rx = parity_bit;
            #10;
        end

        // Bit de parada
        DATA_IN_Rx = 1;
        #10;
    end
    endtask

    // ------------------------------------------------------------
    // PRUEBAS
    // ------------------------------------------------------------
    initial begin
        @(posedge nRST);
        #20;

        // 1) 8 bits sin paridad
        UART_BITS   = 1;
        UART_PARITY = 2'b00;
        #13;
        $display("\n--- Caso 1: 8 bits sin paridad ---");
        receive_uart_frame(8'hA5, 8, UART_PARITY, 1'b0);
        #50;

        // 2) 8 bits paridad par
        UART_BITS   = 1;
        UART_PARITY = 2'b01;
        $display("\n--- Caso 2: 8 bits paridad par ---");
        receive_uart_frame(8'h3C, 8, UART_PARITY, 1'b0);
        #50;

        // 2-E) 8 bits paridad par con error de paridad
        UART_BITS   = 1;
        UART_PARITY = 2'b01;
        $display("\n--- Caso 2E: 8 bits paridad par con error ---");
        receive_uart_frame(8'h19, 8, UART_PARITY, 1'b0);
        #50;

        // 3) 8 bits paridad impar
        UART_BITS   = 1;
        UART_PARITY = 2'b10;
        $display("\n--- Caso 3: 8 bits paridad impar ---");
        receive_uart_frame(8'h7E, 8, UART_PARITY, 1'b1);
        #50;

        // 3-E) 8 bits paridad impar con error
        UART_BITS   = 1;
        UART_PARITY = 2'b10;
        $display("\n--- Caso 3: 8 bits paridad impar con error---");
        receive_uart_frame(8'h92, 8, UART_PARITY, 1'b1);
        #50;

        // 4) 7 bits sin paridad
        UART_BITS   = 0;
        UART_PARITY = 2'b00;
        $display("\n--- Caso 4: 7 bits sin paridad ---");
        receive_uart_frame(8'h55, 7, UART_PARITY, 1'b0);
        #50;

        // 5) 7 bits paridad par
        UART_BITS   = 0;
        UART_PARITY = 2'b01;
        $display("\n--- Caso 5: 7 bits paridad par ---");
        receive_uart_frame(8'h35, 7, UART_PARITY, 1'b0);
        #50;

        // 5-E) 7 bits paridad par con error
        UART_BITS   = 0;
        UART_PARITY = 2'b01;
        $display("\n--- Caso 5-: 7 bits paridad par con error ---");
        receive_uart_frame(8'h52, 7, UART_PARITY, 1'b0);
        #50; 

        // 6) 7 bits paridad impar
        UART_BITS   = 0;
        UART_PARITY = 2'b10;
        $display("\n--- Caso 6: 7 bits paridad impar ---");
        receive_uart_frame(8'h6A, 7, UART_PARITY, 1'b1);
        #50;

        // 6-E) 7 bits paridad impar con error
        UART_BITS   = 0;
        UART_PARITY = 2'b10;
        $display("\n--- Caso 6: 7 bits paridad impar con error ---");
        receive_uart_frame(8'h24, 7, UART_PARITY, 1'b0);
        #50;

        $display("\n--- FIN DE LA SIMULACIÓN ---");
        $finish;
    end

endmodule