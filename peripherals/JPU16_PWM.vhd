-- PWM Module for JPU16
-- --------------------------------------------------------------------------
--Author: Jonathan Castro
-- --------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;


package JPU16_PWM_Pack is
	

	component JPU16_PWM is 
	Generic( 		BusAncho:		integer  := 16;
				nBit_DC:		integer := 4;
				Mascara:			STD_LOGIC_VECTOR(15 downto 0) := X"000C";
				DirPeriod:		STD_LOGIC_VECTOR(15 downto 0) := X"0004";
				DirControlPwm: STD_LOGIC_VECTOR(15 downto 0) := X"0008";
				DirDCREG:		STD_LOGIC_VECTOR(15 downto 0) := X"000C");
	Port(
			SysClk:  in	STD_LOGIC;
			IO_Addr: in STD_LOGIC_VECTOR( BusAncho-1 downto 0);
			IO_Dout: in STD_LOGIC_VECTOR( BusAncho-1 downto 0);
			IO_Din:  out STD_LOGIC_VECTOR( BusAncho-1 downto 0);
			IO_RD: 	in STD_LOGIC;
			IO_WE: 	in STD_LOGIC;
			Reset:   in STD_LOGIC;
			IntLine: out STD_LOGIC;
			PwmOut:  out STD_LOGIC_VECTOR(2**nBit_DC-1 downto 0)
	);
	end component;
end package;


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;

	
	

entity JPU16_PWM is

	
	Generic( 		BusAncho:		integer  := 16;
				nBit_DC:		integer := 4;
				Mascara:			STD_LOGIC_VECTOR(15 downto 0) := X"000C";
				DirPeriod:		STD_LOGIC_VECTOR(15 downto 0) := X"0004";
				DirControlPwm: STD_LOGIC_VECTOR(15 downto 0) := X"0008";
				DirDCREG:		STD_LOGIC_VECTOR(15 downto 0) := X"000C");
	Port(
			SysClk:  in	STD_LOGIC;
			IO_Addr: in STD_LOGIC_VECTOR( BusAncho-1 downto 0);
			IO_Dout: in STD_LOGIC_VECTOR( BusAncho-1 downto 0);
			IO_Din:  out STD_LOGIC_VECTOR( BusAncho-1 downto 0);
			IO_RD: 	in STD_LOGIC;
			IO_WE: 	in STD_LOGIC;
			Reset:   in STD_LOGIC;
			IntLine: out STD_LOGIC;
			PwmOut:  out STD_LOGIC_VECTOR(2**nBit_DC-1 downto 0)
	);
end JPU16_PWM;

