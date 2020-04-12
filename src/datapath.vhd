library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.CU_package.all;		
use work.ALU_package.all;		
use work.RISCV_package.all;		
use work.my_package.all;		
use work.FU_package.all;
use work.HDU_package.all;

entity datapath is
	generic(
		BPU_TAG_FIELD_SIZE	: integer :=8;
		BPU_SET_FIELD_SIZE	: integer :=3;
		BPU_LINES_PER_SET	: integer :=4
	);
	port(
		IRAM_ADDR		: out	word;
		IRAM_OUT		: in	word;
		DRAM_ADDR		: out	word;
		DRAM_IN			: out	word;
		DRAM_OUT		: in	word;
		control_from_CU	: in	CU_OUTS_type;
		control_from_FU : in	FU_OUTS_type;
		control_from_HDU: in	HDU_OUTS_type;
		misprediction	: out	std_logic;
		CLK				: in	std_logic;
		RST				: in	std_logic
	);
end entity datapath;

architecture structural of datapath is

	component reg is
		Generic (N : positive:= 1 );								--number of bits
		Port(	D		: In	std_logic_vector(N-1 downto 0);		--data input
				Q		: Out	std_logic_vector(N-1 downto 0);		--data output
				EN		: In 	std_logic;							--enable active high
				CLK		: In	std_logic;							--clock
				RST		: In	std_logic);							--asynchronous reset active low
	end component reg;

	component PC is
		port(
			PC_IN	: In	word;			--new program count
			PC_OUT	: Out	word;			--current program count
			EN		: In 	std_logic;		--enable active high
			CLK		: In	std_logic;		--clock
			RST		: In	std_logic		--asynchronous reset active low
		);
	end component PC;

	component IR is
		port(
			IR_IN	: In	word;			--instruction register input
			IR_OUT	: Out	word;			--instruction register output
			EN		: In 	std_logic;		--enable active high
			BUBBLE	: in	std_logic;		--if high a bubble is introduced
			CLK		: In	std_logic;		--clock
			RST		: In	std_logic		--asynchronous reset active low
		);
	end component IR;

	component RCA is 
		generic (N:  integer := 8);							--number of bits
		port (	A:	In	std_logic_vector(N-1 downto 0); 	--data input 1
				B:	In	std_logic_vector(N-1 downto 0);		--data input 2
				Ci:	In	std_logic;							--carry in
				S:	Out	std_logic_vector(N-1 downto 0);		--data output
				Co:	Out	std_logic);							--carry out
	end component RCA; 

	component  ADDER_P4 is
		GENERIC (N_BIT	: integer := 32);	--number of bits. Must be a number from 4 to 32 and a multiple of 4
		PORT   (A		: in  std_logic_vector(N_BIT - 1 downto 0);		-- input operand 1
				B		: in  std_logic_vector(N_BIT - 1 downto 0);		-- input operand 2
				add_sub	: in  std_logic;								-- carry-in
				Cout	: out std_logic;								-- carry-out
				SUM		: out std_logic_vector(N_BIT -1 downto 0));		-- ouput sum
	end component ADDER_P4;

	component RF is
		generic(N_bit:		positive := 64;		--bitwidth
				N_reg:		positive := 32);	--number of address bits, the number of registers is equal to 2**N_address
		port(	CLK: 		IN std_logic;		--clock
				RST: 		IN std_logic;		--asynchronous reset, active low
				WR_EN: 		IN std_logic;		--synchronous write, active high
				ADDR_WR: 	IN std_logic_vector(log2_ceiling(N_reg)-1 downto 0);	--writing register address 
				ADDR_RD1: 	IN std_logic_vector(log2_ceiling(N_reg)-1 downto 0);	--reading register address 1
				ADDR_RD2: 	IN std_logic_vector(log2_ceiling(N_reg)-1 downto 0);	--reading register address 2
				DATA_IN: 	IN std_logic_vector(N_bit-1 downto 0);		--data to write
				OUT1: 		OUT std_logic_vector(N_bit-1 downto 0);		--data to read 1
				OUT2: 		OUT std_logic_vector(N_bit-1 downto 0));	--data to read 2
	end component RF;

	component MUX_2to1 is
		Generic (N: integer:= 1);								--number of bits
		Port (	IN0:	In	std_logic_vector(N-1 downto 0);		--data input 1
				IN1:	In	std_logic_vector(N-1 downto 0);		--data input 2
				SEL:	In	std_logic;							--selection input
				Y:		Out	std_logic_vector(N-1 downto 0));	--data output
	end component MUX_2to1;
	
	component MUX_4to1 is
	Generic (N: integer:= 1);	--number of bits
	Port (	IN0, IN1, IN2, IN3	: In	std_logic_vector(N-1 downto 0);		--data inputs
			SEL					: In	std_logic_vector(1 downto 0);		--selection input
			Y					: Out	std_logic_vector(N-1 downto 0));	--data output
	end component MUX_4to1;

	component MUX_8to1 is
		Generic (N: integer:= 1);	--number of bits
		Port (	IN0, IN1, IN2, IN3, IN4, IN5, IN6, IN7	: In	std_logic_vector(N-1 downto 0);		--data inputs
				SEL					: In	std_logic_vector(2 downto 0);		--selection input
				Y					: Out	std_logic_vector(N-1 downto 0));	--data output
	end component MUX_8to1;

	component ALU is
		generic (N : integer := 32);										-- number of bit
		port(	FUNC			: IN ALU_OP_type;							-- operation to do
				DATA1, DATA2	: IN std_logic_vector(N-1 downto 0);		-- data inputs
				OUT_ALU			: OUT std_logic_vector(N-1 downto 0));		-- data output
	end component ALU;

	component branch_comp
		generic(N: integer:= 32);	--number of data-in bits
		port(
			BRANCH_COND		: in BRANCH_COND_type;					--condition to take branch
			DATA_IN1		: in std_logic_vector(N-1 downto 0);	--data to test
			DATA_IN2		: in std_logic_vector(N-1 downto 0);	--data to test
			BRANCH_IS_TAKEN	: out std_logic);						--high if the branch is taken
	end component branch_comp;

	component BPU is
		generic(
			TAG_FIELD_SIZE	: integer := 8;
			SET_FIELD_SIZE	: integer := 3;	
			LINES_PER_SET 	: integer := 4
		);
		port(		
			clk				: in std_logic;				
			rst				: in std_logic;				
			IRAM_out		: in word;	
			pc				: in word;	
			pc_plus4		: in word;	
			npc				: out word;
			misprediction	: out std_logic;
			actual_NPC		: in word;
			IF_ID_EN		: in std_logic;		--fetch-decode registers enable
			ID_EXE_EN		: in std_logic		--decode-execute registers enable
		);
	end component BPU;

	signal PC_IN, PC_IF, PC_ID, NPC_base, NPC_target, PC_plus4, PC_plus4_ID, actual_NPC									: word;
	signal IR_in, IR_out																								: word;
	signal IMM_ITYPE, IMM_STYPE, IMM_BTYPE, IMM_JTYPE, IMM_UTYPE, IMM_ID, IMM_EXE										: word;
	signal RD_ID, RD_EXE, RD_MEM, RD_WB																					: REG_addr;
	signal RF_OUT1, RF_OUT2																								: word;
	signal ALU_IN1_ID, ALU_IN1_ID_fw, ALU_IN2_ID_fw, ALU_IN2_EXE_RF, ALU_IN1_EXE, ALU_IN2_EXE, ALU_OUT_EXE, ALU_OUT_MEM	: word;
	signal MULT_OUT																										: doubleword;
	signal branch_is_taken																								: std_logic;
	signal DRAM_IN_EXE, DRAM_IN_MEM, DRAM_OUT_sb, DRAM_OUT_ub, DRAM_OUT_sh, DRAM_OUT_uh, DRAM_OUT_w, DRAM_OUT_ext		: word;
	signal RF_IN_MEM, RF_IN_WB																							: word;

