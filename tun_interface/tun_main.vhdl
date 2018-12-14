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
	signal reset : std_ulogic := '1';
	signal start : std_ulogic;
	signal i_active_mode : std_ulogic;
	signal i_open        : std_ulogic;     -- shall i save this to registers?
	signal i_timeout     : unsigned (10 downto 0);
	signal o_established : std_ulogic;
	signal i_src_ip       : t_ipv4_address;
	signal i_dst_ip       : t_ipv4_address;
	signal i_src_port     : t_tcp_port;
	signal i_dst_port     : t_tcp_port;
	signal rx_network_tvalid : std_ulogic;
	signal rx_network_tlast  : std_ulogic;
	signal rx_network_tready : std_ulogic;
	signal rx_network_tdata  : std_ulogic_vector(7 downto 0);
	signal rx_application_tvalid : std_ulogic;
	signal rx_application_tlast  : std_ulogic;
	signal rx_application_tready : std_ulogic;
	signal rx_application_tdata  : std_ulogic_vector(7 downto 0);
	signal tx_network_tvalid : std_ulogic;
	signal tx_network_tlast  : std_ulogic;
	signal tx_network_tready : std_ulogic;
	signal tx_network_tdata  : std_ulogic_vector(7 downto 0);
	signal tx_application_tvalid : std_ulogic;
	signal tx_application_tlast  : std_ulogic;
	signal tx_application_tready : std_ulogic;
	signal tx_application_tdata  : std_ulogic_vector(7 downto 0);

	signal initialized : std_ulogic := '0';

begin
	tcp_engine_instance : tcp_engine port map(
		clk => clock, reset => reset,
		start => start, i_active_mode => i_active_mode, i_open => i_open, i_timeout => i_timeout, o_established => o_established,
		i_src_ip => i_src_ip, i_dst_ip => i_dst_ip, i_src_port => i_src_port, i_dst_port => i_dst_port,
		rx_network_tvalid => rx_network_tvalid, rx_network_tlast => rx_network_tlast, rx_network_tready => rx_network_tready, rx_network_tdata => rx_network_tdata,
		rx_application_tvalid => rx_application_tvalid, rx_application_tlast => rx_application_tlast, rx_application_tready => rx_application_tready, rx_application_tdata => rx_application_tdata,
		tx_network_tvalid => tx_network_tvalid, tx_network_tlast => tx_network_tlast, tx_network_tready => tx_network_tready, tx_network_tdata => tx_network_tdata,
		tx_application_tvalid => tx_application_tvalid, tx_application_tlast => tx_application_tlast, tx_application_tready => tx_application_tready, tx_application_tdata => tx_application_tdata
	);

	-- The "application" simply echoes bytes back
	tx_application_tdata <= rx_application_tdata;
	tx_application_tvalid <= rx_application_tvalid;
	rx_application_tready <= tx_application_tready;
	tx_application_tlast <= '0';

	--The network is always ready
	tx_network_tready <= '1';

	--Clock
	process
	begin
		loop
			clock <= '1';
			wait for clock_period / 2;
			clock <= '0';
			wait for clock_period / 2;
		end loop;
	end process;

	--Initialization
	process
	begin
		i_active_mode <= '0';
		start <= '1';
		i_timeout <= (others => '1');
		i_open <= '1';
		i_src_ip <= ipv4_address(10,0,0,1);
		i_dst_ip <= ipv4_address(10,0,0,2);
		i_src_port <= tcp_port(5555);
		i_dst_port <= tcp_port(5555);

		wait until rising_edge(clock);
		wait until rising_edge(clock);
		reset <= '0';
		wait until rising_edge(clock);
		tun_init;
		wait until rising_edge(clock);
		initialized <= '1';
		wait;
	end process;


		-- loop
		-- 	wait until rising_edge(clock);
		-- 	rx_packet_size := tun_receive_packet;
		-- 	if rx_packet_size > 1 then
		-- 		--report integer'image(rx_packet_size);
		-- 		for i in 0 to rx_packet_size - 1 loop
		-- 			rx_byte := tun_read_byte;
		-- 			--write(out_line, rx_byte);
		-- 			--write(out_line, ',');
		-- 		end loop;
       	-- 		for i in 0 to 255 loop
		-- 		   tx_result := tun_write_byte(i);
		-- 		end loop;
		-- 		tx_result := tun_send_packet;
		-- 	end if;
		-- end loop;

	--Receiving data from network
	process
		variable rx_byte_count : integer;
		variable rx_byte : integer;
	begin
		wait until initialized = '1';
		loop
			rx_byte_count := tun_receive_packet;
			if rx_byte_count >= 1 then
				while rx_byte_count > 0 loop
					if rx_network_tready = '1' then
						rx_byte := tun_read_byte;
						assert rx_byte >= 0 and rx_byte <= 255;
						rx_network_tdata <= std_ulogic_vector(to_unsigned(rx_byte, 8));
						rx_network_tvalid <= '1';
						if rx_byte_count = 1 then
							rx_network_tlast <= '1';
						else
							rx_network_tlast <= '0';
						end if;
						rx_byte_count := rx_byte_count - 1;
					else
						rx_network_tdata <= (others => 'U');
						rx_network_tvalid <= '0';
						rx_network_tlast <= '0';
					end if;
					wait until rising_edge(clock);
				end loop;

				rx_network_tdata <= (others => 'U');
				rx_network_tvalid <= '0';
				rx_network_tlast <= '0';
			end if;
			wait until rising_edge(clock);
		end loop;
	end process;

	--Transmitting data to network
	process
		variable tx_byte_count : integer;
		variable tx_success : integer;
	begin
		wait until initialized = '1';
		loop
			if tx_network_tvalid = '1' then
				tx_success := tun_write_byte(to_integer(unsigned(tx_application_tdata)));
				if tx_network_tlast = '1' then
					tx_success := tun_send_packet;
				end if;
			end if;
			wait until rising_edge(clock);
		end loop;
	end process;
end behaviour;