library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.CU_package.all;

entity branch_comp is
	generic(N: integer:= 32);	--number of data-in bits
	port(
		BRANCH_COND		: in BRANCH_COND_type;					--condition to take branch
		DATA_IN1		: in std_logic_vector(N-1 downto 0);	--data to test
		DATA_IN2		: in std_logic_vector(N-1 downto 0);	--data to test
		BRANCH_IS_TAKEN	: out std_logic);						--high if the branch is taken
end entity branch_comp;

architecture behavioral of branch_comp is
begin

	branch_comparator_process: process(BRANCH_COND, DATA_IN1, DATA_IN2)
	begin
		case BRANCH_COND is
			when BRANCH_COND_NO =>
				BRANCH_IS_TAKEN<='0';
			when BRANCH_COND_ALWAYS =>
				BRANCH_IS_TAKEN<='1';
			when BRANCH_COND_EQ =>
				if DATA_IN1=DATA_IN2 then
					BRANCH_IS_TAKEN<='1';
				else
					BRANCH_IS_TAKEN<='0';
				end if;
			when BRANCH_COND_NE =>
				if DATA_IN1/=DATA_IN2 then
					BRANCH_IS_TAKEN<='1';
				else
					BRANCH_IS_TAKEN<='0';
				end if;
			when BRANCH_COND_LT =>
				if signed(DATA_IN1)<signed(DATA_IN2) then
					BRANCH_IS_TAKEN<='1';
				else
					BRANCH_IS_TAKEN<='0';
				end if;
			when BRANCH_COND_GE =>
				if signed(DATA_IN1)>=signed(DATA_IN2) then
					BRANCH_IS_TAKEN<='1';
				else
					BRANCH_IS_TAKEN<='0';
				end if;
			when BRANCH_COND_LTU =>
				if unsigned(DATA_IN1)<unsigned(DATA_IN2) then
					BRANCH_IS_TAKEN<='1';
				else
					BRANCH_IS_TAKEN<='0';
				end if;
			when BRANCH_COND_GEU =>
				if unsigned(DATA_IN1)>=unsigned(DATA_IN2) then
					BRANCH_IS_TAKEN<='1';
				else
					BRANCH_IS_TAKEN<='0';
				end if;
		end case;
	end process branch_comparator_process;

end architecture behavioral;