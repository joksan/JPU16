------------------------------------------------------------------------
-- Entidad de la parte aritmetica binaria y de suma y resta de la ALU --
------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use work.JPU16_PACK.ALL;
use WORK.JPU16_DEFS.ALL;

entity JPU16_ALU_LBSR is
   port (SysClk:     in  STD_LOGIC;
         SysHold:    in  STD_LOGIC;
         CicloInst:  in  STD_LOGIC;
         DataEnable: in  STD_LOGIC;
         FlagEnable: in  STD_LOGIC;
         OperandoA:  in  STD_LOGIC_VECTOR (JPU16_DataBits-1 downto 0);
         OperandoB:  in  STD_LOGIC_VECTOR (JPU16_DataBits-1 downto 0);
         Resultado:  out STD_LOGIC_VECTOR (JPU16_DataBits-1 downto 0);
         CodigoOper: in  STD_LOGIC_VECTOR (2 downto 0);
         EntBandC:   in  STD_LOGIC;
         SalBand:    out GRUPO_BANDERAS_ALU_LBSR);
end JPU16_ALU_LBSR;

architecture Funcionamiento of JPU16_ALU_LBSR is
   --Señales con resultados pre procesados
   signal SumandoB: STD_LOGIC_VECTOR (JPU16_DataBits-1 downto 0);
   signal BandC_Inicial: STD_LOGIC;

   --Registros con resultados parciales para la segunda etapa
   signal ResultadoLB: STD_LOGIC_VECTOR (JPU16_DataBits-1 downto 0) := (others => '0');
   signal ResultadoSR: STD_LOGIC_VECTOR (JPU16_DataBits downto 0) := (others => '0');
   signal RegSignoOpA: STD_LOGIC := '0';
   signal RegSignoOpB: STD_LOGIC := '0';

   --Registros con señales de control
   signal RegCodigoOper2: STD_LOGIC := '0';
   signal RegCodigoOper0: STD_LOGIC := '0';
   signal RegDataEn: STD_LOGIC := '0';
   signal RegFlagEn: STD_LOGIC := '0';

   --Señales con resultados post procesados
   signal ResultadoFinal: STD_LOGIC_VECTOR (JPU16_DataBits-1 downto 0);
