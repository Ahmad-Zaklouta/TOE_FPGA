use std.textio.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library vunit_lib;
context vunit_lib.vunit_context;

library work;
use work.gray_code.all;

entity gray_code_tb is
	generic (
		runner_cfg : string
	);
end gray_code_tb;

architecture behaviour of gray_code_tb is
begin
	process
		constant a : bit_vector(3 downto 0) := "1011";
		variable x : std_ulogic_vector(5 downto 0);
	begin
		test_runner_setup(runner, runner_cfg);
		while test_suite loop
			if run("simple") then
				for i in 0 to 63 loop
					x := std_ulogic_vector(to_unsigned(i, 6));
					assert x = to_bin(to_gray(x));
					assert x = to_gray(to_bin(x));
				end loop;
			end if;
		end loop;
		test_runner_cleanup(runner);
	end process;
end behaviour;
