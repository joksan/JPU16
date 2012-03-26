------------------------------------------------------------------------
-- Entidad de la parte aritmetica binaria y de suma y resta de la ALU --
------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity JPU16_ALU_LBSR is
   generic (nBits_ALU: integer := 16);
   port (SysClk: in STD_LOGIC;
         SysHold: in STD_LOGIC;
         CicloInst: in STD_LOGIC;
         OperandoA: in STD_LOGIC_VECTOR (nBits_ALU-1 downto 0);
         OperandoB: in STD_LOGIC_VECTOR (nBits_ALU-1 downto 0);
         Resultado: out STD_LOGIC_VECTOR (nBits_ALU-1 downto 0);
         CodigoOper: in STD_LOGIC_VECTOR (2 downto 0);
         EntBandC: in STD_LOGIC;
         SalBandC: out STD_LOGIC;
         SalBandZ: out STD_LOGIC;
         SalBandN: out STD_LOGIC;
         SalBandV: out STD_LOGIC);
end JPU16_ALU_LBSR;

architecture Funcionamiento of JPU16_ALU_LBSR is
   signal SumandoB: STD_LOGIC_VECTOR (nBits_ALU-1 downto 0);
   signal BandC_Inicial: STD_LOGIC;
   signal ResultadoLB: STD_LOGIC_VECTOR (nBits_ALU-1 downto 0) := (others => '0');
   signal ResultadoSR: STD_LOGIC_VECTOR (nBits_ALU downto 0) := (others => '0');
   signal RegCodigoOper2: STD_LOGIC := '0';
   signal RegCodigoOper0: STD_LOGIC := '0';
   signal RegSignoOpA: STD_LOGIC := '0';
   signal RegSignoOpB: STD_LOGIC := '0';
   signal ResultadoFinal: STD_LOGIC_VECTOR (nBits_ALU-1 downto 0);

