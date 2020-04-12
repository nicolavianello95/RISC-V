library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package RISCV_package is

	constant BYTE_SIZE : integer := 8;
	constant HALFWORD_SIZE : integer := 2*BYTE_SIZE;
	constant WORD_SIZE : integer := 4*BYTE_SIZE;
	constant DOUBLEWORD_SIZE : integer := 8*BYTE_SIZE;
	subtype BYTE_range is integer range BYTE_SIZE-1 downto 0;
	subtype BYTE1_range is integer range 2*BYTE_SIZE-1 downto BYTE_SIZE;
	subtype BYTE2_range is integer range 3*BYTE_SIZE-1 downto 2*BYTE_SIZE;
	subtype BYTE3_range is integer range 4*BYTE_SIZE-1 downto 3*BYTE_SIZE;
	subtype HALFWORD_range is integer range HALFWORD_SIZE-1 downto 0;
	subtype HALFWORD1_range is integer range 2*HALFWORD_SIZE-1 downto HALFWORD_SIZE;
	subtype WORD_range is integer range WORD_SIZE-1 downto 0;
	subtype DOUBLEWORD_range is integer range DOUBLEWORD_SIZE-1 downto 0;
	subtype byte is std_logic_vector(BYTE_range);
	subtype halfword is std_logic_vector(HALFWORD_range);
	subtype word is std_logic_vector(WORD_range);
	subtype doubleword is std_logic_vector(DOUBLEWORD_range);

	constant IF_STAGE	: integer := 0;
	constant ID_STAGE	: integer := 1;
	constant EXE_STAGE	: integer := 2;
	constant MEM_STAGE	: integer := 3;
	constant WB_STAGE	: integer := 4;
	constant N_STAGE 	: integer := 5;

	subtype OPCODE_range	is integer range 6 downto 0;
	subtype RD_range		is integer range 11 downto 7;
	subtype FUNCT3_range	is integer range 14 downto 12;
	subtype RS1_range		is integer range 19 downto 15;
	subtype RS2_range		is integer range 24 downto 20;
	subtype FUNCT7_range	is integer range 31 downto 25;
	subtype IMM_LONG_range	is integer range 31 downto 12;
	
    constant OPCODE_SIZE	: integer := OPCODE_range'high-OPCODE_range'low+1;			--OPCODE field size
	constant REG_ADDR_SIZE	: integer := RD_range'high-RD_range'low+1;					--register file address field size
    constant FUNCT3_SIZE	: integer := FUNCT3_range'high-FUNCT3_range'low+1;			--FUNC field size
    constant FUNCT7_SIZE	: integer := FUNCT7_range'high-FUNCT7_range'low+1;			--OFFSET field size
	constant IMM_SHORT_SIZE : integer := FUNCT7_SIZE+REG_ADDR_SIZE;						--IMMEDIATE size in I-type, S-type, SB-type instructions
	constant IMM_LONG_SIZE 	: integer := FUNCT7_SIZE+2*REG_ADDR_SIZE+FUNCT3_SIZE;		--IMMEDIATE size in UJ-type, U-type, instructions
	
	constant N_REG		: integer := 2**REG_ADDR_SIZE;	--number of registers
	constant N_FUNCT3	: integer := 2**FUNCT3_SIZE;	--number of possible FUNCT3s
	constant N_FUNCT7	: integer := 2**FUNCT7_SIZE;	--number of possible FUNCT7s
	constant N_OPCODE	: integer := 2**OPCODE_SIZE;	--number of possible OPCODEs

	subtype REG_addr is std_logic_vector(REG_ADDR_SIZE-1 downto 0);
	subtype FUNCT7_type is std_logic_vector(FUNCT7_SIZE-1 downto 0);
	
	--all possible OPCODES in order
	type OPCODE_type is (
		OPCODE_LOAD,
		OPCODE_LOADFP,
		OPCODE_CUSTOM0,
		OPCODE_MISCMEM,
		OPCODE_OPIMM,
		OPCODE_AUIPC,
		OPCODE_OPIMM32,
		OPCODE_WASTE0,
		OPCODE_STORE,
		OPCODE_STOREFP,
		OPCODE_CUSTOM1,
		OPCODE_AMO,
		OPCODE_OP,
		OPCODE_LUI,
		OPCODE_OP32,
		OPCODE_WASTE1,
		OPCODE_MADD,
		OPCODE_MSUB,
		OPCODE_NMSUB,
		OPCODE_NMADD,
		OPCODE_OPFP,
		OPCODE_RESERVED0,
		OPCODE_CUSTOM2,
		OPCODE_WASTE2,
		OPCODE_BRANCH,
		OPCODE_JALR,
		OPCODE_RESERVED1,
		OPCODE_JAL,
		OPCODE_SYSTEM,
		OPCODE_RESERVED2,
		OPCODE_CUSTOM3,
		OPCODE_WASTE3
	);

	--all possible FUNCT3 when OPCODE=OPCODE_BRANCH in order
	type FUNCT3_BRANCH_type is (
		FUNCT3_BEQ,
		FUNCT3_BNE,
		FUNCT3_WASTE0,
		FUNCT3_WASTE1,
		FUNCT3_BLT,
		FUNCT3_BGE,
		FUNCT3_BLTU,
		FUNCT3_BGEU
	);

	--all possible FUNCT3 when OPCODE=OPCODE_LOAD in order
	type FUNCT3_LOAD_type is (
		FUNCT3_LB,
		FUNCT3_LH,
		FUNCT3_LW,
		FUNCT3_WASTE0,
		FUNCT3_LBU,
		FUNCT3_LHU,
		FUNCT3_WASTE1,
		FUNCT3_WASTE2
	);

	--all possible FUNCT3 when OPCODE=OPCODE_STORE in order
	type FUNCT3_STORE_type is (
		FUNCT3_SB,
		FUNCT3_SH,
		FUNCT3_SW,
		FUNCT3_WASTE0,
		FUNCT3_WASTE1,
		FUNCT3_WASTE2,
		FUNCT3_WASTE3,
		FUNCT3_WASTE4
	);

	--all possible FUNCT3 when OPCODE=OPCODE_OPIMM in order
	type FUNCT3_OPIMM_type is (
		FUNCT3_ADDI,
		FUNCT3_SLI,
		FUNCT3_SLTI,
		FUNCT3_SLTIU,
		FUNCT3_XORI,
		FUNCT3_SRI,		--logical or arithmetical according to bit 10 of immediate field (bit 5 of funct7 field)
		FUNCT3_ORI,
		FUNCT3_ANDI
	);

	constant FUNCT7_STD0	: FUNCT7_type := "0000000";
	constant FUNCT7_STD1	: FUNCT7_type := "0100000";
	constant FUNCT7_RV32M	: FUNCT7_type := "0000001";

	--all possible FUNCT3 when OPCODE=OPCODE_OP and FUNCT7=FUNCT7_STD0 in order
	type FUNCT3_OP_STD0_type is (
		FUNCT3_ADD,
		FUNCT3_SL,
		FUNCT3_SLT,
		FUNCT3_SLTU,
		FUNCT3_XOR,
		FUNCT3_SRL,
		FUNCT3_OR,
		FUNCT3_AND
	);
	
	--all possible FUNCT3 when OPCODE=OPCODE_OP and FUNCT7=FUNCT7_STD1 in order
	type FUNCT3_OP_STD1_type is (
		FUNCT3_SUB,
		FUNCT3_WASTE0,
		FUNCT3_WASTE1,
		FUNCT3_WASTE2,
		FUNCT3_WASTE3,
		FUNCT3_SRA,
		FUNCT3_WASTE4,
		FUNCT3_WASTE5
	);
	
	--all possible FUNCT3 when OPCODE=OPCODE_OP and FUNCT7=FUNCT7_RV32M in order
	type FUNCT3_OP_RV32M_type is (
		FUNCT3_MUL,
		FUNCT3_MULH,
		FUNCT3_MULHSU,
		FUNCT3_MULHU,
		FUNCT3_DIV,
		FUNCT3_DIVU,
		FUNCT3_REM,
		FUNCT3_REMU
	);

	--type conversion functions for FUNCT3_BRANCH_type
	function to_integer (FUNCT3: FUNCT3_BRANCH_type) return natural;
	function to_std_logic_vector (FUNCT3: FUNCT3_BRANCH_type) return std_logic_vector;
	function to_FUNCT3_BRANCH_type (FUNCT3_N: integer range 0 to N_FUNCT3-1) return FUNCT3_BRANCH_type;
	function to_FUNCT3_BRANCH_type (FUNCT3_FIELD: std_logic_vector(FUNCT3_SIZE-1 downto 0)) return FUNCT3_BRANCH_type;

	--type conversion functions for FUNCT3_LOAD_type
	function to_integer (FUNCT3: FUNCT3_LOAD_type) return natural;
	function to_std_logic_vector (FUNCT3: FUNCT3_LOAD_type) return std_logic_vector;
	function to_FUNCT3_LOAD_type (FUNCT3_N: integer range 0 to N_FUNCT3-1) return FUNCT3_LOAD_type;
	function to_FUNCT3_LOAD_type (FUNCT3_FIELD: std_logic_vector(FUNCT3_SIZE-1 downto 0)) return FUNCT3_LOAD_type;

	--type conversion functions for FUNCT3_STORE_type
	function to_integer (FUNCT3: FUNCT3_STORE_type) return natural;
	function to_std_logic_vector (FUNCT3: FUNCT3_STORE_type) return std_logic_vector;
	function to_FUNCT3_STORE_type (FUNCT3_N: integer range 0 to N_FUNCT3-1) return FUNCT3_STORE_type;
	function to_FUNCT3_STORE_type (FUNCT3_FIELD: std_logic_vector(FUNCT3_SIZE-1 downto 0)) return FUNCT3_STORE_type;

	--type conversion functions for FUNCT3_OPIMM_type
	function to_integer (FUNCT3: FUNCT3_OPIMM_type) return natural;
	function to_std_logic_vector (FUNCT3: FUNCT3_OPIMM_type) return std_logic_vector;
	function to_FUNCT3_OPIMM_type (FUNCT3_N: integer range 0 to N_FUNCT3-1) return FUNCT3_OPIMM_type;
	function to_FUNCT3_OPIMM_type (FUNCT3_FIELD: std_logic_vector(FUNCT3_SIZE-1 downto 0)) return FUNCT3_OPIMM_type;

	--type conversion functions for FUNCT3_OP_STD0_type
	function to_integer (FUNCT3: FUNCT3_OP_STD0_type) return natural;
	function to_std_logic_vector (FUNCT3: FUNCT3_OP_STD0_type) return std_logic_vector;
	function to_FUNCT3_OP_STD0_type (FUNCT3_N: integer range 0 to N_FUNCT3-1) return FUNCT3_OP_STD0_type;
	function to_FUNCT3_OP_STD0_type (FUNCT3_FIELD: std_logic_vector(FUNCT3_SIZE-1 downto 0)) return FUNCT3_OP_STD0_type;

	--type conversion functions for FUNCT3_OP_STD1_type
	function to_integer (FUNCT3: FUNCT3_OP_STD1_type) return natural;
	function to_std_logic_vector (FUNCT3: FUNCT3_OP_STD1_type) return std_logic_vector;
	function to_FUNCT3_OP_STD1_type (FUNCT3_N: integer range 0 to N_FUNCT3-1) return FUNCT3_OP_STD1_type;
	function to_FUNCT3_OP_STD1_type (FUNCT3_FIELD: std_logic_vector(FUNCT3_SIZE-1 downto 0)) return FUNCT3_OP_STD1_type;

	--type conversion functions for FUNCT3_OP_RV32M_type
	function to_integer (FUNCT3: FUNCT3_OP_RV32M_type) return natural;
	function to_std_logic_vector (FUNCT3: FUNCT3_OP_RV32M_type) return std_logic_vector;
	function to_FUNCT3_OP_RV32M_type (FUNCT3_N: integer range 0 to N_FUNCT3-1) return FUNCT3_OP_RV32M_type;
	function to_FUNCT3_OP_RV32M_type (FUNCT3_FIELD: std_logic_vector(FUNCT3_SIZE-1 downto 0)) return FUNCT3_OP_RV32M_type;
	
	--type conversion functions for OPCODE_type
	function to_integer (OPCODE: OPCODE_type) return natural;
	function to_std_logic_vector (OPCODE: OPCODE_type) return std_logic_vector;
	function to_OPCODE_type	(OPCODE_N: integer range 0 to N_OPCODE-1) return OPCODE_type;
	function to_OPCODE_type (OPCODE_FIELD: std_logic_vector(OPCODE_SIZE-1 downto 0)) return OPCODE_type;

	--functions to get directly opcode, funct3 or registers number from an instruction
	function get_OPCODE (INSTR: word) return OPCODE_type;
	function get_FUNCT3_BRANCH (INSTR: word) return FUNCT3_BRANCH_type;
	function get_FUNCT3_LOAD (INSTR: word) return FUNCT3_LOAD_type;
	function get_FUNCT3_STORE (INSTR: word) return FUNCT3_STORE_type;
	function get_FUNCT3_OPIMM (INSTR: word) return FUNCT3_OPIMM_type;
	function get_FUNCT3_OP_STD0 (INSTR: word) return FUNCT3_OP_STD0_type;
	function get_FUNCT3_OP_STD1 (INSTR: word) return FUNCT3_OP_STD1_type;
	function get_FUNCT3_OP_RV32M (INSTR: word) return FUNCT3_OP_RV32M_type;
	function get_FUNCT7 (INSTR: word) return FUNCT7_type;
	function get_RD (INSTR: word) return natural;
	function get_RS1 (INSTR: word) return natural;
	function get_RS2 (INSTR: word) return natural;
	function get_IMM_ITYPE (INSTR: word) return integer;
	function get_IMM_STYPE (INSTR: word) return integer;
	function get_IMM_BTYPE (INSTR: word) return integer;
	function get_IMM_JTYPE (INSTR: word) return integer;
	function get_IMM_UTYPE (INSTR: word) return integer;

	--instruction encoding functions
	function INSTR_BRANCH (FUNCT3: FUNCT3_BRANCH_type; RS1,RS2: integer range 0 to N_REG; IMM: integer range -2**IMM_SHORT_SIZE to 2**IMM_SHORT_SIZE-1) return word;
	function INSTR_LOAD (FUNCT3: FUNCT3_LOAD_type; RD,RS: integer range 0 to N_REG; IMM: integer range -2**(IMM_SHORT_SIZE-1) to 2**(IMM_SHORT_SIZE-1)-1) return word;
	function INSTR_STORE (FUNCT3: FUNCT3_STORE_type; RS1,RS2: integer range 0 to N_REG; IMM: integer range -2**(IMM_SHORT_SIZE-1) to 2**(IMM_SHORT_SIZE-1)-1) return word;
	function INSTR_OPIMM (FUNCT3: FUNCT3_OPIMM_type; RD,RS: integer range 0 to N_REG; IMM: integer range -2**(IMM_SHORT_SIZE-1) to 2**(IMM_SHORT_SIZE-1)-1) return word;
	function INSTR_OP_STD0 (FUNCT3: FUNCT3_OP_STD0_type; RD,RS1,RS2: integer range 0 to N_REG) return word;
	function INSTR_OP_STD1 (FUNCT3: FUNCT3_OP_STD1_type; RD,RS1,RS2: integer range 0 to N_REG) return word;
	function INSTR_OP_RV32M (FUNCT3: FUNCT3_OP_RV32M_type; RD,RS1,RS2: integer range 0 to N_REG) return word;
	function INSTR_JAL (RD: integer range 0 to N_REG; IMM: integer range -2**IMM_LONG_SIZE to 2**IMM_LONG_SIZE-1) return word;
	function INSTR_JALR (RD,RS: integer range 0 to N_REG; IMM: integer range -2**(IMM_SHORT_SIZE-1) to 2**(IMM_SHORT_SIZE-1)-1) return word;
	function INSTR_UTYPE (OPCODE: OPCODE_type; RD: integer range 0 to N_REG; IMM: integer range -2**(IMM_LONG_SIZE-1) to 2**(IMM_LONG_SIZE-1)-1) return word;

	--instruction type recognition functions
	function is_a_jump (INSTR: word) return boolean;
	function is_a_branch (INSTR: word) return boolean;
	function is_a_store (INSTR: word) return boolean;
	function is_a_load (INSTR: word) return boolean;
	function is_a_mult (INSTR: word) return boolean;
	function is_a_op (INSTR: word) return boolean;
	function is_a_upperimm (INSTR: word) return boolean;
	
	constant INSTR_NOP: word;
	
