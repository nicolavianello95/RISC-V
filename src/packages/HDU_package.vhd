library ieee;
use ieee.std_logic_1164.all;

package HDU_package is

	type HDU_OUTS_type is record
		PC_EN		: std_logic;
		IF_ID_EN	: std_logic;
		ID_EXE_EN	: std_logic;
		EXE_MEM_EN	: std_logic;
		MEM_WB_EN	: std_logic;
		ID_bubble	: std_logic;
		EXE_bubble	: std_logic;
		MEM_bubble	: std_logic;
		WB_bubble	: std_logic;
	end record HDU_OUTS_type;

end package HDU_package;