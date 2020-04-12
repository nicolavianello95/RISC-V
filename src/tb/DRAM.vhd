library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;
use ieee.std_logic_textio.all;
use work.RISCV_package.all;	
use work.CU_package.all;

entity DRAM is
	port(
		DATA_IN		: in word;
		DATA_OUT	: out word;
		ADDR		: in halfword;
		WR_EN		: in std_logic_vector(1 downto 0);	--00 off, 01 byte, 10 halfword, 11 word
		CS			: in std_logic;						--chip select
		CLK			: in std_logic
	);
end entity DRAM;

architecture behavioral of DRAM is
	
	constant MEM_SIZE: positive:= 2**HALFWORD_size;
	type MEM_type is array (0 to MEM_SIZE-1) of byte;

	signal MEM: MEM_type;
	signal ADDR_to_int: natural;
	signal byte0_out, byte1_out, byte2_out, byte3_out: byte;

begin

	ADDR_to_int<=to_integer(unsigned(ADDR));

	byte0_out <= MEM(ADDR_to_int) when CS='1' else
				 (others=>'0');
				
	byte1_out <= MEM(ADDR_to_int+1) when ADDR_to_int+1<=MEM_SIZE-1 and CS='1'  else
				 (others=>'0');
				
	byte2_out <= MEM(ADDR_to_int+2) when ADDR_to_int+2<=MEM_SIZE-1 and CS='1'  else
				 (others=>'0');
				
	byte3_out <= MEM(ADDR_to_int+3) when ADDR_to_int+3<=MEM_SIZE-1 and CS='1'  else
				 (others=>'0');
				
	DATA_OUT <= byte3_out & byte2_out & byte1_out & byte0_out;
	
	file_proc: process(CLK)
		file file_to_read: text;
		variable file_line : line;
		variable n_byte : integer := 0;
		variable instruction : word;
		variable init : boolean:= true;
	begin
		if rising_edge(CLK) then
			if init=true then
				init:=false;
				file_open(file_to_read,"data.hex",READ_MODE);
				while (not endfile(file_to_read)) loop
					readline(file_to_read,file_line);
					hread(file_line,instruction);
					MEM(n_byte) <= instruction(byte_range);
					MEM(n_byte+1) <= instruction(byte1_range);
					MEM(n_byte+2) <= instruction(byte2_range);
					MEM(n_byte+3) <= instruction(byte3_range);
					n_byte := n_byte + 4;
				end loop;
			end if;
			if CS='1' then
				if WR_EN=DRAM_WR_W then
					MEM(ADDR_to_int)<=DATA_IN(byte_range);
					if ADDR_to_int+1<=MEM_SIZE-1 then
						MEM(ADDR_to_int+1)<=DATA_IN(byte1_range);
					end if;
					if ADDR_to_int+2<=MEM_SIZE-1 then
						MEM(ADDR_to_int+2)<=DATA_IN(byte2_range);
					end if;
					if ADDR_to_int+3<=MEM_SIZE-1 then
						MEM(ADDR_to_int+3)<=DATA_IN(byte3_range);
					end if;
				elsif WR_EN=DRAM_WR_H then
					MEM(ADDR_to_int)<=DATA_IN(byte_range);
					if ADDR_to_int+1<=MEM_SIZE-1 then
						MEM(ADDR_to_int+1)<=DATA_IN(byte1_range);
					end if;
				elsif WR_EN=DRAM_WR_B then
					MEM(ADDR_to_int)<=DATA_IN(byte_range);
				end if;
			end if;
		end if;
	end process file_proc;
	
end architecture behavioral;