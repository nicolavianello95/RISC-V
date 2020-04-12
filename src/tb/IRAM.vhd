library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;
use ieee.std_logic_textio.all;
use work.RISCV_package.all;

entity IRAM is
	port(
		DATA_OUT	: out word;
		ADDR		: in halfword;
		CS			: in std_logic	--chip select
	);
end entity IRAM;

architecture behavioral of IRAM is

	constant MEM_SIZE: positive:= 2**HALFWORD_size;
	type MEM_type is array (0 to MEM_SIZE-1) of byte;
	
	signal MEM: MEM_type;
	signal ADDR_to_int: natural;
	signal byte0_out, byte1_out, byte2_out, byte3_out: byte;

begin

	ADDR_to_int<=to_integer(unsigned(ADDR));

	byte0_out <= MEM(ADDR_to_int) when CS='1' else
				 (others=>'0');
				
	byte1_out <= MEM(ADDR_to_int+1) when ADDR_to_int+1<=MEM_SIZE-1 and CS='1' else
				 (others=>'0');
				
	byte2_out <= MEM(ADDR_to_int+2) when ADDR_to_int+2<=MEM_SIZE-1 and CS='1'  else
				 (others=>'0');
				
	byte3_out <= MEM(ADDR_to_int+3) when ADDR_to_int+3<=MEM_SIZE-1 and CS='1'  else
				 (others=>'0');
				
	DATA_OUT <= byte3_out & byte2_out & byte1_out & byte0_out;
	
	file_read_proc: process
		file file_to_read: text;
		variable file_line : line;
		variable n_byte : integer := 0;
		variable instruction : word;
	begin
		file_open(file_to_read,"test.hex",READ_MODE);
		while (not endfile(file_to_read)) loop
			readline(file_to_read,file_line);
			hread(file_line,instruction);
			MEM(n_byte) <= instruction(byte_range);
			MEM(n_byte+1) <= instruction(byte1_range);
			MEM(n_byte+2) <= instruction(byte2_range);
			MEM(n_byte+3) <= instruction(byte3_range);
			n_byte := n_byte + 4;
		end loop;
		wait;
	end process file_read_proc;

end behavioral;
