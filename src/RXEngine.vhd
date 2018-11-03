use std.textio.all;
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.tcp_common.all;

entity rx_engine is
  port(
    clk         : in std_ulogic;
	reset       : in std_ulogic;
	
	-- To and from FSM
    i_forwardRX : in std_ulogic;
	i_discard   : in std_ulogic;
	o_header    : out t_tcp_header;
	o_valid     : out std_ulogic;
	-- AXI-4 between network interface and TOE
	tvalid      : in std_ulogic;
	tlast       : in std_ulogic;
	tready      : out std_ulogic;
	tdata       : in std_ulogic_vector(7 downto 0);
	-- Data to the RX buffer
	o_address   : out std_ulogic_vector(15 downto 0);
	o_data      : out std_ulogic_vector(7 downto 0);
	o_we        : out std_ulogic
  );
end rx_engine;


architecture rx_engine_behaviour of rx_engine is
  type state_t is (await, pseudo_header_read, header_read, read_data, wait_toe);
  type header_buffer_t is array(0 to 27) of std_ulogic_vector(7 downto 0);
  
  signal header_buffer: header_buffer_t;
  signal state, state_next: state_t;
  signal count, count_next, header_count, header_count_next: std_ulogic_vector(15 downto 0) := (others => '0');
  signal checksum, checksum_next: std_ulogic_vector(15 downto 0) := (others => '0');
  signal byte2, byte2_next: std_ulogic := '0'; --forms two bit word
  
begin
  comb: process(state, tvalid, tlast, tdata, i_forwardRX, i_discard)
  begin
    tready <= '1';
	o_valid <= '0';
	
    case state is
	  when await =>
	    if (tvalid = '1') then
		  checksum_next <= X"00" & (checksum(7) xor tdata(7)) & (checksum(6) xor tdata(6)) & (checksum(5) xor tdata(5)) & (checksum(4) xor tdata(4)) & (checksum(3) xor tdata(3)) & (checksum(2) xor tdata(2)) & (checksum(1) xor tdata(1)) & (checksum(0) xor tdata(0));
		  byte2_next <= not byte2;
		  count_next <= std_ulogic_vector(unsigned(count) + 1);
		  header_count_next <= std_ulogic_vector(unsigned(header_count) + 1);
          header_buffer(0) <= tdata;
		  state_next <= pseudo_header_read;
		end if;
	  when pseudo_header_read =>
	    if (tvalid = '1') then
		  byte2_next <= not byte2;
		  if(byte2 = '0') then
		    checksum_next <=checksum(15 downto 8) & (checksum(7) xor tdata(7)) & (checksum(6) xor tdata(6)) & (checksum(5) xor tdata(5)) & (checksum(4) xor tdata(4)) & (checksum(3) xor tdata(3)) & (checksum(2) xor tdata(2)) & (checksum(1) xor tdata(1)) & (checksum(0) xor tdata(0));
	      else
		    checksum_next <= (checksum(15) xor tdata(7)) & (checksum(14) xor tdata(6)) & (checksum(13) xor tdata(5)) & (checksum(12) xor tdata(4)) & (checksum(11) xor tdata(3)) & (checksum(10) xor tdata(2)) & (checksum(9) xor tdata(1)) & (checksum(8) xor tdata(0)) & checksum(7 downto 0);
		  end if;
		  if (unsigned(count) < 11) then
		    if(unsigned(header_count) < 7) then
		      header_buffer(to_integer(unsigned(header_count))) <= tdata;
			  header_count_next <= std_ulogic_vector(unsigned(header_count) + 1);
			elsif(unsigned(header_count) = 7) then
		      header_buffer(to_integer(unsigned(header_count))) <= tdata;
			  header_count_next <= std_ulogic_vector(unsigned(header_count) + 1);
			end if;  
		  else
		    state_next <= header_read;
		  end if;
		end if;
	  when header_read =>
	    if(tvalid = '1') then  
		  byte2_next <= not byte2;
		  if(byte2 = '0') then
		    checksum_next <=checksum(15 downto 8) & (checksum(7) xor tdata(7)) & (checksum(6) xor tdata(6)) & (checksum(5) xor tdata(5)) & (checksum(4) xor tdata(4)) & (checksum(3) xor tdata(3)) & (checksum(2) xor tdata(2)) & (checksum(1) xor tdata(1)) & (checksum(0) xor tdata(0));
	      else
		    checksum_next <= (checksum(15) xor tdata(7)) & (checksum(14) xor tdata(6)) & (checksum(13) xor tdata(5)) & (checksum(12) xor tdata(4)) & (checksum(11) xor tdata(3)) & (checksum(10) xor tdata(2)) & (checksum(9) xor tdata(1)) & (checksum(8) xor tdata(0)) & checksum(7 downto 0);
		  end if;
		  if (unsigned(count) < 31) then
		      header_buffer(to_integer(unsigned(header_count))) <= tdata;
		    header_count_next <= std_ulogic_vector(unsigned(header_count) + 1);
		  else
		    header_buffer(to_integer(unsigned(header_count))) <= tdata;
		    header_count_next <= std_ulogic_vector(unsigned(header_count) + 1);
		  end if;
	      if(tlast = '1') then
			  state_next <= wait_toe;
		    else
			  state_next <= read_data;
		  end if;
		end if;
	  when read_data =>
	    if(tvalid = '1') then
	      byte2_next <= not byte2;
		  if(byte2 = '0') then
		      checksum_next <= checksum(15 downto 8) & (checksum(7) xor tdata(7)) & (checksum(6) xor tdata(6)) & (checksum(5) xor tdata(5)) & (checksum(4) xor tdata(4)) & (checksum(3) xor tdata(3)) & (checksum(2) xor tdata(2)) & (checksum(1) xor tdata(1)) & (checksum(0) xor tdata(0));
	      else
		      checksum_next <= (checksum(15) xor tdata(7)) & (checksum(14) xor tdata(6)) & (checksum(13) xor tdata(5)) & (checksum(12) xor tdata(4)) & (checksum(11) xor tdata(3)) & (checksum(10) xor tdata(2)) & (checksum(9) xor tdata(1)) & (checksum(8) xor tdata(0)) & checksum(7 downto 0);
		  end if;
		  if (tlast = '1') then
		    state_next <= wait_toe;
			tready <= '0';
		  end if;
		end if;
	  when wait_toe =>
	    --check the checksum here
		tready <= '0';
		if(i_forwardRX = '1') then
		  state_next <= await;
		elsif(i_discard = '1') then
		  state_next <= await;
		end if;
	end case;
  end process;  

  seq: process(clk)
  begin
    if (rising_edge(clk) and reset = '1') then
	  state <= await;
	  count <= (others => '0');
	  byte2 <= '0';
	  checksum <= (others => '0');
	elsif (rising_edge(clk)) then
	  state <= state_next;
	  count <= count_next;
	  byte2 <= byte2_next;
	  checksum <= checksum_next;
	end if;
  end process;
end rx_engine_behaviour;