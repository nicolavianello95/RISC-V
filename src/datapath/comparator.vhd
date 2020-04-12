library IEEE;
use IEEE.std_logic_1164.all;
use ieee.numeric_std.all;

entity comparator is
	generic (N: integer:= 32);									--number of bits
	port(                                                   
		SUB			: in	std_logic_vector(N-1 downto 0);		--result of the subtraction between the two operands
		CARRY		: in	std_logic;							--carry out of the subtraction between the two operands
		A_LT_B		: out	std_logic_vector(N-1 downto 0);		--less than (signed)
		A_LTU_B 	: out	std_logic_vector(N-1 downto 0)    	--less than (unsigned)
	);
end comparator;

architecture structural of comparator is

	signal lt, ltu	:std_logic;

begin

	lt<=SUB(N-1);
	ltu<=not CARRY;
	
	A_LT_B(0)<=lt;
	A_LT_B(N-1 downto 1)<=(others=>'0');
	
	A_LTU_B(0)<=ltu;
	A_LTU_B(N-1 downto 1)<=(others=>'0');
	
end architecture structural;

