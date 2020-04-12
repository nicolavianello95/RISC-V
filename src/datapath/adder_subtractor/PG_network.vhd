library ieee; 
use ieee.std_logic_1164.all; 

--Create the two starting signal for each pair of bit

ENTITY PG_NETWORK IS
    PORT (
		op1	: in  std_logic;	--input bit 1
		op2	: in  std_logic;	--input bit 2
		g, p: out std_logic);	--output propagate and generate
END ENTITY PG_NETWORK;		

architecture STRUCTURAL of PG_NETWORK is
BEGIN

	g <= op1 and op2;	--generate
	p <= op1 xor op2;	--propagate

end STRUCTURAL;

