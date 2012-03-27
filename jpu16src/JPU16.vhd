--------------------------------------------------------
-- Paquete con el componente principal del procesador --
--------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

package JPU16_Pack is
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
end JPU16_Pack;

--------------------------------------
-- Entidad principal del procesador --
--------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use work.JPU16_DEFS.ALL;
use work.JPU16_EXPORTS.ALL;
use work.JPU16_MEM_SIZE_DEFS.ALL;
use work.JPU16_Pack.ALL;

entity JPU16 is
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
end JPU16;

architecture Funcionamiento of JPU16 is
   constant nBits_BusProg: integer := 26;

   subtype BUS_DATOS is STD_LOGIC_VECTOR (JPU16_DataBits-1 downto 0);
   type MULTI_BUS_DATOS is array (integer range <>) of BUS_DATOS;
   type MULTI_GRUPO_BANDERAS is array (integer range <>) of GRUPO_BANDERAS;

   -------------------------------------
   -- Declaracion de señales internas --
   -------------------------------------
   signal SyncReset:   STD_LOGIC_VECTOR (2 downto 1);
   signal CicloInst:   STD_LOGIC;
   signal SolInt:      STD_LOGIC;

   signal PC:      STD_LOGIC_VECTOR (nBits_DirProg-1 downto 0);
   signal BusProg: STD_LOGIC_VECTOR (nBits_BusProg-1 downto 0);

   signal InstVal: INSTRUCCIONES_VALIDAS;

   signal Banderas:         GRUPO_BANDERAS;
   signal Wen_Banderas:     GRUPO_BANDERAS;
   signal BandVal_ALU_LBSR: STD_LOGIC;

   signal EntBusOR_Banderas: MULTI_GRUPO_BANDERAS (2 downto 0);
   signal SalBusOR_Banderas: GRUPO_BANDERAS;

   signal BusP: BUS_DATOS;

   signal EntBusOR_BusQ: MULTI_BUS_DATOS (1 downto 0);
   signal SalBusOR_BusQ: BUS_DATOS;
   signal RegSal_BusQ: BUS_DATOS := (others => '0');

   signal EntBusOR_BusR: MULTI_BUS_DATOS (4 downto 0);
   signal SalBusOR_BusR: BUS_DATOS;

   signal RAM_Ren: STD_LOGIC;
   signal RAM_Wen: STD_LOGIC;
