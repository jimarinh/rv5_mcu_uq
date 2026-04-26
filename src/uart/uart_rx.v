module uart_rx (
    input wire UART_CLK,            // Señales de reloj y reset
    input wire nRST,    

    input wire DATA_IN_Rx,          // Entrada de datos de recepción UART (bit de entrada serial)
    input wire UART_BITS,           // Transmisión a 7 u 8 bits
    input wire [1:0] UART_PARITY,   // Tipo de paridad en la transmisión    

    output reg IRQ_Rx,              // Salida de interrupción que indica que la recepción ha terminado
    output wire [7:0] DATA_OUT_Rx,  // Salida de datos recibidos, 8 bits
    output wire UART_PARITY_ERR,    // Chequeo de la paridad
    output wire IDLE                // Indica si el sistema en modo de espera (IDLE)
);

    // Asegura que el bit más significativo en transmisión de 7 bits siempre sea cero
    reg [7:0] rx_reg;
    assign DATA_OUT_Rx = {rx_reg[7] & (UART_BITS), rx_reg[6:0]};

    // Definición de los estados del FSM (Máquina de Estados Finita) de recepción
    localparam  WAIT = 4'b0000,      // Estado de reposo (sin actividad)
                BIT_0 = 4'b0001,    // Recibiendo el bit 0
                BIT_1 = 4'b0010,    // Recibiendo el bit 1
                BIT_2 = 4'b0011,    // Recibiendo el bit 2
                BIT_3 = 4'b0100,    // Recibiendo el bit 3
                BIT_4 = 4'b0101,    // Recibiendo el bit 4
                BIT_5 = 4'b0110,    // Recibiendo el bit 5
                BIT_6 = 4'b0111,    // Recibiendo el bit 6
                BIT_7 = 4'b1000,    // Recibiendo el bit 7
                PARITY= 4'b1001,    // Estado de paridad
                STOP =  4'b1010;    // Fin de la recepción


    // Definición de valores de paridad
    parameter   EVEN = 2'b01,        // Paridad par
                ODD = 2'b10,         // Paridad impar
                No_parity = 2'b00;   // Sin paridad

    reg [3:0] state;        // Registro para el estado actual y el siguiente
    wire [3:0] next;          
    wire check_parity;

    assign IDLE = (state == WAIT);
    assign check_parity = (UART_PARITY!=2'b00);

    // Bloque de transición de estados (FSM)
    always @(posedge UART_CLK) begin
        if (!nRST)                  // Si el reset está activo, se va al estado WAIT
            state <= WAIT;
        else 
            state <= next;          // De lo contrario, se transita al siguiente estado
    end

    // Lógica combinacional para determinar el siguiente estado en función del estado actual
    assign next =
        (state == WAIT) ?
            (!DATA_IN_Rx ? BIT_0 : WAIT) :   // Si la señal de entrada es baja, se inicia la recepción
        (state == BIT_0) ? BIT_1 :           // Transiciones para recibir los 8 bits de datos
        (state == BIT_1) ? BIT_2 :
        (state == BIT_2) ? BIT_3 :
        (state == BIT_3) ? BIT_4 :
        (state == BIT_4) ? BIT_5 :
        (state == BIT_5) ? BIT_6 :
        (state == BIT_6) ?
            (UART_BITS ? BIT_7 :            // Si se usan 8 bits, pasa al siguiente bit
            (check_parity ? PARITY : STOP)) ://Si son 7 bits pasa al estado PARITY donde se verifica la paridad
        (state == BIT_7) ?
            (check_parity ? PARITY : STOP) :
        (state == PARITY) ?
            STOP :
        (state == STOP) ?
            WAIT :
        WAIT;


    // Lógica para calcular el error de paridad
    reg parity_bit;
    
    assign UART_PARITY_ERR = check_parity ? 
            ((^DATA_OUT_Rx) ^ (UART_PARITY==ODD) ^ parity_bit) : 
            1'b0;

    // Lógica secuencial para actualizar las señales y almacenar los datos recibidos
    always @(posedge UART_CLK) begin
        if (!nRST) begin
            rx_reg <= 8'h00;  // Restablecer la salida de datos
            IRQ_Rx <= 1'b0;        // Indicar que no hay datos disponibles
            parity_bit <= 1'b0;
        end else begin
            case (state)
                WAIT:  IRQ_Rx <= 1'b0;
                BIT_0: rx_reg[0] <= DATA_IN_Rx;  // Almacenar el bit 0
                BIT_1: rx_reg[1] <= DATA_IN_Rx;  // Almacenar el bit 1
                BIT_2: rx_reg[2] <= DATA_IN_Rx;  // Almacenar el bit 2
                BIT_3: rx_reg[3] <= DATA_IN_Rx;  // Almacenar el bit 3
                BIT_4: rx_reg[4] <= DATA_IN_Rx;  // Almacenar el bit 4
                BIT_5: rx_reg[5] <= DATA_IN_Rx;  // Almacenar el bit 5
                BIT_6: rx_reg[6] <= DATA_IN_Rx;  // Almacenar el bit 6
                BIT_7: rx_reg[7] <= DATA_IN_Rx;  // Almacenar el bit 7
                PARITY: parity_bit <= DATA_IN_Rx;  // Almacenar bit de paridad 
                STOP: IRQ_Rx <= 1'b1;            // Indicar que los datos están disponibles
            endcase
        end
    end

endmodule
