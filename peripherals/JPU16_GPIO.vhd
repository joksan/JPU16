-- Puerto de entrada y salida de proposito general para JPU16
-- ----------------------------------------------------------
-- Autor: Joksan Alvarado
--
-- Este modulo permite incorporar al procesador un puerto basico de entrada salida (I/O),
-- con un ancho configurable desde 1 a 16 bits. El periferico se conecta directamente al
-- procesador por medio de sus señales externas (bus de I/O) y puede ser configurado
-- mediante parametros genericos.
--
-- Las direcciones se establecen mediante una mascara, la cual indica con un valor de 1
-- cuales bits deben ser descodificados en el bus de direcciones para poder brindar
-- acceso a los registros del periferico. Asimismo, cada registro tiene su propia
-- direccion de manera que el usuario puede elegir distribuirlos en su mapa de I/O como
-- desee.
--
-- Existen 3 registros asociados al modulo:
-- GPI: Provee acceso de lectura a los pines externos del puerto. Las escrituras a este
--      registro son ignoradas.
-- GPO: Provee acceso de lectura/escritura al latch de salida. Notese que para que los
--      bits de este registro aparezcan externamente, los mismos deben ser configurados
--      como salidas, y que al leer este registro no se obtiene el estado de los pines
--      externos si son entradas.
-- DDR: Permite configurar la direccion de los pines externos del puerto. Un cero coloca
--      el pin como entrada (alta impedancia) mientras que un 1 lo coloca como salida
--      (con el dato del latch de salida). El valor de arranque por defecto es cero, y un
--      reset provocara que el registro almacene cero.
-- En caso que se establezca un ancho menor a 16 bits, los MSB de los registros se leeran
-- como 0 y seran ignorados en las escrituras.

--Paquete con las definiciones del periferico
---------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use work.JPU16_Pack.all;

package JPU16_GPIO_Pack is
   component JPU16_GPIO is
   generic (nDataBits: integer := 16;
            Addr_Mask: JPU16_IO_ADDR_BUS := X"0003";
            GPI_Addr:  JPU16_IO_ADDR_BUS := X"0001";
            GPO_Addr:  JPU16_IO_ADDR_BUS := X"0002";
            DDR_Addr:  JPU16_IO_ADDR_BUS := X"0003");
   port (SysClk:   in  STD_LOGIC;
         Reset:    in  STD_LOGIC;
         SysHold:  in  STD_LOGIC;
         IO_Din:   out JPU16_INPUT_BUS;
         IO_Dout:  in JPU16_OUTPUT_BUS;
         IO_Addr:  in JPU16_IO_ADDR_BUS;
         IO_RD:    in STD_LOGIC;
         IO_WR:    in STD_LOGIC;
         DataPort: inout STD_LOGIC_VECTOR (nDataBits-1 downto 0));
   end component;
end package;

--Entidad principal del periferico
----------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use work.JPU16_Pack.all;

entity JPU16_GPIO is
   generic (nDataBits: integer := 16;                --Anchura del puerto
            Addr_Mask: JPU16_IO_ADDR_BUS := X"0003"; --Mascara de direccion
            GPI_Addr:  JPU16_IO_ADDR_BUS := X"0001"; --Locacion del registro de entrada
            GPO_Addr:  JPU16_IO_ADDR_BUS := X"0002"; --Locacion del registro de salida
            DDR_Addr:  JPU16_IO_ADDR_BUS := X"0003");--Locacion del registro de direccion
   port (SysClk:   in  STD_LOGIC;                                 --Entrada de reloj
         Reset:    in  STD_LOGIC;                                 --Entrada de reset
         SysHold:  in  STD_LOGIC;                                 --Entrada de retencion
         IO_Din:   out JPU16_INPUT_BUS;                           --Hacia bus de entrada
         IO_Dout:  in JPU16_OUTPUT_BUS;                           --Desde bus de salida
         IO_Addr:  in JPU16_IO_ADDR_BUS;                          --Bus de direccion
         IO_RD:    in STD_LOGIC;                                  --Entrada de lectura
         IO_WR:    in STD_LOGIC;                                  --Entrada de escritura
         DataPort: inout STD_LOGIC_VECTOR (nDataBits-1 downto 0));--Puerto externo
end JPU16_GPIO;

architecture Funcionamiento of JPU16_GPIO is
   --Habilitacion de seleccion (indican si se descodifican las direcciones)
   signal GPI_Sel: STD_LOGIC;
   signal GPO_Sel: STD_LOGIC;
   signal DDR_Sel: STD_LOGIC;

   --Latch de salida
   signal GPOR: STD_LOGIC_VECTOR (nDataBits-1 downto 0) := (others => '0');
   --Registro de direccion
   signal DDR: STD_LOGIC_VECTOR (nDataBits-1 downto 0) := (others => '0');
begin
   --Se descodifican las direcciones de los registros
   GPI_Sel <= '1' when (IO_Addr and Addr_Mask) = GPI_Addr else '0';
   GPO_Sel <= '1' when (IO_Addr and Addr_Mask) = GPO_Addr else '0';
   DDR_Sel <= '1' when (IO_Addr and Addr_Mask) = DDR_Addr else '0';

   --Proceso de escritura del registro GPOR
   process (SysClk) begin
      if rising_edge(SysClk) then
         if SysHold = '0' and GPO_Sel = '1' and IO_WR = '1' then
            GPOR <= IO_Dout(nDataBits-1 downto 0);
         end if;
      end if;
   end process;

   --Proceso de escritura del registro DDR
   process (SysClk) begin
      if rising_edge(SysClk) then
         if Reset = '1' then
            DDR <= (others => '0');
         elsif SysHold = '0' and DDR_Sel = '1' and IO_WR = '1' then
            DDR <= IO_Dout(nDataBits-1 downto 0);
         end if;
      end if;
   end process;

   --Lectura de los registros
   process (GPI_Sel, GPO_Sel, DDR_Sel, IO_RD, DataPort, GPOR, DDR)
   begin
      --Establece toda la salida a cero inicialmente (en caso que la direccion no sea
      --descodificada y tambien para limpiar los MSB no usados)
      IO_Din <= (others => '0');

      --En caso que se lea y descodifique alguna direccion, se envia el dato al bus
      if    GPI_Sel = '1' and IO_RD = '1' then IO_Din(nDataBits-1 downto 0) <= DataPort;
      elsif GPO_Sel = '1' and IO_RD = '1' then IO_Din(nDataBits-1 downto 0) <= GPOR;
      elsif DDR_Sel = '1' and IO_RD = '1' then IO_Din(nDataBits-1 downto 0) <= DDR;
      end if;
   end process;

   --Logica del puerto externo
   External_Port:
   for i in 0 to nDataBits-1 generate
      --En caso que el bit sea salida, se envia el dato al puerto, caso contrario se
      --establece en alta impedancia
      DataPort(i) <= GPOR(i) when DDR(i) = '1' else 'Z';
   end generate;
end Funcionamiento;