use std.textio.all;
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use tcp_common.all;

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
	o_we        : out std_ulogic;
  );
end rx_engine;

entity

architecture rx_engine_behaviour of rx_engine is
  type state_t is (await, pseudo_header_read, header_read, read_data, wait_toe);
  type header_buffer_t is array(0 to 27) of std_ulogic_vector(7 downto 0);
  signal tcp_header_reg: t_tcp_header;
  signal header_buffer: header_buffer_t;
  signal state, state_next: state_t;
  signal count, count_next, header_count, header_count_next: std_ulogic_vector(15 downto 0);
  signal checksum, checksum_next: std_ulogic_vector(7 downto 0);
  signal half_word, half_word_next: std_ulogic_vector(15 downto 0);
  signal byte2, byte2_next: std_ulogic; --forms two bit word
  signal address_reg
begin
  comb: process(state, tvalid, tlast, tdata, i_forwardRX, i_discard)
  begin
    tready <= '1';
	
    case state is
	  when await =>
	    if (tvalid = '1') then
		  checksum_next <= std_ulogic_vector(unsigned(checksum) + unsigned(tdata));
		  count_next <= std_ulogic_vector(unsigned(count) + 1);
		  header_count_next <= std_ulogic_vector(unsigned(header_count) + 1);
          header_buffer(0) <= tdata
		end if;
	  when pseudo_header_read =>
	    if (tvalid = '1') then
		  checksum_next <= std_ulogic_vector(unsigned(checksum) + unsigned(tdata));
	      if (unsigned(count) < 11) then
		    if(unsigned(header_count) < 7) then
		      header_buffer(unsigned(header_count)) <= tdata;
			  header_count_next <= std_ulogic_vector(unsigned(header_count) + 1);
			elsif(unsigned(header_count) = 7) then
			  header_buffer(unsigned(header_count)) <= tdata;
			  header_count_next <= std_ulogic_vector(unsigned(header_count) + 1);
			end if;  
		  else
		  
		  end if;
		end if;
	  when header_read =>
	    if (unsigned(count < 31) then
		  header_buffer(unsigned(header_count)) <= tdata;
		  header_count_next <= std_ulogic_vector(unsigned(header_count) + 1);
		else
		  header_buffer(unsigned(header_count)) <= tdata;
		  header_count_next <= std_ulogic_vector(unsigned(header_count) + 1);
		end if;
	  when read_data =>
	    checksum_next <= std_ulogic_vector(unsigned(checksum) + unsigned(tdata));
		if (tlast = '1') then
		
		else
		
		end if;
	  when wait_toe =>
	    --check the checksum here
	end case;
  end process;  

  seq: process(clk)
  begin
    if (rising_edge(clk) and reset = '1') then
	  state <= await;
	  count <= (others => '0');
	  half_word <= (others => '0');
	elsif (rising_edge(clk)
	  state <= state_next;
	  count <= count_next;
	  half_word <= half_word_next;
	end if;
  end process;
end rx_engine_behaviour;