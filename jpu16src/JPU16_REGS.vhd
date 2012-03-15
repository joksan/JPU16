------------------------------------------------------------
-- Entidad de los registros de uso general del procesador --
------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity JPU16_REGS_RXX is
   generic (nBits_NumRegs: integer := 4;
            nBits_Regs:    integer := 16);
   Port (SysClk:     in  STD_LOGIC;
         SyncReset2: in  STD_LOGIC;
         SysHold:    in  STD_LOGIC;
         CicloInst:  in  STD_LOGIC;
         SolInt:     in  STD_LOGIC;
         InX:        in  STD_LOGIC_VECTOR (nBits_Regs-1 downto 0);
         OutX:       out STD_LOGIC_VECTOR (nBits_Regs-1 downto 0);
         OutY:       out STD_LOGIC_VECTOR (nBits_Regs-1 downto 0);
         SelX:       in  STD_LOGIC_VECTOR (nBits_NumRegs-1 downto 0);
         SelY:       in  STD_LOGIC_VECTOR (nBits_NumRegs-1 downto 0);
         WenX:       in  STD_LOGIC);
end JPU16_REGS_RXX;

architecture Funcionamiento of JPU16_REGS_RXX is
   --Definicion del tipo de datos usado para el arreglo de 16 registros
   type TIPO_REGS_R is array (2**nBits_NumRegs-1 downto 0) of
      STD_LOGIC_VECTOR (nBits_Regs-1 downto 0);

   --Arreglo de 16 registros de uso general
   signal RegsR: TIPO_REGS_R := (others => (others => '0'));
begin
   --Proceso para la actualizacion del contenido de los registros
   process (SysClk)
   begin
      --Todas las escrituras a registros ocurren en sincronia con el reloj
      if rising_edge(SysClk) then
         if WenX = '1' and CicloInst = '0' and SyncReset2 = '0' and SysHold = '0' and
            SolInt = '0' then
            --Si la habilitacion de escritura esta activa, se procede a actualizar
            --el registro apuntado por SelX con el valor de entrada InX
            RegsR(conv_integer(SelX)) <= InX;
         end if;
      end if;
   end process;

   --Se conectan los registros X e Y a la salida
   OutX <= RegsR(conv_integer(SelX));
   OutY <= RegsR(conv_integer(SelY));
end Funcionamiento;

----------------------------------------------------
-- Entidad para la gestion de las banderas de CPU --
----------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use work.JPU16_DEFS.all;

entity JPU16_REGS_BANDERAS is
   port (SysClk:     in  STD_LOGIC;
         SyncReset2: in  STD_LOGIC;
         SysHold:    in  STD_LOGIC;
         CicloInst:  in  STD_LOGIC;
         SolInt:      in  STD_LOGIC;
         RestSombra: in  STD_LOGIC;
         Wen:        in  GRUPO_BANDERAS;
         EntBand:    in  GRUPO_BANDERAS;
         SalBand:    out GRUPO_BANDERAS);
end JPU16_REGS_BANDERAS;

architecture Funcionamiento of JPU16_REGS_BANDERAS is
   signal Banderas:   GRUPO_BANDERAS  := (others => '0');
   signal BandSombra: BANDERAS_SOMBRA := (others => '0');
