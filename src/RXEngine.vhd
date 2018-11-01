use std.textio.all;
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity rx_engine is
  port(
    clk         : in std_ulogic;
	reset       : in std_ulogic;
	
	-- To and from FSM
    i_forwardRX : in std_ulogic;
	i_discard   : in std_ulogic;
	o_header    : out std_ulogic_vector(19*8 downto 0);
	o_valid     : out std_ulogic;
	-- AXI-4 between network interface and TOE
	tvalid      : in std_ulogic;
	tlast       : in std_ulogic;
	tready      : out std_ulogic;
	tdata       : in std_ulogic_vector(7 downto 0);
	-- Data to the RX buffer
	o_address   : out std_ulogic_vector(15 downto 0);
	o_data      : in std_ulogic_vector(7 downto 0);
	o_we        : out std_ulogic;
  );
end rx_engine;

entity

architecture rx_engine_behaviour of rx_engine is
  type state_t is (pseudo_header_read, header_read, read_data);
begin
  process()
  begin

  end process;  

end rx_engine_behaviour;