begin
   -----------------------------
   -- Primera etapa de la ALU --
   -----------------------------

   --Operaciones logicas NOT, OR, AND y XOR (logica binaria)
   ---------------------------------------------------------
   process (SysClk)
      --Tabla de verdad para determinar todas las operaciones booleanas de la ALU
      constant Tabla_LB: STD_LOGIC_VECTOR(0 to 15) := "1100" &    --NOT A
                                                      "0111" &    --A OR B
                                                      "0001" &    --A AND B
                                                      "0110";     --A XOR B
      --Nota: La composicion de los bits de seleccion de la tabla es la siguiente:
      --CodigoOper(2), CodigoOper(1), OperandoA, OperandoB
   begin
      --Se realizan las operaciones logicas del procesador en forma sincrona
      if rising_edge(SysClk) then
         if CicloInst = '1' and SysHold = '0' then
            --La operacion se determina en base a la tabla, la cual es aplicada bit a bit
            for i in 0 to JPU16_DataBits-1 loop
               ResultadoLB(i) <= Tabla_LB(conv_integer(CodigoOper(2 downto 1) &
                                                       OperandoA(i) & OperandoB(i)));
            end loop;
         end if;
      end if;
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

   --Traslado de las señales de control a la segunda etapa
   -------------------------------------------------------
   --Las señales de control CodigoOper(2) y CodigoOper(0) se usan en la segunda etapa de
   --la ALU para determinar el resultado final. Estas se trasladan a registros para
   --disminuir la carga de combinacional desde la memoria de programa hacia el resto del
   --procesador (bus R, banderas, etc.)
   RegCodigoOper2 <= CodigoOper(2)
                     when rising_edge(SysClk) and CicloInst = '1' and SysHold = '0';
   RegCodigoOper0 <= CodigoOper(0)
                     when rising_edge(SysClk) and CicloInst = '1' and SysHold = '0';

   --Los registros de habilitacion de salida indican a la segunda etapa de la ALU que
   --envie al exterior los resultados de las operaciones en el siguiente ciclo
   RegDataEn <= CicloInst and DataEnable when rising_edge(SysClk) and SysHold = '0';
   RegFlagEn <= CicloInst and FlagEnable when rising_edge(SysClk) and SysHold = '0';

   --Traslado de los signos de los operandos a la segunda etapa
   ------------------------------------------------------------
   --Los signos de los operandos A y B son trasladados tambien a la segunda etapa de la
   --ALU en forma secuencial, pues son usados para determinar el sobreflujo
   RegSignoOpA <= OperandoA(JPU16_DataBits-1)
                  when rising_edge(SysClk) and CicloInst = '1' and SysHold = '0';
   RegSignoOpB <= OperandoB(JPU16_DataBits-1)
                  when rising_edge(SysClk) and CicloInst = '1' and SysHold = '0';

   -----------------------------
   -- Segunda etapa de la ALU --
   -----------------------------

   -- Seleccion del resultado a la salida de la ALU
   ------------------------------------------------
   --De acuerdo al codigo de operacion, se determina si la salida tendra el resultado de
   --la operacion de logica binaria (NOT, OR, AND o XOR) o el resultado de la suma/resta
   --(ADD, ADDC, SUB, SUBB)
   ResultadoFinal <=
      ResultadoLB when RegCodigoOper0 = '0'  else  --Operaciones de logica binaria
      ResultadoSR(JPU16_DataBits-1 downto 0);      --Operaciones de suma y resta

   --Conexion del resultado final a la salida de la ALU
   Resultado <= ResultadoFinal when RegDataEn = '1' else    --Salida habilitada
                (others => '0');                            --Salida deshabilitada

   -- Determinacion del resultado de las banderas
   ----------------------------------------------
   --El acarreo de salida es igual al MSB del resultado de la suma/resta siempre que la
   --salida este habilitada
   SalBand.C <= ResultadoSR(JPU16_DataBits) when RegFlagEn = '1' else '0';

   --La bandera de cero se activa siempre que el resultado sea cero y la salida se active
   SalBand.Z <= '1' when ResultadoFinal = 0 and RegFlagEn = '1' else '0';

   --La bandera de negativo es igual al MSB del resultado final si se activa la salida
   SalBand.N <= ResultadoFinal(JPU16_DataBits-1) when RegFlagEn = '1' else '0';

   --Determinacion de la bandera de sobreflujo
   process (RegFlagEn, RegCodigoOper2, RegSignoOpA, RegSignoOpB,
            ResultadoSR(JPU16_DataBits-1))
   begin
      if RegFlagEn = '0' then
         --Si la salida no esta activada, la bandera generada debe ser 0
         SalBand.V <= '0';
      elsif RegCodigoOper2 = '0' then
         --Definicion de sobreflujo para la suma
         if RegSignoOpA /= RegSignoOpB then
            --Si los signos son diferentes, no puede haber sobreflujo
            SalBand.V <= '0';
         else
            --Si los signos son iguales pero el resultado es de signo distinto,
            --hay sobreflujo
            if RegSignoOpA /= ResultadoSR(JPU16_DataBits-1) then
               SalBand.V <= '1';
            else
               SalBand.V <= '0';
            end if;
         end if;
      else
         --Definicion de sobreflujo para la resta
         if RegSignoOpA = RegSignoOpB then
            --Si los signos son iguales, no puede haber sobreflujo
            SalBand.V <= '0';
         else
            --Si los signos son diferentes y el resultado es de signo distinto
            --que el primer operando (minuendo), hay sobreflujo
            if RegSignoOpA /= ResultadoSR(JPU16_DataBits-1) then
               SalBand.V <= '1';
            else
               SalBand.V <= '0';
            end if;
         end if;
      end if;
   end process;
