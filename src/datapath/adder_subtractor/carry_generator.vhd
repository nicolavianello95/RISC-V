library ieee; 
use ieee.std_logic_1164.all; 
use ieee.std_logic_unsigned.all;
use ieee.math_real.all;
use ieee.numeric_std.all;

-- CLA sparse tree module used in Pentium 4
entity  carry_generator is
	generic(Nbit	 : positive := 32); 							--number of bits of the sparse tree, must be between 4 and 32 and a multiple of 4
    port(                                                           
		A          	 : IN  std_logic_vector(Nbit - 1 downto 0); 	--input operand 1
		B         	 : IN  std_logic_vector(Nbit - 1 downto 0); 	--input operand 2
		Cin			 : IN  std_logic; 								--carry-in
		Cout         : OUT std_logic_vector(Nbit/4 downto 0)  		--carry-out
	);
end entity carry_generator;		

architecture structural of carry_generator is
	--propagate and generate network
	component PG_NETWORK IS 
		PORT (
			op1          	 : in  std_logic;		--input bit 1
			op2         	 : in  std_logic;		--input bit 2
			g,p         	 : out std_logic);	--output propagate and generate 
	end component;
  
	--general propagate block
	component PG_BLOCK IS
		PORT (
			P_ik , G_ik         	 : in  std_logic; 
			P_k1j,G_k1j         	 : in  std_logic;
			P_ij, G_ij         	 : out std_logic);
	end component; 
  
	--general generate block  
	component G_BLOCK IS
		PORT (
			P_ik , G_ik         	 : in  std_logic; 
			G_k1j         	 		 : in  std_logic; 
			G_ij         			 : out std_logic);
	end component; 
  
	-- We create two matrix, one for general propagate(p) and one for general generate(g) 
	-- in this way, we have used the column to select the stage, and the row to select the product
	-- for example: g(0)(1) identify the general generate of the first element(1) provided by pg network(0)
	type matrix is array (4 downto 0) of std_logic_vector(Nbit downto 0);
	signal g, p : matrix ;
	
	-- temporal signal (tmp_p and tmp_g) are used only to semplify the generation of the last stage
	signal tmp_p,tmp_g : std_logic_vector(Nbit/4 -1 downto 0);
	
	-- This signal make easier the last stage implementation
	signal reference_gij : std_logic_vector((Nbit/4)-4 downto 0);
	
	-- co_tmp it is used to keep the temporal carry of the system
	signal co_tmp         : std_logic_vector(Nbit/4 - 1 downto 0);
	
	-- G_10 it is used only in case of carry in = 1. It modify the value provide to G block on first stage, after the pg network
	signal G_10: std_logic;
  
  
