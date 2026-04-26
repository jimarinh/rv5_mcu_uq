module spi_sipo8_tb;
	reg clk;
	reg load;
	reg [7:0] data_tx;
	reg direction;
	reg MISO;
	wire MOSI;
	wire [7:0]data_rx;
	wire serial_out_msb;
	wire serial_out_lsb;
	

	spi_sipo8 uut(
		.clk(clk),
		.load(load),
		.data_tx(data_tx),
		.serial_in_msb(MISO),
		.serial_in_lsb(MISO),
		.direction(direction),
		.data_rx(data_rx)
	);
	
	assign MOSI = direction ? data_rx[7] : data_rx[0];

	always
		begin
			#5 clk = !clk;
		end
	
	initial 
	begin
	   clk=0;
		$dumpfile("spi_sipo.vcd");
		$dumpvars;
		$monitor($time, "clk=%b, load=%b, data_tx=%b, MISO=%b, MOSI=%b, data_rx=%b",
			clk,load,data_tx,MISO,MOSI,data_rx);
	   load=0;
	   data_tx=8'b0;
	   direction=1'b1;
	   MISO=0;
	    
	   #30 load=1; data_tx=8'b00100100;
	   #10 load=0; MISO = 1;
	   #20 MISO=0;
	   #20 MISO=1;
	   #20 MISO=0;
	   
	   #200;
	   
	   #10 load=1; data_tx=8'b10101010; direction = 1'b0;
	   #10 load=0; MISO = 1;
	   #20 MISO=1;
	   #20 MISO=0;
	   #20 MISO=1;
	   
	   #300;
	   
	   $finish;
	   
	end
	
	
endmodule
