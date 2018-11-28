LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;

library work;
use work.tcp_common.all;

entity testbench_toe is
end testbench_toe;

architecture behavioural of testbench_toe is

component iface is
  port(
    clk: in std_ulogic;
	reset: in std_ulogic;
  
    tx_tready1: out std_ulogic;
	tx_tvalid1: in std_ulogic;
	tx_tdata1:  in std_ulogic_vector(7 downto 0);
	tx_tlast1:  in std_ulogic;
	
	tx_tready2: out std_ulogic;
	tx_tvalid2: in std_ulogic;
	tx_tdata2: in std_ulogic_vector(7 downto 0);
	tx_tlast2:  in std_ulogic;
	
	rx_tready1: in std_ulogic;
	rx_tvalid1: out std_ulogic;
	rx_tdata1:  out std_ulogic_vector(7 downto 0);
	rx_tlast1:  out std_ulogic;
	
	rx_tready2: in std_ulogic;
	rx_tvalid2: out std_ulogic;
	rx_tdata2:  out std_ulogic_vector(7 downto 0);
	rx_tlast2:  out std_ulogic
	);
end component;

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
interface: iface port map(clk => clk, reset => reset,
							  tx_tready1 => tx_tready1_internal, tx_tready2 => tx_tready2_internal, tx_tvalid1 => tx_tvalid1_internal, tx_tvalid2 => tx_tvalid2_internal,
							  tx_tlast1 => tx_tlast1_internal, tx_tlast2 => tx_tlast2_internal,
							  rx_tready1 => rx_tready1_internal, rx_tready2 => rx_tready2_internal, rx_tvalid1 => rx_tvalid1_internal, rx_tvalid2 => rx_tvalid2_internal,
							  rx_tlast1 => rx_tlast1_internal, rx_tlast2 => rx_tlast2_internal,
							  rx_tdata1 => rx_tdata1_internal, rx_tdata2 => rx_tdata2_internal,
							  tx_tdata1 => tx_tdata1_internal, tx_tdata2 => tx_tdata2_internal);
end behavioural;