end Funcionamiento;

-----------------------------------------------------
-- Entidad de la parte de multiplicacion de la ALU --
-----------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use work.JPU16_PACK.ALL;
use WORK.JPU16_DEFS.ALL;

entity JPU16_ALU_M is
   port (SysClk:     in STD_LOGIC;
         SysHold:    in STD_LOGIC;
         CicloInst:  in STD_LOGIC;
         UnitEnable: in STD_LOGIC;
         OperandoA:  in STD_LOGIC_VECTOR (JPU16_DataBits-1 downto 0);
         OperandoB:  in STD_LOGIC_VECTOR (JPU16_DataBits-1 downto 0);
         ResultadoL: out STD_LOGIC_VECTOR (JPU16_DataBits-1 downto 0);
         ResultadoH: out STD_LOGIC_VECTOR (JPU16_DataBits-1 downto 0);
         CodigoOper: in STD_LOGIC;
         SalBand:    out GRUPO_BANDERAS_ALU_M);
end JPU16_ALU_M;

architecture Funcionamiento of JPU16_ALU_M is
   --Registros con resultados parciales para la segunda etapa
   signal RegOperandoA: STD_LOGIC_VECTOR (JPU16_DataBits-1 downto 0) := (others => '0');
   signal RegOperandoB: STD_LOGIC_VECTOR (JPU16_DataBits-1 downto 0) := (others => '0');
   signal RegBandZ_A: STD_LOGIC := '0';
   signal RegBandZ_B: STD_LOGIC := '0';

   --Registros con señales de control
   signal RegCodigoOper: STD_LOGIC := '0';
   signal RegOutputEn: STD_LOGIC := '0';

   --Señales con resultados post procesados
   signal ResultadoCompleto: STD_LOGIC_VECTOR (JPU16_DataBits*2-1 downto 0);
begin
   -----------------------------
   -- Primera etapa de la ALU --
   -----------------------------

   --Los argumentos de multiplicacion son trasladados a registros para ser procesados en
   --la segunda etapa
   RegOperandoA <= OperandoA
                   when rising_edge(SysClk) and SysHold = '0' and  CicloInst = '1';
   RegOperandoB <= OperandoB
                   when rising_edge(SysClk) and SysHold = '0' and  CicloInst = '1';

   --La bandera Z es precalculada en base a los 2 operandos, puesto que si cualquiera de
   --ellos es cero, la salida sera cero tambien
   process (SysClk)
   begin
      if rising_edge(SysClk) then
         if SysHold = '0' and CicloInst = '1' then
            if OperandoA = 0 then
               RegBandZ_A <= '1';      --El operando A es cero
            else
               RegBandZ_A <= '0';
            end if;

            if OperandoB = 0 then
               RegBandZ_B <= '1';      --El operando B es cero
            else
               RegBandZ_B <= '0';
            end if;
         end if;
      end if;
   end process;

   --Traslado de las señales de control a la segunda etapa
   -------------------------------------------------------
   --El bit del codigo de operacion es trasladado a la segunda etapa para determinar el
   --tipo de operacion
   RegCodigoOper <= CodigoOper
                    when rising_edge(SysClk) and SysHold = '0' and  CicloInst = '1';

   --El registro de habilitacion de salida se activa en el ciclo siguiente si se
   --descodifica una instruccion valida
   RegOutputEn <= CicloInst and UnitEnable when rising_edge(SysClk) and SysHold = '0';

   -----------------------------
   -- Segunda etapa de la ALU --
   -----------------------------

   --La operacion de multiplicacion se realiza con o sin signo dependiendo del registro
   --de codigo de operacion
   ResultadoCompleto <= RegOperandoA * RegOperandoB when RegCodigoOper = '0' else
                        signed(RegOperandoA) * signed(RegOperandoB);

   --Conexion de la parte baja del resultado final a la salida de la ALU
   ResultadoL <= ResultadoCompleto(JPU16_DataBits-1 downto 0)
                 when RegOutputEn = '1' else (others => '0');

   --Conexion de la parte alta del resultado final a la salida de la ALU
   ResultadoH <= ResultadoCompleto(JPU16_DataBits*2-1 downto JPU16_DataBits);

   --El acarreo es el MSB de la parte baja del resultado si la salida esta habilitada
   SalBand.C <= ResultadoCompleto(JPU16_DataBits-1) when RegOutputEn = '1' else '0';

   --La bandera de cero se activa no a partir del resultado final, sino a partir de los
   --ceros precalculados siempre que la salida se active
   SalBand.Z <= RegBandZ_A or RegBandZ_B when RegOutputEn = '1' else '0';

   --La bandera de negativo es igual al MSB del resultado completo si se activa la salida
   SalBand.N <= ResultadoCompleto(JPU16_DataBits*2-1) when RegOutputEn = '1' else '0';
