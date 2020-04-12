library IEEE;
use IEEE.std_logic_1164.all;
use ieee.numeric_std.all;
use work.my_package.all;

entity logic_block is
	generic (N: integer:= 32);								--number of bits
	port(                                                   
		A			:	In	std_logic_vector(N-1 downto 0);		--operand 1
		B			:	In	std_logic_vector(N-1 downto 0);		--operand 2
		A_AND_B		:	Out	std_logic_vector(N-1 downto 0);		--and
		A_XOR_B		:	Out	std_logic_vector(N-1 downto 0);		--xor
		A_OR_B		:	Out	std_logic_vector(N-1 downto 0)		--or
	);
end entity logic_block;

architecture structural of logic_block is
begin

	A_AND_B	<= A and B;
	A_XOR_B	<= A xor B;
	A_OR_B	<= A or  B;
	
end architecture structural;
