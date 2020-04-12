library ieee;
use ieee.std_logic_1164.all;
use work.RISCV_package.all;		
use work.HDU_package.all;

entity HDU is	--hazard detection unit
	port(
		INSTR_ID		: in word;
		INSTR_EXE		: in word;
		misprediction	: in std_logic;
		HDU_OUTS		: out HDU_OUTS_type;
		clk				: in std_logic;
		rst				: in std_logic
	);
end entity HDU;

architecture behavioral of HDU is

	signal count: integer range 0 to 3;

begin

	HDU_proc: process(INSTR_ID, INSTR_EXE, misprediction, count) is
	
		variable RS1_ID, RS2_ID, RD_EXE : integer range 0 to N_REG;
	
	begin
		
		--compute useful constants
		RS1_ID	:=	get_RS1(INSTR_ID);
		RS2_ID	:=	get_RS2(INSTR_ID);
		RD_EXE	:=	get_Rd(INSTR_EXE);
		
		--default assignment
		HDU_OUTS.PC_EN		<='1';
		HDU_OUTS.IF_ID_EN	<='1';
		HDU_OUTS.ID_EXE_EN	<='1';
		HDU_OUTS.EXE_MEM_EN	<='1';
		HDU_OUTS.MEM_WB_EN	<='1';
		HDU_OUTS.ID_bubble	<='0';
		HDU_OUTS.EXE_bubble	<='0';
		HDU_OUTS.MEM_bubble	<='0';
		HDU_OUTS.WB_bubble	<='0';
		
		--multicycle operations structural hazard
		if is_a_mult(INSTR_EXE) and count/=3 then
			HDU_OUTS.PC_EN<='0';
			HDU_OUTS.IF_ID_EN<='0';
			HDU_OUTS.ID_EXE_EN<='0';
			HDU_OUTS.EXE_MEM_EN<='0';
			HDU_OUTS.MEM_bubble<='1';
		--load from DRAM data hazard
		elsif (RS1_ID/=0 and RS1_ID=RD_EXE and is_a_load(INSTR_EXE) and not is_a_jump(INSTR_ID) and not is_a_upperimm(INSTR_ID)) or	--every instruction following a load that requires its data in RS1 can trigger a hazard
		(RS2_ID/=0 and RS1_ID=RD_EXE and is_a_load(INSTR_EXE) and (is_a_op(INSTR_ID) or is_a_branch(INSTR_ID))) then				--in the case the data is required in RS2, if the instruction is a store, it can forward the data in the next clock cycle
			HDU_OUTS.PC_EN<='0';
			HDU_OUTS.IF_ID_EN<='0';
			HDU_OUTS.ID_EXE_EN<='0';
			HDU_OUTS.EXE_bubble<='1';
		--branch misprediction control hazard
		elsif misprediction='1' then
			HDU_OUTS.IF_ID_EN<='0';
			HDU_OUTS.ID_bubble<='1';
		end if;
		
	end process HDU_proc;
	
	count_proc: process(clk, rst)
	begin
		if rst='0' then
			count<=0;
		elsif rising_edge(clk) then
			if is_a_mult(INSTR_EXE) then
				if count=3 then
					count<=0;
				else
					count<=count+1;
				end if;
			end if;
		end if;
	end process count_proc;
	
end architecture behavioral;