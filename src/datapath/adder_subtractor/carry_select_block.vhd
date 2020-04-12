library ieee; 
use ieee.std_logic_1164.all;

entity carry_select_block is
	generic(N: positive := 4);								--number of bits of the block
	port(	A, B:	in std_logic_vector(N-1 downto 0);		--data inputs
			S:		out std_logic_vector(N-1 downto 0);		--data output
			Ci:		in std_logic);							--block carry-in
end entity carry_select_block;

architecture structural of carry_select_block is

	component MUX_2to1 is
		Generic (N: integer:= 1);								--number of bits
		Port (	IN0:	In	std_logic_vector(N-1 downto 0);		--data input 1
				IN1:	In	std_logic_vector(N-1 downto 0);		--data input 2
				SEL:	In	std_logic;							--selection input
				Y:		Out	std_logic_vector(N-1 downto 0));	--data output
	end component MUX_2to1;

	component RCA is 
		generic (N:  integer := 8);							--number of bits
		Port (	A:	In	std_logic_vector(N-1 downto 0); 	--data input 1
				B:	In	std_logic_vector(N-1 downto 0);		--data input 2
				Ci:	In	std_logic;							--carry-in
				S:	Out	std_logic_vector(N-1 downto 0);		--data output
				Co:	Out	std_logic);							--carry-out
	end component RCA; 
	
	signal S_0: std_logic_vector(N-1 downto 0);				--sum if carry-in is 0
	signal S_1: std_logic_vector(N-1 downto 0);				--sum if carry-in is 1

begin

	--sum with carry-in=0
	RCA_0: RCA	generic map(N)
				port map(A=>A, B=>B, Ci=>'0', S=>S_0, Co=>open);
				
	--sum with carry-in=1			
	RCA_1: RCA	generic map(N)
				port map(A=>A, B=>B, Ci=>'1', S=>S_1, Co=>open);
				
	--select the actual sum depending on the effective carry-in
	SUM_SELECT_MUX:  MUX_2to1	generic map(N)
								port map(IN0=>S_0, IN1=>S_1, SEL=>Ci, Y=>S);
							
end architecture structural;