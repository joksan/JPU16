--------------------------------------
-- Entidad principal del procesador --
--------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use work.JPU16_PACK.ALL;
use work.JPU16_DEFS.ALL;
use work.JPU16_EXPORTS.ALL;
use work.JPU16_MEM_SIZE_DEFS.ALL;

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
   --Declaracion de constantes
   ---------------------------
   constant nBits_BusProg: integer := 26;

   --Declaracion de tipos y subtipos
   ---------------------------------
   subtype BUS_DATOS is STD_LOGIC_VECTOR (JPU16_DataBits-1 downto 0);

   type BUS_OR_BANDERAS is record
      Ent_INSTR:    GRUPO_BANDERAS;
      Ent_ALU_LBSR: GRUPO_BANDERAS_ALU_LBSR;
      Ent_ALU_M:    GRUPO_BANDERAS_ALU_M;
      Ent_ALU_LD:   GRUPO_BANDERAS_ALU_LD;
      Salida:       GRUPO_BANDERAS;
   end record;

   type BUS_OR_Q is record
      Ent_INSTR:    BUS_DATOS;
      Ent_REGS_RXX: BUS_DATOS;
      Salida:       BUS_DATOS;
   end record;

   type BUS_OR_R is record
      Ent_ALU_LBSR: BUS_DATOS;
      Ent_ALU_M:    BUS_DATOS;
      Ent_ALU_LD:   BUS_DATOS;
      Ent_BUS_Q:    BUS_DATOS;
      Ent_RAM:      BUS_DATOS;
      Ent_IO:       BUS_DATOS;
      Salida:       BUS_DATOS;
   end record;

   -- Declaracion de señales internas --
   -------------------------------------
   signal SyncReset:   STD_LOGIC_VECTOR (2 downto 1);
   signal CicloInst:   STD_LOGIC;
   signal SolInt:      STD_LOGIC;

   signal PC:      STD_LOGIC_VECTOR (nBits_DirProg-1 downto 0);
   signal BusProg: STD_LOGIC_VECTOR (nBits_BusProg-1 downto 0);

   signal InstVal: INSTRUCCIONES_VALIDAS;

   signal Banderas:     GRUPO_BANDERAS;
   signal Wen_Banderas: GRUPO_BANDERAS;
   signal BusBand:      BUS_OR_BANDERAS;

   signal BusP: BUS_DATOS;
   signal BusQ: BUS_OR_Q;
   signal BusR: BUS_OR_R;

   signal RAM_Ren: STD_LOGIC;
   signal RAM_Wen: STD_LOGIC;
