LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;

library work;
use work.tcp_common.all;

entity testbench_toe is
end testbench_toe;

architecture behavioural of testbench_toe is



component application is
  port(
       clk : in std_ulogic;
	   reset: in std_ulogic;
	   
       o_start          :  out std_ulogic;
	   o_active_mode  :  out  std_ulogic;
	   o_open         :  out std_ulogic;     
	   o_timeout      :  out  unsigned (10 downto 0);
	   i_close        :  in  std_ulogic;
	   ---------------------------------------------
	   -- SRC IP,PORT / DST IP,PORT defined by App 
	   ---------------------------------------------
	   o_src_ip       : out   t_ipv4_address;
	   o_dst_ip       : out   t_ipv4_address;
	   o_src_port     : out   t_tcp_port;
	   o_dst_port     : out   t_tcp_port;
	   
       rx_tdata: in std_ulogic_vector(7 downto 0);
       rx_tvalid: in std_ulogic;
	   rx_tready: out std_ulogic;
	   rx_tlast: in std_ulogic;
	   
	   tx_tdata: out std_ulogic_vector(7 downto 0);
	   tx_tvalid: out std_ulogic;
	   tx_tready: in std_ulogic;
	   tx_tlast: out std_ulogic
	   );
	   
end component;

component Top is
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


signal clk, reset: std_ulogic := '0';

signal start_internal, active_mode_internal, open_internal, close_internal: std_ulogic;
signal timeout_internal: unsigned(10 downto 0);
signal src_ip_internal, dst_ip_internal: t_ipv4_address;
signal src_port_internal, dst_port_internal: t_tcp_port;
signal app_rx_tdata_internal, app_tx_tdata_internal: std_ulogic_vector(7 downto 0);
signal app_rx_tvalid, app_tx_tvalid, app_rx_tready, 
		app_tx_tready, app_rx_tlast, app_tx_tlast: std_ulogic;
signal tx_tready1_internal, tx_tready2_internal, tx_tvalid1_internal, tx_tvalid2_internal, tx_tlast1_internal, tx_tlast2_internal: std_ulogic;
signal rx_tready1_internal, rx_tready2_internal, rx_tvalid1_internal, rx_tvalid2_internal, rx_tlast1_internal, rx_tlast2_internal: std_ulogic;
signal rx_tdata1_internal, rx_tdata2_internal, tx_tdata1_internal, tx_tdata2_internal: std_ulogic_vector(7 downto 0);

begin

reset<='1', '0' after 50 ns;
clk_proc: process(clk)
begin
    clk <= not clk after 5 ns;
end process;


app: application port map(clk => clk, reset => reset,
						  o_start => start_internal, o_active_mode => active_mode_internal, o_open => open_internal, o_timeout => timeout_internal, i_close => close_internal,
						  o_src_ip => src_ip_internal, o_dst_ip => dst_ip_internal, o_src_port => src_port_internal, o_dst_port => dst_port_internal,
						  rx_tdata => app_rx_tdata_internal, tx_tdata => app_tx_tdata_internal, rx_tvalid => app_rx_tvalid, tx_tready => app_tx_tready,
						  rx_tready => app_rx_tready, rx_tlast => app_rx_tlast, tx_tlast => app_tx_tlast);

top1: Top port map(clk => clk, reset => reset,
				   start => start_internal, i_active_mode => active_mode_internal, i_open => open_internal, i_timeout => timeout_internal, o_established => close_internal,
				   i_src_ip => src_ip_internal, i_dst_ip => dst_ip_internal, i_src_port => src_port_internal, i_dst_port => dst_port_internal,
				   rx_network_tvalid => rx_tvalid1_internal, rx_network_tlast => rx_tlast1_internal, rx_network_tready => rx_tready1_internal, rx_network_tdata => rx_tdata1_internal,
				   rx_application_tvalid => app_rx_tvalid, rx_application_tlast => app_rx_tlast, rx_application_tready => app_rx_tready, rx_application_tdata => app_rx_tdata_internal,
				   tx_network_tvalid => tx_tvalid1_internal, tx_network_tlast => tx_tlast1_internal, tx_network_tready => tx_tready1_internal, tx_network_tdata => tx_tdata1_internal,
				   tx_application_tvalid => app_tx_tvalid, tx_application_tlast => app_tx_tlast, tx_application_tready => app_tx_tready, tx_application_tdata => app_tx_tdata_internal);
top2: Top port map(clk => clk, reset => reset,
				   start => '1', i_active_mode => '0', i_open => '1', i_timeout => (others => '0'), o_established => open,
				   i_src_ip => x"00000002", i_dst_ip => x"00000002", i_src_port => x"0002", i_dst_port => x"0002",
				   rx_network_tvalid => tx_tvalid1_internal, rx_network_tlast => tx_tlast1_internal, rx_network_tready => tx_tready1_internal, rx_network_tdata => tx_tdata1_internal,
				   rx_application_tvalid => rx_tvalid2_internal, rx_application_tlast => rx_tlast2_internal, rx_application_tready => rx_tready2_internal, rx_application_tdata => rx_tdata2_internal,
				   tx_network_tvalid => rx_tvalid1_internal, tx_network_tlast => rx_tlast1_internal, tx_network_tready => rx_tready1_internal, tx_network_tdata => rx_tdata1_internal,
				   tx_application_tvalid => rx_tvalid2_internal, tx_application_tlast => rx_tlast2_internal, tx_application_tready => rx_tready2_internal, tx_application_tdata => tx_tdata2_internal);					  
end behavioural;