begin
   -----------------------------
   -- Primera etapa de la ALU --
   -----------------------------

   --Operaciones logicas NOT, OR, AND y XOR (logica binaria)
   ---------------------------------------------------------
   process (SysClk)
   begin
      --Se realizan las operaciones logicas del procesador en forma sincrona
      if rising_edge(SysClk) then
         if CicloInst = '1' and SysHold = '0' then
            --La operacion a realizar se determina en base al codigo de operacion
            case CodigoOper(2 downto 1) is
            when "00" =>
               ResultadoLB <= not OperandoA;             --Operacion NOT
            when "01" =>
               ResultadoLB <= OperandoA or OperandoB;    --Operacion OR
            when "10" =>
               ResultadoLB <= OperandoA and OperandoB;   --Operacion AND
            when others =>
               ResultadoLB <= OperandoA xor OperandoB;   --Operacion XOR
            end case;
         end if;
      end if;
      --Nota:
      --El proceso se realiza secuencialmente (sincronizado al ciclo de instruccion y
      --habilitado por SysHold como las demas partes secuenciales del CPU) con proposito
      --de mermar la carga de logica combinacional hacia la bandera de cero y lograr 
      --mayor velocidad. El proceso puede hacerse en forma totalmente combinacional y sin
      --afectar la operacion del procesador eliminando la parte sincrona (condiciones if)
      --convirtiendo el proceso en uno combinacional
   end process;

   -- Operaciones de suma y resta
   ------------------------------
   process (CodigoOper(2 downto 1), OperandoB, EntBandC)
   begin
      --Determinacion del segundo sumando y acarreo de entrada
      case CodigoOper(2 downto 1) is
      when "00" =>
         SumandoB <= OperandoB;        --Suma sin acarreo
         BandC_Inicial <= '0';
      when "01" =>
         SumandoB <= OperandoB;        --Suma con acarreo
         BandC_Inicial <= EntBandC;
       when "10" =>
         SumandoB <= not OperandoB;    --Resta sin prestamo
         BandC_Inicial <= '1';
      when others =>
         SumandoB <= not OperandoB;    --Resta con prestamo
         BandC_Inicial <= EntBandC;
      end case;
   end process;

   --Las operaciones de suma y resta (con o sin acarreo) son todas realizadas con el
   --mismo sumador
   ResultadoSR <= ('0' & OperandoA) + SumandoB + BandC_Inicial
                  when rising_edge(SysClk) and CicloInst = '1' and SysHold = '0';
   --Nota:
   --El proceso se realiza secuencialmente con proposito de mermar la carga de logica
   --combinacional hacia la bandera de acarreo y lograr mayor velocidad. El proceso puede
   --hacerse en forma totalmente combinacional sin afectar la operacion eliminando la
   --parte sincrona (segunda linea) de la sentencia anterior.

   --Traslado de las señales de control a la segunda etapa
   -------------------------------------------------------
   --Las señales de control CodigoOper(2) y CodigoOper(0) se usan en la segunda etapa de
   --la ALU para determinar el resultado final. Estas se trasladan a registros para
   --disminuir la carga de combinacional desde la memoria de programa hacia el resto del
   --procesador (bus R, banderas, etc.). Estas operaciones pueden hacerse tambien en
   --forma totalmente combinacional al eliminar la parte sincrona.
   RegCodigoOper2 <= CodigoOper(2)
                     when rising_edge(SysClk) and CicloInst = '1' and SysHold = '0';
   RegCodigoOper0 <= CodigoOper(0)
                     when rising_edge(SysClk) and CicloInst = '1' and SysHold = '0';

   --Traslado de los signos de los operandos a la segunda etapa
   ------------------------------------------------------------
   --Los signos de los operandos A y B son trasladados tambien a la segunda etapa de la
   --ALU en forma secuencial, pues son usados para determinar el sobreflujo. Tambien es
   --posible hacer esto en forma combinacional.
   RegSignoOpA <= OperandoA(nBits_ALU-1)
                  when rising_edge(SysClk) and CicloInst = '1' and SysHold = '0';
   RegSignoOpB <= OperandoB(nBits_ALU-1)
                  when rising_edge(SysClk) and CicloInst = '1' and SysHold = '0';

   -----------------------------
   -- Segunda etapa de la ALU --
   -----------------------------

   -- Seleccion del resultado a la salida de la ALU
   ------------------------------------------------
   --De acuerdo al codigo de operacion, se determina si la operacion es de logica
   --binaria (NOT, OR, AND y XOR) o de suma/resta (ADD, ADDC, SUB, SUBB)
   ResultadoFinal <=
      ResultadoLB when RegCodigoOper0 = '0'     --Operaciones de logica binaria
      else ResultadoSR(nBits_ALU-1 downto 0);   --Operaciones de suma y resta

   --Conexion del resultado final a la salida de la ALU
   Resultado <= ResultadoFinal;

   -- Determinacion del resultado de las banderas
   ----------------------------------------------
   --El acarreo de salida es igual al MSB del resultado de la suma/resta
   SalBandC <= ResultadoSR(nBits_ALU);

   --La bandera de cero se activa siempre que el resultado sea cero
   SalBandZ <= '1' when ResultadoFinal = 0 else '0';

   --La bandera de negativo es igual al bit 7 del resultado final
   SalBandN <= ResultadoFinal(nBits_ALU-1);

   --Determinacion de la bandera de sobreflujo
   process (RegCodigoOper2, RegSignoOpA, RegSignoOpB, ResultadoSR(nBits_ALU-1))
   begin
      if RegCodigoOper2 = '0' then
         --Definicion de sobreflujo para la suma
         if RegSignoOpA /= RegSignoOpB then
            --Si los signos son diferentes, no puede haber sobreflujo
            SalBandV <= '0';
         else
            --Si los signos son iguales pero el resultado es de signo distinto,
            --hay sobreflujo
            if RegSignoOpA /= ResultadoSR(nBits_ALU-1) then
               SalBandV <= '1';
            else
               SalBandV <= '0';
            end if;
         end if;
      else
         --Definicion de sobreflujo para la resta
         if RegSignoOpA = RegSignoOpB then
            --Si los signos son iguales, no puede haber sobreflujo
            SalBandV <= '0';
         else
            --Si los signos son diferentes y el resultado es de signo distinto
            --que el primer operando (minuendo), hay sobreflujo
            if RegSignoOpA /= ResultadoSR(nBits_ALU-1) then
               SalBandV <= '1';
            else
               SalBandV <= '0';
            end if;
         end if;
      end if;
   end process;
end Funcionamiento;

---------------------------------------------------------------
-- Entidad de la parte de logica de desplazamiento de la ALU --
---------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;

