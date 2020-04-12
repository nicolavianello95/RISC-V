library ieee; 
use ieee.std_logic_1164.all; 

-- General propagate block. It takes four inputs and give two outputs.
-- It as general generate block with the adding of the computation of propagate signal
-- For G:
-- P_ik is the general propagate with index i:k which arrives from the same column
-- G_ik is the general generate with index i:k which arrives from the same column
-- G_k1j is the general generate with index k-1:j which arrives from different column
-- G_ij is the result of the block with index i:j 
-- For P:
-- P_ik is the general propagate with index i:k which arrives from the same column
-- P_k1j is the general propagate with index k-1:j which arrives from different column
-- P_ij is the result of the block with index i:j 

ENTITY  PG_BLOCK IS
    PORT (
		P_ik , G_ik	: in  std_logic;
		P_k1j, G_k1j: in  std_logic;
		P_ij, G_ij	: out std_logic);
END ENTITY PG_BLOCK;		

architecture STRUCTURAL of PG_BLOCK is
BEGIN

	--definition of a general propagate block
	P_ij <=  P_ik and P_k1j;
	G_ij <=  G_ik or (P_ik and G_k1j);
 
end STRUCTURAL;

