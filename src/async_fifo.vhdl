use std.textio.all;
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.gray_code.all;

entity async_fifo is
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
end async_fifo;

architecture behaviour of async_fifo is
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

	signal r_r_address : unsigned(ADDRESS_WIDTH downto 0);
	signal sync1_r_address : std_ulogic_vector(ADDRESS_WIDTH downto 0);
	signal sync2_r_address : std_ulogic_vector(ADDRESS_WIDTH downto 0);
	signal sync3_r_address : std_ulogic_vector(ADDRESS_WIDTH downto 0);
	signal w_r_address : unsigned(ADDRESS_WIDTH downto 0);

	signal mem_w_enable : std_ulogic;

	signal w_w_address : unsigned(ADDRESS_WIDTH downto 0);
	signal sync1_w_address : std_ulogic_vector(ADDRESS_WIDTH downto 0);
	signal sync2_w_address : std_ulogic_vector(ADDRESS_WIDTH downto 0);
	signal sync3_w_address : std_ulogic_vector(ADDRESS_WIDTH downto 0);
	signal r_w_address : unsigned(ADDRESS_WIDTH downto 0);

	signal r_possible : std_ulogic;
	signal w_possible : std_ulogic;
begin
	ram : dual_port_ram generic map (DATA_WIDTH, ADDRESS_WIDTH)
	port map(
		a_clock => w_clock,
		a_address => std_ulogic_vector(w_w_address(3 downto 0)),
		a_data_in => w_data,
		a_data_out => open,
		a_write_enable => mem_w_enable,

		b_clock => r_clock,
		b_address => std_ulogic_vector(r_r_address(3 downto 0)),
		b_data_in => (others => '0'),
		b_data_out => r_data,
		b_write_enable => '0'
	);

	r_w_address <= unsigned(to_bin(sync3_w_address));
	r_available <= r_w_address - r_r_address;
	r_possible <= '0' when (r_w_address - r_r_address = 0) else '1';
	r_allowed <= r_possible;

	process (r_clock, reset_async)
	begin
		if reset_async = '1' then
			r_r_address <= (others => '0');
			sync1_r_address <= (others => '0');
			sync2_w_address <= (others => '0');
			sync3_w_address <= (others => '0');
		elsif rising_edge(r_clock) then
			--pull write address from domain boundary
			sync2_w_address <= sync1_w_address;
			sync3_w_address <= sync2_w_address;

			if (r_possible = '1') and (r_enable = '1') then
				r_r_address <= r_r_address + 1;
				--push read address over domain boundary
				sync1_r_address <= to_gray(std_ulogic_vector(r_r_address + 1));
			end if;
		end if;
	end process;

	process (w_clock, reset_async)
	begin
		if reset_async = '1' then
			sync1_w_address <= (others => '0');
			w_w_address <= (others => '0');
			sync2_r_address <= (others => '0');
			sync3_r_address <= (others => '0');
		elsif rising_edge(w_clock) then
			--pull read address from domain boundary
			sync2_r_address <= sync1_r_address;
			sync3_r_address <= sync2_r_address;

			if (w_possible = '1') and (w_enable = '1') then
				w_w_address <= w_w_address + 1;
				--push write address over domain boundary
				sync1_w_address <= to_gray(std_ulogic_vector(w_w_address + 1));
			end if;
		end if;
	end process;

	w_r_address <= unsigned(to_bin(sync3_r_address));
	w_free <= 2**ADDRESS_WIDTH - (w_w_address - w_r_address);
	w_possible <= '0' when (w_w_address - w_r_address = 2**ADDRESS_WIDTH) else '1';
	w_allowed <= w_possible;

	mem_w_enable <= w_possible and w_enable;

end architecture behaviour;