begin
   --Proceso de actualizacion de las banderas aritmeticas
   process (SysClk)
   begin
      --Todas las transacciones de las banderas se realizan en sincronia con el reloj
      if rising_edge(SysClk) then
         if SyncReset2 = '1' then
            --En caso de que el CPU sea reiniciado, se limpian las banderas
            Banderas.C <= '0';
            Banderas.Z <= '0';
            Banderas.N <= '0';
            Banderas.V <= '0';
         elsif CicloInst = '0' and SysHold = '0' then
            --Si el sistema no es reiniciado, el ciclo de instruccion es el apropiado y
            --tampoco se mantiene el sistema en paro, se procede a actualizar las
            --banderas
            if RestSombra = '1' then
               --Si se ejecuta una instruccion que restaura los registros de sombra
               --(retorno de interrupcion), se recuperan los registros almacenados
               Banderas.C <= BandSombra.C;
               Banderas.Z <= BandSombra.Z;
               Banderas.N <= BandSombra.N;
               Banderas.V <= BandSombra.V;
            elsif SolInt = '0' then
               --Si no hay solicitud de interrupcion ni restauracion de banderas
               --pendiente, se actualizan las banderas con normalidad
               if Wen.C = '1' then Banderas.C <= EntBand.C; end if;
               if Wen.Z = '1' then Banderas.Z <= EntBand.Z; end if;
               if Wen.N = '1' then Banderas.N <= EntBand.N; end if;
               if Wen.V = '1' then Banderas.V <= EntBand.V; end if;
            end if;
         end if;
      end if;
   end process;

   --Proceso de actualizacion de bandera de interrupcion
   process (SysClk)
   begin
      --Todas las transacciones de las banderas se realizan en sincronia con el reloj
      if rising_edge(SysClk) then
         if SyncReset2 = '1' then
            --En caso de que el CPU sea reiniciado, se limpia la bandera de interrupcion
            Banderas.I <= '0';
         elsif CicloInst = '0' and SysHold = '0' then
            --Si el sistema no es reiniciado, el ciclo de instruccion es el apropiado y
            --tampoco se mantiene el sistema en paro, se procede a actualizar la bandera
            if SolInt = '1' then
               --Si ocurre una solicitud de interrupcion, se procede a limpiar la bandera
               --para impedir que el CPU sea interrumpido nuevamente en el proximo ciclo
               Banderas.I <= '0';
            elsif RestSombra = '1' then
               --Al retornar de una interrupcion el nuevo estado de la bandera se toma de
               --el puerto de entrada (dato proveniente del opcode)
               Banderas.I <= EntBand.I;
            else
               --Si no ocurren interrupciones o retornos, se actualiza la bandera con
               --normalidad (en caso que haya instrucciones que lo soliciten)
               if Wen.I = '1' then Banderas.I <= EntBand.I; end if;
            end if;
         end if;
      end if;
   end process;

   --Proceso de actualizacion de las banderas sombra
   process (SysClk)
   begin
      --Todas las transacciones de las banderas se realizan en sincronia con el reloj
      if rising_edge(SysClk) then
         if SyncReset2 = '1' then
            --En caso de que el CPU sea reiniciado, se limpia el registro sombra
            BandSombra <= (others => '0');
         elsif CicloInst = '0' and SysHold = '0' then
            --Si el sistema no es reiniciado, el ciclo de instruccion es el apropiado y
            --tampoco se mantiene el sistema en paro, se procede a actualizar las
            --banderas sombra
            if SolInt = '1' then
               --Solo se guarda una copia de todas las banderas en el registro sombra en
               --caso de que ocurra una solicitud de interrupcion
               BandSombra.C <= Banderas.C;
               BandSombra.Z <= Banderas.Z;
               BandSombra.N <= Banderas.N;
               BandSombra.V <= Banderas.V;
            end if;
         end if;
      end if;
   end process;

   --Conexion del registro de banderas al puerto de salida
   SalBand <= Banderas;
end Funcionamiento;

-------------------------------------------------------------------------
-- Entidad para la gestion del contador de programa y pila de llamadas --
-------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity JPU16_REGS_PC is
   generic (nBits_PC:   integer := 10;
            nBits_Pila: integer := 5);
   port (SysClk:     in  STD_LOGIC;
         SyncReset1: in  STD_LOGIC;
         SysHold:    in  STD_LOGIC;
         CicloInst:  in  STD_LOGIC;
         SolInt:     in  STD_LOGIC;
         EntPC:      in  STD_LOGIC_VECTOR (nBits_PC-1 downto 0);
         SalPC:      out STD_LOGIC_VECTOR (nBits_PC-1 downto 0);
         InstValida: in  STD_LOGIC;
         CodigoOper: in  STD_LOGIC_VECTOR (2 downto 0);
         ModoSalto:  in  STD_LOGIC;
         EntBand_C:  in  STD_LOGIC;
         EntBand_Z:  in  STD_LOGIC;
         EntBand_N:  in  STD_LOGIC;
         EntBand_V:  in  STD_LOGIC;
         NumBandera: in  STD_LOGIC_VECTOR (1 downto 0);
         ValBand:    in  STD_LOGIC);
