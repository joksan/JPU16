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
   signal ResultadoLB: STD_LOGIC_VECTOR (nBits_ALU-1 downto 0);
   signal ResultadoSR: STD_LOGIC_VECTOR (nBits_ALU downto 0) := (others => '0');
   signal ResultadoFinal: STD_LOGIC_VECTOR (nBits_ALU-1 downto 0);

begin
   --Operaciones logicas NOT, OR, AND y XOR (logica binaria)
   ---------------------------------------------------------
   process (CodigoOper(2 downto 1), OperandoA, OperandoB)
   begin
      --Se realizan las operaciones logicas del procesador (NOT, OR, AND y XOR) en forma
      --sincrona
      if rising_edge(SysClk) then
         if CicloInst = '1' and SysHold = '0' then
            --La operacion a realizar se determina en base al codigo de operacion
            case CodigoOper(2 downto 1) is
            when "00" =>
               ResultadoLB <= not OperandoA;               --Operacion NOT
            when "01" =>
               ResultadoLB <= OperandoA or OperandoB;      --Operacion OR
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
         SumandoB <= OperandoB;         --Suma sin acarreo
         BandC_Inicial <= '0';
      when "01" =>
         SumandoB <= OperandoB;         --Suma con acarreo
         BandC_Inicial <= EntBandC;
       when "10" =>
         SumandoB <= not OperandoB;      --Resta sin prestamo
         BandC_Inicial <= '1';
      when others =>
         SumandoB <= not OperandoB;      --Resta con prestamo
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

   -- Seleccion del resultado a la salida de la ALU
   ------------------------------------------------
   --De acuerdo al codigo de operacion, se determina si la operacion es de logica
   --binaria (NOT, OR, AND y XOR) o de suma/resta (ADD, ADDC, SUB, SUBB)
   ResultadoFinal <=
      ResultadoLB when CodigoOper(0) = '0'      --Operaciones de logica binaria
      else ResultadoSR(nBits_ALU-1 downto 0);   --Operaciones de suma y resta

   --Conexion del resultado final a la salida de la ALU
   Resultado <= ResultadoFinal;

   -- Determinacion del resultado de las banderas
   ----------------------------------------------
   --El acarreo de salida es igual al MSB del resultado de la suma/resta
   SalBandC <= ResultadoSR(nBits_ALU);

   --La bandera de cero se activa siempre y cuando todos los bits del resultado sean cero
   SalBandZ <=
      '1' when ResultadoFinal(nBits_ALU-1 downto 0) = (nBits_ALU-1 downto 0 => '0')
      else '0';

   --La bandera de negativo es igual al bit 7 del resultado final
   SalBandN <= ResultadoFinal(nBits_ALU-1);

   --Determinacion de la bandera de sobreflujo
   process (CodigoOper(2), OperandoA(nBits_ALU-1), OperandoB(nBits_ALU-1),
            ResultadoSR(nBits_ALU-1))
   begin
      if CodigoOper(2) = '0' then
         --Definicion de sobreflujo para la suma
         if OperandoA(nBits_ALU-1) /= OperandoB(nBits_ALU-1) then
            --Si los signos son diferentes, no puede haber sobreflujo
            SalBandV <= '0';
         else
            --Si los signos son iguales pero el resultado es de signo distinto,
            --hay sobreflujo
            if OperandoA(nBits_ALU-1) /= ResultadoSR(nBits_ALU-1) then
               SalBandV <= '1';
            else
               SalBandV <= '0';
            end if;
         end if;
      else
         --Definicion de sobreflujo para la resta
         if OperandoA(nBits_ALU-1) = OperandoB(nBits_ALU-1) then
            --Si los signos son iguales, no puede haber sobreflujo
            SalBandV <= '0';
         else
            --Si los signos son diferentes y el resultado es de signo distinto
            --que el primer operando (minuendo), hay sobreflujo
            if OperandoA(nBits_ALU-1) /= ResultadoSR(nBits_ALU-1) then
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
   port (Operando: in STD_LOGIC_VECTOR (nBits_ALU-1 downto 0);
         Resultado: out STD_LOGIC_VECTOR (nBits_ALU-1 downto 0);
         CodigoOper: in STD_LOGIC_VECTOR (2 downto 0);
         EntBandC: in STD_LOGIC;
         SalBandC: out STD_LOGIC;
         SalBandZ: out STD_LOGIC;
         SalBandN: out STD_LOGIC);
end JPU16_ALU_LD;

architecture Funcionamiento of JPU16_ALU_LD is
   signal ValorResultante: STD_LOGIC_VECTOR (nBits_ALU-1 downto 0);

begin
   process (Operando, CodigoOper, EntBandC)
   begin
      --Se actua de acuerdo a los bits que definen el codigo de operacion:
      if CodigoOper(2) = '0' then
         --Para la rotacion/desplazamiento hacia la izquierda, se asigna a los bits del
         --1 al MSb los valores de los bits a la derecha:
         for i in 1 to nBits_ALU-1 loop
            ValorResultante(i) <= Operando(i-1);
         end loop;

         --En el caso del bit 0, se actua de acuerdo al codigo de operacion:
         if CodigoOper(1) = '0' then
            --Para los desplazamientos simples, se introduce el valor (0 o 1) de
            --acuerdo a la instruccion (SHL0 / SHL1):
            ValorResultante(0) <= CodigoOper(0);
         else
            if CodigoOper(0) = '0' then
               --Para la rotacion sin acarreo, se asigna el MSb:
               ValorResultante(0) <= Operando(nBits_ALU-1);
            else
               --Para la rotacion con acarreo, se asigna el valor de acarreo:
               ValorResultante(0) <= EntBandC;               
            end if;
         end if;
      else
         --Para la rotacion/desplazamiento hacia la derecha, se asigna a los bits del
         --0 al MSb-1 los valores de los bits a la izquierda:
         for i in 0 to nBits_ALU-2 loop
            ValorResultante(i) <= Operando(i+1);
         end loop;

         --En el caso del MSb, se actua de acuerdo al codigo de operacion:
         if CodigoOper(1) = '0' then
            --Para los desplazamientos simples, se introduce el valor (0 o 1) de
            --acuerdo a la instruccion (SHR0 / SHR1):
            ValorResultante(nBits_ALU-1) <= CodigoOper(0);
         else
            if CodigoOper(0) = '0' then
               --Para la rotacion sin acarreo, se asigna el LSb:
               ValorResultante(nBits_ALU-1) <= Operando(0);
            else
               --Para la rotacion con acarreo, se asigna el valor de acarreo:
               ValorResultante(nBits_ALU-1) <= EntBandC;               
            end if;
         end if;
      end if;
   end process;

   --Asignacion del resultado:
   Resultado <= ValorResultante;

   --La bandera de acarreo toma el valor del bit que "sale"
   SalBandC <= Operando(nBits_ALU-1) when CodigoOper(2) = '0' else Operando(0);

   --La bandera de cero se activa si el resultado fue 0:
   SalBandZ <= '1' when ValorResultante = (nBits_ALU-1 downto 0 => '0') else '0';

   --La bandera de negativo toma el valor del nuevo MSB:
   SalBandN <= ValorResultante(nBits_ALU-1);
end Funcionamiento;