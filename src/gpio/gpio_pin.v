module gpio_pin (
    input clk,
    input resetn,
    input gpio_in,
    input dir_in,
    input special_data,
    input special_en,
    inout gpio_pin,
    output gpio_out,
    output rise_det,
    output fall_det
);

    wire gpio_mux;
    reg  gpio_pin_d;
    
    always @(posedge clk) begin
        if (!resetn) begin
            gpio_pin_d <= 1'b0;
        end else begin
            gpio_pin_d <= gpio_pin;
        end
    end

    assign gpio_mux = special_en ? special_data : gpio_in;
    assign gpio_pin = dir_in ? gpio_mux : 1'bz;
    assign gpio_out = gpio_pin_d | dir_in;
    assign rise_det = ~gpio_pin_d & gpio_pin;
    assign fall_det = gpio_pin_d & ~gpio_pin;
    
endmodule
