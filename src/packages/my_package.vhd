library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

package my_package is

	type std_logic_vector_intrange is array (integer range <>) of std_logic;	--standard logic vector with integer range
	
	--function that receives an integer greater or equal to 1 and returns its base-2 logarithm rounded up to the nearest greater (or equal) integer
	function log2_ceiling (N: positive) return natural;	
	
	--operator xor between a std_logic_vector and a signle std_logic
	function "xor" (vector: std_logic_vector; one_bit: std_logic) return std_logic_vector;
	
	--nor all bits of a generic width std_logic_vector
	function nor_vector (vector: std_logic_vector) return std_logic;
	
end package my_package;

package body my_package is

	function log2_ceiling (N: positive) return natural is
	begin
		return natural(ceil(log2(real(N))));
	end function log2_ceiling;

	function "xor" (vector: std_logic_vector; one_bit: std_logic) return std_logic_vector is
		variable temp: std_logic_vector(vector'range);
	begin
		for i in vector'range loop
			temp(i):=vector(i) xor one_bit;
		end loop;
		return temp;
	end function "xor";

	function nor_vector (vector: std_logic_vector) return std_logic is
		variable temp: std_logic:='0';
	begin
		for i in vector'range loop
			temp:= temp or vector(i);
		end loop;
		return not temp;
	end function nor_vector;

end package body my_package;