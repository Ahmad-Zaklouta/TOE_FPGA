use std.textio.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library vunit_lib;
context vunit_lib.vunit_context;

entity dual_port_ram_tb is
	generic (
		runner_cfg : string
	);
end dual_port_ram_tb;

architecture behaviour of dual_port_ram_tb is
	constant DATA_WIDTH : natural := 16;
	constant ADDRESS_WIDTH : natural := 4;

	procedure pulse (
		signal clock : out std_ulogic
	) is
	begin
		clock <= '0';
		wait for 1 us;
		clock <= '1';
		wait for 1 us;
	end procedure;

	component dual_port_ram
	generic (
		DATA_WIDTH    : natural;
		ADDRESS_WIDTH : natural
	);
	port (
		a_clock : in std_ulogic;
		a_address : in std_ulogic_vector(ADDRESS_WIDTH - 1 downto 0);
		a_data_in : in std_ulogic_vector(DATA_WIDTH - 1 downto 0);
		a_data_out : out std_ulogic_vector(DATA_WIDTH - 1 downto 0);
		a_write_enable : in std_ulogic;

		b_clock : in std_ulogic;
		b_address : in std_ulogic_vector(ADDRESS_WIDTH - 1 downto 0);
		b_data_in : in std_ulogic_vector(DATA_WIDTH - 1 downto 0);
		b_data_out : out std_ulogic_vector(DATA_WIDTH - 1 downto 0);
		b_write_enable : in std_ulogic
	);
	end component;

	signal a_clock : std_ulogic;
	signal a_address : std_ulogic_vector(ADDRESS_WIDTH - 1 downto 0);
	signal a_data_in : std_ulogic_vector(DATA_WIDTH - 1 downto 0);
	signal a_data_out : std_ulogic_vector(DATA_WIDTH - 1 downto 0);
	signal a_write_enable : std_ulogic;

	signal b_clock : std_ulogic;
	signal b_address : std_ulogic_vector(ADDRESS_WIDTH - 1 downto 0);
	signal b_data_in : std_ulogic_vector(DATA_WIDTH - 1 downto 0);
	signal b_data_out : std_ulogic_vector(DATA_WIDTH - 1 downto 0);
	signal b_write_enable : std_ulogic;

begin

	ram : dual_port_ram generic map (
		ADDRESS_WIDTH => ADDRESS_WIDTH,
		DATA_WIDTH => DATA_WIDTH
	)
	port map(
		a_clock => a_clock,
		a_address => a_address,
		a_data_in => a_data_in,
		a_data_out => a_data_out,
		a_write_enable => a_write_enable,
		b_clock => b_clock,
		b_address => b_address,
		b_data_in => b_data_in,
		b_data_out => b_data_out,
		b_write_enable => b_write_enable
	);

	process

	begin
		test_runner_setup(runner, runner_cfg);

		while test_suite loop
			if run("simple") then
				--pulse(a_clock);
				--pulse(b_clock);
				b_write_enable <= '0';
				a_write_enable <= '1';
				for i in 0 to 15 loop
					a_address <= std_ulogic_vector(to_unsigned(i, 4));
					a_data_in <= std_ulogic_vector(to_unsigned(i + 1, 16));
					pulse(a_clock);
					--report "wrote " & to_string(a_data_in) & " to " & to_string(a_address);
					--report "read " & to_string(a_data_out) & " from " & to_string(a_address);
					assert a_data_out = std_ulogic_vector(to_unsigned(i + 1, 16));
				end loop;
				a_write_enable <= '0';

				for i in 0 to 15 loop
					b_address <= std_ulogic_vector(to_unsigned(i, 4));
					pulse(b_clock);
					--report "read " & to_string(b_data_out) & " from " & to_string(b_address);
					assert b_data_out = std_ulogic_vector(to_unsigned(i + 1, 16));
				end loop;
			end if;
		end loop;
		test_runner_cleanup(runner);
	end process;
end behaviour;
