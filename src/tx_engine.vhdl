use std.textio.all;
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.tcp_common.all;

library work;
use work.gray_code.all;

entity tx_buffer is
	generic (
		DATA_WIDTH    : natural := 8;
		MTU : natural := 1024;
		APP_BUF_WIDTH : natural := 16;
		NET_BUF_WIDTH : natural := 12
	);
	port (
		clock : in std_ulogic;
		i_reset : in std_ulogic;

		i_app_axi_data : in std_ulogic_vector(DATA_WIDTH - 1 downto 0);
		i_app_axi_valid : in std_ulogic;
		o_app_axi_ready : out std_ulogic;
		i_app_axi_last : in std_ulogic;

		o_net_axi_data : out std_ulogic_vector(DATA_WIDTH - 1 downto 0);
		o_net_axi_valid : out std_ulogic;
		i_net_axi_ready : in std_ulogic;
		o_net_axi_last : out std_ulogic;

		i_ctrl_packet_header : in t_tcp_header;
		i_ctrl_data_bytes_available : out unsigned(APP_BUF_WIDTH - 1 downto 0);
		i_ctrl_tx_start : in std_ulogic;
		o_ctrl_ready : out std_ulogic
	);
end tx_buffer;

architecture behaviour of tx_buffer is
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

	signal app_buf_write_ptr : unsigned(APP_BUF_WIDTH downto 0);
	signal app_buf_free_ptr : unsigned(APP_BUF_WIDTH downto 0);
	signal app_buf_read_ptr : unsigned(APP_BUF_WIDTH downto 0);
	signal app_buf_write_enable : std_ulogic;
	signal app_buf_data : t_byte;

	signal net_buf_write_ptr : unsigned(APP_BUF_WIDTH downto 0);
	signal net_buf_valid_ptr : unsigned(APP_BUF_WIDTH downto 0);
	signal net_buf_read_ptr : unsigned(APP_BUF_WIDTH downto 0);
	signal net_buf_write_enable : std_ulogic;
	signal net_buf_data : t_byte;

	signal tx_state : integer range 0 to 10;
	signal tx_data_byte : integer range 0 to 65535;
	signal tx_packet_header : t_tcp_header;

begin
	app_buf : dual_port_ram generic map (DATA_WIDTH, APP_BUF_WIDTH)
	port map(
		a_clock => clock,
		a_address => std_ulogic_vector(app_buf_write_ptr(APP_BUF_WIDTH - 1 downto 0)),
		a_data_in => i_app_axi_data,
		a_data_out => open,
		a_write_enable => app_buf_write_enable,

		b_clock => clock,
		b_address => std_ulogic_vector(app_buf_read_ptr(APP_BUF_WIDTH - 1 downto 0)),
		b_data_in => (others => '0'),
		b_data_out => app_buf_data,
		b_write_enable => '0'
	);

	net_buf : dual_port_ram generic map (DATA_WIDTH, NET_BUF_WIDTH)
	port map(
		a_clock => clock,
		a_address => std_ulogic_vector(net_buf_write_ptr(NET_BUF_WIDTH - 1 downto 0)),
		a_data_in => net_buf_data,
		a_data_out => open,
		a_write_enable => net_buf_write_enable,

		b_clock => clock,
		b_address => std_ulogic_vector(net_buf_read_ptr(NET_BUF_WIDTH - 1 downto 0)),
		b_data_in => (others => '0'),
		b_data_out => o_net_axi_data,
		b_write_enable => '0'
	);

	o_ctrl_ready <= '1' when tx_state = 0 else '0';

	process (clock)
	begin
		if rising_edge(clock) then
			if i_reset = '1' then
				app_buf_write_ptr <= (others => '0');
				app_buf_read_ptr <= (others => '0');
				app_buf_free_ptr <= (others => '0');

				net_buf_write_ptr <= (others => '0');
				net_buf_read_ptr <= (others => '0');
				net_buf_valid_ptr <= (others => '0');

				tx_state <= 0;
				tx_data_byte <= 0;
				tx_packet_header <= c_default_tcp_header;

			else
				case tx_state is
					when 0 => --Waiting
						if i_ctrl_tx_start = '1' then
							tx_packet_header <= i_ctrl_packet_header;
						end if;
					when others =>
						tx_state <= 0;
				end case;
			end if;
		end if;
	end process;

end architecture behaviour;