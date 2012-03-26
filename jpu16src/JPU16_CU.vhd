-------------------------------------
-- Entidad de la unidad de control --
-------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use work.JPU16_DEFS.ALL;

entity JPU16_CU is
   generic (nBits_BusProg: integer := 10);
   port (SysClk:          in  STD_LOGIC;
         EntReset:        in  STD_LOGIC;
         SalSyncReset:    out STD_LOGIC_VECTOR (2 downto 1);
         SysHold:         in  STD_LOGIC;
         SalCicloInst:    out STD_LOGIC;
         EntInt:          in  STD_LOGIC;
         EntBandI:        in  STD_LOGIC;
         SalSolInt:       out STD_LOGIC;
         EntBusProg:      in  STD_LOGIC_VECTOR (nBits_BusProg-1 downto nBits_BusProg-10);
         SalInstVal:      out INSTRUCCIONES_VALIDAS;
         SalWen_Banderas: out GRUPO_BANDERAS);
end JPU16_CU;

architecture Funcionamiento of JPU16_CU is
   signal SyncReset: STD_LOGIC_VECTOR (2 downto 0) := (others => '1');
   signal CicloInst: STD_LOGIC := '0';
   signal RegSolInt:    STD_LOGIC := '0';
begin
   process (SysClk)
   begin
      if rising_edge(SysClk) then
         --Se verifica si el reset externo se encuentra activado
         if EntReset = '1' then
            --De estar activado, las señales internas de reset sincrono se activan
            SyncReset(0) <= '1';
            SyncReset(1) <= '1';
            SyncReset(2) <= '1';
         else
            --De no estarlo, las señales se desactivan una a una, en orden con cada ciclo
            --(A medida se desactivan, las partes del CPU comienzan a funcionar)
            SyncReset(0) <= '0';               --Se introduce un cero a la primera
            SyncReset(1) <= SyncReset(0);      --El cero luego se propaga con cada ciclo
            SyncReset(2) <= SyncReset(1);
         end if;

         --Se actualiza el estado del ciclo de instruccion
         if SyncReset(1) = '1' then
            --En caso que el segundo reset sincrono este activado, se establece el ciclo
            --de instruccion en bajo
            CicloInst <= '0';
         elsif SysHold = '0' then
            --En caso que el segundo reset sincrono este desactivado y que la entrada
            --SysHold este desactivada, se alterna el ciclo de instruccion con cada ciclo
            --de reloj
            CicloInst <= not CicloInst;
         end if;

         --Se actualiza tambien el estado del registro de solicitud de interrucpion, el
         --cual sincroniza la linea externa de interrupcion a la logica interna del CPU
         if SyncReset(2) = '1' then
            --En caso que el tercer reset sincrono este activado, se inhibe cualquier
            --solicitud de interrupcion que pudiera ocurrir
            RegSolInt <= '0';
         elsif SysHold = '0' and CicloInst = '0' then
            --En caso que no haya reset, la entrada SysHold este desactivada y que el
            --ciclo de instruccion este en bajo, el registro de interrupcion captura el
            --estado de la linea externa
            RegSolInt <= EntInt;
         end if;
      end if;
   end process;

   --Se traslada las señales globales de reset al puerto de salida
   SalSyncReset <= SyncReset(2 downto 1);

   --Se traslada el ciclo de instruccion actual al puerto de salida
   SalCicloInst <= CicloInst;

   --La linea de solicitud de interrupcion se activa siempre que el registro de solicitud
   --de interrupcion este en alto mentras la bandera de interrupcion este habilitada
   SalSolInt <= RegSolInt and EntBandI;

   --Decodificacion de las instrucciones relacionadas al contador de programa
   SalInstVal.PC <=
      '1' when EntBusProg(nBits_BusProg-1 downto nBits_BusProg-2) = "01" else '0';

   --Decodificacion de las instrucciones relacionadas al retorno de interrucpciones
   --(IERET e IDRET)
   SalInstVal.IXRET <=
      '1' when EntBusProg(nBits_BusProg-1 downto nBits_BusProg-4) = "0111" else '0';

   --Decodificacion de las instrucciones relacionadas a la parte de logica binaria y de
   --suma/resta de la ALU que no guardan resultados en registros sino solo en banderas
   --(TEST, CMP)
   SalInstVal.ALU_LBSR_NR <=
      '1' when EntBusProg(nBits_BusProg-1 downto nBits_BusProg-4) = "0010" else '0';

   --Decodificacion de las instrucciones relacionadas a la parte de logica binaria y de
   --suma/resta de la ALU que guardan su resultado de forma normal (NOT, OR, AND, XOR,
   --ADD, ADDC, SUB, SUBB)
   SalInstVal.ALU_LBSR <=
      '1' when EntBusProg(nBits_BusProg-1 downto nBits_BusProg-2) = "10" else '0';

   --Determinacion de las instrucciones relacionadas a la parte de logica de
   --desplazamiento de la ALU
   SalInstVal.ALU_LD <=
      '1' when EntBusProg(nBits_BusProg-1 downto nBits_BusProg-5) = "11100" else '0';

   --Decodificacion de las instrucciones que afectan a las banderas, tanto las
   --instrucciones CLRX/SETX asi como IDRET/IERET
   SalInstVal.Banderas <=
      '1' when EntBusProg(nBits_BusProg-1 downto nBits_BusProg-4) = "0001" or
               EntBusProg(nBits_BusProg-1 downto nBits_BusProg-4) = "0111" else '0';

   SalWen_Banderas <=
      --Para instrucciones de la forma SETX/CLRX, las banderas de habilitacion ya vienen
      --en el codigo de operacion mismo
      (C => EntBusProg(nBits_BusProg-10), Z => EntBusProg(nBits_BusProg-9),
       N => EntBusProg(nBits_BusProg-8), V => EntBusProg(nBits_BusProg-7),
       I => EntBusProg(nBits_BusProg-6)) when
         EntBusProg(nBits_BusProg-1 downto nBits_BusProg-4) = "0001"
      --Para la instruccion TEST, se actualizan las banderas de cero y negativo solamente
      else (C => '0', Z => '1', N => '1', V => '0', I => '0') when
         EntBusProg(nBits_BusProg-1 downto nBits_BusProg-5) = "00100"
      --Para la instruccion CMP, se actualizan todas las banderas asociadas a la ALU
      else (C => '1', Z => '1', N => '1', V => '1', I => '0') when
         EntBusProg(nBits_BusProg-1 downto nBits_BusProg-5) = "00101"
      --Para las instrucciones de logica binaria (NOT, OR, AND, XOR) se actualizan solo
      --las banderas de cero y negativo
      else (C => '0', Z => '1', N => '1', V => '0', I => '0') when
         EntBusProg(nBits_BusProg-1 downto nBits_BusProg-2) = "10"
         and EntBusProg(nBits_BusProg-5) = '0'
      --Para las instrucciones de suma y resta (ADD, ADDC, SUB, SUBB) se actualizan todas
      --las banderas asociadas a la ALU
      else (C => '1', Z => '1', N => '1', V => '1', I => '0') when
         EntBusProg(nBits_BusProg-1 downto nBits_BusProg-2) = "10"
         and EntBusProg(nBits_BusProg-5) = '1'
      --Para las operaciones de desplazamiento, se actualizan acarreo, cero y negativo
      else (C => '1', Z => '1', N => '1', V => '0', I => '0') when
         EntBusProg(nBits_BusProg-1 downto nBits_BusProg-5) = "11100"
      --Para todas las demas instrucciones, no se actualiza ninguna bandera
      else (others => '0');

   --Decodificacion de las instrucciones de movimiento de datos entre registros y desde
   --literales
   SalInstVal.MoveRegInm <=
      '1' when EntBusProg(nBits_BusProg-1 downto nBits_BusProg-5) = "11101" else '0';

   --Decodificacion de las instrucciones de lectura y escritura de datos con la RAM
   SalInstVal.MoveRamRd <=
      '1' when EntBusProg(nBits_BusProg-1 downto nBits_BusProg-5) = "11110" else '0';

   SalInstVal.MoveRamWr <=
      '1' when EntBusProg(nBits_BusProg-1 downto nBits_BusProg-5) = "00110" else '0';

   --Decodificacion de las instrucciones de entrada y salida de datos al bus de I/O
   SalInstVal.IO_IN <=
      '1' when EntBusProg(nBits_BusProg-1 downto nBits_BusProg-5) = "11111" else '0';

   SalInstVal.IO_OUT <=
      '1' when EntBusProg(nBits_BusProg-1 downto nBits_BusProg-5) = "00111" else '0';
end Funcionamiento;