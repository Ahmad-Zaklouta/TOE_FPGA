library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package tcp_common is
	subtype t_ipv4_address is std_ulogic_vector(31 downto 0);
	subtype t_tcp_port is unsigned(15 downto 0);
	subtype t_seq_num is unsigned(31 downto 0);
	subtype t_byte is std_ulogic_vector(7 downto 0);
	--type t_tcp_header_buffer is array (19 downto 0);

	type t_tcp_header is record
		src_ip : t_ipv4_address;
		dst_ip : t_ipv4_address;
		--length : unsigned(15 downto 0);
		src_port : t_tcp_port;
		dst_port : t_tcp_port;
		seq_num : t_seq_num;
		ack_num : t_seq_num;
		data_offset : unsigned(3 downto 0);
		reserved : std_ulogic_vector(2 downto 0);
		flags : std_ulogic_vector(8 downto 0);
		window_size : unsigned(15 downto 0);
		checksum : std_ulogic_vector(15 downto 0);
		urgent_ptr : unsigned(15 downto 0);
	end record;

	function tcp_header_get_byte (
		header : t_tcp_header;
		index : integer range 0 to 27
	) return t_byte;

	function ipv4_address (
		b0 : integer range 0 to 255;
		b1 : integer range 0 to 255;
		b2 : integer range 0 to 255;
		b3 : integer range 0 to 255
	) return t_ipv4_address;

	function tcp_port (
		n : integer range 0 to 65535
	) return t_tcp_port;

	constant c_default_tcp_header : t_tcp_header := (
		src_ip => (others => '0'),
		dst_ip => (others => '0'),
		--length => (others => '0'),
		src_port => (others => '0'),
		dst_port => (others => '0'),
		seq_num => (others => '0'),
		ack_num => (others => '0'),
		data_offset => (others => '0'),
		reserved => (others => '0'),
		flags => (others => '0'),
		window_size => (others => '0'),
		checksum => (others => '0'),
		urgent_ptr => (others => '0')
	);

end package tcp_common;

package body tcp_common is
	function ipv4_address (
		b0 : integer range 0 to 255;
		b1 : integer range 0 to 255;
		b2 : integer range 0 to 255;
		b3 : integer range 0 to 255
	) return t_ipv4_address is
		variable addr : std_ulogic_vector(31 downto 0) := (others => '0');
	begin
		addr(7 downto 0) := std_ulogic_vector(to_unsigned(b0, 8));
		addr(15 downto 8) := std_ulogic_vector(to_unsigned(b1, 8));
		addr(23 downto 16) := std_ulogic_vector(to_unsigned(b2, 8));
		addr(31 downto 24) := std_ulogic_vector(to_unsigned(b3, 8));
		return addr;
	end function;

	function tcp_port (
		n : integer range 0 to 65535
	) return t_tcp_port is
	begin
		return to_unsigned(n, t_tcp_port'length);
	end function;

	function tcp_header_get_byte (
		header : t_tcp_header;
		index : integer range 0 to 27
	) return t_byte is
		variable ret : std_ulogic_vector(7 downto 0);
	begin
		case index is
			when  0 => ret := header.src_ip(31 downto 24);
			when  1 => ret := header.src_ip(23 downto 16);
			when  2 => ret := header.src_ip(15 downto  8);
			when  3 => ret := header.src_ip( 7 downto  0);

			when  4 => ret := header.dst_ip(31 downto 24);
			when  5 => ret := header.dst_ip(23 downto 16);
			when  6 => ret := header.dst_ip(15 downto  8);
			when  7 => ret := header.dst_ip( 7 downto  0);

			when  8 => ret := std_ulogic_vector(header.src_port(15 downto 8));
			when  9 => ret := std_ulogic_vector(header.src_port( 7 downto 0));
			when 10 => ret := std_ulogic_vector(header.dst_port(15 downto 8));
			when 11 => ret := std_ulogic_vector(header.dst_port( 7 downto 0));

			when 12 => ret := std_ulogic_vector(header.seq_num(31 downto 24));
			when 13 => ret := std_ulogic_vector(header.seq_num(23 downto 16));
			when 14 => ret := std_ulogic_vector(header.seq_num(15 downto  8));
			when 15 => ret := std_ulogic_vector(header.seq_num( 7 downto  0));

			when 16 => ret := std_ulogic_vector(header.ack_num(31 downto 24));
			when 17 => ret := std_ulogic_vector(header.ack_num(23 downto 16));
			when 18 => ret := std_ulogic_vector(header.ack_num(15 downto  8));
			when 19 => ret := std_ulogic_vector(header.ack_num( 7 downto  0));

			when 20 => ret := std_ulogic_vector(header.data_offset & "000" & header.flags(8));
			when 21 => ret := header.flags(7 downto 0);
			when 22 => ret := std_ulogic_vector(header.window_size(15 downto 8));
			when 23 => ret := std_ulogic_vector(header.window_size( 7 downto 0));

			when 24 => ret := header.checksum(15 downto 8);
			when 25 => ret := header.checksum( 7 downto 0);
			when 26 => ret := std_ulogic_vector(header.window_size(15 downto 8));
			when 27 => ret := std_ulogic_vector(header.window_size( 7 downto 0));
		end case;
		return ret;
	end function;

end tcp_common;
