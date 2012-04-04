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

--	"Interrupt Timer Flag" 
	alias ITF: STD_LOGIC is TMRCTRL(6);
	
--	"Interrupt Timer Enable 
	alias ITE: STD_LOGIC is TMRCTRL(5);
	
-- "Timer Enable Bit" 
	alias TEB: STD_LOGIC is TMRCTRL(4);
	
--	"Prescaler Table Input"
	alias PTI: STD_LOGIC_VECTOR(3 downto 0) is TMRCTRL(3	downto 0);
	
-- "Clock Enable"
	signal CEB: STD_LOGIC;
	
-- "Overflow Flag"
	signal CTF: STD_LOGIC := '0';
	
-- "Prescaler Trigger Register"
	signal PTR: STD_LOGIC_VECTOR( BusAncho-2 downto 0);

-- "Prescaler Count Register"
	signal PCR: STD_LOGIC_VECTOR( BusAncho-2 downto 0) := (others =>'0');

-- Write Enable of Principal Registers.
	signal TMRCNT_WE: 	STD_LOGIC;
	signal TMRPR_WE: 		STD_LOGIC;
	signal TMRCTRL_WE: 	STD_LOGIC;
	signal TMRCNT_RE: 	STD_LOGIC;
	signal TMRPR_RE: 		STD_LOGIC;
	signal TMRCTRL_RE: 	STD_LOGIC;
	signal IO_Addr_En: 	STD_LOGIC := '0';
	
begin
-- Timer counter definition
	process (SysClk)
	begin
		if rising_edge(SysClk)  then
			if Reset ='1' then
				TMRCNT <= (others =>'0');
			elsif TMRCNT_WE = '1' then
				TMRCNT <= IO_Dout ;

			else
				if CEB = '1' and TEB = '1' then
					if CTF = '1' then
						TMRCNT <= (others => '0');
					else
						TMRCNT <= TMRCNT + 1;
					end if;
				end if;
			end if;		
		end if;
		
	end process;
	
	
	CTF <= '1' when TMRCNT = TMRPR else '0';
	TMRCNT_WE <= '1' when (((IO_Addr and Mascara) = DirTMRCNT) and IO_WE = '1') else '0';

-- TMRPR process
	
	process(SysClk)
	
	begin
		if rising_edge(SysClk) and TMRPR_WE = '1'  then
			TMRPR <= IO_Dout;
		end if;
	end process;

	TMRPR_WE <= '1' when (((IO_Addr and Mascara) = DirTMRPR) and IO_WE = '1') else '0';
	
-- TMRCTRL definition
		
	process(SysClk)
	begin
		if rising_edge(SysClk) then 
			if  Reset = '1' then
				TEB <='0';
				ITE <='0';
				ITF <= '0';
			elsif TMRCTRL_WE ='1' then
				TMRCTRL <= IO_Dout;
			else
				if CTF = '1' then
					ITF <= '1';
				end if;
			end if;
		end if;
	end process;
	
	IntTMR <= TMRCTRL(6) and ITE;
	TMRCTRL_WE <= '1' when (((IO_Addr and Mascara) = DirTMRCTRL) and IO_WE = '1') else '0';

-- Read
	IO_Din <= TMRCNT  when TMRCNT_RE = '1' and IO_RD ='1' else 
				 TMRCTRL when TMRCTRL_RE = '1' and IO_RD = '1' else
				 TMRPR   when TMRPR_RE = '1' and IO_RD = '1' else (others => '0');
	
	
	
	TMRCNT_RE  <= '1' when ((IO_Addr and Mascara) = DirTMRCNT)  and rising_edge(SysClk) else '0';
	TMRPR_RE   <= '1' when ((IO_Addr and Mascara) = DirTMRPR)  and rising_edge(SysClk) else '0';
	TMRCTRL_RE <= '1' when ((IO_Addr and Mascara) = DirTMRCTRL)  and rising_edge(SysClk) else '0';
				 
-- Prescaler definition

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
	
	CEB <= '1' when PCR = PTR else '0';
	
---------------------------------------------------
-- Prescaler Table 
--------------------------------------------------- 	

	PTR <= "000000000000000" when PTI = 0 else
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
			 "111111111111111" when PTI = 15;
--------------------------------------------------

end Funcionamiento;

