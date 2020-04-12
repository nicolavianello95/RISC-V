library ieee;
use ieee.std_logic_1164.all;
use work.ALU_package.all;		
use work.RISCV_package.all;		

package CU_package is
	
	type BRANCH_COND_type is (
		BRANCH_COND_NO,		--don't jump
		BRANCH_COND_ALWAYS,	--jump always
		BRANCH_COND_EQ,		--branch if equal
		BRANCH_COND_NE,		--branch if not equal
		BRANCH_COND_LT,		--branch if less than
		BRANCH_COND_GE,		--branch if greater than or equal to
		BRANCH_COND_LTU,	--branch if less than (unsigned)
		BRANCH_COND_GEU		--branch if greater than or equal to (unsigned)
	);
	
	type CU_OUTS_ID_type is record
		-- ID outputs		
		MUX_NPC_base_sel	: std_logic;					--select whether the jump/branch target is computed starting from a register or from the PC
		MUX_ALU_IN1_sel		: std_logic_vector(1 downto 0);	--select wether the first operand is taken from the register file or if it is the PC+4
		MUX_IMM_sel			: std_logic_vector(2 downto 0);	--type of immediate extension
		BRANCH_COND			: BRANCH_COND_type;				--branch condition
	end record CU_OUTS_ID_type;

	type CU_OUTS_EXE_type is record
		-- EXE outputs		
		MUX_ALU_IN2_sel		: std_logic;		--select whether the second operand is B or IMM
		ALU_OP				: ALU_OP_type;		--ALU operation selector
	end record CU_OUTS_EXE_type;

	type CU_OUTS_MEM_type is record
		-- MEM outputs					
		DRAM_WR_EN			: std_logic_vector(1 downto 0);	--data RAM write enable
		MUX_DRAM_sel		: std_logic_vector(2 downto 0);	--select size and type of extension of data out from DRAM
		MUX_RF_IN_sel		: std_logic;					--select wether the data to write in the RF is taken from the DRAM or from the ALU
	end record CU_OUTS_MEM_type;

	type CU_OUTS_WB_type is record
		-- WB outputs					
		RF_WR_EN			: std_logic;	--register file write enable 
	end record CU_OUTS_WB_type;

	type CU_OUTS_type is record	
		ID	: CU_OUTS_ID_type;
		EXE	: CU_OUTS_EXE_type;			
		MEM	: CU_OUTS_MEM_type;
		WB	: CU_OUTS_WB_type;
	end record CU_OUTS_type;

	type LUT_FUNCT3_type is array (0 to N_FUNCT3-1) of CU_OUTS_type;
	type LUT_OPCODE_type is array (0 to N_OPCODE-1) of CU_OUTS_type;	
	
	--ID outputs constants
	constant NPC_BASE_REG		: std_logic:= '1';
	constant NPC_BASE_PC		: std_logic:= '0';
	constant ALU_IN1_PC			: std_logic_vector:= "00";
	constant ALU_IN1_PC_plus4	: std_logic_vector:= "01";
	constant ALU_IN1_RF			: std_logic_vector:= "10";
	constant IMM_ITYPE			: std_logic_vector:= "000";
	constant IMM_STYPE			: std_logic_vector:= "001";
	constant IMM_BTYPE			: std_logic_vector:= "010";
	constant IMM_JTYPE			: std_logic_vector:= "011";
	constant IMM_UTYPE			: std_logic_vector:= "100";
	--EXE outputs constants
	constant OUT_ALU		: std_logic:= '0';
	constant OUT_MULT		: std_logic:= '1';
	constant ALU_IN2_RF		: std_logic:= '0';
	constant ALU_IN2_IMM	: std_logic:= '1';
	--MEM outputs
	constant DRAM_WR_OFF	: std_logic_vector:="00";
	constant DRAM_WR_B		: std_logic_vector:="01";
	constant DRAM_WR_H		: std_logic_vector:="10";
	constant DRAM_WR_W		: std_logic_vector:="11";
	constant MUX_DRAM_SB	: std_logic_vector:= "000";
	constant MUX_DRAM_UB	: std_logic_vector:= "001";
	constant MUX_DRAM_SH	: std_logic_vector:= "010";
	constant MUX_DRAM_UH	: std_logic_vector:= "011";
	constant MUX_DRAM_W		: std_logic_vector:= "100";
	constant RF_IN_ALU		: std_logic:= '0';
	constant RF_IN_DRAM		: std_logic:= '1';
	--WB outputs	
	constant RF_WR_OFF		: std_logic:= '0';
	constant RF_WR_ON		: std_logic:= '1';
	
	--										ID																		EXE								MEM												WB
	--										MUX_NPC_base_sel	MUX_ALU_IN1_sel		MUX_IMM_sel	BRANCH_COND			MUX_ALU_IN2_sel	ALU_OP			DRAM_WR_EN		MUX_DRAM_sel	MUX_RF_IN_sel	RF_WR_EN
	constant NOP_outs	:CU_OUTS_type:=(	('-',				"--",				"---",		BRANCH_COND_NO),	('-',			ALU_DONT_CARE),	(DRAM_WR_OFF,	"---",			'-'),			(others=>RF_WR_OFF	));
	--OPIMM instructions outs	
	constant ADDI_outs	:CU_OUTS_type:=(	('-',				ALU_IN1_RF,			IMM_ITYPE,	BRANCH_COND_NO),	(ALU_IN2_IMM,	ALU_ADD),		(DRAM_WR_OFF,	"---",			RF_IN_ALU),		(others=>RF_WR_ON	));
	constant SLI_outs	:CU_OUTS_type:=(	('-',				ALU_IN1_RF,			IMM_ITYPE,	BRANCH_COND_NO),	(ALU_IN2_IMM,	ALU_SL),		(DRAM_WR_OFF,	"---",			RF_IN_ALU),		(others=>RF_WR_ON	));
	constant SLTI_outs	:CU_OUTS_type:=(	('-',				ALU_IN1_RF,			IMM_ITYPE,	BRANCH_COND_NO),	(ALU_IN2_IMM,	ALU_SLT),		(DRAM_WR_OFF,	"---",			RF_IN_ALU),		(others=>RF_WR_ON	));
	constant SLTIU_outs	:CU_OUTS_type:=(	('-',				ALU_IN1_RF,			IMM_ITYPE,	BRANCH_COND_NO),	(ALU_IN2_IMM,	ALU_SLTU),		(DRAM_WR_OFF,	"---",			RF_IN_ALU),		(others=>RF_WR_ON	));
	constant XORI_outs	:CU_OUTS_type:=(	('-',				ALU_IN1_RF,			IMM_ITYPE,	BRANCH_COND_NO),	(ALU_IN2_IMM,	ALU_XOR),		(DRAM_WR_OFF,	"---",			RF_IN_ALU),		(others=>RF_WR_ON	));
	constant SRLI_outs	:CU_OUTS_type:=(	('-',				ALU_IN1_RF,			IMM_ITYPE,	BRANCH_COND_NO),	(ALU_IN2_IMM,	ALU_SRL),		(DRAM_WR_OFF,	"---",			RF_IN_ALU),		(others=>RF_WR_ON	));
	constant SRAI_outs	:CU_OUTS_type:=(	('-',				ALU_IN1_RF,			IMM_ITYPE,	BRANCH_COND_NO),	(ALU_IN2_IMM,	ALU_SRA),		(DRAM_WR_OFF,	"---",			RF_IN_ALU),		(others=>RF_WR_ON	));
	constant ORI_outs	:CU_OUTS_type:=(	('-',				ALU_IN1_RF,			IMM_ITYPE,	BRANCH_COND_NO),	(ALU_IN2_IMM,	ALU_OR),		(DRAM_WR_OFF,	"---",			RF_IN_ALU),		(others=>RF_WR_ON	));
	constant ANDI_outs	:CU_OUTS_type:=(	('-',				ALU_IN1_RF,			IMM_ITYPE,	BRANCH_COND_NO),	(ALU_IN2_IMM,	ALU_AND),		(DRAM_WR_OFF,	"---",			RF_IN_ALU),		(others=>RF_WR_ON	));
	--OP instructions outs	
	constant ADD_outs	:CU_OUTS_type:=(	('-',				ALU_IN1_RF,			"---",		BRANCH_COND_NO),	(ALU_IN2_RF,	ALU_ADD),		(DRAM_WR_OFF,	"---",			RF_IN_ALU),		(others=>RF_WR_ON	));
	constant SL_outs	:CU_OUTS_type:=(	('-',				ALU_IN1_RF,			"---",		BRANCH_COND_NO),	(ALU_IN2_RF,	ALU_SL),		(DRAM_WR_OFF,	"---",			RF_IN_ALU),		(others=>RF_WR_ON	));
	constant SLT_outs	:CU_OUTS_type:=(	('-',				ALU_IN1_RF,			"---",		BRANCH_COND_NO),	(ALU_IN2_RF,	ALU_SLT),		(DRAM_WR_OFF,	"---",			RF_IN_ALU),		(others=>RF_WR_ON	));
	constant SLTU_outs	:CU_OUTS_type:=(	('-',				ALU_IN1_RF,			"---",		BRANCH_COND_NO),	(ALU_IN2_RF,	ALU_SLTU),		(DRAM_WR_OFF,	"---",			RF_IN_ALU),		(others=>RF_WR_ON	));
	constant XOR_outs	:CU_OUTS_type:=(	('-',				ALU_IN1_RF,			"---",		BRANCH_COND_NO),	(ALU_IN2_RF,	ALU_XOR),		(DRAM_WR_OFF,	"---",			RF_IN_ALU),		(others=>RF_WR_ON	));
	constant SRL_outs	:CU_OUTS_type:=(	('-',				ALU_IN1_RF,			"---",		BRANCH_COND_NO),	(ALU_IN2_RF,	ALU_SRL),		(DRAM_WR_OFF,	"---",			RF_IN_ALU),		(others=>RF_WR_ON	));
	constant OR_outs	:CU_OUTS_type:=(	('-',				ALU_IN1_RF,			"---",		BRANCH_COND_NO),	(ALU_IN2_RF,	ALU_OR),		(DRAM_WR_OFF,	"---",			RF_IN_ALU),		(others=>RF_WR_ON	));
	constant AND_outs	:CU_OUTS_type:=(	('-',				ALU_IN1_RF,			"---",		BRANCH_COND_NO),	(ALU_IN2_RF,	ALU_AND),		(DRAM_WR_OFF,	"---",			RF_IN_ALU),		(others=>RF_WR_ON	));
	constant SUB_outs	:CU_OUTS_type:=(	('-',				ALU_IN1_RF,			"---",		BRANCH_COND_NO),	(ALU_IN2_RF,	ALU_SUB),		(DRAM_WR_OFF,	"---",			RF_IN_ALU),		(others=>RF_WR_ON	));
	constant SRA_outs	:CU_OUTS_type:=(	('-',				ALU_IN1_RF,			"---",		BRANCH_COND_NO),	(ALU_IN2_RF,	ALU_SRA),		(DRAM_WR_OFF,	"---",			RF_IN_ALU),		(others=>RF_WR_ON	));
	--STORE instructions outs	
	constant SB_outs	:CU_OUTS_type:=(	('-',				ALU_IN1_RF,			IMM_STYPE,	BRANCH_COND_NO),	(ALU_IN2_IMM,	ALU_ADD),		(DRAM_WR_B,		"---",			'-'),			(others=>RF_WR_OFF	));
	constant SH_outs	:CU_OUTS_type:=(	('-',				ALU_IN1_RF,			IMM_STYPE,	BRANCH_COND_NO),	(ALU_IN2_IMM,	ALU_ADD),		(DRAM_WR_H,		"---",			'-'),			(others=>RF_WR_OFF	));
	constant SW_outs	:CU_OUTS_type:=(	('-',				ALU_IN1_RF,			IMM_STYPE,	BRANCH_COND_NO),	(ALU_IN2_IMM,	ALU_ADD),		(DRAM_WR_W,		"---",			'-'),			(others=>RF_WR_OFF	));
	--LOAD instructions outs	
	constant LB_outs	:CU_OUTS_type:=(	('-',				ALU_IN1_RF,			IMM_ITYPE,	BRANCH_COND_NO),	(ALU_IN2_IMM,	ALU_ADD),		(DRAM_WR_OFF,	MUX_DRAM_SB,	RF_IN_DRAM),	(others=>RF_WR_ON	));
	constant LH_outs	:CU_OUTS_type:=(	('-',				ALU_IN1_RF,			IMM_ITYPE,	BRANCH_COND_NO),	(ALU_IN2_IMM,	ALU_ADD),		(DRAM_WR_OFF,	MUX_DRAM_SH,	RF_IN_DRAM),	(others=>RF_WR_ON	));
	constant LW_outs	:CU_OUTS_type:=(	('-',				ALU_IN1_RF,			IMM_ITYPE,	BRANCH_COND_NO),	(ALU_IN2_IMM,	ALU_ADD),		(DRAM_WR_OFF,	MUX_DRAM_W,		RF_IN_DRAM),	(others=>RF_WR_ON	));
	constant LBU_outs	:CU_OUTS_type:=(	('-',				ALU_IN1_RF,			IMM_ITYPE,	BRANCH_COND_NO),	(ALU_IN2_IMM,	ALU_ADD),		(DRAM_WR_OFF,	MUX_DRAM_UB,	RF_IN_DRAM),	(others=>RF_WR_ON	));
	constant LHU_outs	:CU_OUTS_type:=(	('-',				ALU_IN1_RF,			IMM_ITYPE,	BRANCH_COND_NO),	(ALU_IN2_IMM,	ALU_ADD),		(DRAM_WR_OFF,	MUX_DRAM_UH,	RF_IN_DRAM),	(others=>RF_WR_ON	));
	--BRANCH instructions outs	
	constant BEQ_outs	:CU_OUTS_type:=(	(NPC_BASE_PC,		ALU_IN1_RF,			IMM_BTYPE,	BRANCH_COND_EQ),	('-',			ALU_DONT_CARE),	(DRAM_WR_OFF,	"---",			'-'),			(others=>RF_WR_OFF	));
	constant BNE_outs	:CU_OUTS_type:=(	(NPC_BASE_PC,		ALU_IN1_RF,			IMM_BTYPE,	BRANCH_COND_NE),	('-',			ALU_DONT_CARE),	(DRAM_WR_OFF,	"---",			'-'),			(others=>RF_WR_OFF	));
	constant BLT_outs	:CU_OUTS_type:=(	(NPC_BASE_PC,		ALU_IN1_RF,			IMM_BTYPE,	BRANCH_COND_LT),	('-',			ALU_DONT_CARE),	(DRAM_WR_OFF,	"---",			'-'),			(others=>RF_WR_OFF	));
	constant BGE_outs	:CU_OUTS_type:=(	(NPC_BASE_PC,		ALU_IN1_RF,			IMM_BTYPE,	BRANCH_COND_GE),	('-',			ALU_DONT_CARE),	(DRAM_WR_OFF,	"---",			'-'),			(others=>RF_WR_OFF	));
	constant BLTU_outs	:CU_OUTS_type:=(	(NPC_BASE_PC,		ALU_IN1_RF,			IMM_BTYPE,	BRANCH_COND_LTU),	('-',			ALU_DONT_CARE),	(DRAM_WR_OFF,	"---",			'-'),			(others=>RF_WR_OFF	));
	constant BGEU_outs	:CU_OUTS_type:=(	(NPC_BASE_PC,		ALU_IN1_RF,			IMM_BTYPE,	BRANCH_COND_GEU),	('-',			ALU_DONT_CARE),	(DRAM_WR_OFF,	"---",			'-'),			(others=>RF_WR_OFF	));
	--J-TYPE instructions outs	
	constant JAL_outs	:CU_OUTS_type:=(	(NPC_BASE_PC,		ALU_IN1_PC_plus4,	IMM_JTYPE,	BRANCH_COND_ALWAYS),('-',			ALU_IN1),		(DRAM_WR_OFF,	"---",			RF_IN_ALU),		(others=>RF_WR_ON	));
	constant JALR_outs	:CU_OUTS_type:=(	(NPC_BASE_REG,		ALU_IN1_PC_plus4,	IMM_ITYPE,	BRANCH_COND_ALWAYS),('-',			ALU_IN1),		(DRAM_WR_OFF,	"---",			RF_IN_ALU),		(others=>RF_WR_ON	));
	--U-TYPE instruction outs
	constant LUI_outs	:CU_OUTS_type:=(	('-',				"--",				IMM_UTYPE,	BRANCH_COND_NO),	(ALU_IN2_IMM,	ALU_IN2),		(DRAM_WR_OFF,	"---",			RF_IN_ALU),		(others=>RF_WR_ON	));
	constant AUIPC_outs	:CU_OUTS_type:=(	('-',				ALU_IN1_PC,			IMM_UTYPE,	BRANCH_COND_NO),	(ALU_IN2_IMM,	ALU_ADD),		(DRAM_WR_OFF,	"---",			RF_IN_ALU),		(others=>RF_WR_ON	));
	--custom instructions
	constant ABS_outs	:CU_OUTS_type:=(	('-',				ALU_IN1_RF,			"---",		BRANCH_COND_NO),	('-',			ALU_ABS),		(DRAM_WR_OFF,	"---",			RF_IN_ALU),		(others=>RF_WR_ON	));

end package CU_package;
