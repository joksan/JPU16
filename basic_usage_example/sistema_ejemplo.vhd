-- Ejemplo de aplicacion de JPU16
-- ------------------------------
-- Autor: Joksan Alvarado
--
-- La siguiente entidad VHDL es un ejemplo simple de como conectar un solo puerto de salida al
-- procesador JPU16 para controlar 8 LEDs al exterior del FPGA. Vease el archivo "readme_es.txt"
-- para mas informacion acerca de como integrarlo a un proyecto de ISE y correr el programa de
-- demostracion.

------------------------------------------------------------
-- Entidad del sistema completo que incluye el procesador --
------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use work.JPU16_Pack.all;

entity Sistema_Ejemplo is
   port (OscIn:   in  STD_LOGIC;
         DataOut: out STD_LOGIC_VECTOR (7 downto 0));
end Sistema_Ejemplo;

architecture Funcionamiento of Sistema_Ejemplo is
   --Señales asociadas al bus de salida
   signal IO_Sal: STD_LOGIC_VECTOR (15 downto 0);
   signal IO_WR: STD_LOGIC;

   --Señales asociadas al bus de entrada (comentadas, solo para referencia)
   --signal IO_Ent: STD_LOGIC_VECTOR (15 downto 0);
   --signal IO_RD: STD_LOGIC;

   --Señal del bus de direcciones (comentada, pues no se usan las direcciones al haber un solo
   --puerto de salida).
   --signal IO_Dir: STD_LOGIC_VECTOR (15 downto 0);

   --Latch de salida, permite capturar los datos de manera que persistan entre transacciones de
   --escritura al puerto
   signal DataOutLatch: STD_LOGIC_VECTOR (7 downto 0);

begin
   --Se define el latch de salida de manera que capture datos cada vez que el procesador haga una
   --transaccion de escritura al bus de I/O (sin importar la direccion)
   DataOutLatch <= IO_Sal(7 downto 0) when rising_edge(OscIn) and IO_WR = '1' else
                   DataOutLatch;

   --Se conecta el latch de salida al puerto externo
   DataOut <= DataOutLatch;

   --Se genera la instancia del procesador
   CPU: JPU16
   port map (SysClk => OscIn,       --Entrada de reloj
             Reset => '0',          --Entrada de reset (no usada)
             SysHold => '0',        --Entrada de retencion (no usada)
             Int => '0',            --Entrada de interrupcion (no usada)
             IO_Din(0) => X"0000",  --Bus de entrada (no usado)
             IO_Dout => IO_Sal,     --Bus de salida
             IO_Addr => open,       --Bus de direcciones (no usado)
             IO_RD => open,         --Señal de lectura (no usada)
             IO_WR => IO_WR);       --Señal de escritura
end Funcionamiento;