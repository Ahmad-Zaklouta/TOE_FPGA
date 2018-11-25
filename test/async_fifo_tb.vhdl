use std.textio.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library vunit_lib;

library vunit_lib;
context vunit_lib.vunit_context;
context vunit_lib.com_context;

entity async_fifo_tb is
	generic (
		runner_cfg : string
	);
end async_fifo_tb;

architecture behaviour of async_fifo_tb is
	constant DATA_WIDTH : natural := 8;
	constant ADDRESS_WIDTH : natural := 4;

	component async_fifo
	generic (
		DATA_WIDTH    : natural := 8;
		ADDRESS_WIDTH : natural := 4
	);
	port (
		reset_async : in std_ulogic;

		r_clock : in std_ulogic;
		r_allowed : out std_ulogic;
		r_available : out unsigned(ADDRESS_WIDTH downto 0);
		r_enable : in std_ulogic;
		r_data : out std_ulogic_vector(DATA_WIDTH - 1 downto 0);

		w_clock : in std_ulogic;
		w_allowed : out std_ulogic;
		w_free : out unsigned(ADDRESS_WIDTH downto 0);
		w_enable : in std_ulogic;
		w_data : in std_ulogic_vector(DATA_WIDTH - 1 downto 0)
	);
	end component async_fifo;

	signal reset_async : std_ulogic := '1';

	signal r_clock : std_ulogic := '0';
	signal r_allowed : std_ulogic;
	signal r_available : unsigned(ADDRESS_WIDTH downto 0);
	signal r_enable : std_ulogic := '0';
	signal r_data : std_ulogic_vector(DATA_WIDTH - 1 downto 0);

	signal w_clock : std_ulogic := '0';
	signal w_allowed : std_ulogic;
	signal w_free : unsigned(ADDRESS_WIDTH downto 0);
	signal w_enable : std_ulogic := '0';
	signal w_data : std_ulogic_vector(DATA_WIDTH - 1 downto 0) := (others => '0');

	signal r_clock_period : delay_length := 1 us;
	signal w_clock_period : delay_length := 1 us;

	constant main_process_receiver : actor_t := new_actor("main_process_receiver");

	procedure test_fifo (
		signal net : inout network_t;
		signal w_clock : in std_ulogic;
		signal w_allowed : in std_ulogic;
		signal w_enable : out std_ulogic;
		signal w_data : out std_ulogic_vector
	) is
		variable msg : msg_t;
		variable i : integer := 0;
		variable received_value : integer;
	begin
		i := 0;
		while i < 32 loop
			wait until falling_edge(w_clock);
			if w_allowed = '1' then
				w_data <= std_ulogic_vector(to_unsigned(i, 8));
				i := i + 1;
				w_enable <= '1';
			else
				w_enable <= '0';
			end if;
			wait until rising_edge(w_clock);
		end loop;

		for i in 0 to 31 loop
			receive(net, main_process_receiver, msg);
			received_value := pop_integer(msg);
			report "FIFO received " & to_string(received_value);
			check_equal(received_value, i);
		end loop;
	end procedure;

begin

	fifo : async_fifo generic map (
		ADDRESS_WIDTH => ADDRESS_WIDTH,
		DATA_WIDTH => DATA_WIDTH
	)
	port map(
		reset_async => reset_async,

		r_clock => r_clock,
		r_allowed => r_allowed,
		r_available => r_available,
		r_enable => r_enable,
		r_data => r_data,

		w_clock => w_clock,
		w_allowed => w_allowed,
		w_free => w_free,
		w_enable => w_enable,
		w_data => w_data
	);

	process
	begin
		loop
			r_clock <= '1';
			wait for r_clock_period / 2;
			r_clock <= '0';
			wait for r_clock_period / 2;
		end loop;
	end process;

	process
	begin
		loop
			w_clock <= '1';
			wait for w_clock_period / 2;
			w_clock <= '0';
			wait for w_clock_period / 2;
		end loop;
	end process;

	process
		variable msg : msg_t;
		variable i : integer := 0;
	begin
		loop
			if r_allowed = '1' then
				r_enable <= '1';
			else
				r_enable <= '0';
			end if;
			wait until rising_edge(r_clock);
			wait until falling_edge(r_clock);
			if r_enable = '1' then
				report "Read " & to_string(to_integer(unsigned(r_data))) & " from FIFO.";
				msg := new_msg;
				push(msg, to_integer(unsigned(r_data)));
				send(net, main_process_receiver, msg);
			else
				report "No data in FIFO";
			end if;
		end loop;
		wait;
	end process;

	process
		variable msg : msg_t;
		variable i : integer := 0;
		variable received_value : integer;
	begin
		test_runner_setup(runner, runner_cfg);

		while test_suite loop
			if run("read_faster") then
            assert false;
				r_clock_period <= 1 us;
				w_clock_period <= 2 us;
				wait for 1 us;
				reset_async <= '0';
				test_fifo(net, w_clock, w_allowed, w_enable, w_data);
			elsif run("write_faster") then
            assert false;
				r_clock_period <= 2 us;
				w_clock_period <= 1 us;
				wait for 1 us;
				reset_async <= '0';
				test_fifo(net, w_clock, w_allowed, w_enable, w_data);
			elsif run("same_speed") then
            assert false;
				r_clock_period <= 2 us;
				w_clock_period <= 1 us;
				wait for 1 us;
				reset_async <= '0';
				test_fifo(net, w_clock, w_allowed, w_enable, w_data);
			end if;
		end loop;
		test_runner_cleanup(runner);
	end process;
end behaviour;
