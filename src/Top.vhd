use std.textio.all;
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.tcp_common.all;

entity Top is
  port(
    clk            :  in  std_ulogic;
    reset          :  in  std_ulogic;

	
    --------------------------------------------------------------------------------
    -- Inputs from Application
    --------------------------------------------------------------------------------
    start          :  in  std_ulogic;
    i_active_mode  :  in  std_ulogic;
    i_open         :  in  std_ulogic;     -- shall i save this to registers?
    i_timeout      :  in  unsigned (31 downto 0);
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
      i_open         :  in  std_ulogic;     -- shall i save this to registers?
      i_timeout      :  in  unsigned (31 downto 0);
      o_established  :  out  std_ulogic;
      --------------------------------------------------------------------------------
      -- SRC IP,PORT / DST IP,PORT defined by App 
      --------------------------------------------------------------------------------
      i_src_ip       :  in  t_ipv4_address;
      i_dst_ip       :  in  t_ipv4_address;
      i_src_port     :  in  t_tcp_port;
      i_dst_port     :  in  t_tcp_port;
      --------------------------------------------------------------------------------
      -- Inputs from Rx engine
      --------------------------------------------------------------------------------   
      i_header       :  in t_tcp_header;
      i_valid        :  in std_ulogic;
      i_data_sizeRx  :  in unsigned(15 downto 0);
      
      --------------------------------------------------------------------------------
      -- Outputs for Rx engine
      --------------------------------------------------------------------------------
      o_forwardRX :  out std_ulogic;
      o_discard   :  out std_ulogic;

      --------------------------------------------------------------------------------
      -- Inputs from Tx engine
      --------------------------------------------------------------------------------     
      i_data_sizeApp  :  in unsigned(15 downto 0);      
      i_Txready       :  in  std_ulogic;
      --------------------------------------------------------------------------------
      -- AXI interface
      --------------------------------------------------------------------------------
      last  :  in  std_ulogic;
      --------------------------------------------------------------------------------
      -- Outputs for Tx engine
      --------------------------------------------------------------------------------
     
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

component tx_engine is
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
end component;

  signal clk_internal, reset_internal: std_ulogic;
  signal forward_RX_internal, discard_internal, valid_RX_TOE_internal: std_ulogic;
  signal data_len_RX_TOE_internal: std_ulogic_vector(15 downto 0);
  signal data_len_RX_TOE_internal_as_unsigned: unsigned(15 downto 0);
  signal header_RX_TOE_internal: t_tcp_header;
  
  
  signal packet_header_TX_TOE_internal: t_tcp_header;
  signal packet_data_length_TX_TOE_internal: unsigned(APP_BUF_WIDTH - 1 downto 0);
  signal tx_start_TX_TOE_internal: std_ulogic;
  signal data_bytes_available_TX_TOE_interal: unsigned(APP_BUF_WIDTH - 1 downto 0);
  signal ready_TX_TOE_internal: std_ulogic;
  signal established_internal : std_ulogic;
begin
  clk_internal <= clk;
  reset_internal <= reset;
  data_len_RX_TOE_internal_as_unsigned <= unsigned(data_len_RX_TOE_internal);
  o_established <= established_internal;
  
  rx_engine: RX generic map(16, 8)
				port map(clk => clk_internal, reset => reset_internal,
						 i_forwardRX => forward_RX_internal, i_discard => discard_internal, o_header => header_RX_TOE_internal,
						 o_valid => valid_RX_TOE_internal, o_data_len => data_len_RX_TOE_internal,
						 network_tdata => rx_network_tdata, network_tlast => rx_network_tlast, network_tready => rx_network_tready, network_tvalid => rx_network_tvalid,
						 application_tdata => rx_application_tdata, application_tlast => rx_application_tlast, application_tready => rx_application_tready, application_tvalid => rx_application_tvalid
						 );
  toe: toefsm port map(clk => clk_internal, reset => reset_internal,
					   start => start, i_active_mode => i_active_mode, last => tx_application_tlast, i_open => i_open, i_timeout => i_timeout, o_established => established_internal,
					   i_src_ip => i_src_ip, i_src_port => i_src_port, i_dst_ip => i_dst_ip, i_dst_port => i_dst_port,
					   i_header => header_RX_TOE_internal, i_valid => valid_RX_TOE_internal, i_data_sizeRx => data_len_RX_TOE_internal_as_unsigned,
					   o_forwardRX => forward_RX_internal, o_discard => discard_internal,
					   i_data_sizeApp => data_bytes_available_TX_TOE_interal, o_header => packet_header_TX_TOE_internal, o_forwardTX => tx_start_TX_TOE_internal, i_Txready => ready_TX_TOE_internal);
					   
  tx_eng: tx_engine port map(clock => clk, i_reset => reset,
							 i_ctrl_packet_header => packet_header_TX_TOE_internal, i_ctrl_packet_data_length => X"05DC", i_ctrl_ack_num => (others => '0'),
							 i_ctrl_tx_start => tx_start_TX_TOE_internal, o_ctrl_data_bytes_available => data_bytes_available_TX_TOE_interal, o_ctrl_ready => ready_TX_TOE_internal,
							 i_app_axi_data => tx_application_tdata, i_app_axi_last => tx_application_tlast, o_app_axi_ready => tx_application_tready, i_app_axi_valid => tx_application_tvalid,
							 o_net_axi_data => tx_network_tdata, o_net_axi_last => tx_network_tlast, i_net_axi_ready => tx_network_tready, o_net_axi_valid => tx_network_tvalid);
end structural;