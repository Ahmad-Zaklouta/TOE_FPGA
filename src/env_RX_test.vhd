LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;


entity env is
  port ( 
    clk            : in std_ulogic; -- system clock
    reset          : in std_ulogic; -- asynchronous reset
	tvalid         : out std_ulogic;
	tready         : in std_ulogic;
	tdata          : out std_ulogic_vector(7 downto 0);
	tlast          : out std_ulogic
  );
end env;

architecture behavioural of env is
  type state_t is (start, start_tx, send_data, prefinish, finish);
  type FRAME_1 is array(0 to 31) of std_ulogic_vector(7 downto 0);
  signal state, state_next : state_t;
  constant frame : FRAME_1 := (X"0a",
X"10",
X"8c",
X"9e",
X"02",
X"10",
X"00",
X"06",
X"00",
X"14",
X"3f",
X"41",
X"dd",
X"77",
X"00",
X"50",
X"99",
X"f3",
X"1b",
X"b2",
X"b8",
X"32",
X"89",
X"49",
X"50",
X"11",
X"00",
X"fd",
X"01",
X"ee",
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
   tvalid <= '1';
   tdata <= data;
   tlast <= '0';
   
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
		if (i = 31) then
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