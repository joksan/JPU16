---------------------------------
-- Entidad del bus de banderas --
---------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use work.JPU16_DEFS.all;

entity JPU16_BUS_OR_BANDERAS is
   port (EntBus_INSTR:    in  GRUPO_BANDERAS;
         EntBus_ALU_LBSR: in  GRUPO_BANDERAS;
         EntBus_ALU_LD:   in  GRUPO_BANDERAS;
         SelBus_INSTR:    in  STD_LOGIC;
         SelBus_ALU_LBSR: in  STD_LOGIC;
         SelBus_ALU_LD:   in  STD_LOGIC;
         SalBus:          out GRUPO_BANDERAS);
end JPU16_BUS_OR_BANDERAS;

architecture Funcionamiento of JPU16_BUS_OR_BANDERAS is
   signal ValBus_INSTR:    GRUPO_BANDERAS;
   signal ValBus_ALU_LBSR: GRUPO_BANDERAS;
   signal ValBus_ALU_LD:   GRUPO_BANDERAS;
begin
   ValBus_Instr    <= EntBus_INSTR    when SelBus_INSTR    = '1' else (others => '0');
   ValBus_ALU_LBSR <= EntBus_ALU_LBSR when SelBus_ALU_LBSR = '1' else (others => '0');
   ValBus_ALU_LD   <= EntBus_ALU_LD   when SelBus_ALU_LD   = '1' else (others => '0');

   SalBus.C <= ValBus_INSTR.C or ValBus_ALU_LBSR.C or ValBus_ALU_LD.C;
   SalBus.Z <= ValBus_INSTR.Z or ValBus_ALU_LBSR.Z or ValBus_ALU_LD.Z;
   SalBus.N <= ValBus_INSTR.N or ValBus_ALU_LBSR.N or ValBus_ALU_LD.N;
   SalBus.V <= ValBus_INSTR.V or ValBus_ALU_LBSR.V or ValBus_ALU_LD.V;
   SalBus.I <= ValBus_INSTR.I or ValBus_ALU_LBSR.I or ValBus_ALU_LD.I;
end Funcionamiento;

-----------------------
-- Entidad del bus Q --
-----------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity JPU16_BUS_OR_Q is
   generic (nBits_Bus: integer := 16);
   port (EntBus_INSTR:    in  STD_LOGIC_VECTOR (nBits_Bus-1 downto 0);
         EntBus_REGS_RXX: in  STD_LOGIC_VECTOR (nBits_Bus-1 downto 0);
         SelBus_ModoDir:  in  STD_LOGIC;
         SalBus:          out STD_LOGIC_VECTOR (nBits_Bus-1 downto 0));
end JPU16_BUS_OR_Q;

architecture Funcionamiento of JPU16_BUS_OR_Q is
   signal ValBus_INSTR:    STD_LOGIC_VECTOR (nBits_Bus-1 downto 0);
   signal ValBus_REGS_RXX: STD_LOGIC_VECTOR (nBits_Bus-1 downto 0);
begin
   ValBus_INSTR    <= EntBus_INSTR    when SelBus_ModoDir = '0' else (others => '0');
   ValBus_REGS_RXX <= EntBus_REGS_RXX when SelBus_ModoDir = '1' else (others => '0');

   SalBus <= ValBus_INSTR or ValBus_REGS_RXX;
end Funcionamiento;

-----------------------
-- Entidad del bus R --
-----------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity JPU16_BUS_OR_R is
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
end JPU16_BUS_OR_R;

architecture Funcionamiento of JPU16_BUS_OR_R is
   signal ValBus_ALU_LBSR: STD_LOGIC_VECTOR (nBits_Bus-1 downto 0);
   signal ValBus_ALU_LD:   STD_LOGIC_VECTOR (nBits_Bus-1 downto 0);
   signal ValBus_Q:        STD_LOGIC_VECTOR (nBits_Bus-1 downto 0);
   signal ValBus_RAM:      STD_LOGIC_VECTOR (nBits_Bus-1 downto 0);
   signal ValBus_IO:       STD_LOGIC_VECTOR (nBits_Bus-1 downto 0);
begin
   ValBus_ALU_LBSR <= EntBus_ALU_LBSR when SelBus_ALU_LBSR = '1' else (others => '0');
   ValBus_ALU_LD   <= EntBus_ALU_LD   when SelBus_ALU_LD   = '1' else (others => '0');
   ValBus_Q        <= EntBus_Q        when SelBus_Q        = '1' else (others => '0');
   ValBus_RAM      <= EntBus_RAM      when SelBus_RAM      = '1' else (others => '0');
   ValBus_IO       <= EntBus_IO       when SelBus_IO       = '1' else (others => '0');

   SalBus <= ValBus_ALU_LBSR or ValBus_ALU_LD or ValBus_Q or ValBus_RAM or ValBus_IO;
end Funcionamiento;