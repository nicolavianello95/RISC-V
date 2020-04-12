library ieee; 
use ieee.std_logic_1164.all; 
use ieee.std_logic_unsigned.all;

entity  sum_generator is
	generic(Nblocks			: positive := 8;	--number of carry select block
			bits_per_block	: positive := 4);	--number of bit per each block
												--the number of input bits is equal to Nblocks*bits_per_block
    port (
      A				: in  std_logic_vector(bits_per_block*Nblocks - 1 downto 0);	--data input 1
      B         	: in  std_logic_vector(bits_per_block*Nblocks - 1 downto 0);	--data input 2
      carry_select	: in  std_logic_vector(Nblocks-1 downto 0);						--carries from sparse tree
      SUM			: out std_logic_vector(bits_per_block*Nblocks - 1 downto 0));	--data output
end entity sum_generator;		

architecture structural of sum_generator is

	component carry_select_block is
		generic(N: positive := 4);									--number of bits of the block
		port(	A, B	:	in std_logic_vector(N-1 downto 0);		--data inputs
			S		:	out std_logic_vector(N-1 downto 0);			--data output
			Ci		:	in std_logic								--block carry-in
		);
	end component; 
  
begin

	gen_block: for i in 1 to Nblocks generate	--generate "Nblocks" carry select blocks
	block_n : carry_select_block
		generic map (N =>bits_per_block)		--each with "bits_per_block" bits
		port map(	A=> A((bits_per_block*i)-1 downto (i-1)*bits_per_block),		--split input A in "Nblocks" sub-signal each of "bits_per_block" bits and connect each sub-signal to each block input A
					B=> B((bits_per_block*i)-1 downto (i-1)*bits_per_block),		--idem for input B
					S=> SUM((bits_per_block*i)-1 downto (i-1)*bits_per_block),		--put together all the outputs of the singles blocks to the output of the sum_generator
					Ci => CARRY_SELECT(i-1));										--connect all the input carries from the carry generator to the carry select of each blocks
	end generate gen_block;

end structural;

