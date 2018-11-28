use std.textio.all;
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.tcp_common.all;

entity application is
  port(
       clk : in std_ulogic;
	   reset: in std_ulogic;
	   
       o_start          :  out std_ulogic;
	   o_active_mode  :  out  std_ulogic;
	   o_open         :  out std_ulogic;     
	   o_timeout      :  out  unsigned (10 downto 0);
	   i_close        :  in  std_ulogic;
	   ---------------------------------------------
	   -- SRC IP,PORT / DST IP,PORT defined by App 
	   ---------------------------------------------
	   o_src_ip       : out   t_ipv4_address;
	   o_dst_ip       : out   t_ipv4_address;
	   o_src_port     : out   t_tcp_port;
	   o_dst_port     : out   t_tcp_port;
	   
       rx_tdata: in std_ulogic_vector(7 downto 0);
       rx_tvalid: in std_ulogic;
	   rx_tready: out std_ulogic;
	   rx_tlast: in std_ulogic;
	   
	   tx_tdata: out std_ulogic_vector(7 downto 0);
	   tx_tvalid: out std_ulogic;
	   tx_tready: in std_ulogic;
	   tx_tlast: out std_ulogic
	   );
	   
end application;

architecture behavioural of application is

type FRAME1 is array(0 to 50) of std_ulogic_vector(7 downto 0);
type FRAME2 is array(0 to 4200) of std_ulogic_vector(7 downto 0);
type FRAME3 is array(0 to 1400) of std_ulogic_vector(7 downto 0);

type state_t is (start_trans, send_frame1, send_frame2, send_frame3, request_close);
signal state: state_t;
signal i: integer:= 0;

signal frame_1: FRAME1;
signal frame_2: FRAME2;
signal frame_3: FRAME3;

begin

o_src_ip <=  x"f0000000"; 
o_dst_ip <=  x"00000002"; 
o_src_port <= x"0f00";
o_dst_port <= x"0002";
o_active_mode <= '1';
o_timeout <= (others => '1');


stim1: process(clk, reset)
begin
  tx_tlast <= '0';
  if(rising_edge(clk) and reset = '1') then
    i <= 0;
	state <= start_trans;
  elsif (rising_edge(clk)) then
    case state is
	  when start_trans =>
	    o_start <= '1';
		o_open <= '1';
	    if (tx_tready = '1') then
		   tx_tvalid <= '1';
		   tx_tdata <= frame_1(i);
		   i <= i + 1;
		   state <= send_frame1;
		end if;
	  when send_frame1 =>
	   tx_tvalid <= '1';
	   tx_tdata  <= frame_1(i);
	   if(tx_tready = '1') then
	     i <= i + 1;
	     if(i = 50) then
	       state <= send_frame2;
		   tx_tlast <= '1';
		   i <= 0;
	     end if;
	   end if;
	  when send_frame2 =>
	    tx_tvalid <= '1';
		tx_tdata <= frame_2(i);
		if(tx_tready = '1') then
		  i <= i + 1;
		  if(i = 4200) then
		    state <= send_frame3;
		    tx_tlast <= '1';
			i <= 0;
		  end if;
		end if;
	  when send_frame3 =>
	    tx_tvalid <= '1';
		tx_tdata <= frame_3(i);
		if(tx_tready = '1') then
		  i <= i + 1;
		  if(i = 1400) then
		    state <= request_close;
		    tx_tlast <= '1';
		  end if;
		end if;
	  when request_close =>
	    o_open <= '0';
	end case;
  end if;
end process;
end behavioural;