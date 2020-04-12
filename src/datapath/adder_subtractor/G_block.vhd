library ieee; 
use ieee.std_logic_1164.all; 

-- General generate block. It takes three inputs and give one output.
-- P_ik is the general propagate with index i:k which arrives from the same column
-- G_ik is the general generate with index i:k which arrives from the same column
-- G_k1j is the general generate with index k-1:j which arrives from different column
-- G_ij is the result of the block with index i:j

ENTITY  G_BLOCK IS
    PORT (
      P_ik , G_ik	: in  std_logic; 
      G_k1j			: in  std_logic;
      G_ij			: out std_logic);
END ENTITY G_BLOCK;		

architecture STRUCTURAL of G_BLOCK is
  
BEGIN

	--definition of a general generate block
	G_ij <=  G_ik or (P_ik and G_k1j); 
 
end STRUCTURAL;

