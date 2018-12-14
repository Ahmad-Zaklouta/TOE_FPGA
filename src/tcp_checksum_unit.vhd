use std.textio.all;
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tcp_checksum_unit is
  port(
    clk: in std_ulogic;
	reset: in std_ulogic;
	
	i_data: in std_ulogic_vector(7 downto 0);
	i_valid: in std_ulogic;
	i_checksum_en: in std_ulogic;
	i_end_checksum: in std_ulogic;
	o_checksum_comp_finished: out std_ulogic;
	o_error: out std_ulogic;
	o_checksum: out std_ulogic_vector(15 downto 0)	
   );
  
end tcp_checksum_unit;

architecture behavioural of tcp_checksum_unit is
type state_t is (idle, compute1, compute2, add_remainder, ones_complement, finish);
signal state, state_next: state_t;
signal checksum, checksum_next: unsigned(31 downto 0);
signal byte_prev, byte_prev_next: unsigned(7 downto 0);

begin
  comb: process(all)
  begin
    state_next <= state;
	 byte_prev_next <= byte_prev;
	 checksum_next <= checksum;
    o_checksum <= std_ulogic_vector(checksum(15 downto 0));
	o_error    <= '0';
	o_checksum_comp_finished <= '0';
    case(state) is
	  when idle =>
	    if(i_checksum_en = '1' and i_valid = '1') then
		  byte_prev_next <= unsigned(i_data);
		  state_next <= compute2;
		  checksum_next <= (others => '0');
		end if;
	  when compute1 =>
	    if(i_end_checksum = '1' and i_valid = '1') then
          checksum_next <= checksum +  unsigned(X"000000" & i_data);
          state_next <= add_remainder;		  
		elsif (i_valid = '1') then
		  byte_prev_next <= unsigned(i_data);
		  state_next <= compute2;
		end if;
	  when compute2 =>
	    if (i_valid = '1') then
		  checksum_next <= checksum + unsigned(X"0000" & unsigned(i_data) & byte_prev);
	    end if;
		if(i_end_checksum = '1' and i_valid = '1') then
		   state_next <= add_remainder;
		else
		   state_next <= compute1;
		end if;
	  when add_remainder =>
	    if(checksum(31 downto 16) = X"0000") then
		  state_next <= ones_complement;
		else
		  state_next <= add_remainder;
		  checksum_next <= unsigned(X"0000" & checksum(15 downto 0)) + unsigned(X"0000" & checksum(31 downto 16));
        end if;
	  when ones_complement =>
	    checksum_next <= not(checksum(31 downto 0));
		state_next <= finish;
	  when finish =>
	    o_checksum_comp_finished <= '1';
		if(checksum(15 downto 0) = 0) then
          o_error <= '0';
		else
		  o_error <= '1';
		end if;
		state_next <= idle;
	end case;
  end process;
  
  fsm: process(clk)
  begin
    if(rising_edge(clk) and reset = '1') then
	  checksum <= (others => '0');
	  state <= idle;
	  byte_prev <= to_unsigned(0, byte_prev'length);
	elsif(rising_edge(clk)) then
	  checksum <= checksum_next;
	  state <= state_next;
	  byte_prev <= byte_prev_next;
	end if;
  end process;
end behavioural;