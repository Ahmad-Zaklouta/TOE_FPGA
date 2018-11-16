LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;


entity env_rx_buffer is
  port ( 
    clk            : in std_ulogic; -- system clock
    reset          : in std_ulogic; -- asynchronous reset
    data_length    : out std_ulogic_vector(13 downto 0);
    forward_RX     : out std_ulogic;
	write_address  : out std_ulogic_vector(16 downto 0);
	d_out           : out std_ulogic_vector(7 downto 0);
	we             : out std_ulogic
  );
end env_rx_buffer;

architecture behavioural of env_rx_buffer is
  type state_t is (start, start_tx, send_data, prefinish, finish);
  type FRAME_1 is array(0 to 31) of std_ulogic_vector(7 downto 0);
  signal state, state_next : state_t;
  constant frame : FRAME_1 := (X"0a",
X"10",
X"4a",
X"0c",
X"34",
X"6d",
X"78",
X"14",
X"00",
X"06",
X"00",
X"14",
X"ef",
X"7d",
X"01",
X"bb",
X"54",
X"13",
X"88",
X"3a",
X"ef",
X"26",
X"05",
X"dc",
X"50",
X"10",
X"01",
X"02",
X"eb",
X"ab",
X"00",
X"00"
);
  signal i, i_next: integer := 0;
  signal data: std_ulogic_vector(7 downto 0);

begin


data <= frame(i);

comb: process(i, state, data)
begin
   state_next <= state;
   i_next <= i;
   d_out <= data;
   we <= '0';
   write_address <= std_ulogic_vector(to_unsigned(i, write_address'length));
   
   case state is
      when start =>
	    d_out <= (others => '0');
	    state_next <= start_tx;
	  when start_tx =>
		we <= '1';
		i_next <= i + 1;
		state_next <= send_data;
		data_length <= std_ulogic_vector(to_unsigned(32, data_length'length));
	  when send_data =>
	    we <= '1';
		i_next <= i + 1;
		state_next <= send_data;
		if (i = 31) then
		   i_next <= i;
		   state_next <= prefinish;
		end if;
	  when prefinish =>
	    forward_RX <= '1';
	    state_next <= finish;
	  when finish =>
	     forward_RX <= '0';
	     --data_out <= (others => '0');
	     --state_next <= finish;
		 --assert fcs_error = '0' report "Error spotted" severity failure;
		 --report "Test passed" severity failure;
	end case;
end process;

seq: process(clk, reset)
begin
  if (reset = '1') then
    state <= start;
	i <= 0;
  elsif (rising_edge(clk)) then
    state <= state_next;
	i <= i_next;
  end if;
end process;

end behavioural;