library ieee;
use ieee.std_logic_1164.all;

package FU_package is

	--FU package
	type FU_OUTS_type is record
		MUX_ALU_IN1_sel				: std_logic_vector(1 downto 0);
		MUX_ALU_IN2_sel				: std_logic_vector(1 downto 0);
		MUX_DRAM_IN_sel				: std_logic;
	end record FU_OUTS_type;

	constant ALU_forward_NO		: std_logic_vector(1 downto 0):= "00";
	constant ALU_forward_EXE	: std_logic_vector(1 downto 0):= "01";
	constant ALU_forward_MEM	: std_logic_vector(1 downto 0):= "10";
	constant ALU_forward_WB		: std_logic_vector(1 downto 0):= "11";
	constant DRAM_forward_NO	: std_logic:= '0';
	constant DRAM_forward_WB	: std_logic:= '1';
	
end package FU_package;