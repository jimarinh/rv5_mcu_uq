module uart_bitrate (
    input  wire        clk,
    input  wire        rst,
    input  wire        rst_quarter,
    input  wire [31:0] N_in,
    output reg         clk_out
);

    reg [31:0] counter;

    always @(posedge clk) begin
        if (rst) begin
            counter <= N_in;
            clk_out <= 1'b0;
        end else begin
            if (rst_quarter) begin
                counter <= N_in >> 2;   // N/4
            end else if (counter == 0) begin
                clk_out <= ~clk_out;     
                counter <= N_in;        // recarga normal
            end else begin
                counter <= counter - 1;
            end
        end
    end

endmodule