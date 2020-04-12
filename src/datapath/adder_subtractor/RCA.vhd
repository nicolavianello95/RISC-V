library ieee; 
use ieee.std_logic_1164.all; 
use ieee.std_logic_unsigned.all;

entity RCA is 
	generic (N:  integer := 8);							--number of bits
	Port (	A:	In	std_logic_vector(N-1 downto 0); 	--data input 1
			B:	In	std_logic_vector(N-1 downto 0);		--data input 2
			Ci:	In	std_logic;							--carry in
			S:	Out	std_logic_vector(N-1 downto 0);		--data output
			Co:	Out	std_logic);							--carry out
end RCA; 

architecture STRUCTURAL of RCA is

	signal STMP : std_logic_vector(N-1 downto 0);	--sum
	signal CTMP : std_logic_vector(N downto 0);		--carries

	component FA
		Port(	A:	In	std_logic;
				B:	In	std_logic;
				Ci:	In	std_logic;
				S:	Out	std_logic;
				Co:	Out	std_logic);
	end component; 

begin

  CTMP(0) <= Ci;		--carry in
  S <= STMP;			--sum
  Co <= CTMP(N);		--carry out
  
  ADDER_GEN: for I in 1 to N generate	--generates a fulladder for each bit of the adder
    FULLADDER : FA
		port map (A => A(I-1), B=> B(I-1), Ci => CTMP(I-1), S=> STMP(I-1), Co=> CTMP(I)); 
	end generate ADDER_GEN;

end STRUCTURAL;