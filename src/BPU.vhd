library ieee;
use ieee.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.RISCV_package.all;

entity BPU is
	generic(
		TAG_FIELD_SIZE	: integer := 8;
		SET_FIELD_SIZE	: integer := 3;
		LINES_PER_SET 	: integer := 4
	);
	port(		
		clk				: in std_logic;				
		rst				: in std_logic;				
		IRAM_out		: in word;	
		pc				: in word;	
		pc_plus4		: in word;	
		npc				: out word;
		misprediction	: out std_logic;
		actual_NPC		: in word;
		IF_ID_EN		: in std_logic;		--fetch-decode registers enable
		ID_EXE_EN		: in std_logic		--decode-execute registers enable
	);
end entity BPU;

architecture behavioral of BPU is
	
	constant N_SET: integer := 2**SET_FIELD_SIZE;
	constant DATA_SIZE: integer:= WORD_SIZE-2;
	
	subtype SET_range is integer range SET_FIELD_SIZE+1 downto 2;
	subtype TAG_range is integer range SET_FIELD_SIZE+TAG_FIELD_SIZE+1 downto SET_FIELD_SIZE+2;
	subtype DATA_range is integer range WORD_SIZE-1 downto 2;
	
	subtype SET_index_type is integer range 0 to N_SET-1;
	subtype LINE_index_type is integer range 0 to LINES_PER_SET-1;
	subtype LINE_index_type_ext is integer range -1 to LINES_PER_SET-1;
	subtype TAG_type is std_logic_vector(TAG_FIELD_SIZE-1 downto 0);
	subtype DATA_type is std_logic_vector(DATA_SIZE-1 downto 0);
	
	type CACHE_LINE_type is record
		TAG: TAG_type;
		DATA: DATA_type;
		YOUTH: LINE_index_type_ext;		--the higher this value, the more recently the data has been accessed, if equal to -1 this line is free
	end record CACHE_LINE_type;
	
	type CACHE_SET_type is array (LINE_index_type) of CACHE_LINE_type;
	
	type CACHE_type is array (SET_index_type) of CACHE_SET_type;

	signal cache : CACHE_type;
	
	--asyncronous signal used by read_proc
	signal prediction : word;
	signal hit_index : LINE_index_type_ext;
	
	--asynchronous signal used to read misprediction port
	signal misprediction_sig: std_logic;
	
	--synchronous signal used by write_proc
	signal last_pc_plus4 : word;
	signal last_prediction : word;
	signal verify: std_logic;

begin

	misprediction<=misprediction_sig;
	npc<=prediction;

	read_proc: process(cache, pc_plus4, IRAM_out, pc, misprediction_sig, actual_NPC)
		variable set: SET_index_type;
		variable tag: TAG_type;
	begin
		--useful constants
		set:=to_integer(unsigned(pc(SET_range)));
		tag:=pc(TAG_range);
		--default assignments
		prediction<=pc_plus4;
		hit_index<= -1;
		if misprediction_sig='1' then
			prediction<=actual_NPC;
		elsif is_a_branch(IRAM_out) or is_a_jump(IRAM_out) then
			for i in 0 to LINES_PER_SET-1 loop
				if cache(set)(i).TAG=tag and cache(set)(i).YOUTH/=-1 then
					hit_index<=i;
					prediction<=cache(set)(i).DATA & "00";
					exit;
				end if;
			end loop;
		end if;
	end process read_proc;
	
	write_proc: process(clk, rst)
		variable last_set: SET_index_type;
		variable last_tag: TAG_type;
		variable last_hit_index: LINE_index_type_ext;
		variable oldest_line: LINE_index_type;
		procedure update_youth(set: SET_index_type; index_to_update: LINE_index_type) is
			variable youth_to_update: LINE_index_type_ext;
		begin
			youth_to_update:=cache(set)(index_to_update).YOUTH;
			for i in 0 to LINES_PER_SET-1 loop
				if cache(set)(i).YOUTH>youth_to_update and cache(set)(i).YOUTH/=0 then
					cache(set)(i).YOUTH<=cache(set)(i).YOUTH-1;
				end if;
			end loop;
			cache(set)(index_to_update).YOUTH<=LINES_PER_SET-1;
		end procedure update_youth;
		procedure get_oldest_line(set: SET_index_type) is
			variable smaller_youth: LINE_index_type_ext;
		begin
			smaller_youth:=LINES_PER_SET-1;
			oldest_line:=0;
			for i in 0 to LINES_PER_SET-1 loop
				if cache(set)(i).YOUTH<smaller_youth then
					smaller_youth:=cache(set)(i).YOUTH;
					oldest_line:=i;
				end if;
			end loop;
		end procedure get_oldest_line;
	begin
		if rst='0' then
			cache<=(others=>(others=>(TAG=>(others=>'0'), DATA=>(others=>'0'), YOUTH=>-1)));
			verify<='0';
			last_prediction<=(others=>'0');
			last_pc_plus4<=(others=>'0');
			last_set:=0;
			last_tag:=(others=>'0');
			last_hit_index:= -1;
		elsif rising_edge(clk) then
			if ID_EXE_EN='1' then
				if verify='1' then	--if there was a branch/jump fetch in the previous clock cycle
					if last_hit_index=-1 then	--if there was a cache miss, save the new address (both if the prediction was correct or if it was not)
						get_oldest_line(last_set);
						cache(last_set)(oldest_line).TAG<=last_tag;
						cache(last_set)(oldest_line).DATA<=actual_NPC(DATA_range);
						update_youth(last_set, oldest_line);
					else	--if there was a cache hit
						if misprediction_sig='1' then	--if there was a cache hit but a wrong prediction update the correct address
							cache(last_set)(last_hit_index).DATA<=actual_NPC(DATA_range);
							update_youth(last_set, last_hit_index);
						else --if there was a cache hit and a correct prediction
							update_youth(last_set, last_hit_index);
						end if;
					end if;
					verify<='0';
				end if;
			end if;
			if IF_ID_EN='1' then
				if (is_a_branch(IRAM_out) or is_a_jump(IRAM_out)) and misprediction_sig='0' then
					last_pc_plus4<= pc_plus4;
					last_prediction<= prediction;
					last_set:= to_integer(unsigned(pc(SET_range)));
					last_tag:= pc(TAG_range);
					last_hit_index:= hit_index;
					verify<='1';
				end if;
			end if;
		end if;
	end process write_proc;
	
	misp_proc: process(verify, last_prediction, actual_NPC)
	begin
		misprediction_sig<='0';	--default assignment
		if verify='1' and actual_NPC/=last_prediction then
			misprediction_sig<='1';
		end if;
	end process misp_proc;

end architecture behavioral;