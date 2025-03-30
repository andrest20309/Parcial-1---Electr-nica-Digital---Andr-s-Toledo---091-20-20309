# Parcial 1 Electronica_Digital_Andres-Toledo_091-20-20309
Repositorio que engloba todo lo solicitado para el parcial numero 1 de la clase de electronica digital. 

[![Review Assignment Due Date](https://classroom.github.com/assets/deadline-readme-button-22041afd0340ce965d47ae6ef1cefeee28c7c493a6346c4f15d667ab976d596c.svg)](https://classroom.github.com/a/IxX6jphl)

## video explicativo: [Link: FSM Moore - aspiradora](https://youtu.be/PKCDxPp7X8s)
## Link a video Explicativo de simulacion vivado: [Link Explicacion de Simulacion](https://youtu.be/-G110fX8Qe0)
---
# Aspiradora Automatica (solo tipo Moore) - Implementacion y codigo de VIVADO.

Entonces primero comence por hacer la tabal de verdad. Esta esta basada en basicamente cuatro estados y cuatro entradas para definir tambien los cambios de estado. Se puede ver cual es el estado actual y cual seria el siguiente si determinada entrada se activa. Bien es facil notar que hay estados que no concuerdan entre si, es decir que aun con una tabla pequena, habran estados que jamas se van a utilizar por logica. Tambien hay estados que basicamente se ignoran.

En el fondo a la derecha se pueden observar las ecuciones logicas. Estas las obtuve con logisim a partir de tablas. Aun asi obtenia problemas con el circuito y los estados extra que no eran logicos, finalmente llegue a la conclusion de que el estado de bateria "alta o baja" no tenia mucho sentido al ser muy similar al estado del boton on / off. Por lo cual opte por suprimirla para simplificar las cosas.
 
![Tabla_aspiradora](https://github.com/user-attachments/assets/d8e339c6-99e6-417f-94ee-402b87a4a7ea)

Estas son las ecuaciones obtenidas. on/off , Su = suciedad, obs = obstaculo.

- Ecuaciones SOP del circuito:

- S0= Q1*Su + Q0*Q1' *obs + Q0' *Q1*obs
- R0= Q0*Q1'*obs + Q0*Q1'*obs'					

- S1 = Q0'*Q1'*on/off  + Q1'*Q0*Su' + Q0'*Q1'*Su
- R1 = on/off' *Q0' Su' + Q0*Q1*obs'Su		
 
![image](https://github.com/user-attachments/assets/97772f35-ec45-43d2-8197-9966bf553af8)

Este seria el digrama logico obtenido previo a realizar el circuito, y se pueded ver como practivamente el boton on/off y la bateria, tienen casi el mismo funcionamiento, por lo cual al realizar las ecuaciones logicas casi que boton on/off y bateria, eran casi lo mismo y resultaban redundantes.
![Tabla_aspiradora2](https://github.com/user-attachments/assets/47125161-a0f2-45b1-a4ac-ddf334b63bb0)

Este es el circuito realizado a partir de las ecuaciones logicas. Basicamente el comportamiento se basa en que:
- el boton esta en On -- > estado explorar .
- el boton esta en On y hay obstaculo -- > estado evitar.
- si ya no hay obstaculo --> regresa a explorar.
- el boton esta en On y hay suciedad --> estado aspirar.
- si ya no hay suciedad --> regresa a explorar.
- finalmente en cualquier estado, si el boton esta en off --> se regresa al estado de reposo.
  
![circuito](https://github.com/user-attachments/assets/9ad6002e-cee1-43c3-9b7f-0c4f3597b8e1)

---
# Timing Analisys
Utilizando compuertas de la familia 74LS
- AND (74LS08) = 10 ns = tp
- OR (74LS32) = 10 ns = tp
- Flip-Flop RS (74LS279) = 15 ns = tp

- Entrada S0 = (3 And 1 OR) = ts0 = tand +tor = 10+10 = 20 ns.
- Entrada R0 = (2 And + 1 OR) = tr0 = tand + tor = 10+10 = 20 ns.

- Entrada S1 = (3 And + 1 OR) = ts1 = tand + tor = 10+10 = 20 ns.
- Entrada R1 = (2 And + 1 OR) = tr1 = tand +tor = 10+10 = 20 ns.

- Tiempo total con flip-flops = 35 ns. Este seria el tiempo para cada cambio de Q  en cualquiera de los dos flip-flops.
- La frecuencia maxima a la que podria operar el circuito es: 1/(35x10^-9) = 28.57 Mhz
---
# Implementacion en Vivado 2024.2
## FSM Aspiradora
### Código: (el codigo esta comentado, realmente no es muy complejo).

```systemverilog
`timescale 10 ns / 1ps
// definicion de entradas y salidas, al ser "semi-automatica" no requiere salidas en realidad.
module FSM_Aspiradora  (input logic clk,
                        input logic power_off,
                        input logic on,
                        input logic cleaning,
                        input logic evading,
                        output logic [1:0] state_0); // Solo para visualizar el estado.
// Se definen y enumeran los estados                        
typedef enum logic [1:0] {off_s, exploring_s, cleaning_s, evading_s} state_type;

// registro de estados
state_type state, next_state;

//typedef enum logic [1:0]{
//    off_s = 2'b00,
//    exploring_s = 2'b01,
//    cleaning_s = 2'b10,
//    evading_s = 2'b11
//    } state_type;
//state_type state, next_state;

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

assign state_0 = state; // se asigna el estado actual a la variable para visualizarlo. No tienen otro proposito.

endmodule
```
## Esquematico generado por vivado:
![implementacion_vivado](https://github.com/user-attachments/assets/7bf1f161-e4ee-4ed5-80b0-f0c2eb3c76cd)
## Simulacion del circuito en vivado:
## Link a video Explicativo: [Link Explicacion de Simulacion](https://youtu.be/-G110fX8Qe0)
![Simulacion Vivado](https://github.com/user-attachments/assets/7275aa4a-b134-4c8b-b78f-20c810aabd2b)

### Informacion del codigo, algunos puntos:

- typedef:

Se utiliza para definir un nuevo nombre o alias para un tipo de dato.
En el código, se usa para crear un tipo enumerado (enum) que representa los estados de la máquina, facilitando la lectura y el mantenimiento del código.

- enum:

Es una forma de definir un tipo que puede tener un conjunto limitado de valores nombrados, es decir, una enumeración.
En el ejemplo, se usa para definir los distintos estados de la máquina (por ejemplo, OFF_STATE, EXPLORING_STATE, etc.), de manera que cada estado se identifica de forma clara y única.

- always_ff

Es un bloque de código que se utiliza para describir lógica secuencial basada en flip-flops (registro).
La sintaxis always_ff @(posedge clk or posedge reset) indica que el bloque se evaluará en el flanco de subida del reloj (o del reset, si se utiliza reset asíncrono).
Garantiza que la asignación de valores a los registros se haga de forma secuencial, como en un circuito con memoria.

- always_comb:

Es un bloque que se utiliza para describir lógica combinacional.
Todas las asignaciones dentro de este bloque se realizan de manera "instantánea" (sin retardo secuencial) en función de los valores actuales de las señales de entrada.
Ayuda a evitar errores comunes (como asignaciones múltiples en bloques combinacionales) y asegura que se inferirá lógica combinacional correctamente.

- posedge:

Significa "flanco de subida" (de 0 a 1).
Se usa en la sensibilidad de los bloques always_ff para indicar que se debe evaluar el bloque cada vez que la señal de reloj cambia de 0 a 1, lo cual es típico para actualizar registros en lógica secuencial.

- begin y end:

Son palabras clave que se usan para delimitar un bloque de sentencias.
En estructuras condicionales o de procesos (como dentro de un always_ff o always_comb), begin marca el inicio y end el final del bloque de instrucciones que se deben ejecutar como un grupo.
Esto es útil para agrupar múltiples sentencias cuando se requiere ejecutar varias instrucciones en una misma rama condicional.

---
## C3C Calculos 

El ultimo numero de mi carne es: 9. Entonces 9 + 5 = 14 GB.
Entonces en GiB = 14GB / (2^30) =  (14x10^9) / (2^30) = 13.03 GiB.
De modo que se trata de 0.7 GiB extra que el fabricante incluye.
En KiB = (GiB x 2^10) = 13.03 x 1024 = 13,341 KiB.
Y en TiB = GiB / 2^10 = 13.03 / 1024 = 0.0127 TiB.

## ¿Por qué los fabricantes usan GB en lugar de GiB?
Los fabricantes de almacenamiento utilizan GB (decimal) en lugar de GiB (binario) por razones comerciales:

- Marketing y percepción de mayor capacidad
Un disco de "225 GB" suena más grande que uno de "209.53 GiB" (valor real en binario).
Esto genera la impresión de mayor almacenamiento, aunque en la práctica el sistema operativo lo interpreta en GiB.

- Estándares industriales y facilidad de comunicación
La industria tecnológica ha adoptado el sistema decimal porque es más fácil de entender para el consumidor general.
La conversión binaria (GiB) es utilizada principalmente por software y sistemas operativos.

- Compatibilidad con otros dispositivos
En electrónica y telecomunicaciones, se usan múltiplos de 10 en otras unidades (MHz, Mbps, etc.), por lo que mantener GB facilita la estandarización.

- Entonces por ejemplo mi disco duro es de 225 GB.
GiB = 225x(10^9) / (2^30) = 209.53 GiB.
225 - 209.53 = 15.47 GB

- El porcentaje de  almacenamiento inflado es entonces (15.47/225)*100 = 6.87%
