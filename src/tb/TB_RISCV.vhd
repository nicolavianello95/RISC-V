library ieee;
use ieee.std_logic_1164.all;
use work.RISCV_package.all;	

entity TB_RISCV is
end entity TB_RISCV;

architecture test of TB_RISCV is

	component RISCV is
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
	end component RISCV;

	component IRAM is
		port(
			DATA_OUT	: out word;
			ADDR		: in halfword;
			CS			: in std_logic	--chip select
			);
	end component IRAM;
	
	component DRAM is
		port(
			DATA_IN		: in word;
			DATA_OUT	: out word;
			ADDR		: in halfword;
			WR_EN		: in std_logic_vector(1 downto 0);
			CS			: in std_logic;			--chip select
			CLK			: in std_logic
		);
	end component DRAM;

	component clk_gen is
		port(
			clk     : out std_logic;
			rst		: out std_logic
		);
	end component clk_gen;

	signal IRAM_ADDR, IRAM_OUT, DRAM_ADDR, DRAM_IN, DRAM_OUT: word;
	signal DRAM_WR_EN: std_logic_vector(1 downto 0);
	signal IRAM_CS, DRAM_CS: std_logic;
	signal CLK, RST: std_logic;
	
	constant clk_period : time := 10 ns;
	constant BPU_TAG_FIELD_SIZE : integer:=8;
	constant BPU_SET_FIELD_SIZE : integer:=3;
	constant BPU_LINES_PER_SET : integer:=4;
	
begin

	DUT: RISCV
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
			DRAM_WR_EN=>DRAM_WR_EN,
			CLK=>CLK,
			RST=>RST
		);

	IRAM_instance: IRAM
		port map(
			DATA_OUT=>IRAM_OUT,
			ADDR=>IRAM_ADDR(HALFWORD_range),
			CS=>IRAM_CS
		);
	
	IRAM_CS <= '1' when IRAM_ADDR(halfword1_range)=X"0040" else '0';
	
	DRAM_instance: DRAM
		port map(
			DATA_IN=>DRAM_IN,
			DATA_OUT=>DRAM_OUT,
			ADDR=>DRAM_ADDR(HALFWORD_range),
			WR_EN=>DRAM_WR_EN,
			CS=>DRAM_CS,
			CLK=>CLK
		);
		
	DRAM_CS <= '1' when DRAM_ADDR(HALFWORD1_range)=X"1001" else '0';

	clk_gen_instance: clk_gen
		port map(
			clk=>CLK,
			rst=>RST
		);

end architecture test;