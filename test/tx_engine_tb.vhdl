use std.textio.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library vunit_lib;
context vunit_lib.vunit_context;

entity tx_engine_tb is
	generic (
		runner_cfg : string
	);
end tx_engine_tb;

architecture behaviour of tx_engine_tb is
	constant DATA_WIDTH : natural := 8;

	procedure pulse (
		signal clock : out std_ulogic
	) is
	begin
		clock <= '0';
		wait for 1 us;
		clock <= '1';
		wait for 1 us;
	end procedure;





begin


	process

	begin
		test_runner_setup(runner, runner_cfg);

		while test_suite loop
			if run("simple") then

			end if;
		end loop;
		test_runner_cleanup(runner);
	end process;
end behaviour;
