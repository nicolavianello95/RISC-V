library ieee; 
use ieee.std_logic_1164.all; 

entity FA is
	Port (	A:	In	std_logic;			--input bit 1
			B:	In	std_logic;			--input bit 2
			Ci:	In	std_logic;			--carry in
			S:	Out	std_logic;			--sum
			Co:	Out	std_logic);			--carry out
end FA; 

architecture structural of FA is

begin

  S <= (A xor B xor Ci);								--sum
  Co <= ((A and B) or (B and Ci) or (A and Ci));		--carry out

end structural;
