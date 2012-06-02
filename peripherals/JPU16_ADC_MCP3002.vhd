-- --------------------------------------------------------------------------------------------
--
-- Analog to Digital Converter Module for JPU16 
--
-- --------------------------------------------------------------------------------------------
--
-- Author: Jonathan Castro.
--
-- --------------------------------------------------------------------------------------------
--
-- This module is an implementation for the ADC, MCP3002 of Microchip.
-- the device comunicates through SPI interface, so the implemented SPI design IS NOT GENERIC,
-- the features of the MCP3002 are: 
--	* 10 - Bits resolution.
--	* 2 Channels to be sample and hold, is single or differencial mode.
--
-- For more details, see the MCP3002 datasheet of Microchip products.
--
-- --------------------------------------------------------------------------------------------
--
-- The asociated register to the module are:
--	CONTROLREGADC: This register contains the settings for the AD convertion, Single/diff mode, 
--		    and channel to be converted.
--
--		Sign/Diff bit - controlregadc<13> : if this bit is set the convertion is in single mode
--						otherwise the convertion is in pseudo - differencial mode.
--		Select Channel Bit - controlreg<12>: 
--		       --------------------------------------------------	
--		       -* Single Mode: 	0 - Channel 0 is converted.	-
--		       -		1 - Channel 1 is converted.	-
--		       -* Diff Mode: 	0 - Result = +Ch0 - Ch1.	-
--		       -		1 - Result = +Ch1 - Ch0.	-
--		       --------------------------------------------------
--		Interrupt Enable Bit - controlregadc<9> : this enable the interrupt event for the CPU.
--
--		Interrupt Flag / Status Bit - controlregadc<8> : At the begining of a convertion cycle you must clear this bit before start, and when the convertion is ready, this bit is set automaticly, as any interrupt flag, is cleared by software.
--
--	DATAOUT: This one has two functions, the main function is giving the data converted at the end of the convertion, the second function is begin a convertion.
--		To Iniciate a convertion cycle just need to write ANY data to the dataout register.
--		When the convertion is ready you can use any way, read as fast as you can and check the status bit, if it is set the convertion has finished, and the second option is wait for the interrupt of the CPU, if it were enabled.
--
-- --------------------------------------------------------------------------------------------
--
-- JPU16_ADC_MCP3002_Pack.
--
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

package JPU16_ADC_MCP3002_Pack is
	Component JPU16_ADC_MCP3002 is
	Generic(	AnchoBus: 			integer := 16;
				AnchoPrescaler: 	integer := 5;
				ADC_Mask: 			STD_LOGIC_VECTOR(15 downto 0) := X"0300";
				DirDataOut:			STD_LOGIC_VECTOR(15 downto 0)	:= X"0100";
				DirControlRegADC: STD_LOGIC_VECTOR(15 downto 0) := X"0200"
			);
	Port( SysClk: in  std_logic;
			Reset:  in  std_logic;
			IO_Addr: in std_logic_vector(AnchoBus-1 downto 0);
			IO_Din: out std_logic_vector(AnchoBus-1 downto 0);
			IO_Dout: in std_logic_vector(AnchoBus-1 downto 0);
			IO_WR:	in std_logic;
			IO_RD:	in std_logic;
			IntLine: out std_logic;
-- SPI interface--------------------------------------------------------------------------------------------------
			CS:	  out	std_logic;
			MISO:	  in	std_logic;
			MOSI:	  out std_logic;
			DeviceClk: out std_logic
------------------------------------------------------------------------------------------------------------------
			
	);
	end component;
end package;
--
-- JPU16_ADC_MCP3002_Entity.
--
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity JPU16_ADC_MCP3002 is
	Generic(	AnchoBus: 			integer := 16;
				AnchoPrescaler: 	integer := 5;
				ADC_Mask: 			STD_LOGIC_VECTOR(15 downto 0) := X"0300";
				DirDataOut:			STD_LOGIC_VECTOR(15 downto 0)	:= X"0100";
				DirControlRegADC: STD_LOGIC_VECTOR(15 downto 0) := X"0200"
			);
	Port( SysClk: in  std_logic;
			Reset:  in  std_logic;
			IO_Addr: in std_logic_vector(AnchoBus-1 downto 0);
			IO_Din: out std_logic_vector(AnchoBus-1 downto 0);
			IO_Dout: in std_logic_vector(AnchoBus-1 downto 0);
			IO_WR:	in std_logic;
			IO_RD:	in std_logic;
			IntLine: out std_logic;
-- SPI interface--------------------------------------------------------------------------------------------------
			CS:	  out	std_logic;
			MISO:	  in	std_logic;
			MOSI:	  out std_logic;
			DeviceClk: out std_logic
------------------------------------------------------------------------------------------------------------------
			
	);
	
end JPU16_ADC_MCP3002;

architecture Funcionamiento of JPU16_ADC_MCP3002 is

-- The prescaler is used to adjust the baud rate of the ADC Clock
-- FdeviceClok = Fosc / (2^(AnchoPrescaler + 1))
	signal prescaler: std_logic_vector(AnchoPrescaler - 1 downto 0) := (others => '0');

-- Clock enable for device clk
	signal clk_enable: std_logic := '0';

-- Device Clock Register for the MCP3002
	signal DeviceClkReg:  std_logic := '0';

-- Control Register of the ADC Module	
	signal ControlRegADC: std_logic_vector(AnchoBus -1 downto 0) := (others => '0');

-- Interrupt Enable Bit
	alias	 IntEnable: std_logic is ControlRegADC(9);

-- Interrupt Flag / Status Bit
	alias	 status: std_logic is ControlRegADC(8);

