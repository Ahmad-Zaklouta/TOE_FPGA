----------------------------------------------------------------------------------
-- Company:
-- Engineer:
--
-- Create Date: 01/03/2018 04:39:29 PM
-- Design Name:
-- Module Name: memory_large - Behavioral
-- Project Name:
-- Target Devices:
-- Tool Versions:
-- Description:
--
-- Dependencies:
--
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
----------------------------------------------------------------------------------


LIBRARY ieee;
USE STD.textio.all;
USE ieee.std_logic_1164.ALL;
use IEEE.numeric_std.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity memory_large is
    generic(
		memory_size: natural := 16;
		data_length: natural := 16
	);
    Port ( clk : in std_ulogic;
           we : in std_ulogic;
           en : in std_ulogic;
           addr_r : in std_ulogic_VECTOR (memory_size-1 downto 0);
           addr_w : in std_ulogic_VECTOR (memory_size-1 downto 0);
           di : in std_ulogic_VECTOR (data_length-1 downto 0);
           do : out std_ulogic_VECTOR (data_length-1 downto 0)
		   );
end memory_large;

architecture Behavioral of memory_large is
    type ram_t is array(2**memory_size - 1 downto 0) of std_ulogic_vector(data_length-1 downto 0);

begin
    process(clk)
        variable RAM: ram_t;
		begin
            if rising_edge(clk) then
                if we = '1' then
					RAM(to_integer(unsigned(addr_w))) := di;
                elsif en = '1' then
                    do <= RAM(to_integer(unsigned(addr_r)));
                end if;
            end if;
        end process;
end Behavioral;
