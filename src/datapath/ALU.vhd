library IEEE;
use IEEE.std_logic_1164.all;
use ieee.numeric_std.all;
use work.ALU_package.all;
use work.my_package.all;

entity ALU is
	generic (N : integer := 32);										--number of bits
	port(	FUNC			: in ALU_OP_type;							--operation to do
			DATA1, DATA2	: in std_logic_vector(N-1 downto 0);		--data inputs
			OUT_ALU			: out std_logic_vector(N-1 downto 0));		--data output
end entity ALU;

architecture behavioral of ALU is

	component barrel_shifter is
		port(	
			OPERAND		: 	IN std_logic_vector(31 downto 0);		-- operand that we want shift
			SHIFT_AMOUNT:	IN std_logic_vector(4 downto 0);		-- number of position to shift
			LOGIC_ARITH	: 	IN std_logic;							-- logic 0 arith 1
			LEFT_RIGHT	: 	IN std_logic;							-- left 0 right 1
			OUTPUT		: 	OUT std_logic_vector(31 downto 0)	 	-- result 
		);
	end component barrel_shifter;
	
	component adder_subtractor is
		generic(N_BIT	: integer := 32);							--number of bits
		port(
			A		: in  std_logic_vector(N_BIT - 1 downto 0);		--input operand 1
			B		: in  std_logic_vector(N_BIT - 1 downto 0);		--input operand 2
			add_sub	: in  std_logic;								--addition 0 subtraction 1
			Cout	: out std_logic;								--carry-out
			sum		: out std_logic_vector(N_BIT -1 downto 0)		--sum
		);
	end component adder_subtractor;
	
	component logic_block is
		generic (N: integer:= 32);									--number of bits
		port(                                                   
			A			:	In	std_logic_vector(N-1 downto 0);		--operand 1
			B			:	In	std_logic_vector(N-1 downto 0);		--operand 2
			A_AND_B		:	Out	std_logic_vector(N-1 downto 0);		--and
			A_XOR_B		:	Out	std_logic_vector(N-1 downto 0);		--xor
			A_OR_B		:	Out	std_logic_vector(N-1 downto 0)		--or
		);
	end component logic_block;
	
	component comparator is
		generic (N: integer:= 32);									--number of bits
		port(                                                   
			SUB			:	In	std_logic_vector(N-1 downto 0);		--result of the subtraction between the two operands
			CARRY		:	In	std_logic;							--carry out of the subtraction between the two operands
			A_LT_B		:	Out	std_logic_vector(N-1 downto 0);		--less than (signed)
			A_LTU_B 	:	Out	std_logic_vector(N-1 downto 0)		--less than (unsigned)
		);
	end component comparator;
	
	--first five bits of second operand
	signal SHIFT_AMOUNT_sig: std_logic_vector(4 downto 0);
	
	--signals to select the shift type
	signal logic_arith, left_right	: std_logic; 
	
	--signal to select addition or subtraction
	signal add_sub 		: std_logic;																				
	
	--adder_subtractor carry_out                                                                                     
	signal carry_out 						: std_logic; 					        
	--functional units outputs
	signal out_adder_subtractor				: std_logic_vector(N-1 downto 0);                       
	signal out_barrel_shifter				: std_logic_vector(N-1 downto 0); 
	signal out_and,out_or,out_xor			: std_logic_vector(N-1 downto 0); 
	signal out_slt,out_sltu					: std_logic_vector(N-1 downto 0);                      

	--inputs of the adder/subtractor
	signal in1_addsub, in2_addsub			: std_logic_vector(N-1 downto 0);

	begin                                                                                                    
	
		SHIFT_AMOUNT_sig<=DATA2(4 downto 0);
	
		barrel_shifter_instance : barrel_shifter 	
			port map(
				LOGIC_ARITH=>logic_arith,
				LEFT_RIGHT=>left_right,
				OPERAND=> DATA1,
				SHIFT_AMOUNT=>SHIFT_AMOUNT_sig,
				OUTPUT=> out_barrel_shifter
			);
		
		adder_subtractor_instance: adder_subtractor
			generic map(N)
			port map(
				A=>in1_addsub,
				B=>in2_addsub,
				add_sub=>add_sub,
				Cout=>carry_out,
				SUM=>out_adder_subtractor
			);		

		logic_block_instance: logic_block
			generic map(N)
			port map(
				A=>DATA1,
				B=>DATA2,
				A_AND_B=>out_and,
				A_XOR_B=>out_xor,
				A_OR_B=>out_or
			);
					
		comparator_instance: comparator
			generic map(N)
			port map(
				sub=>out_adder_subtractor,
				carry=>carry_out,
				A_LT_B=>out_slt,
				A_LTU_B=>out_sltu
			);
		
		func_process: process(FUNC, out_adder_subtractor, out_barrel_shifter, out_and, out_or, out_xor, out_slt, out_sltu, DATA1, DATA2)
		begin
			--default assignments
			OUT_ALU<=(others=>'-');
			add_sub<='-';
			left_right<='-';
			logic_arith<='-';
			in1_addsub<=DATA1;
			in2_addsub<=DATA2;
			if FUNC=ALU_IN1 then
				OUT_ALU<=DATA1;
			elsif FUNC=ALU_IN2 then
				OUT_ALU<=DATA2;
			elsif FUNC=ALU_ADD then
				OUT_ALU<=out_adder_subtractor;
				add_sub<='0';
			elsif FUNC=ALU_SUB then
				OUT_ALU<=out_adder_subtractor;
				add_sub<='1';
			elsif FUNC=ALU_XOR then
				OUT_ALU<=out_xor;
			elsif FUNC=ALU_AND then
				OUT_ALU<=out_and;
			elsif FUNC=ALU_OR then
				OUT_ALU<=out_or;
			elsif FUNC=ALU_SL then
				OUT_ALU<=out_barrel_shifter;
				left_right<='0';
			elsif FUNC=ALU_SRL then
				OUT_ALU<=out_barrel_shifter;
				left_right<='1';
				logic_arith<='0';
			elsif FUNC=ALU_SRA then
				OUT_ALU<=out_barrel_shifter;
				left_right<='1';
				logic_arith<='1';
			elsif FUNC=ALU_SLT then
				OUT_ALU<=out_slt;
				add_sub<='1';
			elsif FUNC=ALU_SLTU then
				OUT_ALU<=out_sltu;
				add_sub<='1';
			elsif FUNC=ALU_ABS then
				if DATA1(N-1)='0' then
					OUT_ALU<=DATA1;
				else
					OUT_ALU<=out_adder_subtractor;
					add_sub<='1';
					in1_addsub<=(others=>'0');
					in2_addsub<=DATA1;
				end if;
			end if;
		end process;

end architecture behavioral;
