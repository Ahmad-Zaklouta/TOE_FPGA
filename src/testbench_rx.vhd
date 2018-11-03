LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;

library work;
use work.tcp_common.all;

entity testbench_rx is
end testbench_rx;

architecture behavioural of testbench_rx is
  component rx_engine is
    port(
      clk         : in std_ulogic;
	  reset       : in std_ulogic;
	  
	  -- To and from FSM
      i_forwardRX : in std_ulogic;
	  i_discard   : in std_ulogic;
	  o_header    : out t_tcp_header;
	  o_valid     : out std_ulogic;
	  -- AXI-4 between network interface and TOE
	  tvalid      : in std_ulogic;
	  tlast       : in std_ulogic;
	  tready      : out std_ulogic;
	  tdata       : in std_ulogic_vector(7 downto 0);
	  -- Data to the RX buffer
	  o_address   : out std_ulogic_vector(15 downto 0);
	  o_data      : out std_ulogic_vector(7 downto 0);
	  o_we        : out std_ulogic
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
                        i_forwardRX => '0', i_discard => '0', o_header => open, o_valid => open,
						o_address => open, o_data => open, o_we => open);
environment: env port map(clk => clk, reset => reset, tvalid => tvalid, tlast => tlast, tdata => tdata, tready => '0');
end behavioural;