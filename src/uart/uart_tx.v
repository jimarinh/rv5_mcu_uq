module uart_tx (
    input  wire UART_CLK,
    input  wire nRST,
    input  wire UART_WRITE,         //Bandera para iniciar la transmisión
    input  wire UART_BITS,          //Transmisión a 7 u 8 bits
    input  wire UART_STOPBITS,      //Número de bits de parada
    input  wire [1:0] UART_PARITY,  //Tipo de paridad en la transmisión
    input  wire [7:0] DATA_IN_Tx,   // 8 bits de datos de entrada para transmitir

    output reg DATA_OUT_Tx, // Dato de salida de transmisión serial
    output reg IRQ_Tx       // Señal de interrupción que indica que la transmisión ha terminado
);
  
    // Estados de la máquina de estados
    localparam  IDLE = 4'b0000,  // Estado inactivo
                START = 4'b0001, // Estado de inicio, transmitiendo bit de inicio (0)
                BIT_0 = 4'b0010, // Transmitir el primer bit de datos
                BIT_1 = 4'b0011, // Transmitir el segundo bit de datos
                BIT_2 = 4'b0100, // Transmitir el tercer bit de datos
                BIT_3 = 4'b0101, // Transmitir el cuarto bit de datos
                BIT_4 = 4'b0110, // Transmitir el quinto bit de datos
                BIT_5 = 4'b0111, // Transmitir el sexto bit de datos
                BIT_6 = 4'b1000, // Transmitir el séptimo bit de datos
                BIT_7 = 4'b1001, // Transmitir el octavo bit de datos
                PARITY= 4'b1010, // Transmitir bit de paridad (si se utiliza)
                STOP1 = 4'b1011,  // Transmitir bit de parada (1)
                STOP2 = 4'b1100;  // Transmitir bit de parada (1)

    // Valores para paridad
    parameter   EVEN = 2'b01,   // Paridad par
                ODD = 2'b10,    // Paridad impar
                No_parity = 2'b00; // Sin paridad

    // Registro para controlar el estado actual de la FSM y el siguiente estado
    reg  [3:0] state;
    wire [3:0] next;
    wire parity_bit; // Registro para almacenar el bit de paridad calculado

    // Máquina de estados (FSM) que controla la transmisión de los bits
    always @(posedge UART_CLK) begin
        if (!nRST)               // Si el reset es bajo, el estado se pone a IDLE
            state <= IDLE;
        else
            state <= next;      // Si no, se cambia al siguiente estado
    end

    // Lógica de transición de la máquina de estados
    assign next =
        (state == IDLE) ?
            (UART_WRITE ? START : IDLE) :   // Si UART_WRITE es activado, pasa al estado START
        (state == START) ?                 
            BIT_0 :                         // Pasa al primer bit de datos     
        (state == BIT_0) ?
            BIT_1 :                         // Pasa al siguiente bit
        (state == BIT_1) ?
            BIT_2 :                         // Pasa al siguiente bit
        (state == BIT_2) ?
            BIT_3 :                         // Pasa al siguiente bit
        (state == BIT_3) ?
            BIT_4 :                         // Pasa al siguiente bit
        (state == BIT_4) ?
            BIT_5 :                         // Pasa al siguiente bit
        (state == BIT_5) ?
            BIT_6 :                         // Pasa al siguiente bit
        (state == BIT_6) ?
            (UART_BITS ? BIT_7 :            // Si se usan 8 bits, pasa al siguiente bit
            (UART_PARITY != No_parity ? PARITY : STOP1)) :  // Si hay paridad, pasa al estado de paridad, sino pasa al estado de STOP
        (state == BIT_7) ?
            (UART_PARITY ? PARITY : STOP1) :// Si hay paridad, pasa a paridad, de lo contrario, a STOP
        (state == PARITY) ?
            STOP1 :                         // Después de paridad, pasa a STOP
        (state == STOP1) ?
            ((UART_STOPBITS == 1'b0) ? IDLE : STOP2) :  // Revisa si requiere 2 bits de parada
        (state == STOP2) ?
            IDLE :  // Después del bit de parada, vuelve al estado IDLE
        IDLE;   



    // Calcula bit de paridad
    assign parity_bit = (^{DATA_IN_Tx[7] & UART_BITS, DATA_IN_Tx[6:0]}) ^ (UART_PARITY==ODD);

    // Lógica que controla la salida `DATA_OUT_Tx` y la interrupción `IRQ_Tx`
    always @(posedge UART_CLK) begin
        if (!nRST) begin
            DATA_OUT_Tx <= 1'b1;   // En reset, la salida de datos es 1 (inactivo)
            IRQ_Tx <= 1'b0;         // La interrupción está desactivada
        end else begin
            case (state)
                IDLE:  begin DATA_OUT_Tx <= 1'b1; IRQ_Tx <= 1'b0; end
                START: DATA_OUT_Tx <= 1'b0; // El bit de inicio es 0
                BIT_0: DATA_OUT_Tx <= DATA_IN_Tx[0];   // Transmitir el primer bit
                BIT_1: DATA_OUT_Tx <= DATA_IN_Tx[1];   // Transmitir el segundo bit
                BIT_2: DATA_OUT_Tx <= DATA_IN_Tx[2];   // Transmitir el tercer bit
                BIT_3: DATA_OUT_Tx <= DATA_IN_Tx[3];   // Transmitir el cuarto bit
                BIT_4: DATA_OUT_Tx <= DATA_IN_Tx[4];   // Transmitir el quinto bit
                BIT_5: DATA_OUT_Tx <= DATA_IN_Tx[5];   // Transmitir el sexto bit
                BIT_6: DATA_OUT_Tx <= DATA_IN_Tx[6];   // Transmitir el séptimo bit
                BIT_7: DATA_OUT_Tx <= DATA_IN_Tx[7];   // Transmitir el octavo bit
                PARITY: DATA_OUT_Tx <= parity_bit;     // Transmitir el bit de paridad
                STOP1:  begin
                            DATA_OUT_Tx <= 1'b1;  // El bit de parada es 1
                            if (UART_STOPBITS==1'b0) IRQ_Tx <= 1'b1;       // La interrupción se activa, indicando que la transmisión ha terminado
                        end
                STOP2: begin
                            DATA_OUT_Tx <= 1'b1;  // El bit de parada es 1
                            IRQ_Tx <= 1'b1;       // La interrupción se activa, indicando que la transmisión ha terminado
                        end 
            endcase
        end
    end
endmodule