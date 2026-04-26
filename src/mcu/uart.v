//--------------------------------------------------------
// UART  Native Bus Interface
//--------------------------------------------------------

module UART_Interface
(
    input clk,              // Clock signal
    input resetn,            // Reset
    input cs,                // Chip select
    //Memory interface
    input [3:0] wstrb,       // Write/read enable
    input [31:0] wr_data,    // Data input
    output reg [31:0] rd_data,   // Data output
    input [7:0] addr,        // Low-address input
    output reg ready,        // Ready
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
    reg UART_WRITE;         // TX request (se limpia cuando termina la TX)
    reg UART_AVAIL;         // RX data available
    reg UART_PARITY_ERR;
    reg UART_I_MASK_TX;
    reg UART_I_MASK_RX;

    wire [9:0] uart_ctrl;
    assign uart_ctrl = {
        UART_ON, UART_BITS, UART_PARITY, UART_STOPBITS,
        UART_WRITE, UART_AVAIL, UART_PARITY_ERR,
        UART_I_MASK_TX, UART_I_MASK_RX
    };

    // --------------------------------------------------------------------
    // Bus strobes
    // --------------------------------------------------------------------
    wire bus_wr     = cs && (wstrb != 4'b0000);
    wire bus_rd     = cs && (wstrb == 4'b0000);

    wire wr_bitrate = bus_wr && (addr[3:2] == 2'b00);
    wire wr_dataout = bus_wr && (addr[3:2] == 2'b01);
    wire wr_ctrl    = bus_wr && (addr[3:2] == 2'b11);

    wire rd_bitrate = bus_rd && (addr[3:2] == 2'b00);
    wire rd_dataout = bus_rd && (addr[3:2] == 2'b01);
    wire rd_datain  = bus_rd && (addr[3:2] == 2'b10);
    wire rd_ctrl    = bus_rd && (addr[3:2] == 2'b11);

    // --------------------------------------------------------------------
    // UART submodules
    // --------------------------------------------------------------------
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

    uart_bitrate uart_br_tx (
        .clk(clk),
        .rst(uart_rst_bitrate),
        .rst_quarter(uart_rst4_tx),
        .N_in(uart_bitrate),
        .clk_out(uart_clock_tx)
    );

    uart_tx uart_tx_mod(
        .nRST(UART_ON),
        .UART_CLK(uart_clock_tx),
        .UART_WRITE(UART_WRITE),
        .UART_BITS(UART_BITS),
        .UART_PARITY(UART_PARITY),
        .UART_STOPBITS(UART_STOPBITS),
        .DATA_IN_Tx(uart_data_out),
        .DATA_OUT_Tx(txd),
        .IRQ_Tx(IRQ_Tx)
    );

    assign irq_uart_tx = UART_I_MASK_TX & IRQ_Tx;

    uart_bitrate uart_br_rx (
        .clk(clk),
        .rst(uart_rst_bitrate),
        .rst_quarter(uart_rst4_rx),
        .N_in(uart_bitrate),
        .clk_out(uart_clock_rx)
    );

    uart_rx uart_rx_mod(
        .nRST(UART_ON),
        .UART_CLK(uart_clock_rx),
        .DATA_IN_Rx(rxd),
        .UART_BITS(UART_BITS),
        .UART_PARITY(UART_PARITY),
        .IRQ_Rx(IRQ_Rx),
        .DATA_OUT_Rx(uart_data_in),
        .UART_PARITY_ERR(parity_err),
        .IDLE(idle_rx)
    );

    assign irq_uart_rx = UART_I_MASK_RX & IRQ_Rx;

    // --------------------------------------------------------------------
    // Edge detectors ONLY for quarter-reset (NO tocan UART_WRITE/UART_AVAIL)
    // --------------------------------------------------------------------
    reg UART_WRITE_d;
    always @(posedge clk) begin
        UART_WRITE_d <= UART_WRITE;
        uart_rst4_tx <= UART_WRITE & ~UART_WRITE_d; // inicia quarter reset al flanco subida de request
    end

    reg rxd_d;
    always @(posedge clk) begin
        rxd_d <= rxd;
        uart_rst4_rx <= (~rxd) & rxd_d & idle_rx;    // start-bit detect
    end

    // --------------------------------------------------------------------
    // CONTROL REGISTERS: un solo always (SIN multi-driver)
    // --------------------------------------------------------------------
    reg IRQ_Tx_d;
    reg IRQ_Rx_d;

    always @(posedge clk) begin
        if (!resetn) begin
            UART_ON         <= 1'b0;
            UART_BITS       <= 1'b1;    // 8 bits
            UART_PARITY     <= 2'b00;   // No parity
            UART_STOPBITS   <= 1'b0;    // 1 stop bit
            UART_WRITE      <= 1'b0;
            UART_AVAIL      <= 1'b0;
            UART_PARITY_ERR <= 1'b0;
            UART_I_MASK_TX  <= 1'b0;
            UART_I_MASK_RX  <= 1'b0;

            IRQ_Tx_d        <= 1'b0;
            IRQ_Rx_d        <= 1'b0;
        end else begin
            // flancos IRQ
            IRQ_Tx_d <= IRQ_Tx;
            IRQ_Rx_d <= IRQ_Rx;

            // Escritura del registro de control (addr[3:2]==11)
            if (wr_ctrl) begin
                UART_ON       <= wr_data[9];
                UART_BITS     <= wr_data[8];
                UART_PARITY   <= wr_data[7:6];
                UART_STOPBITS <= wr_data[5];

                // UART_WRITE como "request": solo se SETEA si escribe 1 en bit4.
                // (para que no se borre accidentalmente cuando escribes ctrl sin querer iniciar TX)
                if (wr_data[4]) UART_WRITE <= 1'b1;

                UART_I_MASK_TX <= wr_data[1];
                UART_I_MASK_RX <= wr_data[0];
            end

            // Cuando termina TX -> limpiar request
            if (IRQ_Tx & ~IRQ_Tx_d) begin
                UART_WRITE <= 1'b0;
            end

            // Cuando llega RX -> marcar disponible y capturar parity error
            if (IRQ_Rx & ~IRQ_Rx_d) begin
                UART_AVAIL      <= 1'b1;
                UART_PARITY_ERR <= parity_err;
            end

            // Cuando lee DATA_IN -> limpiar AVAIL
            if (rd_datain) begin
                UART_AVAIL <= 1'b0;
            end
        end
    end

    // --------------------------------------------------------------------
    // Native Memory Interface (data regs + read mux)
    // --------------------------------------------------------------------
    always @(posedge clk) begin
        ready <= 1'b0;
        uart_rst_bitrate <= 1'b0;

        if (cs) begin
            ready <= 1'b1;

            //Write
            if (wstrb != 4'b0000) begin
                case (addr[3:2])
                    2'b00: begin
                        uart_bitrate <= wr_data;
                        uart_rst_bitrate <= 1'b1;
                    end
                    2'b01: uart_data_out <= wr_data[7:0];
                    default: ; // 2'b10 RO, 2'b11 manejado en ctrl always
                endcase
            end else begin
                //Read
                case (addr[3:2])
                    2'b00: rd_data <= uart_bitrate;
                    2'b01: rd_data <= {24'b0, uart_data_out};
                    2'b10: rd_data <= {24'b0, uart_data_in};
                    2'b11: rd_data <= {22'b0, uart_ctrl};
                endcase
            end
        end
    end

endmodule
