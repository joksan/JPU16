--------------------------------------------------------
-- Paquete con el componente principal del procesador --
--------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

package JPU16_PACK is
   --Cantidad de bits de datos que maneja el procesador
   constant JPU16_DataBits: integer := 16;

   --Declaracion de tipos de bus
   subtype JPU16_INPUT_BUS is STD_LOGIC_VECTOR (JPU16_DataBits-1 downto 0);
   type JPU16_INPUT_BUS_ARRAY is array (integer range <>) of JPU16_INPUT_BUS;
   subtype JPU16_OUTPUT_BUS is STD_LOGIC_VECTOR (JPU16_DataBits-1 downto 0);
   subtype JPU16_IO_ADDR_BUS is STD_LOGIC_VECTOR (JPU16_DataBits-1 downto 0);

   --Declaracion del componente principal del procesador
   component JPU16
   generic (nInputPorts: integer := 1);
   port (SysClk:  in  STD_LOGIC;
         Reset:   in  STD_LOGIC;
         SysHold: in  STD_LOGIC;
         Int:     in  STD_LOGIC;
         IO_Din:  in  JPU16_INPUT_BUS_ARRAY (nInputPorts-1 downto 0);
         IO_Dout: out JPU16_OUTPUT_BUS;
         IO_Addr: out JPU16_IO_ADDR_BUS;
         IO_RD:   out STD_LOGIC;
         IO_WR:   out STD_LOGIC);
   end component;
end JPU16_PACK;

----------------------------------------------------------------------
-- Paquete con las constantes y tipos usados a lo largo del sistema --
----------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use work.JPU16_PACK.ALL;
use work.JPU16_MEM_SIZE_DEFS.ALL;

package JPU16_DEFS is
   -------------------------------------
   -- Declaracion de tipos y subtipos --
   -------------------------------------
   --Definicion del grupo completo de banderas (usado en definiciones tanto de registros
   --como de buses)
   type GRUPO_BANDERAS is record
      C: STD_LOGIC;
      Z: STD_LOGIC;
      N: STD_LOGIC;
      V: STD_LOGIC;
      I: STD_LOGIC;
   end record;

   --Grupo de banderas guardadas durante las interrupciones
   type GRUPO_BANDERAS_SOMBRA is record
      C: STD_LOGIC;
      Z: STD_LOGIC;
      N: STD_LOGIC;
      V: STD_LOGIC;
   end record;

   --Grupo de banderas usadas por la parte de logica binaria/suma/resta de la ALU
   type GRUPO_BANDERAS_ALU_LBSR is record
      C: STD_LOGIC;
      Z: STD_LOGIC;
      N: STD_LOGIC;
      V: STD_LOGIC;
   end record;

   --Grupo de banderas usadas por la parte de multiplicacion de la ALU
   type GRUPO_BANDERAS_ALU_M is record
      C: STD_LOGIC;
      Z: STD_LOGIC;
      N: STD_LOGIC;
   end record;

   --Grupo de banderas usadas por la parte de logica de desplazamiento de la ALU
   type GRUPO_BANDERAS_ALU_LD is record
      C: STD_LOGIC;
      Z: STD_LOGIC;
      N: STD_LOGIC;
   end record;

   --Grupo de señales de habilitacion generadas por la unidad de control cuando
   --descodifica las instrucciones correspondientes
   type INSTRUCCIONES_VALIDAS is record
      PC:         STD_LOGIC;  --JMPX, CALLX, RETURN, IDRET, IERET
      IXRET:      STD_LOGIC;  --IDRET, IERET (para restaurar banderas sombra solamente)
      ALU_LBSR_D: STD_LOGIC;  --NOT, OR, AND, XOR, ADDX, SUBX
      ALU_LBSR_F: STD_LOGIC;  --TEST, CMP, NOT, OR, AND, XOR, ADDX, SUBX
      ALU_M:      STD_LOGIC;  --MUL, SMUL
      ALU_LD:     STD_LOGIC;  --SHLX, SHRX, ROLX, RORX
      Banderas:   STD_LOGIC;  --CLRX, SETX
      MoveRegInm: STD_LOGIC;  --MOVE Registro, Registro/Inmediato
      MoveRamRd:  STD_LOGIC;  --MOVE Registro, [Memoria]
      MoveRamWr:  STD_LOGIC;  --MOVE [Memoria], Registro
      IO_IN:      STD_LOGIC;  --IN
      IO_OUT:     STD_LOGIC;  --OUT
   end record;

   --------------------------------------------------------
   -- Declaracion de componentes internos del procesador --
   --------------------------------------------------------
   component JPU16_CU
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
   end component;

   component JPU16_ALU_LBSR
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
   end component;

   component JPU16_ALU_M is
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
   end component;

   component JPU16_ALU_LD
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
   end component;

   component JPU16_REGS_RXX
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
   end component;

   component JPU16_REGS_BANDERAS
   port (SysClk:     in  STD_LOGIC;
         SyncReset2: in  STD_LOGIC;
         SysHold:    in  STD_LOGIC;
         CicloInst:  in  STD_LOGIC;
         SolInt:     in  STD_LOGIC;
         RestSombra: in  STD_LOGIC;
         Wen:        in  GRUPO_BANDERAS;
         EntBand:    in  GRUPO_BANDERAS;
         SalBand:    out GRUPO_BANDERAS);
   end component;

   component JPU16_REGS_PC
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
   end component;

   component JPU16_PROG_MEM
   generic (nBits_BusProg: integer := 26);
   Port (SysClk:    in  STD_LOGIC;
         SysHold:   in  STD_LOGIC;
         CicloInst: in  STD_LOGIC;
         Direccion: in  STD_LOGIC_VECTOR (nBits_DirProg - 1 downto 0);
         DatoProg:  out STD_LOGIC_VECTOR (nBits_BusProg - 1 downto 0));
   end component;

   component JPU16_RAM
   generic (nBits_BusDatos: integer := 16);
   port (SysClk:    in  STD_LOGIC;
         SysHold:   in  STD_LOGIC;
         Ren:       in  STD_LOGIC;
         Wen:       in  STD_LOGIC;
         Direccion: in  STD_LOGIC_VECTOR (nBits_DirDatos-1 downto 0);
         DatoEnt:   in  STD_LOGIC_VECTOR (nBits_BusDatos-1 downto 0);
         DatoSal:   out STD_LOGIC_VECTOR (nBits_BusDatos-1 downto 0));
   end component;
end JPU16_DEFS;

-------------------------------------------------------------------
-- Paquete con las señales internas exportadas por el procesador --
-------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.JPU16_MEM_SIZE_DEFS.ALL;

package JPU16_EXPORTS is
   ----------------------------------------------
   -- Declaracion de elementos para simulacion --
   ----------------------------------------------
   --Nota: Las declaraciones de esta seccion seran ignoradas durante las optimizaciones
   --en el proceso de sintesis

   --Valor actual del contador de programa
   signal Contador_Programa: STD_LOGIC_VECTOR (nBits_DirProg-1 downto 0);
   --Codigo de operacion de la instruccion actual
   signal Opcode: STD_LOGIC_VECTOR (25 downto 0);
end JPU16_EXPORTS;