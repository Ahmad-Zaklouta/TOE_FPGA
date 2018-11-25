library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package tcp_common is
	subtype t_ipv4_address is std_ulogic_vector(31 downto 0);
	subtype t_tcp_port is unsigned(15 downto 0);
	subtype t_seq_num is unsigned(31 downto 0);
	subtype t_byte is std_ulogic_vector(7 downto 0);

	type t_tcp_header is record
		src_ip : t_ipv4_address;
		dst_ip : t_ipv4_address;
		length : unsigned(15 downto 0);
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

	function ipv4_address (
		b0 : integer range 0 to 255;
		b1 : integer range 0 to 255;
		b2 : integer range 0 to 255;
		b3 : integer range 0 to 255
	) return t_ipv4_address;

	function tcp_port (
		n : integer range 0 to 65535
	) return t_tcp_port;
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
end tcp_common;