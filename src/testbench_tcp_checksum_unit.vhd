LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;

library work;
use work.tcp_common.all;

entity testbench_rx is
end testbench_rx;

architecture behavioural of testbench_rx is
  component tcp_checksum_unit is
    port(
      clk: in std_ulogic;
	  reset: in std_ulogic;
	
	  i_data: in std_ulogic_vector(7 downto 0);
	  i_valid: in std_ulogic;
	  i_checksum_en: in std_ulogic;
	  i_end_checksum: in std_ulogic;
	  o_checksum_comp_finished: out std_ulogic;
	  o_error: out std_ulogic;
	  o_checksum: out std_ulogic_vector(15 downto 0);
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

dut: tcp_checksum_unit port map(clk => clk, reset => reset, i_valid => tvalid, i_checksum_en => tvalid, i_end_checksum => tlast, i_data => tdata,
                        o_checksum_comp_finished => open, o_error => open, o_checksum => open);
environment: env port map(clk => clk, reset => reset, tvalid => tvalid, tlast => tlast, tdata => tdata, tready => '0');
end behavioural;