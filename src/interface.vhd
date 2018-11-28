LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;

entity interface is
  port(
    clk: in std_ulogic;
	reset: in std_ulogic;
  
    tx_tready1: out std_ulogic;
	tx_tvalid1: in std_ulogic;
	tx_tdata1:  in std_ulogic_vector(7 downto 0);
	tx_tlast1:  in std_ulogic;
	
	tx_tready2: out std_ulogic;
	tx_tvalid2: in std_ulogic;
	tx_tadata2: in std_ulogic_vector(7 downto 0);
	tx_tlast2:  in std_ulogic;
	
	rx_tready1: in std_ulogic;
	rx_tvalid1: out std_ulogic;
	rx_tdata1:  out std_ulogic_vector(7 downto 0);
	rx_tlast1:  out std_ulogic;
	
	rx_tready2: in std_ulogic;
	rx_tvalid2: out std_ulogic;
	rx_tdata2:  out std_ulogic_vector(7 downto 0);
	rx_tlast2:  out std_ulogic;
  );
end interface;

architecture behavioural is
type state_t is (idle, prepend_ip, send_data);

signal state1, state2: state_t;
signal first_buff1, first_buff2: std_ulogic_vector(7 downto 0);

begin

seq1: process(clk, reset)

variable i: integer := 0;

begin
  tx_tready1 <= rx_tready2;
  rx_tvalid2 <= tx_tvalid1;
  rx_tdata2  <= tx_tdata1;
  rx_tlast2  <= tx_tlast1;
  
  if(rising_edge(clk) and reset = '1') then
    i := 0;
	state1 <= idle;
  elsif(rising_edge(clk)) then
	  case state_t is
		when idle =>
		  tx_ready1 <= '0';
		  if(tx_valid1 = '1') then
			state1 <= prepend_ip;
		  end if;
		when prepend_ip =>
		  tx_ready1 <= '0';
		  rx_valid <= '1';
		  if (i = 0) then
			
       end case;
   end if;	   
end process;

seq2: process(clk, reset)
begin
  tx_tready2 <= rx_tready1;
  rx_tvalid1 <= tx_tvalid2;
  rx_tdata1  <= tx_tdata2;
  rx_tlast1  <= tx_tlast2;
  
end process;

end behavioural;