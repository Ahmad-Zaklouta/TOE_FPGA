library ieee;
use ieee.std_logic_1164.all;

package gray_code is
	function to_gray(bin : std_ulogic_vector) return std_ulogic_vector;
	function to_bin(gray : std_ulogic_vector) return std_ulogic_vector;
end package gray_code;

package body gray_code is
	function to_gray(bin : std_ulogic_vector) return std_ulogic_vector is
		variable gray : std_ulogic_vector(bin'range) := (others => '0');
	begin
		for i in bin'low to bin'high - 1 loop
			gray(i) := bin(i) xor bin(i + 1);
		end loop;
		gray(bin'high) := bin(bin'high);
		return gray;
	end function;

	function to_bin(gray : std_ulogic_vector) return std_ulogic_vector is
		variable bin : std_ulogic_vector(gray'range) := (others => '0');
	begin
		bin(gray'high) := gray(gray'high);
		for i in gray'high - 1 downto gray'low loop
			bin(i) := gray(i) xor bin(i + 1);
		end loop;
		return bin;
	end function;
end gray_code;