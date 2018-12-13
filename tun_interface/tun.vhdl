package tun is
	procedure tun_init;
	attribute foreign of tun_init : procedure is "VHPIDIRECT tun_init";

	function tun_receive_packet return integer;
	attribute foreign of tun_receive_packet : function is "VHPIDIRECT tun_receive_packet";

	function tun_read_byte return integer;
	attribute foreign of tun_read_byte : function is "VHPIDIRECT tun_read_byte";

	function tun_send_packet return integer;
	attribute foreign of tun_send_packet : function is "VHPIDIRECT tun_send_packet";

	function tun_write_byte(byte : integer) return integer;
	attribute foreign of tun_write_byte : function is "VHPIDIRECT tun_write_byte";
end tun;

package body tun is
	procedure tun_init is
	begin
		assert false severity failure;
	end tun_init;

	function tun_receive_packet return integer is
	begin
		assert false severity failure;
	end tun_receive_packet;

	function tun_read_byte return integer is
	begin
		assert false severity failure;
	end tun_read_byte;

	function tun_send_packet return integer is
	begin
		assert false severity failure;
	end tun_send_packet;

	function tun_write_byte(byte : integer) return integer is
	begin
		assert false severity failure;
	end tun_write_byte;
end tun;