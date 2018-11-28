LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;

entity iface is
  port(
    clk: in std_ulogic;
	reset: in std_ulogic;
  
    tx_tready1: out std_ulogic;
	tx_tvalid1: in std_ulogic;
	tx_tdata1:  in std_ulogic_vector(7 downto 0);
	tx_tlast1:  in std_ulogic;
	
	tx_tready2: out std_ulogic;
	tx_tvalid2: in std_ulogic;
	tx_tdata2: in std_ulogic_vector(7 downto 0);
	tx_tlast2:  in std_ulogic;
	
	rx_tready1: in std_ulogic;
	rx_tvalid1: out std_ulogic;
	rx_tdata1:  out std_ulogic_vector(7 downto 0);
	rx_tlast1:  out std_ulogic;
	
	rx_tready2: in std_ulogic;
	rx_tvalid2: out std_ulogic;
	rx_tdata2:  out std_ulogic_vector(7 downto 0);
	rx_tlast2:  out std_ulogic
	);
end iface;

architecture behavioural of iface is
type state_t is (idle, prepend_ip, send_data);

signal state1, state2, state1_next, state2_next: state_t;
signal first_buff1, first_buff2: std_ulogic_vector(7 downto 0);

signal i, j, i_next, j_next: integer;

begin

reg1: process(clk, reset)
begin
  if(rising_edge(clk) and reset = '1') then
    state1 <= idle;
	i <= 0;
  elsif(rising_edge(clk)) then
    state1 <= state1_next;
	i <= i_next;
  end if;
end process;


seq1: process(state1, rx_tready2, tx_tvalid1, tx_tdata1, tx_tlast1, i)
begin
  tx_tready1 <= rx_tready2;
  rx_tvalid2 <= tx_tvalid1;
  rx_tdata2  <= tx_tdata1;
  rx_tlast2  <= tx_tlast1;
  
    
  case state1 is
	when idle =>
	  tx_tready1 <= '0';
	  i_next <= 0;
	  if(tx_tvalid1 = '1') then
		state1_next <= prepend_ip;
	  end if;
	when prepend_ip =>
	  tx_tready1 <= '0';
	  rx_tvalid2 <= '1';
	  if (i = 0 and rx_tready2 = '1') then
		rx_tdata2 <= X"00";
		i_next <= i + 1;
	  elsif (i = 1 and rx_tready2 = '1') then
		rx_tdata2 <= X"00";
		i_next <= i + 1;
	  elsif (i = 2 and rx_tready2 = '1') then
		rx_tdata2 <= X"00";
		i_next <= i + 1;
	  elsif (i = 3 and rx_tready2 = '1') then
		rx_tdata2 <= X"f0";
		i_next <= i + 1;
	  elsif (i = 4 and rx_tready2 = '1') then
		rx_tdata2 <= X"02";
		i_next <= i + 1;
	  elsif (i = 5 and rx_tready2 = '1') then
		rx_tdata2 <= X"00";
		i_next <= i + 1;
	  elsif (i = 6 and rx_tready2 = '1') then
		rx_tdata2 <= X"00";
		i_next <= i + 1;
	  elsif (i = 7 and rx_tready2 = '1') then
		rx_tdata2 <= X"00";
		i_next <= i + 1;
		state1_next <= send_data;
	  end if;
	when send_data =>
	  if(tx_tlast1 = '1') then
	    state1_next <= idle;
	  end if;
    end case;	   
end process;

reg2: process(clk, reset)
begin
  if(rising_edge(clk) and reset = '1') then
    state2 <= idle;
	j <= 0;
  elsif(rising_edge(clk)) then
    state2 <= state2_next;
	j <= j_next;
  end if;
end process;

seq2: process(state2, rx_tready1, tx_tvalid2, tx_tdata2, tx_tlast2, j)
  variable i: integer := 0;
begin
  tx_tready2 <= rx_tready1;
  rx_tvalid1 <= tx_tvalid2;
  rx_tdata1  <= tx_tdata2;
  rx_tlast1  <= tx_tlast2;
  
  case state2 is
	when idle =>
	  j_next <= 0;
	  tx_tready2 <= '0';
	  if(tx_tvalid2 = '1') then
		state2_next <= prepend_ip;
	  end if;
	when prepend_ip =>
	  tx_tready2 <= '0';
	  rx_tvalid1 <= '1';
	  if (j = 0 and rx_tready1 = '1') then
		rx_tdata1 <= X"00";
		j_next <= j + 1;
	  elsif (j = 1 and rx_tready1 = '1') then
		rx_tdata1 <= X"00";
		j_next <= j + 1;
	  elsif (j = 2 and rx_tready1 = '1') then
		rx_tdata1 <= X"00";
		j_next <= j + 1;
	  elsif (j = 3 and rx_tready1 = '1') then
		rx_tdata1 <= X"f0";
		j_next <= j + 1;
	  elsif (j = 4 and rx_tready1 = '1') then
		rx_tdata1 <= X"02";
		j_next <= j + 1;
	  elsif (j = 5 and rx_tready1 = '1') then
		rx_tdata1 <= X"00";
		j_next <= j + 1;
	  elsif (j = 6 and rx_tready1 = '1') then
		rx_tdata1 <= X"00";
		j_next <= j + 1;
	  elsif (j = 7 and rx_tready1 = '1') then
		rx_tdata1 <= X"00";
		j_next <= j + 1;
		state2_next <= send_data;
	  end if;
	when send_data =>
	  if(tx_tlast2 = '1') then
	    state2_next <= idle;
	  end if;
    end case;
  
end process;

end behavioural;