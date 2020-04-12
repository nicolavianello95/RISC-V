library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.my_package.all;	--for log2_ceiling

entity RF is
	generic(N_bit:		positive := 64;		--bitwidth
			N_reg:		positive := 32);	--number of registers
	port(	CLK: 		IN std_logic;		--clock
			RST: 		IN std_logic;		--asynchronous reset, active low
			WR_EN: 		IN std_logic;		--synchronous write, active high
			ADDR_WR: 	IN std_logic_vector(log2_ceiling(N_reg)-1 downto 0);	--writing register address 
			ADDR_RD1: 	IN std_logic_vector(log2_ceiling(N_reg)-1 downto 0);	--reading register address 1
			ADDR_RD2: 	IN std_logic_vector(log2_ceiling(N_reg)-1 downto 0);	--reading register address 2
			DATA_IN: 	IN std_logic_vector(N_bit-1 downto 0);		--data to write
			OUT1: 		OUT std_logic_vector(N_bit-1 downto 0);		--data to read 1
			OUT2: 		OUT std_logic_vector(N_bit-1 downto 0));	--data to read 2
end entity RF;

architecture behavioral of RF is

	type 	REG_ARRAY_TYPE is array(1 to N_reg-1) of std_logic_vector(N_bit-1 downto 0);	--array of registers type
	signal 	REGISTERS : REG_ARRAY_TYPE; 													--registers instantiation

	signal ADDR_RD1_int, ADDR_RD2_int, ADDR_WR_int : natural;

begin

	ADDR_RD1_int<=to_integer(unsigned(ADDR_RD1));
	ADDR_RD2_int<=to_integer(unsigned(ADDR_RD2));
	ADDR_WR_int<=to_integer(unsigned(ADDR_WR));

	OUT1 <= REGISTERS(ADDR_RD1_int) when ADDR_RD1_int<=N_reg-1 and ADDR_RD1_int>=1 else
			(others=>'0');

	OUT2 <= REGISTERS(ADDR_RD2_int) when ADDR_RD2_int<=N_reg-1 and ADDR_RD2_int>=1 else
			(others=>'0');
			
	register_file_proc: process(CLK, RST)
	begin
		if RST='0' then
			REGISTERS <= (others=>(others=>'0'));
		elsif rising_edge(CLK) then						
			if WR_EN = '1' then		--if write signal is active
				if (ADDR_WR_int<=N_reg-1 and ADDR_WR_int>=1) then	--and the write address is valid
					REGISTERS(ADDR_WR_int) <= DATA_IN;	--write register pointed by ADDR_WR with the value contained in DATAIN
				end if;
			end if;
		end if;
	end process;
	
end architecture behavioral;
