library IEEE;
use IEEE.std_logic_1164.all; 
use work.RISCV_package.all;

entity IR is
	port(
		IR_IN	: In	word;			--instruction register input
		IR_OUT	: Out	word;			--instruction register output
		EN		: In 	std_logic;		--enable active high
		BUBBLE	: in	std_logic;		--if high a bubble is introduced
		CLK		: In	std_logic;		--clock
		RST		: In	std_logic		--asynchronous reset active low
	);
end entity IR;

architecture behavioral of IR is

begin

	IR_proc: process(CLK, RST)
	begin
		if RST='0' then
			IR_OUT<=(others=>'0');
		elsif rising_edge(CLK) then
			if BUBBLE='1' then
				IR_OUT<=INSTR_NOP;
			elsif EN='1' then
				IR_OUT<=IR_IN;
			end if;
		end if;
	end process IR_proc;
	
end behavioral;