entity JPU16_ALU_LD is
   generic (nBits_ALU: integer := 16);
   port (SysClk: in STD_LOGIC;
         SysHold: in STD_LOGIC;
         CicloInst: in STD_LOGIC;
         OperandoA: in STD_LOGIC_VECTOR (nBits_ALU-1 downto 0);
         OperandoB: in STD_LOGIC_VECTOR (3 downto 0);
         Resultado: out STD_LOGIC_VECTOR (nBits_ALU-1 downto 0);
         CodigoOper: in STD_LOGIC_VECTOR (2 downto 0);
         EntBandC: in STD_LOGIC;
         SalBandC: out STD_LOGIC;
         SalBandZ: out STD_LOGIC;
         SalBandN: out STD_LOGIC);
end JPU16_ALU_LD;

architecture Funcionamiento of JPU16_ALU_LD is
   signal ValorResultante: STD_LOGIC_VECTOR (nBits_ALU-1 downto 0);

   signal RegRotDes: STD_LOGIC_VECTOR (nBits_ALU-1 downto 0) := (others => '0');
   signal RegRotC: STD_LOGIC_VECTOR (nBits_ALU-1 downto 0) := (others => '0');
   signal RegC: STD_LOGIC_VECTOR (3 downto 0) := (others => '0');

   signal RegOperandoB: STD_LOGIC_VECTOR (1 downto 0) := "00";
   signal RegCodigoOper: STD_LOGIC_VECTOR (2 downto 0);