end Funcionamiento;

---------------------------------------------------------------
-- Entidad de la parte de logica de desplazamiento de la ALU --
---------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use work.JPU16_PACK.ALL;
use WORK.JPU16_DEFS.ALL;

entity JPU16_ALU_LD is
   port (SysClk:     in  STD_LOGIC;
         SysHold:    in  STD_LOGIC;
         CicloInst:  in  STD_LOGIC;
         UnitEnable: in STD_LOGIC;
         OperandoA:  in  STD_LOGIC_VECTOR (JPU16_DataBits-1 downto 0);
         OperandoB:  in  STD_LOGIC_VECTOR (3 downto 0);
         Resultado:  out STD_LOGIC_VECTOR (JPU16_DataBits-1 downto 0);
         CodigoOper: in  STD_LOGIC_VECTOR (2 downto 0);
         EntBandC:   in  STD_LOGIC;
         SalBand:    out GRUPO_BANDERAS_ALU_LD);
end JPU16_ALU_LD;

architecture Funcionamiento of JPU16_ALU_LD is
   --Registros con resultados parciales para la segunda etapa
   signal RegRotDes: STD_LOGIC_VECTOR (JPU16_DataBits-1 downto 0) := (others => '0');
   signal RegOperandoB: STD_LOGIC_VECTOR (1 downto 0) := (others => '0');
   signal RegRotC: STD_LOGIC_VECTOR (JPU16_DataBits-1 downto 0) := (others => '0');
   signal RegC: STD_LOGIC_VECTOR (3 downto 0) := (others => '0');

   --Registros con señales de control
   signal RegCodigoOper: STD_LOGIC_VECTOR (2 downto 0) := (others => '0');
   signal RegOutputEn: STD_LOGIC := '0';

   --Señales con resultados post procesados
   signal ResultadoRotDes:  STD_LOGIC_VECTOR (JPU16_DataBits-1 downto 0);
   signal ResultadoFinal: STD_LOGIC_VECTOR (JPU16_DataBits-1 downto 0);

   --Funcion de evaluacion para la primera etapa del barrel shifter
   ----------------------------------------------------------------
   --Esta funcion permite desplazar bits en grupos de 4 durante la primera etapa, para
   --las instrucciones SHL0, SHL1, ROL, SHR0, SHR1 y ROR
   function Barrel_S1(Dato: STD_LOGIC_VECTOR (JPU16_DataBits-1 downto 0); --Dato a operar
                      nPos: STD_LOGIC_VECTOR (1 downto 0);     --Posiciones a mover
                      Dir: STD_LOGIC;                          --Direccion de movimiento
                      Oper: STD_LOGIC;                         --Operacion (Rot./Despl.)
                      Relleno: STD_LOGIC)                      --Valor de bits entrantes
      return STD_LOGIC_VECTOR is
   begin
      --Primero se determina la clase de operacion (desplazamiento o rotacion)
      if Oper = '0' then
         --Para operaciones de desplazamiento, se determina la direccion
         if Dir = '0' then
            --Las operaciones de desplazamiento a la izquierda introducen bits de relleno
            case nPos is
            when "00"   => return Dato;   --En caso de 0 no se desplaza
            when "01"   => return Dato(11 downto 0) & ( 3 downto 0 => Relleno);
            when "10"   => return Dato( 7 downto 0) & ( 7 downto 0 => Relleno);
            when others => return Dato( 3 downto 0) & (11 downto 0 => Relleno);
            end case;
         else
            --Las operaciones de desplazamiento a la derecha tambien introducen relleno
            case nPos is
            when "00"   => return Dato;
            when "01"   => return ( 3 downto 0 => Relleno) & Dato(15 downto  4);
            when "10"   => return ( 7 downto 0 => Relleno) & Dato(15 downto  8);
            when others => return (11 downto 0 => Relleno) & Dato(15 downto 12);
            end case;
         end if;
      else
         --Las operaciones de rotacion se realizan segun la direccion
         if Dir = '0' then
            --Se realizan las rotaciones a la izquierda
            case nPos is
            when "00"   => return Dato;   --En caso de cero no se rota
            when "01"   => return Dato(11 downto 0) & Dato(15 downto 12);
            when "10"   => return Dato( 7 downto 0) & Dato(15 downto  8);
            when others => return Dato( 3 downto 0) & Dato(15 downto  4);
            end case;
         else
            --Se realizan las rotaciones a la derecha
            case nPos is
            when "00"   => return Dato;
            when "01"   => return Dato( 3 downto 0) & Dato(15 downto  4);
            when "10"   => return Dato( 7 downto 0) & Dato(15 downto  8);
            when others => return Dato(11 downto 0) & Dato(15 downto 12);
            end case;
         end if;
      end if;
   end function;

   --Funcion de evaluacion para la segunda etapa del barrel shifter
   ----------------------------------------------------------------
   --Esta funcion permite desplazar bits hasta 3 posiciones durante la segunda etapa,
   --para las instrucciones SHL0, SHL1, ROL, SHR0, SHR1 y ROR
   function Barrel_S2(Dato: STD_LOGIC_VECTOR (JPU16_DataBits-1 downto 0); --Dato a operar
                      nPos: STD_LOGIC_VECTOR (1 downto 0);     --Posiciones a mover
                      Dir: STD_LOGIC;                          --Direccion de movimiento
                      Oper: STD_LOGIC;                         --Operacion (Rot./Despl.)
                      Relleno: STD_LOGIC)                      --Valor de bits entrantes
      return STD_LOGIC_VECTOR is
   begin
      if Oper = '0' then
         if Dir = '0' then
            --Desplazamientos a la izquierda
            case nPos is
            when "00"   => return Dato;   --En caso de 0 no se desplaza
            when "01"   => return Dato(14 downto 0) & (0 downto 0 => Relleno);
            when "10"   => return Dato(13 downto 0) & (1 downto 0 => Relleno);
            when others => return Dato(12 downto 0) & (2 downto 0 => Relleno);
            end case;
         else
            --Desplazamientos a la derecha
            case nPos is
            when "00"   => return Dato;
            when "01"   => return (0 downto 0 => Relleno) & Dato(15 downto 1);
            when "10"   => return (1 downto 0 => Relleno) & Dato(15 downto 2);
            when others => return (2 downto 0 => Relleno) & Dato(15 downto 3);
            end case;
         end if;
      else
         if Dir = '0' then
            --Rotaciones a la izquierda
            case nPos is
            when "00"   => return Dato;   --En caso de cero no se rota
            when "01"   => return Dato(14 downto 0) & Dato(15 downto 15);
            when "10"   => return Dato(13 downto 0) & Dato(15 downto 14);
            when others => return Dato(12 downto 0) & Dato(15 downto 13);
            end case;
         else
            --Rotaciones a la derecha
            case nPos is
            when "00"   => return Dato;
            when "01"   => return Dato(0 downto 0) & Dato(15 downto 1);
            when "10"   => return Dato(1 downto 0) & Dato(15 downto 2);
            when others => return Dato(2 downto 0) & Dato(15 downto 3);
            end case;
         end if;
      end if;
   end function;

   --Funcion de evaluacion de acarreo para la primera etapa
   --------------------------------------------------------
   --Esta funcion determina los 4 candidatos posibles del acarreo a ser trasladados a la
   --segunda etapa mediante un registro de 4 bits. Notese que se da el mismo tratamiento
   --a la bandera de acarreo en todas las operaciones del barrel shifter.
   function Carry_S1(Dato: STD_LOGIC_VECTOR (JPU16_DataBits-1 downto 0); --Dato a operar
                     Cin: STD_LOGIC;                           --Valor inicial de acarreo
                     nPos: STD_LOGIC_VECTOR (1 downto 0);      --Posiciones a mover
                     Dir: STD_LOGIC)                           --Direccion de movimiento
      return STD_LOGIC_VECTOR is
   begin
      if Dir = '0' then
         --Movimientos a la izquierda
         case nPos is
         when "00"   => return Cin & Dato(15 downto 13);
         when "01"   => return Dato(12 downto 9);
         when "10"   => return Dato(8 downto 5);
         when others => return Dato(4 downto 1);
         --Nota: Como no es posible un desplazamiento de 16 bits, el bit 0 no es un
         --candidato viable
         end case;
      else
         case nPos is
         --Movimientos a la derecha
         when "00"   => return Dato(2 downto 0) & Cin;
         when "01"   => return Dato(6 downto 3);
         when "10"   => return Dato(10 downto 7);
         when others => return Dato(14 downto 11);
         --Nota: De manera similar el bit 15 no es un candidato viable
         end case;
      end if;
      --Nota: en los casos en que la magnitud del desplazamiento sea menor a 4
      --posiciones, el acarreo de entrada se convierte en un candidato potencial para el
      --caso particular de que el desplazamiento sea de 0 posiciones
   end function;

   --Funcion de evaluacion de acarreo para la segunda etapa
   --------------------------------------------------------
   --Esta funcion elige la bandera de acarreo final de los 4 posibles candidatos
   --escogidos en la primera etapa
   function Carry_S2(Cin: STD_LOGIC_VECTOR (3 downto 0);       --Valores de acarreo
                     nPos: STD_LOGIC_VECTOR (1 downto 0);      --Posiciones a mover
                     Dir: STD_LOGIC)                           --Direccion de movimiento
      return STD_LOGIC is
   begin
      if Dir = '0' then
         --Seleccion hacia la izquierda
         case nPos is
         when "00"   => return Cin(3);
         when "01"   => return Cin(2);
         when "10"   => return Cin(1);
         when others => return Cin(0);
         end case;
      else
         --Seleccion hacia la derecha
         case nPos is
         when "00"   => return Cin(0);
         when "01"   => return Cin(1);
         when "10"   => return Cin(2);
         when others => return Cin(3);
         end case;
      end if;
   end function;
