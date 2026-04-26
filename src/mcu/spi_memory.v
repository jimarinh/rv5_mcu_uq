module spi_memory #(
    parameter CLK_DIV = 1,  // divisor de reloj SPI
    parameter BIT_ADDRESS = 24
)(
    input  wire        clk,
    input  wire        rstn,

    // Control
    input  wire        enable,
    output reg         ready,

    // Entradas paralelas
    input  wire [31:0] Din,
    input  wire [BIT_ADDRESS-1:0] A,
    input  wire        WR,

    // Salidas paralelas
    output wire [31:0] Dout,

    // SPI
    output wire       sclk,
    output wire       mosi,
    input  wire       miso,
    output wire       cs
);

    localparam FRAME_WIDTH = 40 + BIT_ADDRESS;
    wire [FRAME_WIDTH-1:0] shifter_val;
    reg  [FRAME_WIDTH-1:0] shift_tx;
    reg [5:0]  bit_cnt; 
    reg busy;
    
    //Count bits process
    wire load_regs;

    always @(posedge clk) begin
        if (!rstn) begin
            bit_cnt <= 0;
        end else if (load_regs) begin
            bit_cnt <= FRAME_WIDTH;
        end else begin
            bit_cnt <= bit_cnt - 1;
        end
    end

    //Shift register
    always @(posedge clk) begin
        if (load_regs) begin
            shift_tx <= shifter_val;
        end else if (busy) begin
            shift_tx <= {shift_tx[62:0], miso};
        end
    end

    //State machine

    assign load_regs = enable & !busy;
    assign shifter_val = WR ? {8'b00000011, A, 32'bx} : {8'b00000010, A, Din}; 
    assign mosi = shift_tx[63];
    assign cs = busy;
    assign sclk = !clk;
    assign Dout = shift_tx[31:0];

    always @(posedge clk) begin
        if (!rstn) begin
            busy <= 0;
            ready <= 0;
        end else begin
            if (enable) begin
                busy <= 1;
                ready <= 0;
            end 
            if (bit_cnt==0) begin
                ready <= 1;
                busy <= 0;
            end
        end            
    end

endmodule