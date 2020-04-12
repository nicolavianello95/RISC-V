library ieee;
use ieee.std_logic_1164.all;

entity clk_gen is
	port(
		clk     : out std_logic;
		rst		: out std_logic
	);
end entity clk_gen;

architecture behavioural of clk_gen is

	constant clk_period : time := 2 ns;

begin

	clk_proc: process
	begin
		CLK<='0';
		wait for clk_period/2;
		CLK<='1';
		wait for clk_period/2;
	end process clk_proc;

	RST<='0', '1' after clk_period;

end architecture behavioural;
