`timescale 100ns / 1ps
// definicion de entradas y salidas, al ser "semi-automatica" no requiere salidas en realidad.
module FSM_Aspiradora  (input logic clk,
                        input logic power_off,
                        input logic on,
                        input logic cleaning,
                        input logic evading);
                        //output logic [1:0] visual_state); // Solo para visualizar el estado.
                        
//// Se definen y enumeran los estados                        
//typedef enum logic [1:0] {off_s, exploring_s, cleaning_s, evading_s} state_type;

//// registro de estados
//state_type state, next_state;

typedef enum logic [1:0]{
    off_s = 2'b00,
    exploring_s = 2'b01,
    cleaning_s = 2'b10,
    evading_s = 2'b11
    } state_type;
state_type state, next_state;

// registro de estado de power_off, logica secuencial a base de flip-flops
always_ff @(posedge clk or posedge power_off) begin // posedge -> flanco positivo.
                                           // begin y end
                                           // sirven para delimitar un bloque de sentencias.
    if(power_off) // se fuerza un reset que es asincrono, este puede darse en cualquier
        state <= off_s;// momento de la "ejecucion".
    else 
        state <= next_state; // de lo contrario, se carga el next state en cada cambio de flanco
end                          // positivo del reloj.

// la logica combinacional del cambio de estados:

always_comb begin // bloque de logica combinacional.   
    next_state = state; // si no hay cambios, se queda en el estado actual.    
    case (state)  
          
        off_s: begin
            if (on)
            // solo se sale de off si on se activa y automaticamente ira a explorar.
                next_state = exploring_s;
            else 
            // si on no se activa, la aspiradora se quedaria en reposo.
                next_state = off_s;
        end
        
        exploring_s: begin // mientras la aspiradora explora tiene 3 posibles estados que le sigan:
            if (power_off) // si hay senal de apagado, pues la aspiradora se apaga.
                next_state = off_s;
            else if (cleaning)  // si hay senal de suciedad, pues la aspiradora comenzara a limpiar.
                next_state = cleaning_s;
            else if (evading)// si hay senal de obstaculo, pues esquiva el obstaculo.
                next_state = evading_s;
            else // si no se da uno de los casos anteriores, la aspiradora continua explorando.
                next_state = exploring_s;
        end
        
        cleaning_s: begin // es el bloque para los cambios de estado mientras "aspira"
            if (power_off) // si hay senal de apagado, pues la aspiradora se apaga.
                next_state = off_s;
            else if (!cleaning) // si no hay senal de suciedad, la aspiradora regresa a explorar.
                next_state = exploring_s; 
            else // si no hay cambios en los inputs, la aspiradora sigue limpiando (aspirando).
                next_state = cleaning_s;
            end
            
        evading_s: begin
            if (power_off) // si hay senal de apagado, la aspiradora se apaga.
                next_state = off_s;
            else if (!evading) // si deja de haber obstaculo, la aspiradora continua explorando.
                next_state = exploring_s;
            else // si no hay cambios en los inputs, la aspiradora continuara explorando.
                next_state = evading_s; 
            end
    endcase // se terminan los posibles casos o mas bien, casos de cambios de estado.
end // termina bloque de logica secuencial.

//assign visual_state = state; // se asigna el estado actual a la variable para visualizarlo. No tienen otro proposito.

endmodule        