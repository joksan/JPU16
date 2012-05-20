-- Timer Module for JPU16
-- --------------------------------------------------------------------------
--Author: Jonathan Castro
--
-- This peripheral is a 16-bit upward timer, its main application is to provide interrupt to JPU16 processor,
-- the module is able to divide the principal system clock, to delay the period count. this prescaler is a 15-bit counter unit.
-- -------------------------------------------------------------------------
-- The associated registers for control, counting, and prescaling the Timer are:
--
-- Timer Count Register (TMRCNT):
-- It is a Readable and Writeable register that has the main count,
--
-- Timer Control Register (TMRCTRL):
-- This register has the control signals like: Timer_On, Prescaler Value, Timer Interrupt Flag and Enable.
-- To calculate the prescale value, use the four LSB's of TMRCTRL.
-- Timer Unit is Turned On when the TMRCTRL(4) is set, otherwise is Off.
-- Timer Interrupt is Enable when TMRCTRL(5) is set, and TMRCTRL(6) is the Timer Interrupt Flag.
-- 
-- Timer Period Register (TMRPR):
-- This is the number that is compared to TMRCNT and when the match, the timer is reset, Timer Interrupt Flag is set.
-- Timer Interrupt Flag is clear by software.

-- Timer Entity 
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity JPU16_Timer is
	generic( BusAncho: integer := 16;
				Mascara: STD_LOGIC_VECTOR(15 downto 0)   := X"E000";
				DirTMRCNT: STD_LOGIC_VECTOR(15 downto 0) := X"2000";
				DirTMRPR: STD_LOGIC_VECTOR(15 downto 0)  := X"6000";
				DirTMRCTRL: STD_LOGIC_VECTOR(15 downto 0)  := X"A000");
	Port(  
			SysClk:  in	STD_LOGIC;
			IO_Addr: in STD_LOGIC_VECTOR( BusAncho-1 downto 0);
			IO_Dout: in STD_LOGIC_VECTOR( BusAncho-1 downto 0);
			IO_Din:  out STD_LOGIC_VECTOR( BusAncho-1 downto 0);
			IO_RD: 	in STD_LOGIC;
			IO_WE: 	in STD_LOGIC;
			Reset:   in STD_LOGIC;
			IntTMR:  out STD_LOGIC
			
	);
end JPU16_Timer;

architecture Funcionamiento of JPU16_Timer is

-- Register that counts called: "Timer Count"
 	signal TMRCNT: STD_LOGIC_VECTOR( BusAncho-1 downto 0) := (others =>'0');

-- "Timer Period"
	signal TMRPR: STD_LOGIC_VECTOR(BusAncho-1 downto 0) := X"0000";
	
-- "Timer Control Register"
	signal TMRCTRL: STD_LOGIC_VECTOR(BusAncho-1 downto 0) := (others => '0');

-- "Interrupt Timer Flag" 
	alias ITF: STD_LOGIC is TMRCTRL(6);
	
-- "Interrupt Timer Enable 
	alias ITE: STD_LOGIC is TMRCTRL(5);
	
-- "Timer Enable Bit" 
	alias TEB: STD_LOGIC is TMRCTRL(4);
	
-- "Prescaler Table Input"
	alias PTI: STD_LOGIC_VECTOR(3 downto 0) is TMRCTRL(3	downto 0);
	
-- "Clock Enable"
	signal CEB: STD_LOGIC;
	
-- "Overflow Flag"
	signal CTF: STD_LOGIC := '0';
	
-- "Prescaler Trigger Register"
	signal PTR: STD_LOGIC_VECTOR( BusAncho-2 downto 0);

-- "Prescaler Count Register"
	signal PCR: STD_LOGIC_VECTOR( BusAncho-2 downto 0) := (others =>'0');

-- "Write Enable of Principal Registers".
	signal TMRCNT_WE: 	STD_LOGIC;
	signal TMRPR_WE: 		STD_LOGIC;
	signal TMRCTRL_WE: 	STD_LOGIC;
	signal TMRCNT_RE: 	STD_LOGIC;
	signal TMRPR_RE: 		STD_LOGIC;
	signal TMRCTRL_RE: 	STD_LOGIC;
	signal IO_Addr_En: 	STD_LOGIC := '0';
	
begin
--------- Timer counter definition ------------------
-- Count Timer Flag is set when the timer counts to the period value.
	CTF <= '1' when TMRCNT = TMRPR and CEB = '1' else '0';
	
-- Process for TMRCNT 
	process (SysClk)
	begin
		if rising_edge(SysClk)  then				-- Souce Clock
			if Reset ='1' then				-- Reset Signal clear the register
				TMRCNT <= (others =>'0');		
			elsif TMRCNT_WE = '1' and IO_WE = '1' then	-- This is executed when CPU requires read the Count Value
				TMRCNT <= IO_Dout ;			

			else
				if CEB = '1' and TEB = '1' then		-- Timer count is reset when it has counted to period value
					if CTF = '1' then
						TMRCNT <= (others => '0'); 
					else
						TMRCNT <= TMRCNT + 1;  -- Normal count activity is executed
					end if;
				end if;
			end if;		
		end if;
		
	end process;
	
	
