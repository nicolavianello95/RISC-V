library IEEE;
use IEEE.std_logic_1164.all; 

entity reg is
	generic (N: positive:= 1 );									--number of bits
	port(	D		: In	std_logic_vector(N-1 downto 0);		--data input
			Q		: Out	std_logic_vector(N-1 downto 0);		--data output
			EN		: In 	std_logic;							--enable active high
			CLK		: In	std_logic;							--clock
			RST		: In	std_logic							--asynchronous reset active low
	);
end entity reg;

architecture behavioral of reg is	--register with asyncronous reset and enable

begin
	reg_proc: process(CLK, RST)		--asynchronous reset
	begin
		if RST='0' then				--if reset is active
			Q<=(others=>'0');		--clear the output
		elsif rising_edge(CLK) then 	--otherwise if there is a positive clock edge
			if EN='1' then			--and enable is active
				Q <= D; 			--writes the input on the output
			end if;
	    end if;
	end process;
	
end behavioral;