begin
   --Primera etapa del barrel shifter (desplazamiento y rotacion sin acarreo)
   --------------------------------------------------------------------------
   process (SysClk)
   begin
      if rising_edge(SysClk) then
         if SysHold = '0' and  CicloInst = '1' then
            --Se determina la clase de operacion (desplazamiento o rotacion) mediante el
            --bit 1 del codigo de operacion
            if CodigoOper(1) = '0' then
               --Si la operacion es de desplazamiento, se determina la direccion mediante
               --el bit 2 del codigo de operacion
               if CodigoOper(2) = '0' then
                  --Para los desplazamientos a la izquierda, los nibbles se desplazan con
                  --ceros o unos entrando por la derecha dependiendo del bit 0 del codigo
                  --de operacion
                  case OperandoB(3 downto 2) is    --Se desplazan nibles usando los MSB
                  when "00" =>
                     RegRotDes <= OperandoA;       --En caso de 0 no se desplaza
                  when "01" =>
                     RegRotDes <= OperandoA(11 downto 0) & ( 3 downto 0 => CodigoOper(0));
                  when "10" =>
                     RegRotDes <= OperandoA( 7 downto 0) & ( 7 downto 0 => CodigoOper(0));
                  when others =>
                     RegRotDes <= OperandoA( 3 downto 0) & (11 downto 0 => CodigoOper(0));
                  end case;
               else
                  --De manera similar, en los desplazamientos a la derecha los unos o
                  --ceros entran por la izquierda dependiendo del bit 0
                  case OperandoB(3 downto 2) is
                  when "00" =>
                     RegRotDes <= OperandoA;
                  when "01" =>
                     RegRotDes <= ( 3 downto 0 => CodigoOper(0)) & OperandoA(15 downto  4);
                  when "10" =>
                     RegRotDes <= ( 7 downto 0 => CodigoOper(0)) & OperandoA(15 downto  8);
                  when others =>
                     RegRotDes <= (11 downto 0 => CodigoOper(0)) & OperandoA(15 downto 12);
                  end case;
               end if;
            else
               --Si la operacion es de rotacion, se determina la direccion mediante el
               --bit 2 del codigo de operacion
               if CodigoOper(2) = '0' then
                  --En las rotaciones a la izquierda, los nibbles mas significativos
                  --reingresan por la derecha
                  case OperandoB(3 downto 2) is
                  when "00" =>
                     RegRotDes <= OperandoA;       --En caso de cero no se rota
                  when "01" =>
                     RegRotDes <= OperandoA(11 downto 0) & OperandoA(15 downto 12);
                  when "10" =>
                     RegRotDes <= OperandoA( 7 downto 0) & OperandoA(15 downto  8);
                  when others =>
                     RegRotDes <= OperandoA( 3 downto 0) & OperandoA(15 downto  4);
                  end case;
               else
                  --En las rotaciones a la derecha, los nibbles menos significativos
                  --entran por la izquierda
                  case OperandoB(3 downto 2) is
                  when "00" =>
                     RegRotDes <= OperandoA;
                  when "01" =>
                     RegRotDes <= OperandoA( 3 downto 0) & OperandoA(15 downto  4);
                  when "10" =>
                     RegRotDes <= OperandoA( 7 downto 0) & OperandoA(15 downto  8);
                  when others =>
                     RegRotDes <= OperandoA(11 downto 0) & OperandoA(15 downto 12);
                  end case;
               end if;
            end if;
         end if;
      end if;
   end process;

   --Primera etapa del rotador con acarreo
   ---------------------------------------
   process (SysClk)
   begin
      if rising_edge(SysClk) then
         if SysHold = '0' and  CicloInst = '1' then
            --Se determina la direccion de la rotacion mediante el bit 2 del codigo de
            --operacion
            if CodigoOper(2) = '0' then
               --En las rotaciones a la izquierda el acarreo entra por la derecha
               RegRotC <= OperandoA(14 downto 0) & EntBandC;
            else
               --Complementariamente, el acarreo entra por la izquierda en el otro caso
               RegRotC <= EntBandC & OperandoA(15 downto 1);
            end if;
            --Nota: en las operaciones de rotacion con acarreo, se ignora el argumento B
            --(siempre se rota solo 1 bit)
         end if;
      end if;
   end process;

   --Registros de señales de control para la segunda etapa (ayuda a disminuir el retardo
   --combinacional)
   process (SysClk)
   begin
      if rising_edge(SysClk) then
         if SysHold = '0' and  CicloInst = '1' then
            --Se copian los LSB del operando B y el codigo de operacion completo
            RegOperandoB <= OperandoB(1 downto 0);
            RegCodigoOper <= CodigoOper;
         end if;
      end if;
   end process;

   --Segunda etapa del barrel shifter (Desplazamiento y rotacion con o sin acarreo)
   --------------------------------------------------------------------------------
   process (RegCodigoOper, RegOperandoB, RegRotDes, RegRotC)
   begin
      --Se determina la clase de operacion mediante el bit 1 del codigo de operacion
      if RegCodigoOper(1) = '0' then
         --Para las operaciones de desplazamiento, se decide la direccion mediante el bit
         --2 del codigo de operacion
         if RegCodigoOper(2) = '0' then
            --Para los desplazamientos a la izquierda, el operando pre-procesado se
            --desplaza con ceros o unos entrando por la derecha dependiendo del bit 0 del
            --codigo de operacion
            case RegOperandoB is                   --Se desplaza un maximo de 3 bits
            when "00" =>
               ValorResultante <= RegRotDes;       --En caso de cero no se desplaza
            when "01" =>
               ValorResultante <= RegRotDes(14 downto 0) & (0 downto 0 => RegCodigoOper(0));
            when "10" =>
               ValorResultante <= RegRotDes(13 downto 0) & (1 downto 0 => RegCodigoOper(0));
            when others =>
               ValorResultante <= RegRotDes(12 downto 0) & (2 downto 0 => RegCodigoOper(0));
            end case;
         else
            --Para los desplazamientos a la derecha, se desplaza con unos o ceros
            --entrando por la izquierda segun el bit 0 del codigo de operacion
            case RegOperandoB is
            when "00" =>
               ValorResultante <= RegRotDes;
            when "01" =>
               ValorResultante <= (0 downto 0 => RegCodigoOper(0)) & RegRotDes(15 downto 1);
            when "10" =>
               ValorResultante <= (1 downto 0 => RegCodigoOper(0)) & RegRotDes(15 downto 2);
            when others =>
               ValorResultante <= (2 downto 0 => RegCodigoOper(0)) & RegRotDes(15 downto 3);
            end case;
         end if;
      else
         --Para las operaciones de rotacion, se distingue si involucran el acarreo
         --mediante el bit 0 del codigo de operacion
         if RegCodigoOper(0) = '0' then
            --Para las operaciones de rotacion sin acarreo, se decide la direccion
            --mediante el bit 2 del codigo de operacion
            if RegCodigoOper(2) = '0' then
               --Para las rotaciones a la izquierda, el operando pre-procesado se rota con
               --los MSB entrando por la derecha
               case RegOperandoB is                --Se rota un maximo de 3 bits
               when "00" =>
                  ValorResultante <= RegRotDes;    --En caso de cero no se rota
               when "01" =>
                  ValorResultante <= RegRotDes(14 downto 0) & RegRotDes(15 downto 15);
               when "10" =>
                  ValorResultante <= RegRotDes(13 downto 0) & RegRotDes(15 downto 14);
               when others =>
                  ValorResultante <= RegRotDes(12 downto 0) & RegRotDes(15 downto 13);
               end case;
            else
               --Para las rotaciones a la derecha, el operando pre-procesado se rota con
               --los LSB entrando por la izquierda
               case RegOperandoB is
               when "00" =>
                  ValorResultante <= RegRotDes;
               when "01" =>
                  ValorResultante <= RegRotDes(0 downto 0) & RegRotDes(15 downto 1);
               when "10" =>
                  ValorResultante <= RegRotDes(1 downto 0) & RegRotDes(15 downto 2);
               when others =>
                  ValorResultante <= RegRotDes(2 downto 0) & RegRotDes(15 downto 3);
               end case;
            end if;
         else
            --Para las operaciones de rotacion con acarreo, el valor pre-procesado se
            --encuentra listo y solo se traslada
            ValorResultante <= RegRotC;
         end if;
      end if;
   end process;

   --Primera etapa de generacion de bandera de acarreo
   ---------------------------------------------------
   --En la primera etapa los 4 candidatos posibles del acarreo son trasladados a la
   --segunda etapa mediante un registro de 4 bits, de manera que se reduce la cantidad
   --posible de entradas a los multiplexores. Notese que se da el mismo tratamiento a la
   --bandera de acarreo en todas las operaciones del barrel shifter sin importar su tipo.
   process (SysClk)
   begin
      if rising_edge(SysClk) then
         if SysHold = '0' and  CicloInst = '1' then
            --Se determina la direccion del desplazamiento/rotacion en base al bit 2 del
            --codigo de operacion
            if CodigoOper(2) = '0' then
               --En las operaciones hacia la izquierda se elige de 16 posibles candidatos
               --en orden de desplazamiento de izquierda a derecha
               case OperandoB(3 downto 2) is
               when "00" =>
                  --En caso que el desplazamiento inicial sea cero, uno de los posibles
                  --candidatos incluye a la bandera de acarreo misma (dependera de los
                  --LSB del operando B si realmente se elige)
                  RegC <= EntBandC & OperandoA(15 downto 13);
               when "01" =>
                  RegC <= OperandoA(12 downto 9);
               when "10" =>
                  RegC <= OperandoA(8 downto 5);
               when others =>
                  --Notese que es imposible desplazar 16 bits, asi que el bit 0 no es un
                  --candidato viable
                  RegC <= OperandoA(4 downto 1);
               end case;
            else
               --En las operaciones hacia la derecha, los 16 candidatos se eligen en
               --orden inverso
               case OperandoB(3 downto 2) is
               when "00" =>
                  --El desplazamiento inicial tembien incluye la bandera de acarreo
                  --original en caso que el operando B sea 0
                  RegC <= OperandoA(2 downto 0) & EntBandC;
               when "01" =>
                  RegC <= OperandoA(6 downto 3);
               when "10" =>
                  RegC <= OperandoA(10 downto 7);
               when others =>
                  --Como no es posible desplazar 16 bits, el bit 15 no es un candidato
                  RegC <= OperandoA(14 downto 11);
               end case;
            end if;
         end if;
      end if;
   end process;

   --Segunda etapa de generacion de bandera de acarreo
   ---------------------------------------------------
   --En la segunda etapa la bandera de acarreo final se elige de los 4 posibles
   --candidatos escogidos en la primera etapa
   process (RegCodigoOper(2), RegOperandoB, RegC)
   begin
      --La direccion de rotacion se determina con el bit 2 del codigo de operacion
      if RegCodigoOper(2) = '0' then
         --En las operaciones hacia la izquierda se eligen un candidato comenzando por el
         --de la izquierda
         case RegOperandoB is
         when "00" =>
            SalBandC <= RegC(3);
         when "01" =>
            SalBandC <= RegC(2);
         when "10" =>
            SalBandC <= RegC(1);
         when others =>
            SalBandC <= RegC(0);
         end case;
      else
         --De manera similar, para el otro sentido se elige un candidato iniciando por el
         --de la derecha
         case RegOperandoB is
         when "00" =>
            SalBandC <= RegC(0);
         when "01" =>
            SalBandC <= RegC(1);
         when "10" =>
            SalBandC <= RegC(2);
         when others =>
            SalBandC <= RegC(3);
         end case;
      end if;
   end process;

   --Asignacion del resultado:
   Resultado <= ValorResultante;

   --La bandera de cero se activa si el resultado fue 0:
   SalBandZ <= '1' when ValorResultante = 0 else '0';

   --La bandera de negativo toma el valor del nuevo MSB:
   SalBandN <= ValorResultante(nBits_ALU-1);
end Funcionamiento;