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
   --Definicion del numero de bits a usar para los buses (fijado a 16 bits)
   constant nBits_BusDatos: integer := 16;

   --Señales asociadas al procesador
   signal EntSysClk:      STD_LOGIC := '1';
   signal EntReset:       STD_LOGIC := '0';
   signal EntSysHold:     STD_LOGIC := '0';
   signal EntInt:         STD_LOGIC := '0';
   signal EntBusIO:       STD_LOGIC_VECTOR (nBits_BusDatos-1 downto 0) := (others => '0');
   signal SalBusIO:       STD_LOGIC_VECTOR (nBits_BusDatos-1 downto 0);
   signal DirBusIO:       STD_LOGIC_VECTOR (nBits_BusDatos-1 downto 0);
   signal RD_IO:          STD_LOGIC;
   signal WR_IO:          STD_LOGIC;

begin
   --Instancia del desensamblador (si no se necesita, puede removerse)
   Disassembler: JPU16_DISASM;

   --Instancia del procesador bajo prueba
   TEST_CPU: JPU16
   port map(EntSysClk => EntSysClk, EntReset => EntReset,
            EntSysHold => EntSysHold, EntInt => EntInt,
            EntBusIO => EntBusIO, SalBusIO => SalBusIO, DirBusIO => DirBusIO,
            RD_IO => RD_IO, WR_IO => WR_IO);
   --Notese que todas las señales se conectan al procesador, con el fin de poder controlarlas
   --o visualizarlas en el simulador

   --Proceso de generacion de señal de reloj
   reloj: process
   begin
      EntSysClk <= '1';    --Pone la linea en alto
      wait for 10ns;       --Preserva el nivel durante 10ns
      EntSysClk <= '0';    --Pone la linea en bajo
      wait for 10ns;       --Preserva el nivel otros 10ns
   end process;

   --Nota:
   --Si se desea agregar Hardware externo al procesador, puede agregarse directamente en esta
   --banca de prueba
end;