-- Write Enable for Timer Count Register
	process (SysClk)
	begin
		if rising_edge(SysClk) then
			if ((IO_Addr and Mascara) = DirTMRCNT) then
				TMRCNT_WE <= '1';
			else
				TMRCNT_WE <= '0';
			end if;
		end if;
	end process;
	

-- Timer Period Register  
-- This process writes to TMRPR the value of the period count value.
	process(SysClk)
	
	begin
		if rising_edge(SysClk) and TMRPR_WE = '1' and IO_WE = '1' then
			TMRPR <= IO_Dout;
		end if;
	end process;

-- Write Enable for Timer Period Register
	process (SysClk)
	begin
		if rising_edge(SysClk) then
			if ((IO_Addr and Mascara) = DirTMRPR) then
				TMRPR_WE <= '1';
			else
				TMRPR_WE <= '0';
			end if;
		end if;
	end process;
	
	
	
-- Description for Timer Control Register
-- Meanwhile Reset signal is set, the timer unit is turned off, and the interrupt flag and enable bits are cleared.
-- If the CPU requires to write a new configuration of the Timer unit, through Timer Control Write Enable.
-- and the Interrupt Timer Flag is set when Count Timer Flag is set too.

	process(SysClk)
	begin
		if rising_edge(SysClk) then 
			if  Reset = '1' then
				TEB <='0';
				ITE <='0';
				ITF <= '0';
			elsif TMRCTRL_WE ='1' and IO_WE ='1' then
				TMRCTRL <= IO_Dout;
			else
				if CTF = '1' then
					ITF <= '1';
				end if;
			end if;
		end if;
	end process;

-- Interrupt Signal of the Unit is active when Interrupt Timer Flag and Enable are set.	
	IntTMR <= TMRCTRL(6) and ITE;

-- Write Enable for Timer Control 
	process(SysClk)
	begin
		if rising_edge(SysClk) then
			if (IO_Addr and Mascara) = DirTMRCTRL then
				TMRCTRL_WE <= '1';
			else
				TMRCTRL_WE <= '0';
			end if;			
		end if;
	end process;
	
--------------------------------------------------------------------------------------------
------- Read signals and process for the Timer Registers -----------------------------------
--------------------------------------------------------------------------------------------
-- IO_Din is the Bus that connect the ouput data, to JPU16 input port
-- if the timer unit is not required for reading process, IO_Din signal gives a clear data for the OR Bus implemented in JPU16.
	IO_Din <= TMRCNT  when TMRCNT_RE  = '1' and IO_RD = '1' else    
				 TMRCTRL when TMRCTRL_RE = '1' and IO_RD = '1' else
				 TMRPR   when TMRPR_RE   = '1' and IO_RD = '1' else (others => '0');


--  Read Enable Process for Timer Count Register	
	process (sysclk)
	begin
		if rising_edge(SysClk) then
			if ((IO_Addr and Mascara) = DirTMRCNT) then
				TMRCNT_RE <= '1';
			else
				TMRCNT_RE <= '0';
			end if;
		end if;
	end process;

--  Read Enable Process for Timer Control Register
	process (sysclk)
	
	begin
		if rising_edge(SysClk) then
			if ((IO_Addr and Mascara) = DirTMRPR) then
				TMRPR_RE <= '1';
			else
				TMRPR_RE <= '0';
			end if;
		end if;
	end process;

--  Read Enable Process for Timer Period Register
	process (sysclk)
	
	begin
		if rising_edge(SysClk) then
			if ((IO_Addr and Mascara) = DirTMRCTRL) then
				TMRCTRL_RE <= '1';
			else
				TMRCTRL_RE <= '0';
			end if;
		end if;
	end process;	
	

				 
-- Prescaler definition

-- The prescaler unit is also a counter unit, but, it is used to divides the frequency of the source clock
-- When Prescaler count is the same as prescaler value (2**(TMRCTRL<3:0>)), writting to Timer Count Register, Reset signal is active, or Timer Enable bit, when all those events occurred the prescaler count is clear, otherwise prescaler woks normally.

	process (SysClk)
	begin
					
		if rising_edge(SysClk) then
			if CEB = '1'  or TMRCNT_WE = '1' or TEB ='0' or Reset = '1' then
				PCR <= (others => '0');
			else
				PCR <= PCR + 1;
			end if;
		end if;
	end process;

-- Count Enable Bit is the signal that make able to the main Counter to increment its value.
	CEB <= '1' when PCR = PTR else '0';
	
---------------------------------------------------
-- Prescaler Table 
--------------------------------------------------- 	

	PTR <= 	"000000000000000" when PTI = 0 else
		"000000000000001" when PTI = 1 else
		"000000000000011" when PTI = 2 else
		"000000000000111" when PTI = 3 else
		"000000000001111" when PTI = 4 else
		"000000000011111" when PTI = 5 else
		"000000000111111" when PTI = 6 else
		"000000001111111" when PTI = 7 else
		"000000011111111" when PTI = 8 else
		"000000111111111" when PTI = 9 else
		"000001111111111" when PTI = 10 else
		"000011111111111" when PTI = 11 else
		"000111111111111" when PTI = 12 else
		"001111111111111" when PTI = 13 else
		"011111111111111" when PTI = 14 else
		"111111111111111" ;
--------------------------------------------------

end Funcionamiento;