architecture Behavioral of JPU16_PWM is
	type TYPE_DutyCycleReg is array (2**nBit_DC-1 downto 0) of
	STD_LOGIC_VECTOR (11 downto 0);
	
	signal ControlPwmReg: std_logic_vector (BusAncho - 1 downto 0) := (others => '0');
	alias Prescale:	std_logic_vector is ControlPwmReg(3 downto 0);
	alias Pwm_Enable: std_logic is ControlPwmReg(4);
	alias	PolOut: 		std_logic is ControlPwmReg(5);
	alias PhaseBit: 	std_logic is ControlPwmReg(6);
	alias OVF_Enable: std_logic is ControlPwmReg(7);
	alias OVF_Flag: 	std_logic is ControlPwmReg(15);
	alias DutyCycleDecoder:  std_logic_vector is ControlPwmReg(8 + nBit_DC - 1 downto 8);

	signal Pwm_EnableReg: std_logic_vector(PwmOut'range);
	signal PolOutReg: std_logic_vector(PwmOut'range);
	signal PrescalerCount: std_logic_vector (BusAncho-2 downto 0) := (others => '0');
	signal PrescalerReg:   std_logic_vector (BusAncho-2 downto 0) := (others => '0');
	
	signal CountEnable:  std_logic;
	
	signal CountPwm: 		std_logic_vector (11 downto 0) := (others => '0');
	signal PeriodReg: 	std_logic_vector (11 downto 0) := (others => '0');	
	
	signal DutyCyclePwm: TYPE_DutyCycleReg := (others => (others => '0'));
	signal DCREG: 	     TYPE_DutyCycleReg := (others => (others => '0'));
	
	
	signal PwmOutReg:    std_logic_vector(PwmOut'range);
	
	signal PhaseControlBit: std_logic := '0';

	signal OVFPwm: 		std_logic;
	signal PreOVFPwm: 		std_logic;
	signal Period_RWE:		std_logic :='0' ;
	signal DCREG_RWE:			std_logic :='0' ;
	signal ControlPwmReg_RWE:	std_logic :='0' ;
	
begin
	IntLine <=  OVF_Flag and OVF_Enable;

	CountEnable <= '1' when PrescalerReg = PrescalerCount else '0';
	
	OVFPwm <= '1' when CountPwm = PeriodReg else '0';

	PreOVFPwm <= '1' when CountPwm = (PeriodReg-1) else '0';

	PwmOutGen: 
	for i in 0 to 15 generate
		PwmOutReg(i) <= '1' when DutyCyclePwm(i) > CountPwm else '0';
	end generate PwmOutGen;
	
	process(SysClk, Pwm_Enable)
	begin
		if rising_edge(SysClk) then
			if Pwm_Enable = '0' or CountEnable = '1' then
				PrescalerCount <= (others => '0');
			else
				PrescalerCount <= PrescalerCount + 1;				
			end if;
		end if;
	end process;
	
-----------------------------------------------------------	
	process(SysClk, Pwm_Enable, CountEnable, PhaseControlBit)
	begin
		if rising_edge(SysClk) then
			if Reset = '1' or  Pwm_Enable = '0' or (OVFPwm = '1' and PhaseBit = '0') then
				CountPwm <= (others => '0');
			elsif CountEnable = '1' then
					if PhaseControlBit = '0' then
						CountPwm <= CountPwm  + 1;
					
					else
						CountPwm <= CountPwm - 1;
					end if;
			end if;
		end if;
	end process;
	

	PolOutReg <= (others => '1') when PolOut = '1' else (others => '0');
	Pwm_EnableReg <= (others => '1') when Pwm_Enable = '1' else (others => '0');
	PwmOut <= (PwmOutReg xor PolOutReg) and Pwm_EnableReg ;

---------------------------------------------------------------
	DutyCyclePwm(conv_integer(DutyCycleDecoder)) <= DCREG(conv_integer(DutyCycleDecoder)) when rising_edge(SysClk) and OVFPwm = '1' else DutyCyclePwm(conv_integer(DutyCycleDecoder));
---------------------------------------------------------------	
	process(SysClk, PhaseBit, CountPwm)
	begin
		if rising_edge(SysClk) then
			if CountPwm = 1 or PhaseBit = '0' then
				PhaseControlBit <= '0';
			elsif PreOVFPwm = '1' then
				PhaseControlBit <= '1';
			end if;
		end if;
	end process;
	
---------------------------------------------------------------


-- Writing on Control Registers
-- Write Enable for 	Prescale
	process(SysClk)
	begin
		if rising_edge(SysClk) then
			if ((IO_Addr and Mascara) = DirPeriod) then
				Period_RWE <= '1';
			else
				Period_RWE <= '0';
			end if;
		end if;
	end process;
	
-- Write to Period Register
	process(SysClk)
	begin
		if rising_Edge(SysClk) then
			if Reset = '1' then
				PeriodReg <= (others => '0');			 
			elsif Period_RWE = '1' and IO_WE='1' then
				PeriodReg <= IO_Dout(PeriodReg'range);
			end if;
		end if;
	end process;
	
-- Write Enable for 	DCREG arrays
	process(SysClk)
	begin
		if rising_edge(SysClk) then
			if ((IO_Addr and Mascara) = DirDCREG) then
				DCREG_RWE <= '1';
			else
				DCREG_RWE <= '0';
			end if;
		end if;
	end process;
	
-- Write to DCREG
	process(SysClk)
	begin
		if rising_Edge(SysClk) then
			if Reset = '1' then
				DCREG(conv_integer(DutyCycleDecoder)) <= (others => '0');			 
			elsif DCREG_RWE = '1' and IO_WE='1' then
				DCREG(conv_integer(DutyCycleDecoder)) <= IO_Dout(CountPwm'range);
			end if;
		end if;
	end process;
	
-- Write Enable for 	ControlPwm
	process(SysClk)
	begin
		if rising_edge(SysClk) then
			if ((IO_Addr and Mascara) = DirControlPwm) then
				ControlPwmReg_RWE <= '1';
			else
				ControlPwmReg_RWE <= '0';
			end if;
		end if;
	end process;	
	
-- Write to ControlPwm
	process(SysClk)
	begin
		if rising_Edge(SysClk) then
			if Reset = '1' then
				ControlPwmReg <= (others => '0');			 
			elsif ControlPwmReg_RWE = '1' and IO_WE='1' then
				ControlPwmReg <= IO_Dout;
			elsif OVFPwm = '1' then
				OVF_Flag <= '1';
			end if;
		end if;
	end process;	
---------------------------------------------------------------
-- Reading Control Registers
	IO_Din <= "0000" & DCREG(conv_integer(DutyCycleDecoder)) when DCREG_RWE = '1' and IO_RD = '1' else
				 ControlPwmReg when ControlPwmReg_RWE='1' and IO_RD = '1' else
				 "0000" & PeriodReg		when Period_RWE = '1' 		and IO_RD = '1' else (others => '0');
-------------------------------------------------------------------------

-- Prescaler Table 
------------------------------------------------------------------- 	

	PrescalerReg <= 	"000000000000000" when Prescale = 0 else
							"000000000000001" when Prescale = 1 else
							"000000000000011" when Prescale = 2 else
							"000000000000111" when Prescale = 3 else
							"000000000001111" when Prescale = 4 else
							"000000000011111" when Prescale = 5 else
							"000000000111111" when Prescale = 6 else
							"000000001111111" when Prescale = 7 else
							"000000011111111" when Prescale = 8 else
							"000000111111111" when Prescale = 9 else
							"000001111111111" when Prescale = 10 else
							"000011111111111" when Prescale = 11 else
							"000111111111111" when Prescale = 12 else
							"001111111111111" when Prescale = 13 else
							"011111111111111" when Prescale = 14 else
							"111111111111111" ;
--------------------------------------------------
end Behavioral;

