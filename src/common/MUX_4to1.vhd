library IEEE;
use IEEE.std_logic_1164.all;

entity MUX_4to1 is
	Generic (N: integer:= 1);	--number of bits
	Port (	IN0, IN1, IN2, IN3	: In	std_logic_vector(N-1 downto 0);		--data inputs
			SEL					: In	std_logic_vector(1 downto 0);		--selection input
			Y					: Out	std_logic_vector(N-1 downto 0));	--data output
end entity MUX_4to1;

architecture behavioral of MUX_4to1 is
begin

	with SEL select Y<=
		IN0 when "00",
		IN1 when "01",
		IN2 when "10",
		IN3 when others;
	
end architecture behavioral;
