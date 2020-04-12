library IEEE;
use IEEE.std_logic_1164.all; 
use work.RISCV_package.all;

entity PC is
	port(
		PC_IN	: In	word;			--new program count
		PC_OUT	: Out	word;			--current program count
		EN		: In 	std_logic;		--enable active high
		CLK		: In	std_logic;		--clock
		RST		: In	std_logic		--asynchronous reset active low
	);
end entity PC;

architecture behavioral of PC is

begin
	PC_proc: process(CLK, RST)			--asynchronous reset
	begin
		if RST='0' then					--if reset is active
			PC_OUT<=X"00400000";		--initialize de PC to the first instruction
		elsif rising_edge(CLK) then 	--otherwise if there is a positive clock edge
			if EN='1' then				--and enable is active
				PC_OUT <= PC_IN; 		--writes the input on the output
			end if;
	    end if;
	end process;
	
end behavioral;
