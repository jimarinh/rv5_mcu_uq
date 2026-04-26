module MCU_UQ(
	input clk,
	input ext_resetn,
	output trap,

	inout [15:0] gpio_pins,

	output reg ready_debugging,
	output reg [7:0] debugdata,

	output txd,
	input  rxd,

	output mosi,
	input  miso,
	output sclk,
	output ss
);

	parameter PROG_MEM_SIZE_WORDS = 32*1024; 	//Size of the program memory in words
	parameter PROG_MEM_BASE = 32'h3000_0000;	//Base address for the program memory
	parameter PROG_MEM_END = PROG_MEM_BASE+PROG_MEM_SIZE_WORDS*4-1;

	parameter DATA_MEM_SIZE_WORDS = 32*1024; 	//Size of the data memory in words
	parameter DATA_MEM_BASE = 32'h1000_0000;	//Base address for the program memory
	parameter DATA_MEM_END = DATA_MEM_BASE+DATA_MEM_SIZE_WORDS*4-1;

	parameter DEBUG_BASE = 32'h2000_0000;

	wire resetn;

	wire mem_valid;
	wire mem_instr;
	wire mem_ready;
	wire [31:0] mem_addr;
	wire [31:0] mem_wdata;
	wire [3:0]  mem_wstrb;
	reg  [31:0] mem_rdata;

	wire [31:0] mem_rdata_flash;
	wire [31:0] mem_rdata_sram;
	wire [31:0] mem_rdata_timer0;
	wire [31:0] mem_rdata_timer1;
	wire [31:0] mem_rdata_gpio;
	wire [31:0] mem_rdata_uart;
	wire [31:0] mem_rdata_watchdog;
	wire [31:0] mem_rdata_spi;
	wire [31:0] mem_rdata_i2c;
	
	wire en_mem;
	wire is_io_address;
	wire en_io_address;
	wire [7:0] io_address;
	wire [31:0] irq;
	wire [31:0] eoi;

	picorv32 #(
