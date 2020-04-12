library ieee;
use ieee.std_logic_1164.all;
use work.RISCV_package.all;		
use work.CU_package.all;		
use work.my_package.all;		
use work.FU_package.all;
use work.HDU_package.all;

entity RISCV is
	generic(
		BPU_TAG_FIELD_SIZE	: integer :=8;
		BPU_SET_FIELD_SIZE	: integer :=3;
		BPU_LINES_PER_SET	: integer :=4
	);
	port(
		IRAM_ADDR	: out	word;
		IRAM_OUT	: in	word;
		DRAM_ADDR	: out	word;
		DRAM_IN		: out	word;
		DRAM_OUT	: in	word;
		DRAM_WR_EN  : out	std_logic_vector(1 downto 0);
		CLK			: in	std_logic;
		RST			: in	std_logic
	);
end entity RISCV;

architecture structural of RISCV is

	component reg is
		Generic (N : positive:= 1 );								--number of bits
		Port(	D		: In	std_logic_vector(N-1 downto 0);		--data input
				Q		: Out	std_logic_vector(N-1 downto 0);		--data output
				EN		: In 	std_logic;							--enable active high
				CLK		: In	std_logic;							--clock
				RST		: In	std_logic);							--asynchronous reset active low
	end component reg;

	component CU is
		port(
			INSTR_ID	: in word;					--instruction register input
			CU_OUTS		: out CU_OUTS_type			--CU outs to datapath
		);
	end component CU;

	component HDU is
		port(
			INSTR_ID		: in word;
			INSTR_EXE		: in word;
			misprediction	: in std_logic;
			HDU_OUTS		: out HDU_OUTS_type;
			clk				: in std_logic;
			rst				: in std_logic
		);
	end component HDU;
	
	component FU is
		port(
			INSTR_ID	: in word;
			INSTR_EXE	: in word;
			INSTR_MEM	: in word;
			INSTR_WB	: in word;
			FU_OUTS		: out FU_OUTS_type
		);
	end component FU;

	component datapath is
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
	end component datapath;

	--signals to pipelined the CU outputs
	signal CU_OUTS, CU_OUTS_pipelined							: CU_OUTS_type;
	signal CU_OUTS_EXE_atEXE									: CU_OUTS_EXE_type;
	signal CU_OUTS_MEM_atEXE, CU_OUTS_MEM_atMEM					: CU_OUTS_MEM_type;
	signal CU_OUTS_WB_atEXE, CU_OUTS_WB_atMEM, CU_OUTS_WB_atWB	: CU_OUTS_WB_type;
	
	--signals to connect components
	signal HDU_OUTS	: HDU_OUTS_type;
	signal FU_OUTS	: FU_OUTS_type;
	signal misprediction	: std_logic;
	
	--signals to record the instruction for each stage
	signal INSTR_ID, INSTR_EXE, INSTR_MEM, INSTR_WB	: word;