begin
   -----------------------------
   -- Primera etapa de la ALU --
   -----------------------------

   --Proceso para determinar el resultado preliminar de las instrucciones SHL0, SHL1,
   --ROL, SHR0, SHR1 y ROR
   process (SysClk)
   begin
      if rising_edge(SysClk) then
         if SysHold = '0' and not (CicloInst = '1' and UnitEnable = '1' and
                                   CodigoOper(1 downto 0) /= "11") then
            --Si no se habilita la logica de las instrucciones, se limpia el registro
            RegRotDes <= (others => '0');
            --Nota: Esta limpieza se hace en las instrucciones ROLC y RORC para no
            --interferir con ellas (se realiza una rotacion nula en la segunda etapa)
         elsif SysHold = '0' and  CicloInst = '1' then
            --El resultado se determina a traves de la funcion de etapa 1 correspondiente
            RegRotDes <= Barrel_S1(OperandoA, OperandoB(3 downto 2),
                                   CodigoOper(2), CodigoOper(1), CodigoOper(0));
         end if;
      end if;
   end process;

   --Proceso para trasladar los LSB del operando B a la segunda etapa
   process (SysClk)
   begin
      if rising_edge(SysClk) then
         if SysHold = '0' and not (CicloInst = '1' and UnitEnable = '1') then
            --Si no se habilita la logica de las instrucciones, se limpia el registro
            RegOperandoB <= (others => '0');
         elsif SysHold = '0' and  CicloInst = '1' then
            --Si la logica se habilita, se hace el traslado
            RegOperandoB <= OperandoB(1 downto 0);
         end if;
      end if;
   end process;

   --Proceso para determinar el resultado de las instrucciones ROLC y RORC
   process (SysClk)
   begin
      if rising_edge(SysClk) then
         if SysHold = '0' and not (CicloInst = '1' and UnitEnable = '1' and
                                   CodigoOper(1 downto 0) = "11") then
            --Si no se habilita la logica de las instrucciones, se limpia el registro
            RegRotC <= (others => '0');
         elsif SysHold = '0' and  CicloInst = '1' then
            --El resultado se determina en base a la direccion de rotacion
            if CodigoOper(2) = '0' then
               RegRotC <= OperandoA(14 downto 0) & EntBandC;      --ROLC
            else
               RegRotC <= EntBandC & OperandoA(15 downto 1);      --RORC
            end if;
         end if;
      end if;
   end process;

   --Proceso para determinar el resultado previo del acarreo para todas las instrucciones
   process (SysClk)
   begin
      if rising_edge(SysClk) then
         if SysHold = '0' and not (CicloInst = '1' and UnitEnable = '1') then
            --Si no se habilita la logica de las instrucciones, se limpia el registro
            RegC <= (others => '0');
         elsif SysHold = '0' and  CicloInst = '1' then
            --El resultado se determina a traves de la funcion de etapa 1 correspondiente
            RegC <= Carry_S1(OperandoA, EntBandC, OperandoB(3 downto 2), CodigoOper(2));
         end if;
      end if;
   end process;

   --Traslado de las señales de control a la segunda etapa
   -------------------------------------------------------
   --El codigo de operacion es trasladado para determinar el resultado final
   RegCodigoOper <= CodigoOper
                    when rising_edge(SysClk) and SysHold = '0' and CicloInst = '1';

   --El registro de habilitacion de salida se activa en el ciclo siguiente si se
   --descodifica una instruccion valida
   RegOutputEn <= CicloInst and UnitEnable when rising_edge(SysClk) and SysHold = '0';

   -----------------------------
   -- Segunda etapa de la ALU --
   -----------------------------
   --El resultado para las instrucciones de rotacion/desplazamieto se determina con la
   --funcion de barrel shifter para etapa 2
   ResultadoRotDes <= Barrel_S2(RegRotDes, RegOperandoB,
                                RegCodigoOper(2), RegCodigoOper(1), RegCodigoOper(0));

   --Dado que los registros de cada etapa se limpian cuando no se descodifica la
   --instruccion correspondiente, el resultado final es simplemente la combinacion OR del
   --resultado de rotacion/desplazamiento con el de rotacion con acarreo
   ResultadoFinal <= ResultadoRotDes or RegRotC;

   --Conexion del resultado final a la salida de la ALU
   Resultado <= ResultadoFinal;

   --La bandera de acarreo se determina mediante la funcion de etapa 2 correspondiente
   SalBand.C <= Carry_S2(RegC, RegOperandoB, RegCodigoOper(2));

   --La bandera de cero se activa siempre que el resultado sea cero y la salida se active
   SalBand.Z <= '1' when ResultadoFinal = 0 and RegOutputEn = '1' else '0';

   --La bandera de negativo es igual al MSB del resultado final
   SalBand.N <= ResultadoFinal(JPU16_DataBits-1);

   --Nota: Las banderas C y N no son afectadas por el registro de habilitacion de salida,
   --puesto que los registros de donde provienen sus datos iniciales son limpiados en la
   --primera etapa en caso que la unidad se deshabilite
end Funcionamiento;