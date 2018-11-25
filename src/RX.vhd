use std.textio.all;
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.tcp_common.all;

entity RX is
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
	i_ready_TOE : in std_ulogic;
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
  
end RX;

architecture behavioural of RX is

  component rx_engine is
    generic(
      memory_address_bits: natural := 14
	);
    port(
      clk         : in std_ulogic;
	  reset       : in std_ulogic;
	  
	  -- To and from FSM
      i_forwardRX : in std_ulogic;
	  i_discard   : in std_ulogic;
	  o_header    : out t_tcp_header;
	  o_valid     : out std_ulogic;
      o_data_len  : out std_ulogic_vector(15 downto 0);	 
	  -- AXI-4 between network interface and TOE
	  tvalid      : in std_ulogic;
	  tlast       : in std_ulogic;
	  tready      : out std_ulogic;
	  tdata       : in std_ulogic_vector(7 downto 0);
	  -- Data to the RX buffer
	  o_address   : out std_ulogic_vector(memory_address_bits downto 0);
	  o_data      : out std_ulogic_vector(7 downto 0);
	  o_we        : out std_ulogic;
	  i_address_r : in  std_ulogic_vector(memory_address_bits downto 0);
	  i_ready_TOE : in std_ulogic
    );
  end component;
  
  component rx_buffer is
    generic(
      memory_address_bits: natural := 14;
	  data_size          : natural := 16
    );
    port(
      clk            : in std_ulogic;
	  reset          : in std_ulogic;
  
      i_forwardRX    : in std_ulogic;
      -- AXI-4 between TOE and 
	  tvalid         : out std_ulogic;
	  tlast          : out std_ulogic;
	  tready         : in std_ulogic;
	  tdata          : out std_ulogic_vector(data_size-1 downto 0);
	  -- between RX Engine and buffer
	  o_read_address : out std_ulogic_vector(memory_address_bits downto 0);
      i_data_length  : in std_ulogic_vector(15 downto 0);
	  i_write_address: in std_ulogic_vector(memory_address_bits downto 0);
	  i_data         : in std_ulogic_vector(data_size-1 downto 0);
	  i_we           : in std_ulogic;
	  o_ready        : out std_ulogic
    );
  end component;	

  signal read_address, write_address : std_ulogic_vector(memory_address_bits downto 0);
  signal data : std_ulogic_vector(7 downto 0);
  signal data_length: std_ulogic_vector(15 downto 0);
  signal we : std_ulogic;
begin
  o_data_len <= data_length;

  rx_engine_comp: rx_engine generic map(memory_address_bits)
                  port map(clk => clk, reset => reset, i_forwardRX => i_forwardRX, i_discard => i_discard, 
				           o_header => o_header, o_valid => o_valid, o_data_len => data_length, i_ready_TOE => i_ready_TOE,
						   tvalid => network_tvalid, tlast => network_tlast, tready => network_tready, tdata => network_tdata,
						   o_address => write_address, o_data => data, o_we => we, i_address_r => read_address);
				  
  rx_buffer_comp: rx_buffer generic map(memory_address_bits, data_size)
                  port map(clk => clk, reset => reset, i_forwardRX => i_forwardRX,
				           tvalid => application_tvalid, tlast => application_tlast, tready => application_tready, tdata => application_tdata,
						   o_read_address => read_address, i_data_length => data_length, i_write_address => write_address, i_data => data,
						   i_we => we, o_ready => open);
end behavioural;