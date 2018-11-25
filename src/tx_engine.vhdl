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
		--Transfer one byte at a time through the busses.
		DATA_WIDTH : natural := 8;
		MTU : natural := 1024;
		APP_BUF_WIDTH : natural := 16;
		NET_BUF_WIDTH : natural := 12
	);
	port (
		--Clocked on rising edge
		clock : in std_ulogic;
		--Synchronous reset
		i_reset : in std_ulogic;

		--AXI stream for input data from application
		i_app_axi_data : in std_ulogic_vector(DATA_WIDTH - 1 downto 0);
		i_app_axi_valid : in std_ulogic;
		o_app_axi_ready : out std_ulogic;
		--Last signal will indicate TCP engine should flush buffer ASAP
		i_app_axi_last : in std_ulogic;

		--AXI stream outputting to network interface
		o_net_axi_data : out std_ulogic_vector(DATA_WIDTH - 1 downto 0);
		o_net_axi_valid : out std_ulogic;
		i_net_axi_ready : in std_ulogic;
		--Last signal will indicate the end of a packet
		o_net_axi_last : out std_ulogic;

		--Sequence number acknowledged by reciever. When this value increases,
		--space in the buffer is freed.
		i_ctrl_ack_num : in t_seq_num;
		--Header with the packet to send. Must be valid for one clock cycle with
		--when i_tx_start is high.
		i_ctrl_packet_header : in t_tcp_header;
		--Length of data to insert in packet.  Must be valid for one clock cycle
		--with when i_tx_start is high.
		i_ctrl_packet_data_length : in unsigned(APP_BUF_WIDTH - 1 downto 0);
		--Set high for a single clock cycle to start transmission of a packet.
		i_ctrl_tx_start : in std_ulogic;
		--Outputs how many bytes are available in the buffer to transmit.
		o_ctrl_data_bytes_available : out unsigned(APP_BUF_WIDTH - 1 downto 0);
		--Outputs high only when the TX engine is free to send another packet.
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
	signal app_buf_write_enable : std_ulogic;
	signal app_buf_read_possible : std_ulogic;
	signal app_buf_write_possible : std_ulogic;
	signal app_buf_read_data : t_byte;


	signal net_buf_read_ptr : unsigned(APP_BUF_WIDTH downto 0);
	signal net_buf_write_enable : std_ulogic;
	signal net_buf_write_possible : std_ulogic;
	signal net_buf_read_possible : std_ulogic;
	signal net_buf_write_data : t_byte;

	signal app_buf_free_ptr : unsigned(APP_BUF_WIDTH downto 0);

	type t_registers is record
		app_buf_read_ptr : unsigned(APP_BUF_WIDTH downto 0);

		net_buf_write_ptr : unsigned(APP_BUF_WIDTH downto 0);
		net_buf_valid_ptr : unsigned(APP_BUF_WIDTH downto 0);

		tx_state : integer range 0 to 10;
		tx_header_byte : integer range 0 to 63;
		tx_data_byte : integer range 0 to 65535;
		tx_packet_header : t_tcp_header;
		tx_packet_data_length : integer range 0 to 65535;
	end record;

	signal reg : t_registers;
	signal nxt : t_registers;

begin
	app_buf : dual_port_ram generic map (DATA_WIDTH, APP_BUF_WIDTH)
	port map(
		a_clock => clock,
		a_address => std_ulogic_vector(app_buf_write_ptr(APP_BUF_WIDTH - 1 downto 0)),
		a_data_in => i_app_axi_data,
		a_data_out => open,
		a_write_enable => app_buf_write_enable,

		b_clock => clock,
		b_address => std_ulogic_vector(nxt.app_buf_read_ptr(APP_BUF_WIDTH - 1 downto 0)),
		b_data_in => (others => '0'),
		b_data_out => app_buf_read_data,
		b_write_enable => '0'
	);

	net_buf : dual_port_ram generic map (DATA_WIDTH, NET_BUF_WIDTH)
	port map(
		a_clock => clock,
		a_address => std_ulogic_vector(nxt.net_buf_write_ptr(NET_BUF_WIDTH - 1 downto 0)),
		a_data_in => net_buf_write_data,
		a_data_out => open,
		a_write_enable => net_buf_write_enable,

		b_clock => clock,
		b_address => std_ulogic_vector(net_buf_read_ptr(NET_BUF_WIDTH - 1 downto 0)),
		b_data_in => (others => '0'),
		b_data_out => o_net_axi_data,
		b_write_enable => '0'
	);

	app_buf_free_ptr <= i_ctrl_ack_num(APP_BUF_WIDTH downto 0);

	app_buf_write_possible <= '0' when (app_buf_write_ptr - app_buf_free_ptr = 2**APP_BUF_WIDTH) else '1';
	app_buf_write_enable <= app_buf_write_possible and i_app_axi_valid;
	app_buf_read_possible <= '0' when (reg.app_buf_read_ptr - app_buf_write_ptr = 2**APP_BUF_WIDTH) else '1';

	net_buf_write_possible <= '0' when (reg.net_buf_write_ptr - net_buf_read_ptr = 2**NET_BUF_WIDTH) else '1';
	net_buf_read_possible <= '0' when (net_buf_read_ptr - reg.net_buf_valid_ptr = 2**APP_BUF_WIDTH) else '1';

	o_ctrl_ready <= '1' when reg.tx_state = 0 else '0';
	o_app_axi_ready <= app_buf_write_possible;

	process (all)
	begin
		net_buf_write_data <= (others => '-');
		net_buf_write_enable <= '0';

		nxt <= reg;

		case reg.tx_state is
			when 0 => --waiting
				if i_ctrl_tx_start <= '1' then
					nxt.tx_packet_header <= i_ctrl_packet_header;
					nxt.tx_packet_header.checksum <=
						std_ulogic_vector(i_ctrl_packet_data_length) xor
						i_ctrl_packet_header.src_ip(31 downto 16) xor
						i_ctrl_packet_header.src_ip(15 downto 0) xor
						i_ctrl_packet_header.dst_ip(31 downto 16) xor
						i_ctrl_packet_header.dst_ip(15 downto 0) xor
						std_ulogic_vector(i_ctrl_packet_header.src_port) xor
						std_ulogic_vector(i_ctrl_packet_header.dst_port) xor
						std_ulogic_vector(i_ctrl_packet_header.seq_num(31 downto 16)) xor
						std_ulogic_vector(i_ctrl_packet_header.seq_num(15 downto 0)) xor
						std_ulogic_vector(i_ctrl_packet_header.ack_num(31 downto 16)) xor
						std_ulogic_vector(i_ctrl_packet_header.ack_num(15 downto 0)) xor
						(std_ulogic_vector(i_ctrl_packet_header.data_offset) & "000" & i_ctrl_packet_header.flags) xor
						std_ulogic_vector(i_ctrl_packet_header.window_size) xor
						std_ulogic_vector(i_ctrl_packet_header.urgent_ptr);
					nxt.tx_packet_data_length <= to_integer(i_ctrl_packet_data_length);
					nxt.tx_header_byte <= 0;
					nxt.tx_data_byte <= 0;
					nxt.tx_state <= 1;
				end if;
			when 1 =>
				if net_buf_write_possible = '1' then
					net_buf_write_data <= tcp_header_get_byte(reg.tx_packet_header, reg.tx_header_byte);
					nxt.net_buf_write_ptr <= reg.net_buf_write_ptr + 1;
					net_buf_write_enable <= '1';
					nxt.tx_header_byte <= reg.tx_header_byte + 1;
					if reg.tx_header_byte = 27 then
						nxt.tx_state <= nxt.tx_state + 1;
						nxt.app_buf_read_ptr <= app_buf_free_ptr;
					end if;
				end if;
			when 2 =>
				if net_buf_write_possible = '1' then
					net_buf_write_data <= app_buf_read_data;
					if (reg.tx_data_byte mod 2) = 0 then
						nxt.tx_packet_header.checksum(15 downto 8) <= reg.tx_packet_header.checksum(15 downto 8) xor app_buf_read_data;
					else
						nxt.tx_packet_header.checksum(7 downto 0) <= reg.tx_packet_header.checksum(7 downto 0) xor app_buf_read_data;
					end if;
					nxt.net_buf_write_ptr <= reg.net_buf_write_ptr + 1;
					net_buf_write_enable <= '1';
					nxt.tx_data_byte <= reg.tx_header_byte + 1;
					if reg.tx_data_byte = nxt.tx_packet_data_length then
						nxt.tx_state <= nxt.tx_state + 1;
					end if;
				end if;
			when 3 =>
				nxt.net_buf_valid_ptr <= reg.net_buf_write_ptr;
				nxt.tx_state <= 0;
			when others =>
				assert false;
		end case;
	end process;


	process (clock)
	begin
		if rising_edge(clock) then
			if i_reset = '1' then
				app_buf_write_ptr <= app_buf_free_ptr;

				net_buf_read_ptr <= (others => '0');

				reg <= (
					tx_state => 0,
					tx_header_byte => 0,
					tx_data_byte => 0,
					tx_packet_header => c_default_tcp_header,
					tx_packet_data_length => 0,

					app_buf_read_ptr => app_buf_free_ptr,
					net_buf_write_ptr => (others => '0'),
					net_buf_valid_ptr => (others => '0')
				);
			else
				if app_buf_write_possible = '1' and i_app_axi_valid = '1' then
					app_buf_write_ptr <= app_buf_write_ptr + 1;
				end if;
				reg <= nxt;
			end if;
		end if;
	end process;

end architecture behaviour;