begin
   ---------------------------------------------------------------------------------
   --Definicion de entradas de buses de acuerdo a las instrucciones decodificadas --
   ---------------------------------------------------------------------------------
   --Conexion del bus de programa al bus de banderas mediante registros (instrucciones
   --SETX y CLRX)
   BusBand.Ent_INSTR <=
      (others => BusProg(nBits_BusProg-5) and Instval.Banderas and CicloInst)
      when rising_edge(SysClk) and SysHold = '0';

   --Conexion del bus de programa al bus Q (valores literales contenidos en instrucciones)
   BusQ.Ent_INSTR <= BusProg(JPU16_DataBits-1 downto 0);

   --Conexion del bus Q al bus R mediante registro (para disminuir la carga combinacional
   --de las instrucciones de movimiento de literales a registros)
   process (SysClk)
   begin
      if rising_edge(SysClk) then
         if SysHold = '0' then
            if CicloInst = '1' and InstVal.MoveRegInm = '1' then
               BusR.Ent_BUS_Q <= BusQ.Salida;
            else
               BusR.Ent_BUS_Q <= (others => '0');
            end if;
         end if;
      end if;
   end process;

   -------------------------------------
   --Definicion de los buses internos --
   -------------------------------------
   --Bus de banderas
   BusBand.Salida.C <= BusBand.Ent_INSTR.C or BusBand.Ent_ALU_LBSR.C
                       or BusBand.Ent_ALU_M.C or BusBand.Ent_ALU_LD.C;
   BusBand.Salida.Z <= BusBand.Ent_INSTR.Z or BusBand.Ent_ALU_LBSR.Z
                       or BusBand.Ent_ALU_M.Z or BusBand.Ent_ALU_LD.Z;
   BusBand.Salida.N <= BusBand.Ent_INSTR.N or BusBand.Ent_ALU_LBSR.N
                       or BusBand.Ent_ALU_M.N or BusBand.Ent_ALU_LD.N;
   BusBand.Salida.V <= BusBand.Ent_INSTR.V or BusBand.Ent_ALU_LBSR.V;
   BusBand.Salida.I <= BusBand.Ent_INSTR.I;

   --Bus Q
   BusQ.Salida <= BusQ.Ent_INSTR when BusProg(nBits_BusProg-6) = '0' else
                  BusQ.Ent_REGS_RXX;

   --Bus R
   BusR.Salida <= BusR.Ent_ALU_LBSR or BusR.Ent_ALU_M or BusR.Ent_ALU_LD
                  or BusR.Ent_BUS_Q or BusR.Ent_RAM or BusR.Ent_IO;

   ------------------------------------------------
   -- Mapeo de los puertos de entradas y salidas --
   ------------------------------------------------
   --Puertos de entrada
   process (IO_Din)
      variable ValorEntrada: BUS_DATOS;
   begin
      ValorEntrada := (others => '0');
      for i in 0 to nInputPorts-1 loop
         ValorEntrada := ValorEntrada or IO_Din(i);
      end loop;
      BusR.Ent_IO <= ValorEntrada;
   end process;

   --Puertos de salida
   IO_Dout <= BusP;
   IO_Addr <= BusQ.Salida;

   --Señales de control del bus de I/O:
   process (SysClk)
   begin
      if rising_edge(SysClk) then
         if SyncReset(1) = '1' then
            --En caso de reinicio del sistema la señal IO_RD se establece a 0
            IO_RD <= '0';
         elsif SysHold = '0' then
            if CicloInst = '1' and InstVal.IO_IN = '1' and SolInt = '0' then
               --Si se efectua una instruccion de lectura del bus de I/O, se activa la
               --linea IO_RD al final del ciclo 1 (siempre que no haya interrupcion)
               IO_RD <= '1';
            else
               --Si el ciclo no es correcto, no se descodifica la instruccion adecuada u
               --ocurre una interrupcion, la linea se establece a 0
               IO_RD <= '0';
            end if;
         end if;

         --Se procede de manera similar para la linea IO_WR
         if SyncReset(1) = '1' then
            IO_WR <= '0';
         elsif SysHold = '0' then
            if CicloInst = '1' and InstVal.IO_OUT = '1' and SolInt = '0' then
               IO_WR <= '1';
            else
               IO_WR <= '0';
            end if;
         end if;
      end if;
   end process;

   --Señales de control de la memoria RAM:
   RAM_Ren <= '1' when InstVal.MoveRamRd = '1' and CicloInst = '1' and
              SyncReset(2) = '0' and SolInt = '0' else '0';
   RAM_Wen <= '1' when InstVal.MoveRamWr = '1' and CicloInst = '1' and
              SyncReset(2) = '0' and SolInt = '0' else '0';

   -----------------------------------------------------
   -- Definicion de las instancias de los componentes --
   -----------------------------------------------------
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
   port map (SysClk     => SysClk,
             SysHold    => SysHold,
             CicloInst  => CicloInst,
             DataEnable => InstVal.ALU_LBSR_D,
             FlagEnable => InstVal.ALU_LBSR_F,
             OperandoA  => BusP,
             OperandoB  => BusQ.Salida,
             Resultado  => BusR.Ent_ALU_LBSR,
             CodigoOper => BusProg(nBits_BusProg-3 downto nBits_BusProg-5),
             EntBandC   => Banderas.C,
             SalBand    => BusBand.Ent_ALU_LBSR);

   ALU_M: JPU16_ALU_M
   port map (SysClk => SysClk,
             SysHold => SysHold,
             CicloInst => CicloInst,
             UnitEnable => InstVal.ALU_M,
             OperandoA => BusP,
             OperandoB => BusQ.Salida,
             ResultadoL => BusR.Ent_ALU_M,
             ResultadoH => open,
             CodigoOper => BusProg(nBits_BusProg-5),
             SalBand => BusBand.Ent_ALU_M);

   ALU_LD: JPU16_ALU_LD
   port map (SysClk     => SysClk,
             SysHold    => SysHold,
             CicloInst  => CicloInst,
             UnitEnable => InstVal.ALU_LD,
             OperandoA  => BusP,
             OperandoB  => BusQ.Salida(3 downto 0),
             Resultado  => BusR.Ent_ALU_LD,
             CodigoOper => BusProg(nBits_BusProg-15 downto nBits_BusProg-17),
             EntBandC   => Banderas.C,
             SalBand    => BusBand.Ent_ALU_LD);

   REGS_RXX: JPU16_REGS_RXX
   generic map (nBits_Regs => JPU16_DataBits)
   port map (SysClk     => SysClk,
             SyncReset2 => SyncReset(2),
             SysHold    => SysHold,
             CicloInst  => CicloInst,
             SolInt     => SolInt,
             InX        => BusR.Salida,
             OutX       => BusP,
             OutY       => BusQ.Ent_REGS_RXX,
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
             EntBand    => BusBand.Salida,
             SalBand    => Banderas);

   REGS_PC: JPU16_REGS_PC
   generic map (nBits_PC => nBits_DirProg)
   port map (SysClk     => SysClk,
             SyncReset1 => SyncReset(1),
             SysHold    => SysHold,
             CicloInst  => CicloInst,
             SolInt     => SolInt,
             EntRelPC   => BusProg(nBits_DirProg - 1 downto 0),
             EntAbsPC   => BusQ.Ent_REGS_RXX(nBits_DirProg - 1 downto 0),
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
             Direccion => BusQ.Salida(nBits_DirDatos-1 downto 0),
             DatoEnt   => BusP,
             DatoSal   => BusR.Ent_RAM);

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