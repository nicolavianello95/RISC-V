library ieee;
use ieee.std_logic_1164.all;
use work.RISCV_package.all;		
use work.ALU_package.all;		
use work.CU_package.all;		

entity CU is
	port(
		INSTR_ID	: in word;					--instruction register output
		CU_OUTS		: out CU_outs_type			--CU outs to datapath
	);
end entity CU;

architecture behavioral of CU is

	constant LUT_BRANCH: LUT_FUNCT3_type:=(
		FUNCT3_BRANCH_type'pos(FUNCT3_BEQ)	=> BEQ_outs,
		FUNCT3_BRANCH_type'pos(FUNCT3_BNE)	=> BNE_outs,
		FUNCT3_BRANCH_type'pos(FUNCT3_BLT)	=> BLT_outs,
		FUNCT3_BRANCH_type'pos(FUNCT3_BGE)	=> BGE_outs,
		FUNCT3_BRANCH_type'pos(FUNCT3_BLTU)	=> BLTU_outs,
		FUNCT3_BRANCH_type'pos(FUNCT3_BGEU)	=> BGEU_outs,
		others	=> NOP_outs
	);
	
	constant LUT_LOAD: LUT_FUNCT3_type:=(
		FUNCT3_LOAD_type'pos(FUNCT3_LB)		=> LB_outs,
		FUNCT3_LOAD_type'pos(FUNCT3_LH)		=> LH_outs,
		FUNCT3_LOAD_type'pos(FUNCT3_LW)		=> LW_outs,
		FUNCT3_LOAD_type'pos(FUNCT3_LBU)	=> LBU_outs,
		FUNCT3_LOAD_type'pos(FUNCT3_LHU)	=> LHU_outs,
		others	=> NOP_outs
	);

	constant LUT_STORE: LUT_FUNCT3_type:=(
		FUNCT3_STORE_type'pos(FUNCT3_SB)	=> SB_outs,
		FUNCT3_STORE_type'pos(FUNCT3_SH)	=> SH_outs,
		FUNCT3_STORE_type'pos(FUNCT3_SW)	=> SW_outs,
		others	=> NOP_outs
	);

	signal LUT_OPIMM: LUT_FUNCT3_type;	--computed in runtime as one of the two following LUT (they differ only for shift right)

	constant LUT_OPIMM_0: LUT_FUNCT3_type:=(
		FUNCT3_OPIMM_type'pos(FUNCT3_ADDI)	=> ADDI_outs,
		FUNCT3_OPIMM_type'pos(FUNCT3_SLI)	=> SLI_outs,
		FUNCT3_OPIMM_type'pos(FUNCT3_SLTI)	=> SLTI_outs,
		FUNCT3_OPIMM_type'pos(FUNCT3_SLTIU)	=> SLTIU_outs,
		FUNCT3_OPIMM_type'pos(FUNCT3_XORI)	=> XORI_outs,
		FUNCT3_OPIMM_type'pos(FUNCT3_SRI)	=> SRLI_outs,
		FUNCT3_OPIMM_type'pos(FUNCT3_ORI)	=> ORI_outs,
		FUNCT3_OPIMM_type'pos(FUNCT3_ANDI)	=> ANDI_outs,
		others	=> NOP_outs
	);

	constant LUT_OPIMM_1: LUT_FUNCT3_type:=(
		FUNCT3_OPIMM_type'pos(FUNCT3_ADDI)	=> ADDI_outs,
		FUNCT3_OPIMM_type'pos(FUNCT3_SLI)	=> SLI_outs,
		FUNCT3_OPIMM_type'pos(FUNCT3_SLTI)	=> SLTI_outs,
		FUNCT3_OPIMM_type'pos(FUNCT3_SLTIU)	=> SLTIU_outs,
		FUNCT3_OPIMM_type'pos(FUNCT3_XORI)	=> XORI_outs,
		FUNCT3_OPIMM_type'pos(FUNCT3_SRI)	=> SRAI_outs,
		FUNCT3_OPIMM_type'pos(FUNCT3_ORI)	=> ORI_outs,
		FUNCT3_OPIMM_type'pos(FUNCT3_ANDI)	=> ANDI_outs,
		others	=> NOP_outs
	);

	constant LUT_OP_STD0: LUT_FUNCT3_type:=(
		FUNCT3_OP_STD0_type'pos(FUNCT3_ADD)		=> ADD_outs,
		FUNCT3_OP_STD0_type'pos(FUNCT3_SL)		=> SL_outs,
		FUNCT3_OP_STD0_type'pos(FUNCT3_SLT)		=> SLT_outs,
		FUNCT3_OP_STD0_type'pos(FUNCT3_SLTU)	=> SLTU_outs,
		FUNCT3_OP_STD0_type'pos(FUNCT3_XOR)		=> XOR_outs,
		FUNCT3_OP_STD0_type'pos(FUNCT3_SRL)		=> SRL_outs,
		FUNCT3_OP_STD0_type'pos(FUNCT3_OR)		=> OR_outs,
		FUNCT3_OP_STD0_type'pos(FUNCT3_AND)		=> AND_outs,
		others	=> NOP_outs
	);

	constant LUT_OP_STD1: LUT_FUNCT3_type:=(
		FUNCT3_OP_STD1_type'pos(FUNCT3_SUB)		=> SUB_outs,
		FUNCT3_OP_STD1_type'pos(FUNCT3_SRA)		=> SRA_outs,
		others	=> NOP_outs
	);

	constant LUT_OP_RV32M: LUT_FUNCT3_type:=(
		-- FUNCT3_OP_RV32M_type'pos(FUNCT3_MUL)	=> MUL_outs,
		-- FUNCT3_OP_RV32M_type'pos(FUNCT3_MULH)	=> MULH_outs,
		-- FUNCT3_OP_RV32M_type'pos(FUNCT3_MULHSU)	=> MULHSU_outs,
		-- FUNCT3_OP_RV32M_type'pos(FUNCT3_MULHU)	=> MULHU_outs,
		-- FUNCT3_OP_RV32M_type'pos(FUNCT3_DIV)	=> DIV_outs,
		-- FUNCT3_OP_RV32M_type'pos(FUNCT3_DIVU)	=> DIVU_outs,
		-- FUNCT3_OP_RV32M_type'pos(FUNCT3_REM)	=> REM_outs,
		-- FUNCT3_OP_RV32M_type'pos(FUNCT3_REMU)	=> REMU_outs,
		others	=> NOP_outs
	);

	constant LUT_OTHERS: LUT_OPCODE_type :=(
		OPCODE_type'pos(OPCODE_JALR)	=> JALR_outs,
		OPCODE_type'pos(OPCODE_JAL)		=> JAL_outs,
		OPCODE_type'pos(OPCODE_LUI)		=> LUI_outs,
		OPCODE_type'pos(OPCODE_AUIPC)	=> AUIPC_outs,
		OPCODE_type'pos(OPCODE_CUSTOM0)	=> ABS_outs,
		others	=> NOP_outs
	);

	signal OPCODE: OPCODE_type;
	signal FUNCT7: FUNCT7_type;

