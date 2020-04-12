library ieee; 
use ieee.std_logic_1164.all; 
use ieee.std_logic_unsigned.all;
use work.my_package.all;

entity  adder_subtractor IS
	generic (N_BIT	: integer := 32);	--number of bits, must be a number from 4 to 32 and a multiple of 4
    port(
		A		: in  std_logic_vector(N_BIT - 1 downto 0);		--input operand 1
		B		: in  std_logic_vector(N_BIT - 1 downto 0);		--input operand 2
		add_sub	: in  std_logic;								--addition 1 subtraction 0
		Cout	: out std_logic;								--carry-out
		sum		: out std_logic_vector(N_BIT -1 downto 0)		--ouput sum
	);		
end entity adder_subtractor;		

architecture structural of adder_subtractor is

	component sum_generator is
		generic(
			Nblocks			: positive := 8;	--number of carry select block
			bits_per_block	: positive := 4		--number of bit per each block
		);										--the number of input bits is equal to Nblocks*bits_per_block			
		port(
			A				: in  std_logic_vector(bits_per_block*Nblocks - 1 downto 0);	--data input 1
			B         		: in  std_logic_vector(bits_per_block*Nblocks - 1 downto 0);	--data input 2
			carry_select	: in  std_logic_vector(Nblocks-1 downto 0);						--block carry-in
			sum				: out std_logic_vector(bits_per_block*Nblocks - 1 downto 0)		--block sum
		);
	end component; 
  
	component carry_generator is
		generic(Nbit		: positive := 32);					--number of bits of the sparse tree, must be between 4 and 32 and a multiple of 4
		port(
			A		: in  std_logic_vector(Nbit - 1 downto 0);	--input operand 1
			B		: in  std_logic_vector(Nbit - 1 downto 0);	--input operand 2
			Cin		: in  std_logic;							--carry-in
			Cout	: out std_logic_vector(Nbit/4 downto 0)		--carry-out
		);
	end component; 
  
	signal carries	: std_logic_vector(N_BIT/4	downto 0);	--carries between the two modules
	signal B_xor	: std_logic_vector(N_BIT - 1 downto 0); --B xor add_sub
begin

	carry_generator_instance: carry_generator 
		generic map (Nbit => N_BIT)
		port map  (A => A,	B => B_xor, Cin	=> add_sub, Cout => carries);

	sum_generator_instance: sum_generator
		generic map(Nblocks=> N_BIT/4, bits_per_block => 4)
		port map(A => A, B => B_xor , carry_select => carries (N_BIT/4-1 downto 0), sum => sum);
		 
	--the last carry is the carry-out of the entire structure
	Cout <= carries(N_BIT/4);
	
	--if add_sub=1, B is complemented and the carry-in of the adder becomes 1
	B_xor <= B xor add_sub;

end structural;

