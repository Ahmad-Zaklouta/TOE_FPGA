use std.textio.all;
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use tcp_common.all;	

entity rx_buffer is
  generic(
    memory_address_bits: natural := 14
  );
  port(
    clk            : in std_ulogic;
	reset          : in std_ulogic;
  
    i_forwardRX    : in std_ulogic;
    -- AXI-4 between TOE and 
	tvalid         : out std_ulogic;
	tlast          : out std_ulogic;
	tready         : in std_ulogic;
	tdata          : out std_ulogic_vector(7 downto 0);
	-- between RX Engine and buffer
	o_read_address : out std_ulogic_vector(memory_address_bits downto 0);
    i_data_length  : in std_ulogic_vector(13 downto 0);
	i_write_address: in std_ulogic_vector(memory_address_bits downto 0);
	o_ready        : out std_ulogic;
  );
end rx_buffer;	

architecture behavioural of rx_buffer is
  component Memory is
    Port ( wclk          : in STD_LOGIC;
           rclk          : in std_logic;
		   waddr         : in std_logic_vector(3 downto 0);
           raddr         : in std_logic_vector(3 downto 0);
           wen           : in STD_LOGIC;
           ren           : in STD_LOGIC;
           write_data_in : in std_logic_vector(7 downto 0);
           read_data_out : out std_logic_vector(7 downto 0)
		   );
  end component;

  type state_t is (await, forward_data);
  
  signal state, state_next: state_t;
  signal read_address, read_address_next : std_ulogic_vector(memory_address_bits downto 0);
  signal data_to_send, data_to_send_next : std_ulogic_vector(13 downto 0);
begin
   empty <= '1' when (read_address = i_write_address) else '0';
   tdata <= ...;
  
  comb: process()
  begin
    o_ready <= '1';
	
    case state is
      when await =>
        if (i_forwardRX = '1') then
		  state_next <= forward_data;
		  data_to_send_next <= i_data_length
		end if;
      when forward_data	=>
        if (empty = '1' ) then
        
        elsif (tready = '1') then
		  read_address_next <= std_ulogic_vector(unsigned(read_address) + 1);
	      data_to_send_next <= std_ulogic(unsigned(data_to_send) - 1);
		  if (unsigned(data_to_send) = 1) then
		    tlast <= '1';
			state_next <= await;
		  end if;
    end case;	  
  end process;
  
  seq: process(clk)
  begin
    if (rising_edge(clk) and reset = '1') then
	
	elsif (rising_edge(clk)) then
	
	end if;
  end process;
  
end;