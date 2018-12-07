LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;

library work;
use work.tcp_common.all;

entity testbench_rx is
end testbench_rx;

architecture behavioural of testbench_rx is
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
	i_ready_buffer : in std_ulogic
  );
end component;


  
  component env is
    port ( 
      clk            : in std_ulogic; -- system clock
      reset          : in std_ulogic; -- asynchronous reset
	  tvalid         : out std_ulogic;
	  tready         : in std_ulogic;
	  tdata          : out std_ulogic_vector(7 downto 0);
	  tlast          : out std_ulogic
    );
  end component;
  
  signal clk: std_ulogic := '0';
  signal reset: std_ulogic;
  signal tvalid: std_ulogic;
  signal tlast: std_ulogic;
  signal tdata: std_ulogic_vector(7 downto 0);
  signal o_valid: std_ulogic;
  
begin

reset<='1', '0' after 50 ns;
clk_proc: process(clk)
begin
    clk <= not clk after 5 ns;
end process;

dut: rx_engine port map(clk => clk, reset => reset, tvalid => tvalid, tlast => tlast, tdata => tdata, tready => open,
                        i_forwardRX => '0', i_discard => '0', o_header => open, o_valid => open, o_data_len => open,
						o_address => open, o_data => open, o_we => open, i_ready_TOE => '1', i_address_r => (others => '1'));
environment: env port map(clk => clk, reset => reset, tvalid => tvalid, tlast => tlast, tdata => tdata, tready => '0');
end behavioural;

architecture behavioural_2 of testbench_rx is

component env_rx is
  port ( 
    clk         : in std_ulogic;
	reset       : in std_ulogic;
  
    forward_RX  : out std_ulogic;
	discard     : out std_ulogic;
	
	--between network and RX
	network_tvalid : out std_ulogic;
	network_tlast  : out std_ulogic;
	network_tready : in std_ulogic;
	network_tdata  : out std_ulogic_vector(7 downto 0)
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

signal clk, reset: std_ulogic := '0';
signal forward_RX, discard: std_ulogic;
signal tvalid, tlast, tready: std_ulogic;
signal tdata: std_ulogic_vector(7 downto 0);

begin

reset<='1', '0' after 50 ns;
clk_proc: process(clk)
begin
    clk <= not clk after 5 ns;
end process;

dut: RX generic map(16, 8)
     port map(clk => clk, reset => reset, 
	          i_forwardRX => forward_RX, i_discard => discard, o_header => open, o_valid => open, o_data_len => open,
			  network_tvalid => tvalid, network_tlast => tlast, network_tready => tready, network_tdata => tdata,
			  application_tvalid => open, application_tlast => open, application_tready => '1', application_tdata => open
			  );
environment: env_rx port map(clk => clk, reset => reset,
                             forward_RX => forward_RX, discard => discard,
							 network_tvalid => tvalid, network_tlast => tlast, network_tready => tready, network_tdata => tdata);
end behavioural_2;