begin
		
	instr_prop: process(CLK, RST) is
	begin
		if RST='0' then
			INSTR_ID<=(others=>'0');
			INSTR_EXE<=(others=>'0');
			INSTR_MEM<=(others=>'0');
			INSTR_WB<=(others=>'0');
		elsif rising_edge(CLK) then
			if HDU_OUTS.ID_bubble='1' then
				INSTR_ID<=INSTR_NOP;
			elsif HDU_OUTS.IF_ID_EN='1' then
				INSTR_ID<=IRAM_OUT;
			end if;
			if HDU_OUTS.EXE_bubble='1' then
				INSTR_EXE<=INSTR_NOP;
			elsif HDU_OUTS.ID_EXE_EN='1' then
				INSTR_EXE<=INSTR_ID;
			end if;
			if HDU_OUTS.MEM_bubble='1' then
				INSTR_MEM<=INSTR_NOP;
			elsif HDU_OUTS.EXE_MEM_EN='1' then
				INSTR_MEM<=INSTR_EXE;
			end if;
			if HDU_OUTS.WB_bubble='1' then
				INSTR_WB<=INSTR_NOP;
			elsif HDU_OUTS.MEM_WB_EN='1' then
				INSTR_WB<=INSTR_MEM;
			end if;
		end if;
	end process instr_prop;
	
	HDU_instance: HDU
		port map(
			HDU_OUTS=>HDU_OUTS,
			INSTR_ID=>INSTR_ID,
			INSTR_EXE=>INSTR_EXE,
			misprediction=>misprediction,
			clk=>clk,
			rst=>rst
		);

	FU_instance: FU
		port map(
			INSTR_ID=>INSTR_ID,
			INSTR_EXE=>INSTR_EXE,
			INSTR_MEM=>INSTR_MEM,
			INSTR_WB=>INSTR_WB,
			FU_OUTS=>FU_OUTS
		);

	CU_instance: CU
		port map(
			INSTR_ID=>INSTR_ID,
			CU_OUTS=>CU_OUTS
		);
		
	REGS_CU: process(CLK, RST)
	begin
		if RST='0' then
			CU_OUTS_EXE_atEXE<=NOP_outs.EXE;
			CU_OUTS_MEM_atEXE<=NOP_outs.MEM;
			CU_OUTS_WB_atEXE<=NOP_outs.WB;
			CU_OUTS_MEM_atMEM<=NOP_outs.MEM;
			CU_OUTS_WB_atMEM<=NOP_outs.WB;
			CU_OUTS_WB_atWB<=NOP_outs.WB;
		elsif rising_edge(CLK) then
			if HDU_OUTS.EXE_bubble='1' then
				CU_OUTS_EXE_atEXE<=NOP_outs.EXE;
				CU_OUTS_MEM_atEXE<=NOP_outs.MEM;
				CU_OUTS_WB_atEXE<=NOP_outs.WB;
			elsif HDU_OUTS.ID_EXE_EN='1' then
				CU_OUTS_EXE_atEXE<=CU_OUTS.EXE;
				CU_OUTS_MEM_atEXE<=CU_OUTS.MEM;
				CU_OUTS_WB_atEXE<=CU_OUTS.WB;
			end if;
			if HDU_OUTS.MEM_bubble='1' then
				CU_OUTS_MEM_atMEM<=NOP_outs.MEM;
				CU_OUTS_WB_atMEM<=NOP_outs.WB;
			elsif HDU_OUTS.EXE_MEM_EN='1' then
				CU_OUTS_MEM_atMEM<=CU_OUTS_MEM_atEXE;
				CU_OUTS_WB_atMEM<=CU_OUTS_WB_atEXE;
			end if;
			if HDU_OUTS.WB_bubble='1' then
				CU_OUTS_WB_atWB<=NOP_outs.WB;
			elsif HDU_OUTS.MEM_WB_EN='1' then
				CU_OUTS_WB_atWB<=CU_OUTS_WB_atMEM;
			end if;
		end if;
	end process REGS_CU;
		
	CU_OUTS_pipelined<=(
		ID=>CU_OUTS.ID,
		EXE=>CU_OUTS_EXE_atEXE,
		MEM=>CU_OUTS_MEM_atMEM,
		WB=>CU_OUTS_WB_atWB	
	);
		
	datapath_instance: datapath
		generic map(
			BPU_TAG_FIELD_SIZE=>BPU_TAG_FIELD_SIZE,
			BPU_SET_FIELD_SIZE=>BPU_SET_FIELD_SIZE,
			BPU_LINES_PER_SET=>BPU_LINES_PER_SET
		)
		port map(
			IRAM_ADDR=>IRAM_ADDR,
			IRAM_OUT=>IRAM_OUT,
			DRAM_ADDR=>DRAM_ADDR,
			DRAM_IN=>DRAM_IN,
			DRAM_OUT=>DRAM_OUT,
			control_from_CU=>CU_OUTS_pipelined,
			control_from_FU=>FU_OUTS,
			control_from_HDU=>HDU_OUTS,
			misprediction=>misprediction,
			CLK=>CLK,
			RST=>RST
		);

	DRAM_WR_EN<=CU_OUTS_pipelined.MEM.DRAM_WR_EN;

end architecture structural;