-- Converted Data Out Register
	signal DataOut: std_logic_vector(9 downto 0) := (others => '0');

-- Read / Write Enable for the registers	
	signal ControlRegADC_RWE: std_logic := '0';
	signal DataOut_RE: std_logic := '0';

-- Q Registers for  the CS signal and interrupt event.	
	signal CS_Q: std_logic := '1';
	signal CS_Q1: std_logic := '1';
	signal CS_Q2: std_logic := '1';

-- Counter states
	type counter_states is (waiting, counting);
	signal data_counter_state: counter_states := waiting;

-- Data counter for the Tx y Rx registers of the SPI interface.
	signal data_counter: std_logic_vector(3 downto 0) := X"F";

-- Data Rececption Register	
	signal DataRx: std_logic_vector(AnchoBus-1 downto 0) := (others => '0');

-- Data Transmition Register
	signal DataTx: std_logic_vector(AnchoBus-1 downto 0) := (others => '0');
	
	
begin

-- Interruption Line definition
	IntLine <= IntEnable and status;

-- interruption event enable
	CS_Q2 <= CS_Q1 when rising_edge(SysClk) else CS_Q2;

-- Clock for IC definition
-- FdeviceClok = Fosc / (2^(AnchoPrescaler + 1))
	clk_enable <= '1' when prescaler=2**(prescaler'High+1)-1 else '0';
	prescaler <= prescaler + 1 when rising_edge(SysClk) else prescaler;
	DeviceClk <= DeviceClkReg;

-- Driver for the MCP3002 Clk	
	DeviceClkPro: process (SysClk, clk_enable)
	begin	
		if rising_edge(SysClk) and clk_enable = '1' then
				DeviceClkReg <= not DeviceClkReg;
		end if;
	end process;
	
	
-- Write and Read for Registers.
--Control Register Write
	process(SysClk)
	begin
		if rising_edge(SysClk) then
			if Reset = '1' then
				ControlRegADC <= (others => '0');
			elsif ControlRegADC_RWE = '1'  and IO_WR = '1' then
				ControlRegADC <= IO_Dout;
			elsif CS_Q1 = '1' and CS_Q2 = '0' then
				status <= '1';
			end if;
		end if;
	end process;
	
-- Read/Write Enable for	ControlRegADC
	process(SysClk)
	begin
		if rising_edge(SysClk) then
			if ((IO_Addr and ADC_Mask ) = DirControlRegADC) then
				ControlRegADC_RWE <= '1';
			else
				ControlRegADC_RWE <= '0';
			end if;
		end if;
   end process;
	

--Read Enable for DataOut
	process(SysClk)
	begin
		if rising_edge(SysClk) then
			if ((IO_Addr and ADC_Mask ) = DirDataOut) then
				DataOut_RE <= '1';
			else
				DataOut_RE <= '0';
			end if;
		end if;
   end process;
	
	
-- IO_Din Bus definition.
	
	IO_Din <= ControlRegADC  		  when ControlRegADC_RWE = '1'  and IO_RD = '1' else
		  (15 downto 10 => '0') & DataOut when DataOut_RE = '1' 	and IO_RD = '1' else (others => '0');

-- Assignment of MOSI - SPI interface
	MOSI <= DataTx(conv_integer(data_counter));

-- Data read  from MISO - SPI interface	
-- Shift register Implementation 
	DataRx(0) <= MISO when rising_edge(DeviceClkReg) and CS_Q1 ='0' else DataRx(0);
				
	rxGen: for i in 1 to 15 generate
		DataRx(i) <= DataRx(i - 1) when rising_edge(DeviceClkReg) and CS_Q1 ='0' else DataRx(i); 
	end generate rxGen;
	
-- FSM for the data counter.	
	datacounterState: process(sysClk, DeviceClkReg)
	begin
		if falling_edge(DeviceClkReg) then
			if CS_Q1='0' then
				case data_counter_state is
					when waiting => data_counter_state <= counting;
					when counting =>
							if data_counter = X"0" then
								data_counter_state <= waiting;
							end if;
				end case;
			end if;
		end if;
	end process;


-- Drive for data counter ( Countdown ).
-- counter is only active when the convertion starts.
-- and it is reset when the convertion has finished
	dataCountProc: process(SysClk, DeviceClkReg)
	begin
		if falling_edge(DeviceClkReg) then
			if CS_Q1 = '1' then
				data_counter <= X"F";
			else
				data_counter <= data_counter - 1;
			end if;
		end if;
	end process;


-- Data TX is masked to obtain the right protocol for the MCP3002.
-- this is the only difference in contrast a general SPI module, but without anothers SPI features
	DataTx <= (ControlRegADC and X"3000") or X"4800";

-- Data converted, only the 10 LSB's of the Data Rx.
	DataOut <= DataRx(DataOut'range);
	
-- Q register to begin the convertion
	CS_Q_Proc: process(SysClk, data_counter)
	begin
		if rising_edge(SysClk) then
			if DataOut_RE = '1' and IO_WR = '1' then
				CS_Q <= '0';
			elsif data_counter = X"0" then
				CS_Q <= '1';
			end if;
		end if;
	end process;
	
-- Q register that works as driver for the CS phy pin.
	CS_Q1_Proc: process(SysClk, DeviceClkReg)
	begin
		if falling_edge(DeviceClkReg) then
			if data_counter = X"0" then
				CS_Q1 <= '1';
			elsif CS_Q = '0' then
				CS_Q1 <= '0';
			end if;
		end if;
	end process;

-- Conection between the CS drive and the phy.
	CS <= CS_Q1;
	
end Funcionamiento;