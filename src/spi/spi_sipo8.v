module spi_sipo8(
    input clk,                  // Reloj del sistema
    input load,                 // Señal para cargar nuevos datos
    input [7:0] data_tx,        // Entrada paralela de datos
    input serial_in_msb,        // Entrada serial por el bit más significativo
    input serial_in_lsb,        // Entrada serial por el bit menos significativo
    input direction,            // Dirección de corrimiento (0: derecha, 1:izquierda)
    output reg [7:0] data_rx   // Salida paralela de datos recibidos
);
    
    always @(posedge clk)
    begin
        if (load) begin
            data_rx <= data_tx;     // Cargar datos paralelos en el registro
        end else if (direction) begin
                data_rx <= data_rx << 1;
                data_rx[0] <= serial_in_lsb;
            end else begin
                data_rx <= data_rx >> 1;
                data_rx[7] <= serial_in_msb;
            end
    end

endmodule

