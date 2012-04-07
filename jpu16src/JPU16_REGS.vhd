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
         SolInt:     in  STD_LOGIC;
         RestSombra: in  STD_LOGIC;
         Wen:        in  GRUPO_BANDERAS;
         EntBand:    in  GRUPO_BANDERAS;
         SalBand:    out GRUPO_BANDERAS);
end JPU16_REGS_BANDERAS;

architecture Funcionamiento of JPU16_REGS_BANDERAS is
   signal Banderas:   GRUPO_BANDERAS        := (others => '0');
   signal BandSombra: GRUPO_BANDERAS_SOMBRA := (others => '0');
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
         EntRelPC:   in  STD_LOGIC_VECTOR (nBits_PC-1 downto 0);
         EntAbsPC:   in  STD_LOGIC_VECTOR (nBits_PC-1 downto 0);
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
   --Definicion del tipo de datos de la pila
   type TIPO_PILA_PC is array (2**nBits_Pila-1 downto 0) of
      STD_LOGIC_VECTOR (nBits_PC-1 downto 0);

   --Memoria con la pila de llamadas
   signal PilaPC: TIPO_PILA_PC := (others => (others => '0'));

   --Registro de contador de programa con su valor precalculado de incremento y su valor
   --antiguo
   signal PC: STD_LOGIC_VECTOR (nBits_PC-1 downto 0) := (others => '0');
   signal PC_Inc: STD_LOGIC_VECTOR (nBits_PC-1 downto 0) := (others => '0');
   signal PC_Ant: STD_LOGIC_VECTOR (nBits_PC-1 downto 0) := (others => '0');

   --Registro de puntero de pila con sus valores precalculados de incremento y decremento
   signal SP: STD_LOGIC_VECTOR (nBits_Pila-1 downto 0) := (others => '0');
   signal SP_Inc: STD_LOGIC_VECTOR (nBits_Pila-1 downto 0) := (others => '0');
   signal SP_Dec: STD_LOGIC_VECTOR (nBits_Pila-1 downto 0) := (others => '0');

   --Señal de habilitacion que indica si los saltos/llamadas son validos segun las
   --condiciones codificadas en las instrucciones
   signal SaltoValido: STD_LOGIC;
   --Registro para la señal anterior, que permite validar las operaciones de escritura a
   --la pila en el siguiente ciclo (ciclo 0)
   signal RegSaltoValido: STD_LOGIC := '0';
