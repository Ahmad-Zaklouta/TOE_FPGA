use std.textio.all;
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.tcp_common.all;

entity Top is
  port(
    --------------------------------------------------------------------------------
    -- Inputs from Application
    --------------------------------------------------------------------------------
    clk            :  in  std_ulogic;
    reset          :  in  std_ulogic;
    start          :  in  std_ulogic;
    i_active_mode  :  in  std_ulogic;
    last           :  in  std_ulogic; -- send data
    i_open         :  in  std_ulogic;     -- shall i save this to registers?
    i_timeout      :  in  unsigned (10 downto 0);
    o_close        :  out  std_ulogic;
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
	rx_application_tdata          : out std_ulogic_vector(data_size-1 downto 0)
  );
end Top;

architecture structural of Top is

component toefsm is

   port(
      --------------------------------------------------------------------------------
      -- Inputs from Application
      --------------------------------------------------------------------------------
      clk            :  in  std_ulogic;
      reset          :  in  std_ulogic;
      start          :  in  std_ulogic;
      i_active_mode  :  in  std_ulogic;
      last           :  in  std_ulogic; -- send data
      i_open         :  in  std_ulogic;     -- shall i save this to registers?
      i_timeout      :  in  unsigned (10 downto 0);
      o_close        :  out  std_ulogic;
      --------------------------------------------------------------------------------
      -- SRC IP,PORT / DST IP,PORT defined by App 
      --------------------------------------------------------------------------------
      i_src_ip       :  in  t_ipv4_address;
      i_dst_ip       :  in  t_ipv4_address;
      i_src_port     :  in  t_tcp_port;
      i_dst_port     :  in  t_tcp_port;
      --------------------------------------------------------------------------------
      -- Inputs from Rx engine
      --------------------------------------------------------------------------------    ----IF PACKET CORRECT BUT NOT DATA LIKE SYN OR ACK ,SENT FORWARD HIGH TO RX
      i_header       :  in t_tcp_header;
      i_valid        :  in std_ulogic;
      i_data_sizeRx  :  in unsigned(31 downto 0);
      
      --------------------------------------------------------------------------------
      -- Outputs for Rx engine
      --------------------------------------------------------------------------------
      o_forwardRX :  out std_ulogic;
      o_discard   :  out std_ulogic;

      --------------------------------------------------------------------------------
      -- Inputs from Tx engine
      --------------------------------------------------------------------------------

      i_data_inbuffer :  in std_ulogic;
      i_data_sizeApp  :  in unsigned(31 downto 0);
      --------------------------------------------------------------------------------
      -- Outputs for Tx engine
      --------------------------------------------------------------------------------
      o_Txsenddata : out std_ulogic; -- to say to the Tx when doing the handshake not to send data that may be stored in the buffer
      o_header    :  out t_tcp_header;
      o_forwardTX :  out std_ulogic
 
    );
end component;

component RX is
  -- bunch of things going here
  generic(
    memory_address_bits: natural := 14;
	data_size          : natural := 16
  );
  -- another bunch of things here as well
  port(
    clk : in std_ulogic;
	reset : in std_ulogic;
	
	i_forwardRX : in std_ulogic;
	i_discard   : in std_ulogic;
	o_header    : out t_tcp_header;
	o_valid     : out std_ulogic;
	o_data_len  : out std_ulogic_vector(15 downto 0);
	--between network and RX
	network_tvalid : in std_ulogic;
	network_tlast  : in std_ulogic;
	network_tready : out std_ulogic;
	network_tdata  : in std_ulogic_vector(7 downto 0);
	
    --between RX and  application
	application_tvalid         : out std_ulogic;
	application_tlast          : out std_ulogic;
	application_tready         : in std_ulogic;
	application_tdata          : out std_ulogic_vector(data_size-1 downto 0)
  );
  
end component;

  signal clk_internal, reset_internal: std_ulogic;
  signal forward_RX_internal, discard_internal, valid_RX_TOE_internal: std_ulogic
  signal data_len_RX_TOE_internal: std_ulogic_vector(15 downto 0);
  signal header_RX_TOE_internal: t_tcp_header;
begin
  clk_internal <= clk;
  reset_internal <= reset;
  
  rx_engine: RX generic map(16, 8)
				port map(clk => clk_internal, reset => reset_internal,
						 i_forwardRX => forward_RX_internal, i_discard => discard_internal, o_header => header_RX_TOE_internal,
						 o_valid => valid_RX_TOE_internal, o_data_len => data_len_RX_TOE_internal,
						 network_tdata => rx_network_tdata, network_tlast => rx_network_tlast, network_tready => rx_network_tready, network_tvalid => rx_network_tvalid,
						 application_tdata => rx_application_tdata, application_tlast => rx_application_tlast, application_tready => rx_application_tready, application_tvalid => rx_application_tvalid
						 );
  toe: toefsm port map(clk => clk_internal, reset => reset_internal,
					   start => start, i_active_mode => i_active_mode, last => last, i_open => i_open, i_timeout => i_timeout, o_close => o_close,
					   i_src_ip => i_src_ip, i_src_port => i_src_port, i_dst_ip => i_dst_ip, i_dst_port => i_dest_port,
					   i_header => header_RX_TOE_internal, i_valid => valid_RX_TOE_internal, i_data_sizeRx => data_len_RX_TOE_internal,
					   o_forwardRX => forward_RX_internal, o_discard => discard_internal,
					   );
end structural;