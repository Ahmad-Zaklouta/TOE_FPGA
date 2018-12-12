use std.textio.all;
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.tcp_common.all;	

entity testbench_rx_buffer is
end testbench_rx_buffer;

architecture behavioural of testbench_rx_buffer is

  constant memory_address_bits : natural := 16;
  constant data_size           : natural := 8;

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

  component env_rx_buffer is
    port ( 
      clk            : in std_ulogic; -- system clock
      reset          : in std_ulogic; -- asynchronous reset
      data_length    : out std_ulogic_vector(15 downto 0);
      forward_RX     : out std_ulogic;
	  write_address  : out std_ulogic_vector(16 downto 0);
	  d_out           : out std_ulogic_vector(7 downto 0);
	  we             : out std_ulogic
    );
  end component;  

  signal clk, reset, forward_RX, we: std_ulogic := '0';
  signal write_address: std_ulogic_vector(memory_address_bits downto 0);
  signal data_length  : std_ulogic_vector(15 downto 0);
  signal data         : std_ulogic_vector(data_size-1 downto 0);
begin

	
  reset<='1', '0' after 50 ns;
  clk_proc: process(clk)
  begin
     clk <= not clk after 5 ns;
  end process;

  dut: rx_buffer generic map(memory_address_bits, data_size)
                 port map(clk => clk, reset => reset, i_forwardRX => forward_RX, tvalid => open, 
                          tlast => open, tready => '1', tdata => open, o_read_address => open, 
						  i_data_length => data_length, i_write_address => write_address, i_data => data,
						  i_we => we, o_ready => open);
  environment: env_rx_buffer port map(clk => clk, reset => reset, data_length => data_length, forward_RX => forward_RX,
                                      write_address => write_address, d_out => data, we => we);

end behavioural;