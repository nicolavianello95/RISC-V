library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity barrel_shifter is
port 	(	OPERAND		: 	IN std_logic_vector(31 downto 0);		-- operand that we want shift
			SHIFT_AMOUNT:	IN std_logic_vector(4 downto 0);		-- number of position to shift
			LOGIC_ARITH	: 	IN std_logic;							-- logic 0 arith 1
			LEFT_RIGHT	: 	IN std_logic;							-- left 0 right 1
			OUTPUT		: 	OUT std_logic_vector(31 downto 0)); 	-- result 
end  barrel_shifter;


architecture structural of  barrel_shifter is

	component MUX_2to1 is
		Generic (N: integer:= 1);								--number of bits
		Port (	IN0:	In	std_logic_vector(N-1 downto 0);		--data input 1
				IN1:	In	std_logic_vector(N-1 downto 0);		--data input 2
				SEL:	In	std_logic;							--selection input
				Y:		Out	std_logic_vector(N-1 downto 0));	--data output
	end component MUX_2to1;

	component MUX_8to1 is
		Generic (N: integer:= 1);	--number of bits
		Port (	IN0, IN1, IN2, IN3, IN4, IN5, IN6, IN7	: In	std_logic_vector(N-1 downto 0);		--data inputs
				SEL					: In	std_logic_vector(2 downto 0);							--selection input
				Y					: Out	std_logic_vector(N-1 downto 0));						--data output
	end component MUX_8to1;

	constant Nbit 		: positive 	:= 32;
	type matrix is array (Nbit/4 downto 1) of std_logic_vector(Nbit+3 downto 0);
	signal out_left, out_right, out_mux_right, out_first_stage: matrix ;
	
	-- oversized signal to manage the mask creation
	signal zero_vector, MSB_vector : std_logic_vector(Nbit+3 downto 0);
	
	-- signal used to propagate result from stage two to stage three
	signal out_second_stage : std_logic_vector(Nbit+3 downto 0);
	
	-- signal used to manage the mux of the third stage
	signal sel_mux_out				: std_logic;
	signal select_mux_3s			:std_logic_vector(2 downto 0);
	
 	-- it holds only five bits of the SHIFT_AMOUNT input signal because on 32 bit, it is possible has a max shift of 32 bit (log2(32) = 5)
	signal shift_pos 				: std_logic_vector ( 4 downto 0);
BEGIN
	-- create a vector of all 0
	zero_vector <= (others => '0');
	
	-- simple assignement to manage the shift position
	shift_pos <= SHIFT_AMOUNT;
	-- it generates a signal with all the bits equal to the MSB. It is used in the arithmetical shift
	MSB_fill: for x in 0 to Nbit+3 generate
	MSB_vector (x)<= OPERAND(31);
	end generate MSB_fill;

	-- FIRST STAGE --------------------------------------------------------------------------------------------------------
	-- create the eight possible general mask for left shift
	-- mask 0 : OPERAND(31 downto 0) & "0000"
	-- mask 4 : OPERAND(27 downto 0) & "00000000"
	-- ...other mask...
	-- mask 28: OPERAND(3 downto 0) & "00000000000000000000000000000000"
	FIRST_STAGE_1: for x in 1 to Nbit/4 generate	
		out_left(x) <= (OPERAND(35-4*x downto 0) & zero_vector(4*x -1 downto 0));
	end generate FIRST_STAGE_1;	
	
	-- it select if fill with the MSB or with the 0 based on if it is a arithmetic or a logical shift
	FIRST_STAGE_2: for x in 1 to Nbit/4 generate
		right_MUX2to1 : MUX_2to1
						Generic map(N => 4*x)
						Port map(IN0=> (others=>'0'),IN1=> MSB_vector(4*x-1 downto 0),SEL=> LOGIC_ARITH ,Y=> out_mux_right(x)(4*x-1 downto 0));	
	end generate FIRST_STAGE_2;
	
	--  create the eight possible general mask for right shift
	-- if LOGIC shift:
	-- mask 0 : "0000" & OPERAND(31 downto 0)
	-- mask 4 : "00000000" & OPERAND(31 downto 4)
	-- ...other mask...
	-- mask 28: "00000000000000000000000000000000" & OPERAND(31 downto 28)  
	-- if ARITHMETIC shift:
	-- mask 0 : "1111" & OPERAND(31 downto 0)
	-- mask 4 : "11111111" & OPERAND(31 downto 4)
	-- ...other mask...
	-- mask 28: "11111111111111111111111111111111" & OPERAND(31 downto 28)  
	FIRST_STAGE_3: for x in 1 to Nbit/4 generate	
		out_right(x) <= (out_mux_right(x)(4*x-1 downto 0) & OPERAND(Nbit-1 downto 4*x-4));
	end generate FIRST_STAGE_3;	
	
	-- it select if it is a mask for right shift or a mask for left shift
	FIRST_STAGE_4: for x in 1 to Nbit/4 generate
		MASK_MUX2to1 : MUX_2to1
					Generic map(N => Nbit + 4)
					Port map(IN0=> out_left(x) ,IN1=> out_right(x) ,SEL=> LEFT_RIGHT ,Y=>out_first_stage(x));
	end generate FIRST_STAGE_4;
	
	-- SECOND STAGE -------------------------------------------------------------------------------------
	-- select the best mask approximation based on the 3 upper bits of shift_pos
	mux_second_stage: MUX_8to1 
					Generic map(N => Nbit + 4)
					Port map(IN0=>out_first_stage(1),IN1=>out_first_stage(2),IN2=>out_first_stage(3),
					IN3=>out_first_stage(4),IN4=>out_first_stage(5),IN5=>out_first_stage(6),
					IN6=>out_first_stage(7),IN7=>out_first_stage(8),SEL=>shift_pos(4 downto 2),Y=> out_second_stage);	
				 
	-- THIRD STAGE --------------------------------------------------------------------------------------
	-- It select the right mask based on the last two bit of shift_pos and on the LEFT_RIGHT signal.
	-- if LEFT_RIGHT = LEFT it select one mask between input OPERAND and D
	-- if LEFT_RIGHT = RIGHT it select one mask between input E and H
	-- The different entries cut the input signal in order to provide the correct shifting
	select_mux_3s <= (LEFT_RIGHT & shift_pos(1) & shift_pos(0));
	mux_third_stage: MUX_8to1
					Generic map(N => Nbit)
					Port map(IN0=>out_second_stage(Nbit+3 downto 4),IN1=>out_second_stage(Nbit+2 downto 3),
					IN2=>out_second_stage(Nbit+1 downto 2),IN3=>out_second_stage(Nbit downto 1),
					IN4=>out_second_stage(Nbit -1 downto 0),IN5=>out_second_stage(Nbit downto 1),
					IN6=>out_second_stage(Nbit+1 downto 2),IN7=>out_second_stage(Nbit+2 downto 3),
					SEL=>select_mux_3s,Y=> OUTPUT);

end structural;


