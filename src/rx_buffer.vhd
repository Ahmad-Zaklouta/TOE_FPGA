use std.textio.all;
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.tcp_common.all;	

entity rx_buffer is
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
    i_data_length  : in std_ulogic_vector(13 downto 0);
	i_write_address: in std_ulogic_vector(memory_address_bits downto 0);
	i_data         : in std_ulogic_vector(data_size-1 downto 0);
	i_we           : in std_ulogic;
	o_ready        : out std_ulogic
  );
end rx_buffer;	

architecture behavioural of rx_buffer is
  component memory_large is
    generic(
		memory_size: natural := 16;
		data_length: natural := 16
	);
    Port ( clk : in std_ulogic;
           we : in std_ulogic;
           en : in std_ulogic;
           addr_r : in std_ulogic_VECTOR (memory_size-1 downto 0);
           addr_w : in std_ulogic_VECTOR (memory_size-1 downto 0);
           di : in std_ulogic_VECTOR (data_length downto 0);
           do : out std_ulogic_VECTOR (data_length downto 0)
		   );
    end component;

  type state_t is (await, forward_data);
  
  signal state, state_next: state_t;
  signal read_address, read_address_next : std_ulogic_vector(memory_address_bits downto 0);
  signal data_to_send, data_to_send_next : std_ulogic_vector(13 downto 0);
  signal read_enabled, empty : std_ulogic;
begin
  empty <= '1' when (read_address = i_write_address) else '0';
  
  mem: memory_large generic map(memory_address_bits, data_size)
			  port map(clk => clk, we => i_we, en => read_enabled,
			           addr_w => i_write_address, addr_r => read_address,
					   do => tdata, di =>    i_data);
  
  comb: process(state, i_forwardRX, i_data_length, read_address, data_to_send)
  begin
    o_ready <= '1';
	
    case state is
      when await =>
        if (i_forwardRX = '1') then
		  state_next <= forward_data;
		  data_to_send_next <= i_data_length;
		end if;
      when forward_data	=>
	    o_ready <= '0';
	  
        if (empty = '1' or tready = '0') then
           -- do nothing
        else
		  read_address_next <= std_ulogic_vector(unsigned(read_address) + 1);
	      data_to_send_next <= std_ulogic_vector(unsigned(data_to_send) - 1);
		  if (unsigned(data_to_send) = 1) then
		    tlast <= '1';
			state_next <= await;
		  end if;
		end if;
    end case;	  
  end process;
  
  seq: process(clk)
  begin
    if (rising_edge(clk) and reset = '1') then
	   state <= await;
	   read_address <= (others => '0');
	   data_to_send <= (others => '0');
	elsif (rising_edge(clk)) then
	   state <= state_next;
	   read_address <= read_address_next;
	   data_to_send <= data_to_send_next;
	end if;
  end process;
  
end;