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

entity Memory is
    Port ( wclk          : in STD_LOGIC;
           rclk          : in std_logic;
		   waddr         : in std_logic_vector(3 downto 0);
           raddr         : in std_logic_vector(3 downto 0);
           wen           : in STD_LOGIC;
           ren           : in STD_LOGIC;
           write_data_in : in std_logic_vector(7 downto 0);
           read_data_out : out std_logic_vector(7 downto 0)
		   );
end Memory;

architecture Behavioral of Memory is
    type ram_t is array(2**4 - 1 downto 0) of std_logic_vector(7 downto 0);
    shared variable RAM: ram_t;
begin
    process(rclk)
	begin
	  if (rising_edge(rclk) and ren = '1') then
	    read_data_out <= RAM(to_integer(unsigned(raddr)));
	  end if;
	end process;

	process(wclk)
	begin
	  if (rising_edge(wclk) and wen = '1') then
	    RAM(to_integer(unsigned(waddr))) := write_data_in;
	  end if;
	end process;
end Behavioral;
