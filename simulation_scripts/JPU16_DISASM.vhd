----------------------------------------------------------------
-- Paquete con los elementos exportados por el desensamblador --
----------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

package JPU16_DISASM_DEFS is
   --Cadena que contiene la instruccion desensamblada (incluye el nombre de la
   --instruccion y sus argumentos)
   signal Instruccion: STD_LOGIC_VECTOR (0 to 255) := (others => '0');

   --Componente con la definicion del desensamblador
   component JPU16_DISASM is
   end component;
end package;

------------------------------------------
-- Entidad principal del desensamblador --
------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.std_logic_arith.all;
use IEEE.STD_LOGIC_TEXTIO.all;
library STD;
use STD.TEXTIO.ALL;
use work.JPU16_DISASM_DEFS.all;
use work.JPU16_EXPORTS.all;

entity JPU16_DISASM is
end JPU16_DISASM;

architecture Simulacion of JPU16_DISASM is
   --Procedimiento que convierte una dato tipo LINE hacia un vector de STD_LOGIC en formato
   --ascii para su visualizacion en el simulador
   procedure Conv_Linea_Vector(signal Vector: out STD_LOGIC_VECTOR; Linea: inout LINE) is
      --Variables que especifican el rango de operacion dentro del vector para cada
      --iteracion del lazo
      variable Rango_L: integer;
      variable Rango_H: integer;
   begin
      --Se itera dentro del vector tantas veces como caracteres de 8 bits quepan en el
      for i in 0 to (Vector'length/8)-1 loop
         --El rango para cada caracter se hace de tal manera que se abarquen 8 bits
         Rango_L := i*8;
         Rango_H := Rango_L+7;
         --Debido a que la linea de texto puede tener una cantidad de caracteres
         --diferente del vector (la linea tiene una longitud variable, mientras que el
         --vector tiene longitud fija), se verifica que la posicion dentro del vector no
         --exceda la longitud de la linea
         if (i+1) <= Linea'length then
            --Si no excede la longitud, entonces se copia un caracter desde la linea
            --hacia el vector, convirtiendolo primero a ascii (buscando la posicion del
            --caracter en la secuencia de datos tipo character) y luego el entero con el
            --codigo ascii a vector de 8 bits
            Vector(Rango_L to Rango_H) <=
               conv_std_logic_vector(character'pos(Linea.all(i+1)), 8);
            --Nota: Se usan indices "(i+1)" porque la linea de texto es de tipo LINE, y
            --su primer elemento es indice 1 y no 0
         else
            --Si se excede la longitud, entonces se rellena el resto del vector con
            --espacios (el codigo ascii del espacio en hexadecimal es 0x20)
            Vector(Rango_L to Rango_H) <= X"20";
         end if;
      end loop;
   end procedure;

   --Procedimiento que escribe el registro RX de una instruccion, codificado en los bits
   --del 16 al 19 del opcode
   procedure Escribir_Arg_RX(Linea: inout LINE) is
   begin
      WRITE(Linea, 'r');
      WRITE(Linea, conv_integer(opcode(19 downto 16)));
   end procedure;

   --Procedimiento que escribe el registro RY de una instruccion o bien un valor literal,
   --con corchetes opcionales.
   procedure Escribir_Arg_RY_LIT(Linea: inout LINE; bCorchetes: in boolean := false) is
   begin
      --Si se solicitan corchetes los agrega
      if bCorchetes then WRITE(Linea, '['); end if;

      if opcode(20) = '0' then
         --Si la instruccion codifica el argumento como literal (basado en el bit 20 del
         --opcode), lo escribe
         WRITE(Linea, "0x");
         HWRITE(Linea, opcode(15 downto 0));
      else
         --Si la instruccion codifica el argumento como registro, entonces lo escribe
         --basado en los bits del 12 al 15 del opcode
         WRITE(Linea, 'r');
         WRITE(Linea, conv_integer(opcode(15 downto 12)));
      end if;

      --Agrega el corchete opcional
      if bCorchetes then WRITE(Linea, ']'); end if;      
   end procedure;

   --Procedimiento que escribe el registro RY de una instruccion, o bien la direccion de
   --destino de un salto
   procedure Escribir_Arg_RY_DIR(Linea: inout LINE) is
   begin
      if opcode(20) = '0' then
         --Si la instruccion codifica el argumento como literal, entonces computa el
         --destino del salto y lo escribe
         WRITE(Linea, "0x");
         HWRITE(Linea, Contador_Programa + opcode(15 downto 0));
      else
         --Si la instruccion codifica el argumento como registro, lo escribe
         WRITE(Linea, 'r');
         WRITE(Linea, conv_integer(opcode(15 downto 12)));
      end if;
   end procedure;

   --Procedimiento que escribe una instruccion con sintaxis de operacion de ALU de 1
   --argumento
   procedure Escr_Instr_ALU_1_Arg(Linea: inout LINE; Nombre: in string) is
   begin
      WRITE(Linea, Nombre);         --Escribe el nombre de la instruccion
      WRITE(Linea, ' ');            --Espacio separador
      Escribir_Arg_RX(Linea);       --Escribe el argumento RX
   end procedure;

   --Procedimiento que escribe una instruccion con sintaxis de operacion de ALU de 2
   --argumentos
   procedure Escr_Instr_ALU_2_Arg(Linea: inout LINE; Nombre: in string) is
   begin
      --Debido a que las instrucciones con esta forma sintactica son varias, se escribe
      --la cadena con el nombre directamente
      WRITE(Linea, Nombre);
      WRITE(Linea, ' ');            --Espacio separador
      Escribir_Arg_RX(Linea);       --Escribe el argumento RX
      Write(Linea, ", ");           --Coma separadora
      Escribir_Arg_RY_LIT(Linea);   --Escribe el argumento RY/Literal
   end procedure;

   --Procedimiento que escribe una instruccion de desplazamieno o rotacion
   procedure Escr_Instr_ALU_LD(Linea: inout LINE) is
   begin
      --Determina el nombre de la instruccion en base a los bits del 9 al 11
      case opcode(11 downto 9) is
      when  "000" => WRITE(Linea, "shl0 ");
      when  "001" => WRITE(Linea, "shl1 ");
      when  "010" => WRITE(Linea, "rol ");
      when  "011" => WRITE(Linea, "rolc ");
      when  "100" => WRITE(Linea, "shr0 ");
      when  "101" => WRITE(Linea, "shr1 ");
      when  "110" => WRITE(Linea, "ror ");
      when  "111" => WRITE(Linea, "rorc ");
      end case;

      Escribir_Arg_RX(Linea);             --Escribe el argumento RX

      --Determina si la instruccion involucra acarreo (rolc y rorc)
      if opcode(10 downto 9) /= "11" then
         --En caso que no sea involucrado, escribe el segundo argumento
         WRITE(Linea, ", ");                 --Coma separadora
         if opcode(20) = '0' then
            --Si el argumento es un literal de 4 bits (determinado segun bit 20 del
            --opcode), lo escribe
            WRITE(Linea, conv_integer(opcode(3 downto 0)));
         else
            --Si el argumento es un registro, lo escribe
            WRITE(Linea, 'r');
            WRITE(Linea, conv_integer(opcode(15 downto 12)));
         end if;
      else
         --En caso de involucrarlo, corrobora que el modo de direccionamiento sea
         --inmediato y que argumento literal de 4 bits sea "0001", caso contrario imprime
         --un segundo argumento con signos de interrogacion para llamar la atencion
         if opcode(20) /= '0' or opcode(3 downto 0) /= "0001" then
            WRITE(Linea, ", ???");
         end if;
      end if;
   end procedure;

   --Procedimiento que escribe una instruccion de movimiento de datos hacia la RAM
   procedure Escr_Instr_move_to_ram(Linea: inout LINE) is
   begin
      WRITE(Linea, "move ");              --Escribe el nombre de la instruccion
      Escribir_Arg_RY_LIT(Linea, true);   --Escribe el argumento RY/Literal con corchetes
      WRITE(Linea, ", ");                 --Coma separadora
      Escribir_Arg_RX(Linea);             --Escribe el argumento RX
   end procedure;

   --Procedimiento que escribe una instruccion de salida de datos a I/O
   procedure Escr_Instr_out(Linea: inout LINE) is
   begin
      WRITE(Linea, "out ");         --Escribe el nombre de la instruccion
      Escribir_Arg_RY_LIT(Linea);   --Escribe el argumento RY/Literal
      WRITE(Linea, ", ");           --Coma separadora
      Escribir_Arg_RX(Linea);       --Escribe el argumento RX
   end procedure;

   --Procedimiento que escribe una instruccion de movimiento de datos desde la RAM
   procedure Escr_Instr_move_from_ram(Linea: inout LINE) is
   begin
      WRITE(Linea, "move ");              --Escribe el nombre de la instruccion
      Escribir_Arg_RX(Linea);             --Escribe el argumento RX
      WRITE(Linea, ", ");                 --Coma separadora
      Escribir_Arg_RY_LIT(Linea, true);   --Escribe el argumento RY/Literal con corchetes
   end procedure;

   --Procedimiento que escribe una instruccion de entrada de datos de I/O
   procedure Escr_Instr_in(Linea: inout LINE) is
   begin
      WRITE(Linea, "in ");          --Escribe el nombre de la instruccion
      Escribir_Arg_RX(Linea);       --Escribe el argumento RX
      WRITE(Linea, ", ");           --Coma separadora
      Escribir_Arg_RY_LIT(Linea);   --Escribe el argumento RY/Literal
   end procedure;

   --Procedimiento que escribe una instruccion de salto o llamada de subrutina
   procedure Escr_Instr_Salto(Linea: inout LINE) is
   begin
      --Determina mediante el bit 22 del opcode si la instruccion es de salto o llamada,
      --para escribir correctamente el inicio de su nombre
      if opcode(22) = '0' then
         WRITE(Linea, "jmp");
      else
         WRITE(Linea, "call");
      end if;

      --Determina mediante el bit 21 del opcode si la instruccion es de salto condicional
      if opcode(21) = '1' then
         --Si es un salto condicional, agrega un sufijo al nomrbre de la instruccion,
         --basado en la condicion codificada en los bits 16 al 18
         case opcode(18 downto 16) is
         when "000" => WRITE(Linea, "nc");
         when "001" => WRITE(Linea, "c");
         when "010" => WRITE(Linea, "nz");
         when "011" => WRITE(Linea, "z");
         when "100" => WRITE(Linea, "p");
         when "101" => WRITE(Linea, "n");
         when "110" => WRITE(Linea, "nv");
         when "111" => WRITE(Linea, "v");
         end case;
      end if;

      --Una vez escrito el nombre de la instruccion, escribe el resto
      WRITE(Linea, ' ');            --Espacio separador
      Escribir_Arg_RY_DIR(Linea);   --Escribe el argumento RY/Direccion
   end procedure;
begin
   --Proceso principal del desensamblador
   process (Opcode)
      --Variable con el texto descriptivo de la instruccion desensamblada
      variable Texto: LINE;
   begin
      --Cada vez que el opcode cambia, se procede inmediatamente a su desensamble
      if opcode'event then
         --Primeramente, se limpia la cadena de texto
         DEALLOCATE(Texto);

         --A continuacion se descodifican las instrucciones basandose en los bits mas
         --significativos del opcode, iniciando por la instruccion nop
         if opcode(25 downto 22) = "0000" then WRITE(Texto, "nop");
         --Luego se prosigue con las instrucciones de manipulacion de banderas
         elsif opcode(25 downto 16) = "0001000001" then WRITE(Texto, "clrc");
         elsif opcode(25 downto 16) = "0001100001" then WRITE(Texto, "setc");
         elsif opcode(25 downto 16) = "0001000010" then WRITE(Texto, "clrz");
         elsif opcode(25 downto 16) = "0001100010" then WRITE(Texto, "setz");
         elsif opcode(25 downto 16) = "0001000100" then WRITE(Texto, "clrn");
         elsif opcode(25 downto 16) = "0001100100" then WRITE(Texto, "setn");
         elsif opcode(25 downto 16) = "0001001000" then WRITE(Texto, "clrv");
         elsif opcode(25 downto 16) = "0001101000" then WRITE(Texto, "setv");
         elsif opcode(25 downto 16) = "0001010000" then WRITE(Texto, "clri");
         elsif opcode(25 downto 16) = "0001110000" then WRITE(Texto, "seti");
         --Instrucciones de prueba de datos (solo afectan banderas)
         elsif opcode(25 downto 21) = "00100" then Escr_Instr_ALU_2_Arg(Texto, "test");
         elsif opcode(25 downto 21) = "00101" then Escr_Instr_ALU_2_Arg(Texto, "cmp");
         --Instrucciones para almacenar datos fuera del procesador
         elsif opcode(25 downto 21) = "00110" then Escr_Instr_move_to_ram(Texto);
         elsif opcode(25 downto 21) = "00111" then Escr_Instr_out(Texto);
         --Instrucciones de control de flujo
         elsif opcode(25 downto 23) = "010" then Escr_Instr_Salto(Texto);
         elsif opcode(25 downto 22) = "0110" then  WRITE(Texto, "return");
         elsif opcode(25 downto 21) = "01110" then  WRITE(Texto, "idret");
         elsif opcode(25 downto 21) = "01111" then  WRITE(Texto, "ieret");
         --Instrucciones de Logica binaria y suma/resta (ALU)
         elsif opcode(25 downto 21) = "10000" then Escr_Instr_ALU_1_Arg(Texto, "not");
         elsif opcode(25 downto 21) = "10001" then Escr_Instr_ALU_2_Arg(Texto, "add");
         elsif opcode(25 downto 21) = "10010" then Escr_Instr_ALU_2_Arg(Texto, "or");
         elsif opcode(25 downto 21) = "10011" then Escr_Instr_ALU_2_Arg(Texto, "addc");
         elsif opcode(25 downto 21) = "10100" then Escr_Instr_ALU_2_Arg(Texto, "and");
         elsif opcode(25 downto 21) = "10101" then Escr_Instr_ALU_2_Arg(Texto, "sub");
         elsif opcode(25 downto 21) = "10110" then Escr_Instr_ALU_2_Arg(Texto, "xor");
         elsif opcode(25 downto 21) = "10111" then Escr_Instr_ALU_2_Arg(Texto, "subb");
         --Instrucciones de multiplicacion (ALU)
         elsif opcode(25 downto 21) = "11000" then Escr_Instr_ALU_2_Arg(Texto, "mul");
         elsif opcode(25 downto 21) = "11001" then Escr_Instr_ALU_2_Arg(Texto, "smul");
         --Instrucciones de desplazamiento y rotacion de bits (ALU)
         elsif opcode(25 downto 21) = "11100" then Escr_Instr_ALU_LD(Texto);
         --Instruccion de movimiento que involucran solo registros
         elsif opcode(25 downto 21) = "11101" then Escr_Instr_ALU_2_Arg(Texto, "move");
         --Instrucciones para tomar datos desde fuera del procesador
         elsif opcode(25 downto 21) = "11110" then Escr_Instr_move_from_ram(Texto);
         elsif opcode(25 downto 21) = "11111" then Escr_Instr_in(Texto);
         --Si la instruccion no se reconoce, se imprimen signos de interrogacion para
         --llamar la atencion
         else WRITE(Texto, "???");
         end if;

         --Al final del proceso, se convierte la cadena con el texto descriptivo a un
         --vector, de manera que se despliegue correctamente en el simulador
         Conv_Linea_Vector(Instruccion, Texto);
      end if;
   end process;
end Simulacion;