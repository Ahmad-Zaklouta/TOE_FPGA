use std.textio.all;
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity rx_engine is
  generic(ip_length: integer := 32;
          port_length: integer := 16;
		  flags_length: integer := 6;
		  sequence_length: integer := 32;
		  data_size_length: integer := 32
    );
  port(
    i_source_ip       : in std_ulogic_vector(ip_length-1 downto 0);
    i_dest_ip         : in std_ulogic_vector(ip_length-1 downto 0);
    i_source_port     : in std_ulogic_vector(port_length-1 downto 0);
    i_dest_port       : in std_ulogic_vector(port_length-1 downto 0);
    i_flags           : in std_ulogic_vector(flags_length-1 downto 0);
    i_sequence_number : in std_ulogic_vector(sequence_length-1 downto 0);
    i_data_size       : in std_ulogic_vector(data_size_length-1 downto 0);
    i_valid           : in std_ulogic;
	clk:		      : in std_ulogic;
	reset             : in std_ulogic;
  );
end rx_engine;

architecture rx_engine_behaviour of rx_engine is

begin

end rx_engine_behaviour;