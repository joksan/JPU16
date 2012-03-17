-- Ejemplo de simulacion de JPU16
-- ------------------------------
-- Autor: Joksan Alvarado
--
-- La siguiente entidad VHDL es un ejemplo de banca de prueba para simular el procesador.
-- Vease el archivo "readme_es.txt" para mas informacion acerca de como integrarlo a un
-- proyecto de ISE y correr la simulacion.

------------------------------------------------------
-- Entidad de la banca de prueba para el procesador --
------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.JPU16_Pack.all;
use work.JPU16_DISASM_DEFS.all;

entity Banca_JPU16 is
end Banca_JPU16;

architecture simulacion of Banca_JPU16 is
   --Señales asociadas al procesador
   signal SysClk:  STD_LOGIC := '1';
   signal Reset:   STD_LOGIC := '0';
   signal SysHold: STD_LOGIC := '0';
   signal Int:     STD_LOGIC := '0';
   signal IO_Din:  JPU16_INPUT_BUS (0 downto 0) := (others => (others => '0'));
   signal IO_Dout: JPU16_OUTPUT_BUS;
   signal IO_Addr: JPU16_IO_ADDR_BUS;
   signal IO_RD:   STD_LOGIC;
   signal IO_WR:   STD_LOGIC;

begin
   --Instancia del desensamblador (si no se necesita, puede removerse)
   Disassembler: JPU16_DISASM;

   --Instancia del procesador bajo prueba
   TEST_CPU: JPU16
   port map(SysClk => SysClk, Reset => Reset, SysHold => SysHold, Int => Int,
            IO_Din => IO_Din, IO_Dout => IO_Dout, IO_Addr => IO_Addr,
            IO_RD => IO_RD, IO_WR => IO_WR);
   --Notese que todas las señales se conectan al procesador, con el fin de poder controlarlas
   --o visualizarlas en el simulador

   --Proceso de generacion de señal de reloj
   reloj: process
   begin
      SysClk <= '1';    --Pone la linea en alto
      wait for 10ns;    --Preserva el nivel durante 10ns
      SysClk <= '0';    --Pone la linea en bajo
      wait for 10ns;    --Preserva el nivel otros 10ns
   end process;

   --Nota:
   --Si se desea agregar Hardware externo al procesador, puede agregarse directamente en esta
   --banca de prueba
end;