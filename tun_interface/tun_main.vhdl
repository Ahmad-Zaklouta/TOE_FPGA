use std.textio.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.tun.all;
use work.tcp_common.all;

entity tun_main is
end tun_main;

architecture behaviour of tun_main is
	component tcp_engine is
	port(
		clk            :  in  std_ulogic;
		reset          :  in  std_ulogic;
		--------------------------------------------------------------------------------
		-- Inputs from Application
		--------------------------------------------------------------------------------
		start          :  in  std_ulogic;
		i_active_mode  :  in  std_ulogic;
		i_open         :  in  std_ulogic;     -- shall i save this to registers?
		i_timeout      :  in  unsigned (10 downto 0);
		o_established        :  out  std_ulogic;
		--------------------------------------------------------------------------------
		-- SRC IP,PORT / DST IP,PORT defined by App
		--------------------------------------------------------------------------------
		i_src_ip       :  in  t_ipv4_address;
		i_dst_ip       :  in  t_ipv4_address;
		i_src_port     :  in  t_tcp_port;
		i_dst_port     :  in  t_tcp_port;
		--------------------------------------------------------------------------------
		--between network and RX
		--------------------------------------------------------------------------------
		rx_network_tvalid : in std_ulogic;
		rx_network_tlast  : in std_ulogic;
		rx_network_tready : out std_ulogic;
		rx_network_tdata  : in std_ulogic_vector(7 downto 0);
		--------------------------------------------------------------------------------
			--between RX and  application
		--------------------------------------------------------------------------------
		rx_application_tvalid         : out std_ulogic;
		rx_application_tlast          : out std_ulogic;
		rx_application_tready         : in std_ulogic;
		rx_application_tdata          : out std_ulogic_vector(7 downto 0);
		--------------------------------------------------------------------------------
			--between TX and  network
		--------------------------------------------------------------------------------
		tx_network_tvalid : out std_ulogic;
		tx_network_tlast  : out std_ulogic;
		tx_network_tready : in std_ulogic;
		tx_network_tdata  : out std_ulogic_vector(7 downto 0);
		--------------------------------------------------------------------------------
			--between TX and  application
		--------------------------------------------------------------------------------
		tx_application_tvalid         : in std_ulogic;
		tx_application_tlast          : in std_ulogic;
		tx_application_tready         : out std_ulogic;
		tx_application_tdata          : in std_ulogic_vector(7 downto 0)
	);
	end component;

	constant clock_period : delay_length := 1 us;
	signal clock : std_ulogic;

begin
	process
	begin
		loop
			clock <= '1';
			wait for clock_period / 2;
			clock <= '0';
			wait for clock_period / 2;
		end loop;
	end process;

	process
		variable rx_packet_size : integer;
		variable out_line : line;
		variable rx_byte : integer;
		variable tx_result : integer;
	begin
		tun_init;
		loop
			wait until rising_edge(clock);
			rx_packet_size := tun_receive_packet;
			if rx_packet_size > 1 then
				--report integer'image(rx_packet_size);
				for i in 0 to rx_packet_size - 1 loop
					rx_byte := tun_read_byte;
					--write(out_line, rx_byte);
					--write(out_line, ',');
				end loop;
       			for i in 0 to 255 loop
				   tx_result := tun_write_byte(i);
				end loop;
				tx_result := tun_send_packet;
			end if;
		end loop;
	end process;
end behaviour;