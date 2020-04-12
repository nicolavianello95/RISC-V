use work.my_package.all;

package ALU_package is
	
	--all possible ALU operations
	type ALU_OP_type is (
		ALU_DONT_CARE,	--the operation don't care
		ALU_IN1,		--out = first operand
		ALU_IN2,		--out = second operand
		ALU_ADD,		--addition
		ALU_SUB,		--subtraction
		ALU_XOR,		--bitwise xor
		ALU_AND,		--bitwise and
		ALU_OR,			--bitwise or
		ALU_SL,			--shift left 
		ALU_SRL,		--shift right logical
		ALU_SRA,		--shift right airthmetical
		ALU_SLT,        --set if less than (signed)   
		ALU_SLTU,      	--set if less than (unsigned) 
		ALU_ABS			--absolute value
		);

	constant N_ALU_OP : integer := ALU_OP_type'pos(ALU_OP_type'high)+1;		--number of possible ALU operations
	constant ALU_OP_SEL_SIZE : integer := log2_ceiling(N_ALU_OP);			--ALU operation selector size
	
end package ALU_package;
