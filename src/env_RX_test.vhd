LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;


entity env_rx_engine is
  port ( 
    clk            : in std_ulogic; -- system clock
    reset          : in std_ulogic; -- asynchronous reset
	tvalid         : out std_ulogic;
	tready         : in std_ulogic;
	tdata          : out std_ulogic_vector(7 downto 0);
	tlast          : out std_ulogic
  );
end env_rx_engine;

architecture behavioural of env_rx_engine is
  type state_t is (start, start_tx, send_data, prefinish, finish);
  type FRAME_1 is array(0 to 27) of std_ulogic_vector(7 downto 0);
  signal state, state_next : state_t;
  constant frame : FRAME_1 := (X"0a",
X"10",
X"4a",
X"0c",
X"33",
X"6d",
X"78",
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
   tdata <= data;
   tlast <= '0';
   tvalid <= '0';
   
   case state is
      when start =>
	    tdata <= (others => '0');
	    state_next <= start_tx;
	  when start_tx =>
	    tvalid <= '1';
		i_next <= i + 1;
		state_next <= send_data;
	  when send_data =>
		i_next <= i + 1;
		state_next <= send_data;
	    tvalid <= '1';
		if (i = 27) then
		   i_next <= 0;
		   tlast <= '1';
		   state_next <= prefinish;
		end if;
	  when prefinish =>
	    state_next <= finish;
	  when finish =>
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