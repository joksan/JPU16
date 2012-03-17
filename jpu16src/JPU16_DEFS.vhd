----------------------------------------------------------------------
-- Paquete con las constantes y tipos usados a lo largo del sistema --
----------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use work.JPU16_MEM_SIZE_DEFS.ALL;

package JPU16_DEFS is
   -------------------------------------
   -- Declaracion de tipos y subtipos --
   -------------------------------------
   --Definicion del grupo de registros/buses asociados a las banderas
   type GRUPO_BANDERAS is record
      C: STD_LOGIC;
      Z: STD_LOGIC;
      N: STD_LOGIC;
      V: STD_LOGIC;
      I: STD_LOGIC;
   end record;

   --Grupo de registros/buses asociados a las banderas guardadas durante las
   --interrupciones
   type BANDERAS_SOMBRA is record
      C: STD_LOGIC;
      Z: STD_LOGIC;
      N: STD_LOGIC;
      V: STD_LOGIC;
   end record;

   --Grupo de señales de habilitacion generadas por la unidad de control cuando
   --descodifica las instrucciones correspondientes
   type INSTRUCCIONES_VALIDAS is record
      PC:          STD_LOGIC; --JMPX, CALLX, RETURN, IDRET, IERET
      IXRET:       STD_LOGIC; --IDRET, IERET (para restaurar banderas sombra solamente)
      ALU_LBSR_NR: STD_LOGIC; --TEST, CMP
      ALU_LBSR:    STD_LOGIC; --NOT, OR, AND, XOR, ADDX, SUBX
      ALU_LD:      STD_LOGIC; --SHLX, SHRX, ROLX, RORX
      Banderas:    STD_LOGIC; --CLRX, SETX
      MoveRegInm:  STD_LOGIC; --MOVE Registro, Inmediato
      MoveRamRd:   STD_LOGIC; --MOVE Registro, [Memoria]
      MoveRamWr:   STD_LOGIC; --MOVE [Memoria], Registro
      IO_IN:       STD_LOGIC; --IN
      IO_OUT:      STD_LOGIC; --OUT
   end record;

   --------------------------------
   -- Declaracion de componentes --
   --------------------------------

   -- Componentes de logica superior
   ---------------------------------
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
   end component;

   component JPU16_ALU_LD
   generic (nBits_ALU: integer := 16);
   port (Operando: in STD_LOGIC_VECTOR (nBits_ALU-1 downto 0);
         Resultado: out STD_LOGIC_VECTOR (nBits_ALU-1 downto 0);
         CodigoOper: in STD_LOGIC_VECTOR (2 downto 0);
         EntBandC: in STD_LOGIC;
         SalBandC: out STD_LOGIC;
         SalBandZ: out STD_LOGIC;
         SalBandN: out STD_LOGIC);
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
         SolInt:      in  STD_LOGIC;
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

   -- Componentes de buses
   -----------------------
   component JPU16_BUS_OR_BANDERAS
   port (EntBus_INSTR:    in  GRUPO_BANDERAS;
         EntBus_ALU_LBSR: in  GRUPO_BANDERAS;
         EntBus_ALU_LD:   in  GRUPO_BANDERAS;
         SelBus_INSTR:    in  STD_LOGIC;
         SelBus_ALU_LBSR: in  STD_LOGIC;
         SelBus_ALU_LD:   in  STD_LOGIC;
         SalBus:          out GRUPO_BANDERAS);
   end component;

   component JPU16_BUS_OR_Q
   generic (nBits_Bus: integer := 16);
   port (EntBus_INSTR:    in  STD_LOGIC_VECTOR (nBits_Bus-1 downto 0);
         EntBus_REGS_RXX: in  STD_LOGIC_VECTOR (nBits_Bus-1 downto 0);
         SelBus_ModoDir:  in  STD_LOGIC;
         SalBus:          out STD_LOGIC_VECTOR (nBits_Bus-1 downto 0));
   end component;

   component JPU16_BUS_OR_R
   generic (nBits_Bus: integer := 16);
   port (EntBus_ALU_LBSR: in  STD_LOGIC_VECTOR (nBits_Bus-1 downto 0);
         EntBus_ALU_LD:   in  STD_LOGIC_VECTOR (nBits_Bus-1 downto 0);
         EntBus_Q:        in  STD_LOGIC_VECTOR (nBits_Bus-1 downto 0);
         EntBus_RAM:      in  STD_LOGIC_VECTOR (nBits_Bus-1 downto 0);
         EntBus_IO:       in  STD_LOGIC_VECTOR (nBits_Bus-1 downto 0);
         SelBus_ALU_LBSR: in  STD_LOGIC;
         SelBus_ALU_LD:   in  STD_LOGIC;
         SelBus_Q:        in  STD_LOGIC;
         SelBus_RAM:      in  STD_LOGIC;
         SelBus_IO:       in  STD_LOGIC;
         SalBus:          out STD_LOGIC_VECTOR (nBits_Bus-1 downto 0));
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