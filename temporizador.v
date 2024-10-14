// Módulo do decodificador de 7 segmentos
module decodificador_7segmentos (
    input [3:0] valor,         // Entrada de 0 a 9 (4 bits)
    output reg [6:0] segmentos // Saída para os 7 segmentos (a, b, c, d, e, f, g)
);

    always @(*) begin
        case (valor)
            4'b0000: segmentos = 7'b0111111; // '0'
            4'b0001: segmentos = 7'b0000110; // '1'
            4'b0010: segmentos = 7'b1011011; // '2'
            4'b0011: segmentos = 7'b1001111; // '3'
            4'b0100: segmentos = 7'b1100110; // '4'
            4'b0101: segmentos = 7'b1101101; // '5'
            4'b0110: segmentos = 7'b1111101; // '6'
            4'b0111: segmentos = 7'b0000111; // '7'
            4'b1000: segmentos = 7'b1111111; // '8'
            4'b1001: segmentos = 7'b1101111; // '9' 
            default: segmentos = 7'b0000000; // Apaga o display em caso inválido
        endcase
    end

endmodule

// Módulo do cronômetro digital
module cronometro_digital(
    input clk,              // Clock principal do sistema
    input reset,            // Botão de reset
    input botao0,           // Botão para alternar entre estados
    input botao1, 
    input SW3,          // Botão para incrementar valores
    input botao2,           // Botão para parar/continuar a contagem
    output reg [6:0] seg_hora_d,   // Display para dígitos das horas (dezenas)
    output reg [7:0] seg_hora_u,   // Display para dígitos das horas (unidades)
    output reg [6:0] seg_minuto_d, // Display para dígitos dos minutos (dezenas)
    output reg [6:0] seg_minuto_u, // Display para dígitos dos minutos (unidades)
    output reg [5:0] leds_segundos, // LEDs para contagem dos segundos
    output reg estado1, 
    output reg estado2,
    output reg estado3// LEDs de estados
);

    // Registrador de estado
    reg [2:0] estado;
    reg [5:0] segundos;        // Agora 6 bits para suportar até 59
    reg [4:0] unidademinutos;
    reg [4:0] dezenaminutos;  
    reg [4:0] unidadehoras;    // Unidade das horas
    reg [4:0] dezenahoras;     // Dezena das horas

    parameter PARADO = 3'b000,
              AJUSTAR_SEGUNDOS = 3'b001,
              AJUSTAR_MINUTO = 3'b010,
              AJUSTAR_HORA = 3'b011,
              RODANDO = 3'b111;

    // Instâncias do decodificador
    decodificador_7segmentos u_hora_d (.valor(dezenahoras), .segmentos(seg_hora_d));
    decodificador_7segmentos u_hora_u (.valor(unidadehoras), .segmentos(seg_hora_u[6:0]));
    decodificador_7segmentos u_minuto_d (.valor(dezenaminutos), .segmentos(seg_minuto_d));
    decodificador_7segmentos u_minuto_u (.valor(unidademinutos), .segmentos(seg_minuto_u));

    // Lógica do cronômetro
    always @(posedge clk or posedge reset) begin 
        if (reset) begin
            estado <= PARADO;  // Inicializa o estado como PARADO
            // Inicializa todos os segmentos para mostrar 00:00
            segundos <= 0; // Inicializa os segundos como 0
            leds_segundos <= 6'b000000; // Inicializa LEDs apagados
            unidademinutos <= 0; // Inicializa unidade de minutos
            dezenaminutos <= 0; // Inicializa dezena de minutos
            unidadehoras <= 0;   // Inicializa unidade de horas
            dezenahoras <= 0;    // Inicializa dezena de horas
            seg_hora_u[7] <= 1'b1;
        end else begin 
            case (estado)
                PARADO: begin
                    if (botao0) begin
                        estado <= AJUSTAR_SEGUNDOS; // Muda para ajustar segundos
                        estado1 = 1'b1;
                    end 
                    if (botao2) begin 
                        estado1 = 1'b0;
                        estado2 = 1'b0;
                        estado3 = 1'b0;
                        estado <= RODANDO;  
                    end 
                    if (reset) begin 
                        estado1 = 1'b0;
                        estado2 = 1'b0;
                        estado3 = 1'b0;
                    end
                end
                
                AJUSTAR_SEGUNDOS: begin
                    if (botao1) begin
                        if (segundos < 60) begin // Limite de segundos
                            segundos <= segundos + 10; // Incrementa segundos
                            leds_segundos <= {leds_segundos[5:0], 1'b1}; // Acende LEDs
                        end
                    end else if (botao0) begin 
                        estado <= AJUSTAR_MINUTO; // Muda para ajustar minutos
                        estado2 = 1'b1;
                    end if (reset) begin 
                        estado1 = 1'b0;
                    end
                end
                
                AJUSTAR_MINUTO: begin
                     if (botao1 && !SW3) begin
                        if (unidademinutos < 9) begin
                            unidademinutos <= unidademinutos + 1; // Incrementa unidade de minutos
                        end else if (dezenaminutos < 5 && unidademinutos ==9) begin
                            unidademinutos <= 0; // Reseta unidade de minutos
                            dezenaminutos <= dezenaminutos + 1; // Incrementa dezena de minutos
                        end else begin
                            unidademinutos <= 0; // Reseta unidade de minutos
                            dezenaminutos <= 0; // Reseta dezena de minutos
                        end
                    end
                        if (botao1 && SW3) begin 
                        if (dezenaminutos <5) begin
                            dezenaminutos <= dezenaminutos + 1;
                        end else if (dezenaminutos == 5 && unidademinutos == 9) begin 
                              dezenaminutos <= 0;
                              unidademinutos <= 0;
                        end
                     end
                    
                    if (botao0) begin
                        estado <= AJUSTAR_HORA; // Muda para ajustar horas
                        estado3 = 1'b1;
                    end 
                    if (reset) begin 
                        estado1 = 1'b0;
                        estado2 = 1'b0;
                    end
                end

                AJUSTAR_HORA: begin
                    if (botao1) begin
                        if (unidadehoras < 9) begin
                            unidadehoras <= unidadehoras + 1; // Incrementa unidade das horas
                        end else if (unidadehoras == 9 && dezenahoras < 2) begin
                            unidadehoras <= 0; // Reseta unidade de horas
                            dezenahoras <= dezenahoras + 1; // Incrementa dezena de horas
                        end
                    end 
                    
                    // Reseta as horas se passar de 24
                    if (dezenahoras == 2 && unidadehoras == 4) begin
                        unidadehoras <= 0; // Reseta unidade de horas
                        dezenahoras <= 0; // Reseta dezena de horas
                    end

                    if (botao0) begin
                        estado <= RODANDO; // Muda para rodando
                        estado1 = 1'b0;
                        estado2 = 1'b0;
                        estado3 = 1'b0;
                    end
                    
                end

                RODANDO: begin
                    if (botao2 == 1'b1) begin
                        estado <= PARADO; // Para o cronômetro
                    end else begin
                        if (segundos > 0) begin
                            segundos <= segundos - 1; // Decrementa segundos se maior que zero
                            if (segundos %10 ==0) begin// Acende o LED correspondente ao segundo
                            leds_segundos <= {leds_segundos[5:0], 1'b0}; 
                            end
                        end else begin
                            // Se os segundos são zero, precisamos ajustar os minutos
                            segundos <= 59; // Reinicia os segundos para 59
                            if (unidademinutos > 0) begin
                                unidademinutos <= unidademinutos - 1; // Decrementa unidade de minutos
                            end else if (dezenaminutos > 0) begin
                                unidademinutos <= 9; // Ajusta unidade de minutos para 9
                                dezenaminutos <= dezenaminutos - 1; // Decrementa dezena de minutos
                            end else begin
                                // Se os minutos já são zero, precisamos ajustar as horas
                                unidademinutos <= 0;
                                dezenaminutos <= 0; // Ajusta os minutos para 59
                                if (unidadehoras > 0) begin
                                    unidadehoras <= unidadehoras - 1; // Decrementa unidade de horas
                                end else if (dezenahoras > 0) begin
                                    unidadehoras <= 9; // Ajusta unidade de horas para 9
                                    dezenahoras <= dezenahoras - 1; // Decrementa dezena de horas
                                end
                                if ( estado == RODANDO && unidademinutos == 0 && segundos == 0 && dezenaminutos == 0 && unidadehoras ==0 && dezenahoras ==0) begin
                                    estado<= PARADO;
                                    leds_segundos <= {leds_segundos[5:0], 10'b111111}; 
                                end
                                if (reset) begin 
                                    estado1 = 1'b0;
                                    estado2 = 1'b0;
                                    estado3 = 1'b0;
                                end
                            end
                        end
                    end
                end
                
                default: estado <= PARADO; 
            endcase
        end
    end
endmodule