begin
   --Proceso para definir combinacionalmente si la condicion de salto/llamada es valida
   process (CodigoOper(0), NumBandera, ValBand,
            EntBand_C, EntBand_Z, EntBand_N, EntBand_V)
   begin
      --Primero se determina si el salto/llamada es condicional o incondicional
      if CodigoOper(0) = '0' then
         --Todos los saltos incondicionales son automaticamente validados
         SaltoValido <= '1';
      else
         --Los saltos condicionales se determinan a partir de la bandera seleccionada en
         --la instruccion. Si la bandera es igual al valor de entrada (determinado
         --mediante operacion xnor), se da el salto por por valido.
         case NumBandera is
         when "00"   => SaltoValido <= ValBand xnor EntBand_C;
         when "01"   => SaltoValido <= ValBand xnor EntBand_Z;
         when "10"   => SaltoValido <= ValBand xnor EntBand_N;
         when others => SaltoValido <= ValBand xnor EntBand_V;
         end case;
      end if;
   end process;
   --Nota: En un Spartan 3E, este proceso genera exactamente 2 niveles de logica
   --contenidos en tres LUT4, proporcionando un camino eficiente para la habilitacion

   --El registro de salto valido se actualiza durante el ciclo 1
   RegSaltoValido <= SaltoValido
                     when rising_edge(SysClk) and SysHold = '0' and CicloInst = '1';

   --Proceso para determinar todos los registros con valores precalculados
   process (SysClk)
   begin
      if rising_edge(SysClk) then
         --Los valores precalculados se determinan en ciclo 0
         if SysHold = '0' and CicloInst = '0' then
            PC_Inc <= PC + 1;    --Contador de programa incrementado
            PC_Ant <= PC;        --Valor antiguo de contador de programa
            SP_Inc <= SP + 1;    --Puntero de pila incrementado
            SP_Dec <= SP - 1;    --Puntero de pila decrementado
         end if;
      end if;
   end process;

   --Proceso para determinar el nuevo valor del contador de programa
   process (SysClk)
   begin
      if rising_edge(SysClk) then
         if SyncReset1 = '1' then
            --En caso de Reinicio general del CPU, el contador de programa se pone a 0
            PC <= (others => '0');
         elsif SolInt = '1' and CicloInst = '1' and SysHold = '0' then
            --En caso de Solicitud de interrupcion, el contador de programa carga la ultima
            --direccion de memoria (con todos los bits en 1) durante el ciclo 1
            PC <= (others => '1');
         elsif CicloInst = '1' and SysHold = '0' then
            --Todos los cambios en el contador de programa ocurren en el ciclo 1
            if InstValida = '0' then
               --Cuando no hay instruccion que afecte el PC, se carga siempre el valor
               --preincrementado (avanza a la siguiente instruccion)
               PC <= PC_Inc;
            else
               --Si se descodifica una instruccion que afecte el PC, se determina si es
               --de salto/llamada o bien retorno
               if CodigoOper(2) = '0' then
                  --En caso de ser instruccion de salto/llamada, se determina si su
                  --condicion es valida
                  if SaltoValido = '0' then
                     --Si no es valida, se carga el valor preincrementado
                     PC <= PC_Inc;
                  else
                     --Si es valida, se hace el salto segun el modo de direccionamiento
                     if ModoSalto = '0' then
                        --Para direccionamiento inmediato, el salto es relativo
                        PC <= PC + EntRelPC;
                     else
                        --Para direccionamiento de registro, el salto es absoluto
                        PC <= EntAbsPC;
                     end if;
                  end if;
               else
                  --En caso de ser instruccion de retorno, se restaura el valor de
                  --contador de programa almacenado en el tope de la pila
                  PC <= PilaPC(conv_integer(SP));
               end if;
            end if;
         end if;
      end if;
   end process;

   --Proceso para determinar el valor del puntero de pila
   process (SysClk)
   begin
      if rising_edge(SysClk) then
         if SyncReset1 = '1' then
            --En caso de reinicio global del sistema, el puntero de pila se pone a 0
            SP <= (others => '0');
         elsif CicloInst = '1' and SysHold = '0' then
            --Las operaciones del puntero de pila ocurren en el ciclo 1
            if SolInt = '1' then
               --En caso de solicitud de interrupcion, se carga el valor predecrementado
               SP <= SP_Dec;
            elsif InstValida = '1'then
               --En caso de descodificarse instrucciones validas, se determina si son de
               --salto/llamada o bien retorno
               if CodigoOper(2) = '0' then
                  --Si la instruccion es de salto/llamada, se verifica que sea una llamada
                  --con condicion valida
                  if CodigoOper(1) = '1' and SaltoValido = '1' then
                     --En caso de ser valida, se decrementa el puntero de pila
                     SP <= SP_Dec;
                  end if;
               else
                  --Si la isntruccion es de retorno, se incrementa el puntero de pila
                  SP <= SP_Inc;
               end if;
            end if;
         end if;
      end if;
   end process;

   --Proceso de control de escritura a la pila de llamadas
   process (SysClk)
   begin
      if rising_edge(SysClk) then
         if CicloInst = '0' and SysHold = '0' then
            --Todas las operaciones de escritura a la pila ocurren en el ciclo 0
            if SolInt = '1' then
               --En caso de solicitud de interrupcion, se guarda el valor antiguo del
               --contador de programa en la pila
               PilaPC(conv_integer(SP)) <= PC_Ant;
            elsif InstValida = '1' and CodigoOper(2 downto 1) = "01" then
               --En caso que se descodifique una instruccion de llamada, se verifica que
               --su condicion sea valida
               if RegSaltoValido = '1' then
                  --Si lo es, se guarda la direccion de la siguiente instruccion
                  PilaPC(conv_integer(SP)) <= PC_Inc;
               end if;
            end if;
         end if;
      end if;
   end process;
   --Nota: Debido a que el proceso anterior modifica la pila en el ciclo 0, el valor
   --original del contador de programa podria ya no estar presente. Por ello es que se
   --elige entre el valor antiguo del PC o bien el valor preincrementado del mismo, pues
   --sus valores son actualizados al final del ciclo 0.

   SalPC <= PC;      --Conecta el contador de programa al puerto de salida
end Funcionamiento;