begin
   --Definicion de entradas de buses de acuerdo a las instrucciones decodificadas
   ------------------------------------------------------------------------------

   --La entrada 0 del bus tipo OR de las banderas contiene el valor indicado por la
   --instruccion de cambio de estado de bandera
   EntBusOR_Banderas(0) <= (others => '1') when BusProg(nBits_BusProg-5) = '1'
      else (others => '0');

   --Señal que indica que la parte de logica binaria y suma/resta de la ALU genera
   --nuevos valores de banderas (independientemente de que se guarde el resultado)
   BandVal_ALU_LBSR <= InstVal.ALU_LBSR_NR or InstVal.ALU_LBSR;

   --La entrada 0 del bus Q contiene el valor literal contenido en la instruccion
   EntBusOR_BusQ(0) <= BusProg(JPU16_DataBits-1 downto 0);

   --La salida del bus Q es capturada en un registro, para disminuir la carga
   --combinacional de las instrucciones de movimiento entre registros y literales
   RegSal_BusQ <= SalBusOR_BusQ
                  when rising_edge(SysClk) and CicloInst = '1' and SysHold = '0';

   --La entrada 2 del bus R contiene el registro del bus Q (para instrucciones de
   --movimiento entre registros y de literales)
   EntBusOR_BusR(2) <= RegSal_BusQ;

   ------------------------------------------------
   -- Mapeo de los puertos de entradas y salidas --
   ------------------------------------------------
   --Puertos de entrada
   process (IO_Din)
      variable Resultado: BUS_DATOS;
   begin
      Resultado := (others => '0');
      for i in 0 to nInputPorts-1 loop
         Resultado := Resultado or IO_Din(i);
      end loop;
      EntBusOR_BusR(4) <= Resultado;
   end process;

   --Puertos de salida
   IO_Dout <= BusP;
   IO_Addr <= SalBusOR_BusQ;

   --Señales de control del bus de I/O:
   IO_RD <= '1' when InstVal.IO_IN = '1' and CicloInst = '0' and SyncReset(2) = '0' and
            SolInt = '0' else '0';
   IO_WR <= '1' when InstVal.IO_OUT = '1' and CicloInst = '0' and SyncReset(2) = '0' and
            SolInt = '0' else '0';

   --Señales de control de la memoria RAM:
   RAM_Ren <= '1' when InstVal.MoveRamRd = '1' and CicloInst = '1' and
              SyncReset(2) = '0' and SolInt = '0' else '0';
   RAM_Wen <= '1' when InstVal.MoveRamWr = '1' and CicloInst = '1' and
              SyncReset(2) = '0' and SolInt = '0' else '0';

   -----------------------------------------------------
   -- Definicion de las instancias de los componentes --
   -----------------------------------------------------

   -- Componentes de logica superior
   ---------------------------------
   CU: JPU16_CU
   generic map (nBits_BusProg => nBits_BusProg)
   port map (SysClk          => SysClk,
             EntReset        => Reset,
             SalSyncReset    => SyncReset,
             SysHold         => SysHold,
             SalCicloInst    => CicloInst,
             EntInt          => Int,
             EntBandI        => Banderas.I,
             SalSolInt       => SolInt,
             EntBusProg      => BusProg(nBits_BusProg-1 downto nBits_BusProg-10),
             SalInstVal      => InstVal,
             SalWen_Banderas => Wen_Banderas);

   ALU_LBSR: JPU16_ALU_LBSR
   generic map (nBits_ALU => JPU16_DataBits)
   port map (SysClk     => SysClk,
             SysHold    => SysHold,
             CicloInst  => CicloInst,
             OperandoA  => BusP,
             OperandoB  => SalBusOR_BusQ,
             Resultado  => EntBusOR_BusR(0),
             CodigoOper => BusProg(nBits_BusProg-3 downto nBits_BusProg-5),
             EntBandC   => Banderas.C,
             SalBandC   => EntBusOR_Banderas(1).C,
             SalBandZ   => EntBusOR_Banderas(1).Z,
             SalBandN   => EntBusOR_Banderas(1).N,
             SalBandV   => EntBusOR_Banderas(1).V);
   EntBusOR_Banderas(1).I <= '0';

   ALU_LD: JPU16_ALU_LD
   generic map (nBits_ALU => JPU16_DataBits)
   port map (SysClk     => SysClk,
             SysHold    => SysHold,
             CicloInst  => CicloInst,
             OperandoA  => BusP,
             OperandoB  => SalBusOR_BusQ(3 downto 0),
             Resultado  => EntBusOR_BusR(1),
             CodigoOper => BusProg(nBits_BusProg-15 downto nBits_BusProg-17),
             EntBandC   => Banderas.C,
             SalBandC   => EntBusOR_Banderas(2).C,
             SalBandZ   => EntBusOR_Banderas(2).Z,
             SalBandN   => EntBusOR_Banderas(2).N);
   EntBusOR_Banderas(2).V <= '0';
   EntBusOR_Banderas(2).I <= '0';

   REGS_RXX: JPU16_REGS_RXX
   generic map (nBits_Regs => JPU16_DataBits)
   port map (SysClk     => SysClk,
             SyncReset2 => SyncReset(2),
             SysHold    => SysHold,
             CicloInst  => CicloInst,
             SolInt     => SolInt,
             InX        => SalBusOR_BusR,
             OutX       => BusP,
             OutY       => EntBusOR_BusQ(1),
             SelX       => BusProg(JPU16_DataBits+3 downto JPU16_DataBits),
             SelY       => BusProg(JPU16_DataBits-1 downto JPU16_DataBits-4),
             WenX       => BusProg(nBits_BusProg-1));

   REGS_BANDERAS: JPU16_REGS_BANDERAS
   port map (SysClk     => SysClk,
             SyncReset2 => SyncReset(2),
             SysHold    => SysHold,
             CicloInst  => CicloInst,
             SolInt     => SolInt,
             RestSombra => InstVal.IXRET,
             Wen        => Wen_Banderas,
             EntBand    => SalBusOR_Banderas,
             SalBand    => Banderas);

   REGS_PC: JPU16_REGS_PC
   generic map (nBits_PC => nBits_DirProg)
   port map (SysClk     => SysClk,
             SyncReset1 => SyncReset(1),
             SysHold    => SysHold,
             CicloInst  => CicloInst,
             SolInt     => SolInt,
             EntPC      => SalBusOR_BusQ(nBits_DirProg - 1 downto 0),
             SalPC      => PC,
             InstValida => InstVal.PC,
             CodigoOper => BusProg(nBits_BusProg-3 downto nBits_BusProg-5),
             ModoSalto  => BusProg(nBits_BusProg-6),
             EntBand_C  => Banderas.C,
             EntBand_Z  => Banderas.Z,
             EntBand_N  => Banderas.N,
             EntBand_V  => Banderas.V,
             NumBandera => BusProg(nBits_BusProg-8 downto nBits_BusProg-9),
             ValBand    => BusProg(nBits_BusProg-10));

   PROG_MEM: JPU16_PROG_MEM
   generic map (nBits_BusProg => nBits_BusProg)
   port map (SysClk    => SysClk,
             SysHold   => SysHold,
             CicloInst => CicloInst,
             Direccion => PC,
             DatoProg  => BusProg);

   RAM: JPU16_RAM
   generic map (nBits_BusDatos => JPU16_DataBits)
   port map (SysClk    => SysClk,
             SysHold   => SysHold,
             Ren       => RAM_Ren,
             Wen       => RAM_Wen,
             Direccion => SalBusOR_BusQ(nBits_DirDatos-1 downto 0),
             DatoEnt   => BusP,
             DatoSal   => EntBusOR_BusR(3));

   -- Componentes de buses
   -----------------------
   BUS_OR_BANDERAS: JPU16_BUS_OR_BANDERAS
   port map (EntBus_INSTR    => EntBusOR_Banderas(0),
             EntBus_ALU_LBSR => EntBusOR_Banderas(1),
             EntBus_ALU_LD   => EntBusOR_Banderas(2),
             SelBus_INSTR    => InstVal.Banderas,
             SelBus_ALU_LBSR => BandVal_ALU_LBSR,
             SelBus_ALU_LD   => InstVal.ALU_LD,
             SalBus          => SalBusOR_Banderas);

   BUS_OR_Q: JPU16_BUS_OR_Q
   generic map (nBits_Bus => JPU16_DataBits)
   port map (EntBus_INSTR    => EntBusOR_BusQ(0),
             EntBus_REGS_RXX => EntBusOR_BusQ(1),
             SelBus_ModoDir  => BusProg(nBits_BusProg-6),
             SalBus          => SalBusOR_BusQ);

   BUS_OR_R: JPU16_BUS_OR_R
   generic map (nBits_Bus => JPU16_DataBits)
   port map (EntBus_ALU_LBSR => EntBusOR_BusR(0),
             EntBus_ALU_LD   => EntBusOR_BusR(1),
             EntBus_Q        => EntBusOR_BusR(2),
             EntBus_RAM      => EntBusOR_BusR(3),
             EntBus_IO       => EntBusOR_BusR(4),
             SelBus_ALU_LBSR => InstVal.ALU_LBSR,
             SelBus_ALU_LD   => InstVal.ALU_LD,
             SelBus_Q        => InstVal.MoveRegInm,
             SelBus_RAM      => InstVal.MoveRamRd,
             SelBus_IO       => InstVal.IO_IN,
             SalBus          => SalBusOR_BusR);

   -----------------------------------------
   -- Operaciones con fines de simulacion --
   -----------------------------------------
   --Nota: Las operaciones de esta seccion seran eliminadas durante las optimizaciones en
   --el proceso de sintesis

   --Copia el contenido del contador de programa a la variable del paquete asociado
   --(JPU16_EXPORTS) para que la pueda acceder el desensamblador
   Contador_Programa <= PC;
   --Copia el contenido del bus de programa a la variable Opcode para que la pueda
   --visualizar el desensamblador
   Opcode <= BusProg;
end Funcionamiento;