library IEEE;
use IEEE.std_logic_1164.all;

entity MUX_2to1 is
	Generic (N: integer:= 1);								--number of bits
	Port (	IN0:	In	std_logic_vector(N-1 downto 0);		--data input 1
			IN1:	In	std_logic_vector(N-1 downto 0);		--data input 2
			SEL:	In	std_logic;							--selection input
			Y:		Out	std_logic_vector(N-1 downto 0));	--data output
end entity MUX_2to1;

architecture behavioral of MUX_2to1 is
begin

	with SEL select Y<=
		IN0 when '0',
		IN1 when others;
	
end architecture behavioral;
