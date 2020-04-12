library IEEE;
use IEEE.std_logic_1164.all;

entity MUX_8to1 is
	Generic (N: integer:= 1);	--number of bits
	Port (	IN0, IN1, IN2, IN3, IN4, IN5, IN6, IN7	: In	std_logic_vector(N-1 downto 0);		--data inputs
			SEL					: In	std_logic_vector(2 downto 0);		--selection input
			Y					: Out	std_logic_vector(N-1 downto 0));	--data output
end entity MUX_8to1;

architecture behavioral of MUX_8to1 is
begin

	with SEL select Y<=
		IN0 when "000",
		IN1 when "001",
		IN2 when "010",
		IN3 when "011",
		IN4 when "100",
		IN5 when "101",
		IN6 when "110",
		IN7 when others;
	
end architecture behavioral;
