library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.RISCV_package.all;		
use work.FU_package.all;	

entity FU is
	port(
		INSTR_ID	: in word;
		INSTR_EXE	: in word;
		INSTR_MEM	: in word;
		INSTR_WB	: in word;
		FU_OUTS		: out FU_OUTS_type
	);
end entity FU;

architecture behavioral of FU is

begin

	FU_process: process(INSTR_ID, INSTR_EXE, INSTR_MEM, INSTR_WB) is
	
		variable RS1_ID, RS2_ID, RS2_EXE, RD_EXE, RD_MEM, RD_WB : integer range 0 to N_REG;
	
	begin
	
		--compute usefull constants
		RS1_ID	:=	get_RS1(INSTR_ID);
		RS2_ID	:=	get_RS2(INSTR_ID);
		RS2_EXE	:=	get_RS2(INSTR_EXE);
		RD_EXE	:=	get_RD(INSTR_EXE);
		RD_MEM	:=	get_RD(INSTR_MEM);
		RD_WB	:=	get_RD(INSTR_WB);
	
		--default assignment
		FU_OUTS.MUX_ALU_IN1_sel<=ALU_forward_NO;
		FU_OUTS.MUX_ALU_IN2_sel<=ALU_forward_NO;
		FU_OUTS.MUX_DRAM_IN_sel<=DRAM_forward_NO;

		--ALU_IN1 forwarding
		if RS1_ID/=0 and RS1_ID=RD_EXE and not is_a_branch(INSTR_EXE) and not is_a_store(INSTR_EXE) then	--if INSTR_EXE is a load, the HDU intervenes
			FU_OUTS.MUX_ALU_IN1_sel<=ALU_forward_EXE;
		elsif RS1_ID/=0 and RS1_ID=RD_MEM and not is_a_branch(INSTR_MEM) and not is_a_store(INSTR_MEM) then
			FU_OUTS.MUX_ALU_IN1_sel<=ALU_forward_MEM;
		elsif RS1_ID/=0 and RS1_ID=RD_WB and not is_a_branch(INSTR_WB) and not is_a_store(INSTR_WB) then
			FU_OUTS.MUX_ALU_IN1_sel<=ALU_forward_WB;
		end if;

		--ALU_IN2 forwarding
		if RS2_ID/=0 and RS2_ID=RD_EXE and not is_a_branch(INSTR_EXE) and not is_a_store(INSTR_EXE) then	--if INSTR_EXE is a load, the HDU intervenes
			FU_OUTS.MUX_ALU_IN2_sel<=ALU_forward_EXE;
		elsif RS2_ID/=0 and RS2_ID=RD_MEM and not is_a_branch(INSTR_MEM) and not is_a_store(INSTR_MEM) then
			FU_OUTS.MUX_ALU_IN2_sel<=ALU_forward_MEM;
		elsif RS2_ID/=0 and RS2_ID=RD_WB and not is_a_branch(INSTR_WB) and not is_a_store(INSTR_WB) then
			FU_OUTS.MUX_ALU_IN2_sel<=ALU_forward_WB;
		end if;
		
		--DRAM IN forwarding
		if RS2_EXE/=0 and RS2_EXE=RD_MEM then
			FU_OUTS.MUX_DRAM_IN_sel<=DRAM_forward_WB;
		end if;
		
	end process FU_process;
	
end architecture behavioral;