end package RISCV_package;

package body RISCV_package is

	function to_integer (FUNCT3: FUNCT3_BRANCH_type) return natural is
	begin
		return FUNCT3_BRANCH_type'pos(FUNCT3);
	end function to_integer;
	
	function to_std_logic_vector (FUNCT3: FUNCT3_BRANCH_type) return std_logic_vector is
	begin
		return std_logic_vector(to_unsigned(to_integer(FUNCT3), FUNCT3_SIZE));
	end function to_std_logic_vector;
	
	function to_FUNCT3_BRANCH_type (FUNCT3_N: integer range 0 to N_FUNCT3-1) return FUNCT3_BRANCH_type is
	begin
		return FUNCT3_BRANCH_type'val(FUNCT3_N);
	end function to_FUNCT3_BRANCH_type;
		
	function to_FUNCT3_BRANCH_type (FUNCT3_FIELD: std_logic_vector(FUNCT3_SIZE-1 downto 0)) return FUNCT3_BRANCH_type is
	begin
		return to_FUNCT3_BRANCH_type(to_integer(unsigned(FUNCT3_FIELD)));
	end function to_FUNCT3_BRANCH_type;

	function to_integer (FUNCT3: FUNCT3_LOAD_type) return natural is
	begin
		return FUNCT3_LOAD_type'pos(FUNCT3);
	end function to_integer;
	
	function to_std_logic_vector (FUNCT3: FUNCT3_LOAD_type) return std_logic_vector is
	begin
		return std_logic_vector(to_unsigned(to_integer(FUNCT3), FUNCT3_SIZE));
	end function to_std_logic_vector;
	
	function to_FUNCT3_LOAD_type (FUNCT3_N: integer range 0 to N_FUNCT3-1) return FUNCT3_LOAD_type is
	begin
		return FUNCT3_LOAD_type'val(FUNCT3_N);
	end function to_FUNCT3_LOAD_type;
		
	function to_FUNCT3_LOAD_type (FUNCT3_FIELD: std_logic_vector(FUNCT3_SIZE-1 downto 0)) return FUNCT3_LOAD_type is
	begin
		return to_FUNCT3_LOAD_type(to_integer(unsigned(FUNCT3_FIELD)));
	end function to_FUNCT3_LOAD_type;

	function to_integer (FUNCT3: FUNCT3_STORE_type) return natural is
	begin
		return FUNCT3_STORE_type'pos(FUNCT3);
	end function to_integer;
	
	function to_std_logic_vector (FUNCT3: FUNCT3_STORE_type) return std_logic_vector is
	begin
		return std_logic_vector(to_unsigned(to_integer(FUNCT3), FUNCT3_SIZE));
	end function to_std_logic_vector;
	
	function to_FUNCT3_STORE_type (FUNCT3_N: integer range 0 to N_FUNCT3-1) return FUNCT3_STORE_type is
	begin
		return FUNCT3_STORE_type'val(FUNCT3_N);
	end function to_FUNCT3_STORE_type;
		
	function to_FUNCT3_STORE_type (FUNCT3_FIELD: std_logic_vector(FUNCT3_SIZE-1 downto 0)) return FUNCT3_STORE_type is
	begin
		return to_FUNCT3_STORE_type(to_integer(unsigned(FUNCT3_FIELD)));
	end function to_FUNCT3_STORE_type;

	function to_integer (FUNCT3: FUNCT3_OPIMM_type) return natural is
	begin
		return FUNCT3_OPIMM_type'pos(FUNCT3);
	end function to_integer;
	
	function to_std_logic_vector (FUNCT3: FUNCT3_OPIMM_type) return std_logic_vector is
	begin
		return std_logic_vector(to_unsigned(to_integer(FUNCT3), FUNCT3_SIZE));
	end function to_std_logic_vector;
	
	function to_FUNCT3_OPIMM_type (FUNCT3_N: integer range 0 to N_FUNCT3-1) return FUNCT3_OPIMM_type is
	begin
		return FUNCT3_OPIMM_type'val(FUNCT3_N);
	end function to_FUNCT3_OPIMM_type;
		
	function to_FUNCT3_OPIMM_type (FUNCT3_FIELD: std_logic_vector(FUNCT3_SIZE-1 downto 0)) return FUNCT3_OPIMM_type is
	begin
		return to_FUNCT3_OPIMM_type(to_integer(unsigned(FUNCT3_FIELD)));
	end function to_FUNCT3_OPIMM_type;

	function to_integer (FUNCT3: FUNCT3_OP_STD0_type) return natural is
	begin
		return FUNCT3_OP_STD0_type'pos(FUNCT3);
	end function to_integer;
	
	function to_std_logic_vector (FUNCT3: FUNCT3_OP_STD0_type) return std_logic_vector is
	begin
		return std_logic_vector(to_unsigned(to_integer(FUNCT3), FUNCT3_SIZE));
	end function to_std_logic_vector;
	
	function to_FUNCT3_OP_STD0_type (FUNCT3_N: integer range 0 to N_FUNCT3-1) return FUNCT3_OP_STD0_type is
	begin
		return FUNCT3_OP_STD0_type'val(FUNCT3_N);
	end function to_FUNCT3_OP_STD0_type;
		
	function to_FUNCT3_OP_STD0_type (FUNCT3_FIELD: std_logic_vector(FUNCT3_SIZE-1 downto 0)) return FUNCT3_OP_STD0_type is
	begin
		return to_FUNCT3_OP_STD0_type(to_integer(unsigned(FUNCT3_FIELD)));
	end function to_FUNCT3_OP_STD0_type;

	function to_integer (FUNCT3: FUNCT3_OP_STD1_type) return natural is
	begin
		return FUNCT3_OP_STD1_type'pos(FUNCT3);
	end function to_integer;
	
	function to_std_logic_vector (FUNCT3: FUNCT3_OP_STD1_type) return std_logic_vector is
	begin
		return std_logic_vector(to_unsigned(to_integer(FUNCT3), FUNCT3_SIZE));
	end function to_std_logic_vector;
	
	function to_FUNCT3_OP_STD1_type (FUNCT3_N: integer range 0 to N_FUNCT3-1) return FUNCT3_OP_STD1_type is
	begin
		return FUNCT3_OP_STD1_type'val(FUNCT3_N);
	end function to_FUNCT3_OP_STD1_type;
		
	function to_FUNCT3_OP_STD1_type (FUNCT3_FIELD: std_logic_vector(FUNCT3_SIZE-1 downto 0)) return FUNCT3_OP_STD1_type is
	begin
		return to_FUNCT3_OP_STD1_type(to_integer(unsigned(FUNCT3_FIELD)));
	end function to_FUNCT3_OP_STD1_type;

	function to_integer (FUNCT3: FUNCT3_OP_RV32M_type) return natural is
	begin
		return FUNCT3_OP_RV32M_type'pos(FUNCT3);
	end function to_integer;
	
	function to_std_logic_vector (FUNCT3: FUNCT3_OP_RV32M_type) return std_logic_vector is
	begin
		return std_logic_vector(to_unsigned(to_integer(FUNCT3), FUNCT3_SIZE));
	end function to_std_logic_vector;
	
	function to_FUNCT3_OP_RV32M_type (FUNCT3_N: integer range 0 to N_FUNCT3-1) return FUNCT3_OP_RV32M_type is
	begin
		return FUNCT3_OP_RV32M_type'val(FUNCT3_N);
	end function to_FUNCT3_OP_RV32M_type;
		
	function to_FUNCT3_OP_RV32M_type (FUNCT3_FIELD: std_logic_vector(FUNCT3_SIZE-1 downto 0)) return FUNCT3_OP_RV32M_type is
	begin
		return to_FUNCT3_OP_RV32M_type(to_integer(unsigned(FUNCT3_FIELD)));
	end function to_FUNCT3_OP_RV32M_type;
		
	function to_integer (OPCODE: OPCODE_type) return natural is
	begin
		return OPCODE_type'pos(OPCODE)*4+3;
	end function to_integer;	
	
	function to_std_logic_vector (OPCODE: OPCODE_type) return std_logic_vector is
	begin
		return std_logic_vector(to_unsigned(to_integer(OPCODE), OPCODE_SIZE));
	end function to_std_logic_vector;
	
	function to_opcode_type (OPCODE_N: integer range 0 to N_OPCODE-1) return OPCODE_type is
	begin
			return OPCODE_type'val(OPCODE_N/4);
	end function to_opcode_type;	
		
	function to_opcode_type (OPCODE_FIELD: std_logic_vector(OPCODE_SIZE-1 downto 0)) return OPCODE_type is
	begin
		return to_opcode_type(to_integer(unsigned(OPCODE_FIELD)));
	end function to_opcode_type;

	function get_opcode (INSTR: word) return OPCODE_type is
	begin
		return to_opcode_type(INSTR(OPCODE_range));
	end function get_opcode;
	
	function get_FUNCT3_BRANCH (INSTR: word) return FUNCT3_BRANCH_type is
	begin
		return to_FUNCT3_BRANCH_type(INSTR(FUNCT3_range));
	end function get_FUNCT3_BRANCH;
	
	function get_FUNCT3_LOAD (INSTR: word) return FUNCT3_LOAD_type is
	begin
		return to_FUNCT3_LOAD_type(INSTR(FUNCT3_range));
	end function get_FUNCT3_LOAD;
	
	function get_FUNCT3_STORE (INSTR: word) return FUNCT3_STORE_type is
	begin
		return to_FUNCT3_STORE_type(INSTR(FUNCT3_range));
	end function get_FUNCT3_STORE;
	
	function get_FUNCT3_OPIMM (INSTR: word) return FUNCT3_OPIMM_type is
	begin
		return to_FUNCT3_OPIMM_type(INSTR(FUNCT3_range));
	end function get_FUNCT3_OPIMM;
	
	function get_FUNCT3_OP_STD0 (INSTR: word) return FUNCT3_OP_STD0_type is
	begin
		return to_FUNCT3_OP_STD0_type(INSTR(FUNCT3_range));
	end function get_FUNCT3_OP_STD0;
	
	function get_FUNCT3_OP_STD1 (INSTR: word) return FUNCT3_OP_STD1_type is
	begin
		return to_FUNCT3_OP_STD1_type(INSTR(FUNCT3_range));
	end function get_FUNCT3_OP_STD1;
	
	function get_FUNCT3_OP_RV32M (INSTR: word) return FUNCT3_OP_RV32M_type is
	begin
		return to_FUNCT3_OP_RV32M_type(INSTR(FUNCT3_range));
	end function get_FUNCT3_OP_RV32M;
	
	function get_FUNCT7 (INSTR: word) return FUNCT7_type is
	variable temp: FUNCT7_type;
	begin
		temp:=INSTR(FUNCT7_range);
		return temp;
	end function get_FUNCT7;

	function get_RS1 (INSTR: word) return natural is
	begin
		return to_integer(unsigned(INSTR(RS1_range)));
	end function get_RS1;
	
	function get_RS2 (INSTR: word) return natural is
	begin
		return to_integer(unsigned(INSTR(RS2_range)));
	end function get_RS2;
	
	function get_RD (INSTR: word) return natural is
	begin
		return to_integer(unsigned(INSTR(RD_range)));
	end function get_RD;

	function get_IMM_ITYPE (INSTR: word) return integer is
	begin
		return to_integer(signed(INSTR(FUNCT7_range) & INSTR(RS2_range)));
	end function get_IMM_ITYPE;

	function get_IMM_STYPE (INSTR: word) return integer is
	begin
		return to_integer(signed(INSTR(FUNCT7_range) & INSTR(RD_range)));
	end function get_IMM_STYPE;

	function get_IMM_BTYPE (INSTR: word) return integer is
		variable FUNCT7_field : FUNCT7_type := INSTR(FUNCT7_range);
		variable RD_field : REG_addr := INSTR(RD_range);
	begin
		return to_integer(signed(FUNCT7_field(6) & RD_field(0) & FUNCT7_field(5 downto 0) & RD_field(4 downto 1) & '0'));
	end function get_IMM_BTYPE;

	function get_IMM_JTYPE (INSTR: word) return integer is
		variable IMM_field : std_logic_vector(IMM_LONG_SIZE-1 downto 0) := INSTR(IMM_LONG_range);
	begin
		return to_integer(signed(IMM_field(19) & IMM_field(7 downto 0) & IMM_field(8) & IMM_field(18 downto 9) & '0'));
	end function get_IMM_JTYPE;

	function get_IMM_UTYPE (INSTR: word) return integer is
	begin
		return to_integer(signed(INSTR(IMM_LONG_range)) & to_signed(0, 12));
	end function get_IMM_UTYPE;

	function INSTR_BRANCH (FUNCT3: FUNCT3_BRANCH_type; RS1,RS2: integer range 0 to N_REG; IMM: integer range -2**IMM_SHORT_SIZE to 2**IMM_SHORT_SIZE-1) return word is
		constant IMM_std_logic_vector : std_logic_vector(IMM_SHORT_SIZE downto 0) := std_logic_vector(to_signed(IMM, IMM_SHORT_SIZE+1));
		constant temp: word:= IMM_std_logic_vector(12) & IMM_std_logic_vector(10 downto 5) & std_logic_vector(to_unsigned(RS2,REG_ADDR_SIZE)) & std_logic_vector(to_unsigned(RS1,REG_ADDR_SIZE)) & to_std_logic_vector(FUNCT3) & IMM_std_logic_vector(4 downto 1) & IMM_std_logic_vector(11) & to_std_logic_vector(OPCODE_BRANCH);
	begin
		return temp;
	end function INSTR_BRANCH;

	function INSTR_LOAD (FUNCT3: FUNCT3_LOAD_type; RD,RS: integer range 0 to N_REG; IMM: integer range -2**(IMM_SHORT_SIZE-1) to 2**(IMM_SHORT_SIZE-1)-1) return word is
		constant temp: word:= std_logic_vector(to_signed(IMM, IMM_SHORT_SIZE)) & std_logic_vector(to_unsigned(RS,REG_ADDR_SIZE)) & to_std_logic_vector(FUNCT3) & std_logic_vector(to_unsigned(RD,REG_ADDR_SIZE)) & to_std_logic_vector(OPCODE_LOAD);
	begin
		return temp;
	end function INSTR_LOAD;

	function INSTR_STORE (FUNCT3: FUNCT3_STORE_type; RS1,RS2: integer range 0 to N_REG; IMM: integer range -2**(IMM_SHORT_SIZE-1) to 2**(IMM_SHORT_SIZE-1)-1) return word is
		constant IMM_std_logic_vector : std_logic_vector(IMM_SHORT_SIZE-1 downto 0) := std_logic_vector(to_signed(IMM, IMM_SHORT_SIZE));
		constant temp: word:= IMM_std_logic_vector(11 downto 5) & std_logic_vector(to_unsigned(RS2,REG_ADDR_SIZE)) & std_logic_vector(to_unsigned(RS1,REG_ADDR_SIZE)) & to_std_logic_vector(FUNCT3) & IMM_std_logic_vector(4 downto 0) & to_std_logic_vector(OPCODE_STORE);
	begin
		return temp;
	end function INSTR_STORE;

	function INSTR_OPIMM (FUNCT3: FUNCT3_OPIMM_type; RD,RS: integer range 0 to N_REG; IMM: integer range -2**(IMM_SHORT_SIZE-1) to 2**(IMM_SHORT_SIZE-1)-1) return word is
		constant temp: word:= std_logic_vector(to_signed(IMM, IMM_SHORT_SIZE)) & std_logic_vector(to_unsigned(RS,REG_ADDR_SIZE)) & to_std_logic_vector(FUNCT3) & std_logic_vector(to_unsigned(RD,REG_ADDR_SIZE)) & to_std_logic_vector(OPCODE_OPIMM);
	begin
		return temp;
	end function INSTR_OPIMM;

	function INSTR_OP_STD0 (FUNCT3: FUNCT3_OP_STD0_type; RD,RS1,RS2: integer range 0 to N_REG) return word is
		constant temp: word := FUNCT7_STD0 & std_logic_vector(to_unsigned(RS2,REG_ADDR_SIZE)) & std_logic_vector(to_unsigned(RS1,REG_ADDR_SIZE)) & to_std_logic_vector(FUNCT3) & std_logic_vector(to_unsigned(RD,REG_ADDR_SIZE)) & to_std_logic_vector(OPCODE_OP);
	begin
		return temp;
	end function INSTR_OP_STD0;

	function INSTR_OP_STD1 (FUNCT3: FUNCT3_OP_STD1_type; RD,RS1,RS2: integer range 0 to N_REG) return word is
		constant temp: word := FUNCT7_STD1 & std_logic_vector(to_unsigned(RS2,REG_ADDR_SIZE)) & std_logic_vector(to_unsigned(RS1,REG_ADDR_SIZE)) & to_std_logic_vector(FUNCT3) & std_logic_vector(to_unsigned(RD,REG_ADDR_SIZE)) & to_std_logic_vector(OPCODE_OP);
	begin
		return temp;
	end function INSTR_OP_STD1;

	function INSTR_OP_RV32M (FUNCT3: FUNCT3_OP_RV32M_type; RD,RS1,RS2: integer range 0 to N_REG) return word is
	begin
		return FUNCT7_RV32M & std_logic_vector(to_unsigned(RS2,REG_ADDR_SIZE)) & std_logic_vector(to_unsigned(RS1,REG_ADDR_SIZE)) & to_std_logic_vector(FUNCT3) & std_logic_vector(to_unsigned(RD,REG_ADDR_SIZE)) & to_std_logic_vector(OPCODE_OP);
	end function INSTR_OP_RV32M;

	function INSTR_JAL (RD: integer range 0 to N_REG; IMM: integer range -2**IMM_LONG_SIZE to 2**IMM_LONG_SIZE-1) return word is
		constant IMM_std_logic_vector : std_logic_vector(IMM_LONG_SIZE downto 0) := std_logic_vector(to_unsigned(IMM, IMM_LONG_SIZE+1));
		constant temp: word :=  IMM_std_logic_vector(20) & IMM_std_logic_vector(10 downto 1) & IMM_std_logic_vector(11) & IMM_std_logic_vector(19 downto 12) & std_logic_vector(to_unsigned(RD,REG_ADDR_SIZE)) & to_std_logic_vector(OPCODE_JAL);
	begin
		return temp;
	end function INSTR_JAL;
	
	function INSTR_JALR (RD,RS: integer range 0 to N_REG; IMM: integer range -2**(IMM_SHORT_SIZE-1) to 2**(IMM_SHORT_SIZE-1)-1) return word is
		constant temp: word:= std_logic_vector(to_signed(IMM, IMM_SHORT_SIZE)) & std_logic_vector(to_unsigned(RS,REG_ADDR_SIZE)) & "000" & std_logic_vector(to_unsigned(RD,REG_ADDR_SIZE)) & to_std_logic_vector(OPCODE_JALR);
	begin
		return temp;
	end function INSTR_JALR;
	
	function INSTR_UTYPE (OPCODE: OPCODE_type; RD: integer range 0 to N_REG; IMM: integer range -2**(IMM_LONG_SIZE-1) to 2**(IMM_LONG_SIZE-1)-1) return word is
		constant temp: word:= std_logic_vector(to_signed(IMM, IMM_LONG_SIZE)) & std_logic_vector(to_unsigned(RD,REG_ADDR_SIZE)) & to_std_logic_vector(OPCODE);
	begin
		return temp;
	end function INSTR_UTYPE;
	
	function is_a_jump(instr: word) return boolean is
		variable opcode: OPCODE_type;
	begin
		opcode:=get_opcode(instr);
		return opcode=OPCODE_JAL or opcode=OPCODE_JALR;
	end function is_a_jump;
	
	function is_a_branch(instr: word) return boolean is
		variable opcode: OPCODE_type;
	begin
		opcode:=get_opcode(instr);
		return opcode=OPCODE_BRANCH;
	end function is_a_branch;
	
	function is_a_store (INSTR: word) return boolean is
		variable opcode: OPCODE_type;
	begin
		opcode:=get_opcode(INSTR);
		return opcode=OPCODE_STORE;
	end function is_a_store;
	
	function is_a_load (INSTR: word) return boolean is
		variable opcode: OPCODE_type;
	begin
		opcode:=get_opcode(INSTR);
		return opcode=OPCODE_LOAD;
	end function is_a_load;

	function is_a_mult (INSTR: word) return boolean is
		variable opcode: OPCODE_type;
		variable funct7: FUNCT7_type;
		variable funct3: FUNCT3_OP_RV32M_type;
	begin
		opcode:=get_OPCODE(INSTR);
		funct7:=get_FUNCT7(INSTR);
		funct3:=get_FUNCT3_OP_RV32M(INSTR);
		return opcode=OPCODE_OP and funct7=FUNCT7_RV32M and (funct3=FUNCT3_MUL or funct3=FUNCT3_MULH or funct3=FUNCT3_MULHSU or funct3=FUNCT3_MULHU);
	end function is_a_mult;
	
	function is_a_op (INSTR: word) return boolean is
		variable opcode: OPCODE_type;
	begin
		opcode:=get_opcode(INSTR);
		return opcode=OPCODE_OP;
	end function is_a_op;
	
	function is_a_upperimm (INSTR: word) return boolean is
		variable opcode: OPCODE_type;
	begin
		opcode:=get_opcode(INSTR);
		return opcode=OPCODE_LUI or opcode=OPCODE_AUIPC;
	end function is_a_upperimm;
	
	constant INSTR_NOP: word:= INSTR_OPIMM(FUNCT3_ADDI, 0, 0, 0);
	
end package body RISCV_package;