end JPU16_REGS_PC;

architecture Funcionamiento of JPU16_REGS_PC is
   type TIPO_PILA_PC is array (2**nBits_Pila-1 downto 0) of
      STD_LOGIC_VECTOR (nBits_PC-1 downto 0);

   signal PC: STD_LOGIC_VECTOR (nBits_PC-1 downto 0) := (others => '0');
   signal PilaPC: TIPO_PILA_PC := (others => (others => '0'));
   signal PunteroPila: STD_LOGIC_VECTOR (nBits_Pila-1 downto 0) := (others => '0');

   signal BandSel: STD_LOGIC;
   signal SaltoValido: STD_LOGIC;

begin
   --De acuerdo a la instruccion actual, se selecciona la bandera que participa en la
   --evaluacion de un salto condicional (Notese que esta operacion se realiza
   --independientemente de que la instruccion actual sea de salto condicional o que sea
   --de cualquier otro tipo)
   with NumBandera select BandSel <= EntBand_C when "00", EntBand_Z when "01",
                          EntBand_N when "10", EntBand_V when others;

   --En base a las condiciones consideradas a continuacion, se determina si debe ocurrir
   --un salto (o cambio) en el contador de programa
   process (InstValida, CodigoOper(2), CodigoOper(0), ValBand, BandSel)
   begin
      --Se determina si la instruccion es valida
      if InstValida = '1' then
         --Se determina si la instruccion es de salto/llamada o retorno
         if CodigoOper(2) = '0' then
            --En caso que la instruccion sea de salto/llamada, se verifica si es
            --condicional o no
            if CodigoOper(0) = '0' then
               --En caso que la instruccion sea de salto/llamada incondicional, se
               --producira un salto
               SaltoValido <= '1';
            else
               --En caso que sea condicional, se verifica si la condicion se cumple
               if ValBand = BandSel then
                  --Si la condicion se cumple, se producira un salto
                  SaltoValido <= '1';
               else
                  --Si no se cumple, el salto no se produce
                  SaltoValido <= '0';
               end if;
            end if;
         else
            --En caso que la instruccion sea de retorno, se cambiara el valor del
            --contador de programa incondicionalmente
            SaltoValido <= '1';
         end if;
      else
         --En caso que no se detecte una instruccion valida, no se realiza un cambio al
         --contador de programa
         SaltoValido <= '0';
      end if;
   end process;

   --Se procede a actualizar todas las partes sincronas asociadas al contador de programa
   --y a la pila de llamadas
   process (SysClk)
   begin
      --Todas las operaciones de el contador de programa y la pila se hacen en sincronia
      --con el reloj
      if rising_edge(SysClk) then
         --Se determina la siguiente accion a seguir para el contador de programa
         if SyncReset1 = '1' then
            --Si el CPU es reiniciado, el contador de programa se regresa a 0
            PC <= (others => '0');
         elsif CicloInst = '1' and SysHold = '0' then
            --En caso que no haya reset, que el ciclo de instruccion este en alto y que
            --el procesador no este en paro, se determina el siguiente estado del
            --contador de programa
            if SolInt = '1' then
               --Si ocurre una solicitud de interrupcion, se detiene la instruccion
               --actual (no se ejecuta) y se carga la direccion del vector de
               --interrupcion en el contador de programa
               PC <= (others => '1');
            else
               --Si no existe una interrupcion pendiente, se verifica si deberia ocurrir
               --un cambio en el contador de programa a causa de una instruccion valida y
               --una posible condicion de salto valida
               if SaltoValido = '0' then
                  --Si no se decodifica ninguna instruccion de salto/llamada/retorno
                  --valida, o si el salto/llamada condicional no cumple su condicion, se
                  --avanza a la siguiente instruccion
                  PC <= PC + 1;
               else
                  --En caso que debiera producirse un cambio del contador de programa, se
                  --determina la razon
                  if CodigoOper(2) = '0' then
                     --Si se trata de una instruccion de salto o llamada condicional o
                     --incondicional, se verifica el tipo de salto
                     if ModoSalto = '0' then
                        --Para salto relativo, se suma el valor al contador actual
                        PC <= PC + EntPC;
                     else
                        --Para salto indirecto, se carga el valor directamente
                        PC <= EntPC;
                     end if;
                  else
                     --Si se trata de una instruccion de retorno, se verifica el tipo de
                     --la misma
                     if CodigoOper(1) = '0' then
                        --Para el retorno normal, se recupera el valor al tope de la pila
                        --de llamadas incrementado en 1 (para ejecutar la siguiente
                        --instruccion despues de la llamada)
                        PC <= PilaPC(conv_integer(PunteroPila - 1)) + 1;
                     else
                        --Para la instruccion de retorno de interrupcion, se recupera el
                        --valor al tope de la pila de llamadas directamente, para
                        --ejecutar la instruccion que fue suspendida
                        PC <= PilaPC(conv_integer(PunteroPila - 1));
                     end if;
                  end if;
               end if;
            end if;
         end if;

         --Se determina la accion a seguir para la pila de llamadas
         if SyncReset1 = '0' and CicloInst = '1' and SysHold = '0' and
            ((SaltoValido = '1' and CodigoOper(2) = '0' and CodigoOper(1) = '1') or
            SolInt = '1') then
            --La pila de llamadas guardara el contador de programa actual si y solo si se
            --cumplen las siguientes condiciones:
            -- * No hay reset
            -- * El ciclo de instruccion es el adecuado (en alto)
            -- * No se detiene el sistema por la señal SysHold
            -- Y uno de estos grupos de condiciones:
            --       * Se dio una condicion de salto valida que cambio el PC
            --       * La instruccion actual no es de retorno
            --       * La instruccion actual es de llamada
            --    o bien
            --         * Se genero una interrupcion
            PilaPC(conv_integer(PunteroPila)) <= PC;   --Guarda el PC
         end if;

         --Se determina la accion a seguir para el puntero de pila
         if SyncReset1 = '1' then
            --Si el CPU es reiniciado, el puntero de pila se regresa a 0
            PunteroPila <= (others => '0');
         elsif CicloInst = '1' and SysHold = '0' then
            --En caso que el ciclo de instruccion este en alto y que el sistema no este
            --detenido, se verifica si se produjo una interrupcion
            if SolInt = '1' then
               --Si se produjo una interrupcion, se adelanta el puntero de pila, pues se
               --tuvo que guardar el contador de programa
               PunteroPila <= PunteroPila + 1;
            elsif SaltoValido = '1' then
               --Por otra parte, si se trata de instruccion de salto/llamada/retorno
               --valida (que produce un cambio en el contador de programa), se verifica
               --si la instruccion fue de salto/llamada o bien de retorno
               if CodigoOper(2) = '0' then
                  --En caso de ser de salto/llamada, se verifica que sea de llamada
                  if CodigoOper(1) = '1' then
                     --Si la instruccion ejecutada fue de llamada, se adelanta el puntero
                     --de pila
                     PunteroPila <= PunteroPila + 1;
                  end if;
               else
                  --Si la instruccion fue de retorno, se retrocede el puntero de pila
                  PunteroPila <= PunteroPila - 1;
               end if;
            end if;
         end if;
      end if;
   end process;

   SalPC <= PC;      --Conecta el contador de programa al puerto de salida
end Funcionamiento;