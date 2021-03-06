use std.textio.all;
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity dual_port_ram is
	generic (
		DATA_WIDTH    : natural;
		ADDRESS_WIDTH : natural
	);
	port (
		clock : in std_ulogic;

		a_address : in std_ulogic_vector(ADDRESS_WIDTH - 1 downto 0);
		a_data_in : in std_ulogic_vector(DATA_WIDTH - 1 downto 0);
		a_data_out : out std_ulogic_vector(DATA_WIDTH - 1 downto 0);
		a_write_enable : in std_ulogic;

		b_address : in std_ulogic_vector(ADDRESS_WIDTH - 1 downto 0);
		b_data_in : in std_ulogic_vector(DATA_WIDTH - 1 downto 0);
		b_data_out : out std_ulogic_vector(DATA_WIDTH - 1 downto 0);
		b_write_enable : in std_ulogic
	);
end dual_port_ram;

architecture behaviour of dual_port_ram is
	type memory_array_type is array(2**ADDRESS_WIDTH - 1 downto 0)
		of std_ulogic_vector(DATA_WIDTH - 1 downto 0);

	signal memory_array : memory_array_type;
begin
	process (clock)
	begin
		if rising_edge(clock) then
			if a_write_enable = '1' then
				memory_array(to_integer(unsigned(a_address))) <= a_data_in;
				a_data_out <= a_data_in;
			else
				a_data_out <= memory_array(to_integer(unsigned(a_address)));
			end if;
			if b_write_enable = '1' then
				memory_array(to_integer(unsigned(b_address))) <= b_data_in;
				b_data_out <= b_data_in;
			else
				b_data_out <= memory_array(to_integer(unsigned(b_address)));
			end if;
		end if;
	end process;
end architecture behaviour;