BEGIN
	-- particular case assignement 
	p(0)(0) <= '0';
	g(0)(0) <= Cin;
	 
	-- Create the pg network for the required number of bit. It is consider as stage 0, so the index of the column is 0.
	-- Stage 0 ---------------------------------------------------------------------------------------------------------------------
	generation_PG_Network: for x in 1 to Nbit generate
		Block_PG_NET : PG_NETWORK
		PORT MAP(op1 => A(x-1), op2=>B(x-1), g=> g(0)(x), p=>p(0)(x));
	end generate generation_PG_Network;

	-- in case of carry in, g(0)(1) must be different (in lecture it is the value identify by G [1:0]), so:
	G_10 <= g(0)(1) or (p(0)(1) and g(0)(0));

	-- First stage -----------------------------------------------------------------------------------------------------------------
	g_1 : G_BLOCK PORT MAP(P_ik => p(0)(2), G_ik =>g(0)(2) ,G_k1j => G_10, G_ij => g(1)(0));
			
	First_stage: for x in 1 to (Nbit-2)/2 generate
		Block_Stage_ONE : PG_BLOCK
		PORT MAP(P_ik => p(0)(x*2+2), G_ik =>g(0)(x*2+2) , P_k1j=>p(0)(x*2+1) , G_k1j =>g(0)(x*2+1) , P_ij => p(1)(x), G_ij =>g(1)(x) );
	end generate First_stage;
		
	-- Second stage ----------------------------------------------------------------------------------------------------------------
	g_2 : G_BLOCK PORT MAP(P_ik => p(1)(1), G_ik =>g(1)(1) ,G_k1j => g(1)(0), G_ij => co_tmp(0));	

	Second_stage: for x in 1 to Nbit/4 -1 generate
		Block_Stage_TWO : PG_BLOCK
		PORT MAP( P_ik =>p(1)(x*2+1) , G_ik => g(1)(x*2+1), P_k1j=> p(1)(x*2), G_k1j =>g(1)(x*2) , P_ij =>p(2)(x), G_ij => g(2)(x));
	end generate Second_stage;

	-- Third Stage -----------------------------------------------------------------------------------------------------------------
	if4: if Nbit>4 generate
		g_3 : G_BLOCK PORT MAP(P_ik =>p(2)(1), G_ik =>g(2)(1) ,G_k1j =>co_tmp(0), G_ij =>co_tmp(1)); 

		Third_stage: for x in 1 to (Nbit/8 -1 )generate	
			Block_Stage_THREE : PG_BLOCK
			PORT MAP( P_ik => p(2)(x*2+1), G_ik =>  g(2)(x*2+1), P_k1j=>  p(2)(x*2), G_k1j =>  g(2)(x*2), P_ij =>p(3)(x), G_ij =>g(3)(x) );
		end generate Third_stage;
		
	end generate if4;
	
	-- Fourth Stage -----------------------------------------------------------------------------------------------------------------
	if8: if Nbit> 8 generate
		stage_c12_c16: for x in 0 to 1 generate
			g_4_c12_c16: G_BLOCK PORT MAP(P_ik =>p(2+x)(2-x), G_ik =>g(2+x)(2-x) ,G_k1j =>co_tmp(1), G_ij =>co_tmp(2+x)); 
		end generate stage_c12_c16;
	end generate if8;

	if16_1: if Nbit>= 16 generate 
		loopK: for k in 2 to Nbit/16 generate
			Fourth_stage : for x in 0 to 1 generate
				Block_stage_FOUR : PG_BLOCK PORT MAP( P_ik =>p(x+2)((-2+4*k)/(x+1)), G_ik =>g(x+2)((-2+4*k)/(x+1)) , P_k1j=>p(3)(2*(k-1)), G_k1j => g(3)(2*(k-1)), P_ij =>p(4)(x+2*k-2), G_ij =>g(4)(x+2*k-2) );
			end generate Fourth_stage;
		end generate loopK;
	end generate if16_1;
	--------------------------------------------------------------------------------------------------------------------------------
	-- Fifth stage.
	-- This are used to create a order sequence of p and g operand, so the last stage is simpler 
	if16_2: if (Nbit>16) generate
		create_vector: for x in 1 to integer(log2(real(Nbit)))-4 generate
			tmp_p (4*x-1 downto 4*x-4) <=  ( p(4)(2*x+1) & p(4)(2*x) & p(3)(2*x) & p(2)(4*x));
			tmp_g (4*x-1 downto 4*x-4) <=  ( g(4)(2*x+1) & g(4)(2*x) & g(3)(2*x) & g(2)(4*x)); 
		end generate create_vector;
	end generate if16_2;
	
	-- The two following if, are used to create the PG block that preceding the G block that generate the carry52,carry56,carry60 and carry64	
	if64_1: if Nbit>32 generate
		Stage_52_56 : for x in 0 to 1 generate
			Block_carry52_carry56 : PG_BLOCK PORT MAP( P_ik =>p(2+x)(12/(x+1)), G_ik =>g(2+x)(12/(x+1)) , P_k1j=>p(4)(5), G_k1j => g(4)(5), P_ij =>tmp_p(8+x), G_ij =>tmp_g(8+x) );
		end generate Stage_52_56;
	end generate if64_1;
	
	if64_2: if Nbit>32 generate
		Stage_60_64 : for x in 0 to 1 generate
			Block_carry60_carry64 : PG_BLOCK PORT MAP( P_ik =>p(4)(6+x), G_ik =>g(4)(6+x) , P_k1j=>p(4)(5), G_k1j => g(4)(5), P_ij =>tmp_p(10+x), G_ij =>tmp_g(10+x) );
		end generate Stage_60_64;
	end generate if64_2;
	
	-- i value is:
	-- 0 for 32 bit
	-- 1 for 64 bit
	-- This is used to create a vector with some value repeated.
	----------------------------------- Example: if Nbit = 64 it creates:
	-- (co_tmp(7) & co_tmp(7) & co_tmp(7) & co_tmp(7) & co_tmp(7) & co_tmp(7) & co_tmp(7) & co_tmp(7) & co_tmp(3) & co_tmp(3) & co_tmp(3) & co_tmp(3))
	-- co_tmp(7) is used by all 8 block of the last stage between 32 and 62, while co_tmp(3) is used by the 4 block between 16 and 32 
	-- k starts from 1 and not from 0
	if16_3: if Nbit > 16 generate
		selection_i : for i in 0 to integer(log2(real(Nbit)))-5 generate
			range_selection: for k in 4*(2**(i+1)-1)-(2**(i+2)-1) to 4*(2**(i+1)-1) generate
				reference_gij(k) <= co_tmp(-1+2**(i+2));
			end generate range_selection;
		end generate selection_i;
	end generate if16_3;
	
	 -- This is used to generate the last stage of G block
	if16_4: if (Nbit>16) generate 
		Fifth_stage : for x in 4 to Nbit/4 -1 generate
			Block_stage_FIVE : G_BLOCK PORT MAP(P_ik =>tmp_p(x-4), G_ik =>tmp_g(x-4) ,G_k1j => reference_gij(x-3), G_ij => co_tmp(x));
		end generate Fifth_stage;
	end generate if16_4;
	-- END OF STAGES -----------------------------------------------------------------------------------------------------------------

	-- Now, the carries obtained from the various stages are assigned, with also the concatenation of the carry in, to the output of the tree
	Cout <= co_tmp & Cin;

end STRUCTURAL;