begin

	OPCODE<=get_OPCODE(INSTR_ID);
	FUNCT7<=get_FUNCT7(INSTR_ID);

	LUT_OPIMM<= LUT_OPIMM_0	when FUNCT7(5)='0' else
				LUT_OPIMM_1	when FUNCT7(5)='1' else
				(others=>NOP_outs);
										

	CU_OUTS <=	LUT_BRANCH(to_integer(get_FUNCT3_BRANCH(INSTR_ID)))		when OPCODE=OPCODE_BRANCH						else
				LUT_LOAD(to_integer(get_FUNCT3_LOAD(INSTR_ID)))			when OPCODE=OPCODE_LOAD							else
				LUT_STORE(to_integer(get_FUNCT3_STORE(INSTR_ID)))		when OPCODE=OPCODE_STORE						else
				LUT_OPIMM(to_integer(get_FUNCT3_OPIMM(INSTR_ID)))		when OPCODE=OPCODE_OPIMM						else
				LUT_OP_STD0(to_integer(get_FUNCT3_OP_STD0(INSTR_ID)))	when OPCODE=OPCODE_OP and FUNCT7=FUNCT7_STD0	else
				LUT_OP_STD1(to_integer(get_FUNCT3_OP_STD1(INSTR_ID)))	when OPCODE=OPCODE_OP and FUNCT7=FUNCT7_STD1	else
				LUT_OP_RV32M(to_integer(get_FUNCT3_OP_RV32M(INSTR_ID)))	when OPCODE=OPCODE_OP and FUNCT7=FUNCT7_RV32M	else
				LUT_OTHERS(to_integer(OPCODE)/4);

end architecture behavioral;