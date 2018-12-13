LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;


entity env_rx is
  port ( 
    clk         : in std_ulogic;
	reset       : in std_ulogic;
  
    forward_RX  : out std_ulogic;
	discard     : out std_ulogic;
	
	--between network and RX
	network_tvalid : out std_ulogic;
	network_tlast  : out std_ulogic;
	network_tready : in std_ulogic;
	network_tdata  : out std_ulogic_vector(7 downto 0)
  );
end env_rx;

architecture behavioural of env_rx is
  type state_t is (start, start_tx, send_data, prefinish, finish);
  type FRAME_1 is array(0 to 69) of std_ulogic_vector(7 downto 0);
  signal state, state_next : state_t;
  constant frame : FRAME_1 := (X"28",
X"4d",
X"e2",
X"f9",
X"0a",
X"10",
X"86",
X"bd",
X"01",
X"bb",
X"cb",
X"bc",
X"56",
X"77",
X"36",
X"9d",
X"b5",
X"43",
X"79",
X"ec",
X"50",
X"18",
X"04",
X"02",
X"1d",
X"64",
X"00",
X"00",
X"17",
X"03",
X"03",
X"00",
X"25",
X"00",
X"00",
X"00",
X"00",
X"00",
X"00",
X"00",
X"06",
X"6c",
X"a7",
X"db",
X"90",
X"15",
X"d3",
X"84",
X"b0",
X"07",
X"ce",
X"4b",
X"e5",
X"d8",
X"99",
X"ee",
X"4f",
X"c5",
X"93",
X"0a",
X"91",
X"e5",
X"6f",
X"df",
X"f6",
X"08",
X"57",
X"d4",
X"e6",
X"f9"
);
  signal i, i_next: integer := 0;
  signal data: std_ulogic_vector(7 downto 0);

begin


data <= frame(i);

comb: process(i, state, data)
begin
   state_next <= state;
   i_next <= i;
   network_tdata <= data;
   network_tvalid <= '0';
   network_tlast  <= '0';
   
   case state is
      when start =>
	    state_next <= start_tx;
	  when start_tx =>
		network_tvalid <= '1';
		i_next <= i + 1;
		state_next <= send_data;
	  when send_data =>
		network_tvalid <= '1';
	    i_next <= i + 1;
		state_next <= send_data;
		if (i = 69) then
		   network_tlast <= '1';
		   i_next <= i;
		   state_next <= prefinish;
		end if;
	  when prefinish =>
	    forward_RX <= '1';
	    state_next <= finish;
	  when finish =>
	     forward_RX <= '1';
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