`ifdef COMPRESSED_ISA
		.COMPRESSED_ISA(0),
`endif
		.ENABLE_MUL(0),
		.ENABLE_DIV(0),
		.ENABLE_IRQ(1),
        .ENABLE_IRQ_QREGS (0),
		.ENABLE_TRACE(0),
		.PROGADDR_RESET(PROG_MEM_BASE),
		.PROGADDR_IRQ(PROG_MEM_BASE+32'h10)
	) RISCVCore (
		.clk         (clk        ),
		.resetn      (resetn     ),
		.trap        (trap       ),
		.mem_valid   (mem_valid  ),
		.mem_instr   (mem_instr  ),
		.mem_ready   (mem_ready  ),
		.mem_addr    (mem_addr   ),
		.mem_wdata   (mem_wdata  ),
		.mem_wstrb   (mem_wstrb  ),
		.mem_rdata   (mem_rdata  ),
		.irq		 (irq		 ),
		.eoi		 (eoi		 )
	);

	// This signal tells memory and I/O modules when microprocessor is accessing to the native interface
	assign en_mem = mem_valid & !mem_ready;
	assign is_io_address = (mem_addr[31:8] == 24'b0) ? 1'b1 : 1'b0;
	assign en_io_address = en_mem & is_io_address; 
	assign io_address[7:0] = mem_addr[7:0];
	
	//--------------------------------------------------------
	// Program memory
	//--------------------------------------------------------	
	wire cs_prog;
	wire ready_prog;
	assign cs_prog = en_mem & (mem_addr>=PROG_MEM_BASE) & (mem_addr <= PROG_MEM_END);

	memory_nobwe #(.MEM_WORDS(PROG_MEM_SIZE_WORDS),.MEM_INIT_FILE("flash.hex")) prog_memory (
		.clk(clk),
		.cs(cs_prog),
		.addr(mem_addr[($clog2(PROG_MEM_SIZE_WORDS)+1):2]),
		
		.rd_data(mem_rdata_flash),
		.ready(ready_prog)	);

	//--------------------------------------------------------
	// Data memory
	//--------------------------------------------------------

	wire cs_data;
	wire ready_data;
	assign cs_data = en_mem & (mem_addr>=DATA_MEM_BASE) & (mem_addr <= DATA_MEM_END);

	memory_bwe #(.MEM_WORDS(DATA_MEM_SIZE_WORDS)) data_memory (
		.clk(clk),
		.cs(cs_data),
		.wstrb(mem_wstrb),
		.wr_data(mem_wdata),  
		.addr(mem_addr[($clog2(DATA_MEM_SIZE_WORDS)+1):2]),
		
		
		.rd_data(mem_rdata_sram),
		.ready(ready_data)
	); 

	//--------------------------------------------------------
	// Debugging interface
	//--------------------------------------------------------

	always @(posedge clk) begin
		ready_debugging <= 0;
		if (en_mem && (mem_addr == DEBUG_BASE) && mem_wstrb[0]) begin
			ready_debugging <= 1;
			debugdata <= mem_wdata[7:0];
			//$write("%c", mem_wdata[7:0]);
		end
	end

	//--------------------------------------------------------
	// Watchdog timer
	//--------------------------------------------------------

	wire watchdog_cs;		//Chip select according to base address for watchdog
	wire watchdog_reset;	//Output reset from watchdog
	wire ready_watchdog;	//Ready when watchdog accepted memory transaction

	watchdog_timer WDTIMER (
		.clk(clk),
		.resetn_in(resetn),
		.cs(watchdog_cs),
		.wstrb(mem_wstrb),
		.wr_data(mem_wdata),
		.rd_data(mem_rdata_watchdog),
		.addr(io_address),
		.ready(ready_watchdog),
		.resetn_out(watchdog_reset)
	);

	assign watchdog_cs = en_io_address & ((io_address == 8'h08) | (io_address == 8'h0C));
	assign resetn = ext_resetn & !watchdog_reset;


	//--------------------------------------------------------
	// GPIO
	//-------------------------------------------------------

	wire gpio_cs;			//Chip select according to base address for GPIO
	wire ready_gpio;		//Ready when GPIO accepted memory transaction


	//wire tmr_in0 = gpio_pins[10];
	wire tmr_in0;
    wire pwm_outa0;
    wire pwm_outb0;

	//wire tmr_in1 = gpio_pins[13];
	wire tmr_in1;
    wire pwm_outa1;
    wire pwm_outb1;

 	//wire sda = gpio_pins[2];
	wire sda;
    wire scl;

 	//wire mosi;
    //wire miso = gpio_pins[6];
    //wire sclk;
    //wire ss;

	//wire rxd = gpio_pins[0];
    //wire txd;

    wire en_tmr_in0;
    wire en_pwm_outa0;
    wire en_pwm_outb0;
	wire en_tmr_in1;
    wire en_pwm_outa1;
    wire en_pwm_outb1;
	wire en_i2c;
	wire en_spi;
	wire en_uart;


	GPIO_Interface GPIO (
		//Bus interface
		.clk(clk),
		.resetn(resetn),
		.cs(gpio_cs),
		.wstrb(mem_wstrb),
		.wr_data(mem_wdata),
		.rd_data(mem_rdata_gpio),
		.addr(io_address),
		.ready(ready_gpio),
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
		.irq_int0(irq[3]),
		.irq_int1(irq[4]),
		.irq_pinchange(irq[5])		
	);

	assign gpio_cs = en_io_address & (io_address[7:4] == 4'h1);

	//--------------------------------------------------------
	// TIMER0
	//--------------------------------------------------------

	wire timer0_cs;			//Chip select according to base address for TIMER0
	wire ready_timer0;		//Ready when TIMER0 accepted memory transaction

	TIMER_Interface TIMER0 (
		.clk(clk),
		.resetn(resetn),
		.cs(timer0_cs),
		.wstrb(mem_wstrb),
		.wr_data(mem_wdata),
		.rd_data(mem_rdata_timer0),
		.addr(io_address),
		.ready(ready_timer0),

		.tmr_in(tmr_in0),
		.pwm_outa(pwm_outa0),
		.pwm_outb(pwm_outa0),
		.en_tmr_in(en_tmr_in0),
		.en_pwm_outa(en_pwm_outa0),
		.en_pwm_outb(en_pwm_outb0),
		.irq_timer(irq[6])
	);

	assign timer0_cs = en_io_address & ((io_address[7:4] == 4'h2)|(io_address[7:4] == 4'h3));


	//--------------------------------------------------------
	// TIMER1
	//--------------------------------------------------------

	wire timer1_cs;			//Chip select according to base address for TIMER1
	wire ready_timer1;		//Ready when TIMER1 accepted memory transaction

	TIMER_Interface TIMER1 (
		.clk(clk),
		.resetn(resetn),
		.cs(timer1_cs),
		.wstrb(mem_wstrb),
		.wr_data(mem_wdata),
		.rd_data(mem_rdata_timer1),
		.addr(io_address),
		.ready(ready_timer1),

		.tmr_in(tmr_in1),
		.pwm_outa(pwm_outa1),
		.pwm_outb(pwm_outa1),
		.en_tmr_in(en_tmr_in1),
		.en_pwm_outa(en_pwm_outa1),
		.en_pwm_outb(en_pwm_outb1),
		.irq_timer(irq[7])
	);

	assign timer1_cs = en_io_address & ((io_address[7:4] == 4'h4)|(io_address[7:4] == 4'h5));


	//--------------------------------------------------------
	// UART
	//--------------------------------------------------------

	wire uart_cs;			//Chip select according to base address for UART
	wire ready_uart;		//Ready when UART accepted memory transaction
    
	UART_Interface UART (
		.clk(clk),
		.resetn(resetn),
		.cs(uart_cs),
		.wstrb(mem_wstrb),
		.wr_data(mem_wdata),
		.rd_data(mem_rdata_uart),
		.addr(io_address),
		.ready(ready_uart),

		.rxd(rxd),	
		.txd(txd),
		.en_uart(en_uart),
		.irq_uart_rx(irq[10]),
		.irq_uart_tx(irq[11])
	);

	assign uart_cs = en_io_address & (io_address[7:4] == 4'h6);


	//--------------------------------------------------------
	// I2C
	//--------------------------------------------------------

	wire i2c_cs;		//Chip select according to base address for I2C
	wire ready_i2c;		//Ready when I2C accepted memory transaction
    
	I2C_Interface I2C (
		.clk(clk),
		.resetn(resetn),
		.cs(i2c_cs),
		.wstrb(mem_wstrb),
		.wr_data(mem_wdata),
		.rd_data(mem_rdata_i2c),
		.addr(io_address),
		.ready(ready_i2c),

		.sda(sda),
		.scl(scl),
		.en_i2c(en_i2c),
		.irq_i2c(irq[8])
	);

	assign i2c_cs = en_io_address & (io_address[7:4] == 4'h7);


	//--------------------------------------------------------
	// SPI
	//--------------------------------------------------------

	wire spi_cs;		//Chip select according to base address for SPI
	wire ready_spi;		//Ready when SPI accepted memory transaction
    
	SPI_Interface SPI (
		.clk(clk),
		.resetn(resetn),
		.cs(spi_cs),
		.wstrb(mem_wstrb),
		.wr_data(mem_wdata),
		.rd_data(mem_rdata_spi),
		.addr(io_address),
		.ready(ready_spi),

		.mosi(mosi),
		.miso(miso),
		.sclk(sclk),
		.ss(ss),
		.en_spi(en_spi),
		.irq_spi(irq[9])
	);

	assign spi_cs = en_io_address & (io_address[7:4] == 4'h8);


	//--------------------------------------------------------
	// Ready interconnect
	//--------------------------------------------------------

	assign mem_ready = ready_prog | ready_data | ready_debugging | 
						ready_watchdog | ready_gpio | ready_timer0 | ready_timer1 | 
						ready_uart | ready_i2c | ready_spi;


	// Multiplexer 
	always @(*) begin
		case({ ready_prog, ready_data, ready_watchdog, ready_gpio, ready_timer0, ready_timer1,ready_uart,ready_i2c,ready_spi})
			9'b100000000: mem_rdata<=mem_rdata_flash;
			9'b010000000: mem_rdata<=mem_rdata_sram;
			9'b001000000: mem_rdata<=mem_rdata_watchdog;
			9'b000100000: mem_rdata<=mem_rdata_gpio;
			9'b000010000: mem_rdata<=mem_rdata_timer0;
			9'b000001000: mem_rdata<=mem_rdata_timer1;
			9'b000000100: mem_rdata<=mem_rdata_uart;
			9'b000000010: mem_rdata<=mem_rdata_i2c;
			9'b000000001: mem_rdata<=mem_rdata_spi;
			default: mem_rdata<=32'd0;
		endcase
	end

endmodule