begin

	-------------------------------------IF stage
	
	IRAM_ADDR<=PC_IF;
	IR_in<=IRAM_OUT;
	
	PC_instance: PC
		port map(
			PC_IN=>PC_IN,
			PC_OUT=>PC_IF,
			EN=>control_from_HDU.PC_EN,
			CLK=>clk,
			RST=>rst
		);

	PC_plus4<=std_logic_vector(unsigned(PC_IF)+4);
			
	BPU_instance: BPU
		generic map(
			TAG_FIELD_SIZE=>BPU_TAG_FIELD_SIZE,
			SET_FIELD_SIZE=>BPU_SET_FIELD_SIZE,
			LINES_PER_SET=>BPU_LINES_PER_SET
		)
		port map(
			clk=>clk,
			rst=>rst,
			IRAM_out=>IRAM_out,
			pc=>PC_IF,
			pc_plus4=>PC_plus4,
			npc=>PC_IN,
			misprediction=>misprediction,
			actual_NPC=>actual_NPC,
			IF_ID_EN=>control_from_HDU.IF_ID_EN,
			ID_EXE_EN=>control_from_HDU.ID_EXE_EN
		);
			
	REG_PC_plus4: reg
		generic map(N=>WORD_SIZE)
		port map(
			D=>PC_plus4,
			Q=>PC_plus4_ID,
			EN=>control_from_HDU.IF_ID_EN,
			CLK=>clk,
			RST=>rst
		);
			
	REG_PC: reg
		generic map(N=>WORD_SIZE)
		port map(
			D=>PC_IF,
			Q=>PC_ID,
			EN=>control_from_HDU.IF_ID_EN,
			CLK=>clk,
			RST=>rst
		);
			
	IR_instance: IR
		port map(
			IR_IN=>IR_in,
			IR_OUT=>IR_out,
			EN=>control_from_HDU.IF_ID_EN,
			BUBBLE=>control_from_HDU.ID_bubble,
			CLK=>clk,
			RST=>rst
		);

	-------------------------------------------------ID stage
	
	MUX_NPC_base: MUX_2to1
		generic map(N=>WORD_SIZE)
		port map(
			IN0=>PC_ID,
			IN1=>ALU_IN1_ID_fw,
			SEL=>control_from_CU.ID.MUX_NPC_base_sel,
			Y=>NPC_base
		);
	
	NPC_target<=std_logic_vector(unsigned(NPC_base)+unsigned(IMM_ID));
		
	branch_comp_instance: branch_comp
		generic map(N=>WORD_SIZE)
		port map(
			BRANCH_COND=>control_from_CU.ID.BRANCH_COND,
			DATA_IN1=>ALU_IN1_ID_fw,
			DATA_IN2=>ALU_IN2_ID_fw,
			BRANCH_IS_TAKEN=>branch_is_taken
		);
		
	MUX_actual_NPC: MUX_2to1
		generic map(N=>WORD_SIZE)
		port map(
			IN0=>PC_plus4_ID,
			IN1=>NPC_target,
			SEL=>branch_is_taken,
			Y=>actual_NPC
		);
		
	MUX_ALU_IN1: MUX_4to1
		generic map(N=>WORD_SIZE)
		port map(
			IN0=>PC_ID,
			IN1=>PC_plus4_ID,
			IN2=>ALU_IN1_ID_fw,
			IN3=>(others=>'-'),
			SEL=>control_from_CU.ID.MUX_ALU_IN1_sel,
			Y=>ALU_IN1_ID
		);
		
	MUX_ALU_IN1_fw: MUX_4to1
		generic map(N=>WORD_SIZE)
		port map(
			IN0=>RF_OUT1,
			IN1=>ALU_OUT_EXE,
			IN2=>RF_IN_MEM,
			IN3=>RF_IN_WB,
			SEL=>control_from_FU.MUX_ALU_IN1_sel,
			Y=>ALU_IN1_ID_fw
		);
		
	MUX_ALU_IN2_fw: MUX_4to1
		generic map(N=>WORD_SIZE)
		port map(
			IN0=>RF_OUT2,
			IN1=>ALU_OUT_EXE,
			IN2=>RF_IN_MEM,
			IN3=>RF_IN_WB,
			SEL=>control_from_FU.MUX_ALU_IN2_sel,
			Y=>ALU_IN2_ID_fw
		);
		
	RD_ID<=IR_out(RD_range);
		
	REG_RD_ID_EXE: reg
		generic map(N=>REG_ADDR_SIZE)
		port map(
			D=>RD_ID,
			Q=>RD_EXE,
			EN=>control_from_HDU.ID_EXE_EN,
			CLK=>clk,
			RST=>rst
		);

	RF_instance: RF
		generic map(
			N_bit=>WORD_SIZE,
			N_reg=>N_REG
		)	
		port map(
			CLK=>clk,
			RST=>rst,
			WR_EN=>control_from_CU.WB.RF_WR_EN,
			ADDR_WR=>RD_WB,
			ADDR_RD2=>IR_out(RS2_range),
			ADDR_RD1=>IR_out(RS1_range),
			DATA_IN=>RF_IN_WB,
			OUT1=>RF_OUT1,
			OUT2=>RF_OUT2
		);
		
	REG_ALU_IN1: reg
		generic map(N=>WORD_SIZE)
		port map(
			D=>ALU_IN1_ID,
			Q=>ALU_IN1_EXE,
			EN=>control_from_HDU.ID_EXE_EN,
			CLK=>clk,
			RST=>rst
		);
		
	REG_ALU_IN2: reg
		generic map(N=>WORD_SIZE)
		port map(
			D=>ALU_IN2_ID_fw,
			Q=>ALU_IN2_EXE_RF,
			EN=>control_from_HDU.ID_EXE_EN,
			CLK=>clk,
			RST=>rst
		);
		
	IMM_ITYPE<=std_logic_vector(to_signed(get_IMM_ITYPE(IR_out), WORD_SIZE));
	IMM_STYPE<=std_logic_vector(to_signed(get_IMM_STYPE(IR_out), WORD_SIZE));
	IMM_BTYPE<=std_logic_vector(to_signed(get_IMM_BTYPE(IR_out), WORD_SIZE));
	IMM_JTYPE<=std_logic_vector(to_signed(get_IMM_JTYPE(IR_out), WORD_SIZE));
	IMM_UTYPE<=std_logic_vector(to_signed(get_IMM_UTYPE(IR_out), WORD_SIZE));

	MUX_IMM: MUX_8to1
		generic map(N=>WORD_SIZE)
		port map(
			IN0=>IMM_ITYPE,
			IN1=>IMM_STYPE,
			IN2=>IMM_BTYPE,
			IN3=>IMM_JTYPE,
			IN4=>IMM_UTYPE,
			IN5=>(others=>'-'),
			IN6=>(others=>'-'),
			IN7=>(others=>'-'),
			SEL=>control_from_CU.ID.MUX_IMM_sel,
			Y=>IMM_ID
		);
				
	REG_IMM: reg
		generic map(N=>WORD_SIZE)
		port map(
			D=>IMM_ID,
			Q=>IMM_EXE,
			EN=>control_from_HDU.ID_EXE_EN,
			CLK=>clk,
			RST=>rst
		);
		
	---------------------------------------EXE stage

	MUX_DRAM_IN_fw: MUX_2to1
		generic map(N=>WORD_SIZE)
		port map(
			IN0=>ALU_IN2_EXE_RF,
			IN1=>RF_IN_MEM,
			SEL=>control_from_FU.MUX_DRAM_IN_sel,
			Y=>DRAM_IN_EXE
		);

	MUX_ALU_IN2: MUX_2to1
		generic map(N=>WORD_SIZE)
		port map(
			IN0=>ALU_IN2_EXE_RF,
			IN1=>IMM_EXE,
			SEL=>control_from_CU.EXE.MUX_ALU_IN2_sel,
			Y=>ALU_IN2_EXE
		);

	ALU_instance: ALU
		generic map(N=>WORD_SIZE)
		port map(
			FUNC=>control_from_CU.EXE.ALU_OP,
			DATA1=>ALU_IN1_EXE,
			DATA2=>ALU_IN2_EXE,
			OUT_ALU=>ALU_OUT_EXE
		);

			
	REG_ALU_OUT_EXE_MEM: reg
		generic map(N=>WORD_SIZE)
		port map(
			D=>ALU_OUT_EXE,
			Q=>ALU_OUT_MEM,
			EN=>control_from_HDU.EXE_MEM_EN,
			CLK=>clk,
			RST=>rst
		);
		
	REG_DRAM_IN: reg
		generic map(N=>WORD_SIZE)
		port map(
			D=>DRAM_IN_EXE,
			Q=>DRAM_IN_MEM,
			EN=>control_from_HDU.EXE_MEM_EN,
			CLK=>clk,
			RST=>rst
		);
				
	REG_RD_EXE_MEM: reg
		generic map(N=>REG_ADDR_SIZE)
		port map(
			D=>RD_EXE,
			Q=>RD_MEM,
			EN=>control_from_HDU.EXE_MEM_EN,
			CLK=>clk,
			RST=>rst
		);
		
	----------------------------------------------------------------MEM stage

	DRAM_ADDR<=ALU_OUT_MEM;
	DRAM_IN<=DRAM_IN_MEM;
	
	DRAM_OUT_sb<=std_logic_vector(resize(signed(DRAM_OUT(byte_range)), WORD_SIZE));
	DRAM_OUT_ub<=std_logic_vector(resize(unsigned(DRAM_OUT(byte_range)), WORD_SIZE));
	DRAM_OUT_sh<=std_logic_vector(resize(signed(DRAM_OUT(halfword_range)), WORD_SIZE));
	DRAM_OUT_uh<=std_logic_vector(resize(unsigned(DRAM_OUT(halfword_range)), WORD_SIZE));
	DRAM_OUT_w<=DRAM_OUT;
	
	MUX_DRAM: MUX_8to1
		generic map(N=>WORD_SIZE)
		port map(
			IN0=>DRAM_OUT_sb,
			IN1=>DRAM_OUT_ub,
			IN2=>DRAM_OUT_sh,
			IN3=>DRAM_OUT_uh,
			IN4=>DRAM_OUT_w,
			IN5=>(others=>'-'),
			IN6=>(others=>'-'),
			IN7=>(others=>'-'),
			SEL=>control_from_CU.MEM.MUX_DRAM_sel,
			Y=>DRAM_OUT_ext
		);
	
	MUX_RF_IN: MUX_2to1
		generic map(N=>WORD_SIZE)
		port map(
			IN0=>ALU_OUT_MEM,
			IN1=>DRAM_OUT_ext,
			SEL=>control_from_CU.MEM.MUX_RF_IN_sel,
			Y=>RF_IN_MEM
		);
	
	REG_RF_IN: reg
		generic map(N=>WORD_SIZE)
		port map(
			D=>RF_IN_MEM,
			Q=>RF_IN_WB,
			EN=>control_from_HDU.MEM_WB_EN,
			CLK=>clk,
			RST=>rst
		);
	
	REG_RD_MEM_WB: reg
		generic map(N=>REG_ADDR_SIZE)
		port map(
			D=>RD_MEM,
			Q=>RD_WB,
			EN=>control_from_HDU.MEM_WB_EN,
			CLK=>clk,
			RST=>rst
		);

	------------------------------------------------------------WB stage
	

end architecture structural;