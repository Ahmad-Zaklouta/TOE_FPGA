
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

use work.tcp_common.all;

entity acc is
   
   port(
      --------------------------------------------------------------------------------
      -- Inputs from Application
      --------------------------------------------------------------------------------
      i_active_mode  :  in  std_ulogic;
      last           :  in  std_ulogic; -- send data
      i_open         :  in  std_ulogic;      shall i save this to registers?
      --------------------------------------------------------------------------------
      -- Inputs from Rx engine
      --------------------------------------------------------------------------------
      i_header :  in t_tcp_header;
      i_valid  :  in std_ulogic;
      
      --------------------------------------------------------------------------------
      -- Outputs for Rx engine
      --------------------------------------------------------------------------------
      o_forwardRX :  out std_ulogic;
      o_discard  :  out std_ulogic;

      --------------------------------------------------------------------------------
      -- Inputs from Tx engine
      --------------------------------------------------------------------------------
      i_data_size :  in  --register
      --------------------------------------------------------------------------------
      -- Outputs for Tx engine
      --------------------------------------------------------------------------------
      o_header    :  out t_tcp_header;
      o_forwardTX :  out std_ulogic;
 
    );
end acc;

--------------------------------------------------------------------------------
-- The desription of the accelerator.
--------------------------------------------------------------------------------

architecture rtl of acc is

type state_type is ( CLOSED, LISTEN, SYN_SENT, SYN_RCVD, ESTABLISHED, FIN_WAIT_1, FIN_WAIT_2,
                     CLOSE_WAIT, LAST_ACK, CLOSING, TIME_WAIT);
signal state, next_state : state_type;
--signal counter , next_counter
--------------------------------------------------------------------------------
-- Signals to Tx engine
--------------------------------------------------------------------------------
signal   ro_headerRx, ro_next_headerRx      :  t_tcp_header; -- CREATE HEADER ,REPLY TO RECEIVED PACKET 
signal   ro_headerApp, ro_next_headerApp    :  t_tcp_header; -- CREATE HEADER, APP WANTS TO SEND
--------------------------------------------------------------------------------
-- Signals for Tx engine
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- My IP.PORT
--------------------------------------------------------------------------------
signal ip 
signal port_no
   
--------------------------------------------------------------------------------
-- other Procedure signals
--------------------------------------------------------------------------------

signal   r_counter, r_next_counter  :
signal   control  :  std_ulogic;


-- mux me next_reg

begin  
   o_header <= ro_headerApp WHEN control = '1' ELSE ro_headerRx;   
  
   comb_logic: process()     
   begin
      ro_next_headerRx <= ro_headerRx;
      ro_next_headerApp <= ro_headerApp;    
      control <= '1';
      
      case state is
         when CLOSED =>            
            if i_open = '1'  then  -- active_open
               ------------------------
               --construct header sent SYN
               -----------------------
               next_state <=  SYN_SENT;
               ro_next_headerApp.src_ip    <= ???????????;
               ro_next_headerApp.dst_ip    <= ?????????;
               ro_next_headerApp.src_port    <= ???????????;
               ro_next_headerApp.dst_port    <= ?????????;
               ro_next_headerApp.seq_num   <= x"0001";
               -- omit o_header.ack_num 
               ro_next_headerApp.reserved  <= "000";
               ro_next_headerApp.flags     <= "00000010";  --  SENT SYN
               ro_next_headerApp.window_size  <= x"00"
               ro_next_headerApp.urgent_ptr   <= x"00"
               o_forwardTX        <= '1';          -- signat to Tx TO transmit THE SEGMENT 
               
             
            elsif i_open = '0' then  -- passive_open
               read listeing port and ip from App
               next_state <=  LISTEN;
            else
            next_state <= state;
            end if;
            
         when LISTEN =>
            ------------------------
            -- PASSIVE OPEN
            -----------------------
            if i_open = '0'  then   -- appl_close = '1'
               next_state <= CLOSED;
            elsif i_valid = '1' and i_header.flags = "000000010" then --- SYN RECEIVED
               control <= '0';
               if (ip = i_header.dst_ip) and (port_no = i_header.dst_port)   then
               
               
               ro_next_headerRx.src_ip    <= i_header.dst_ip;
               ro_next_headerRx.dst_ip    <= i_header.src_ip;
               ro_next_headerRx.seq_num   <= x"0001";
               ro_next_headerRx.ack_num   <= i_header.seq_num;
               ro_next_headerRx.reserved  <= "000";
               ro_next_headerRx.flags     <= "000010010";  --  SENT SYN,ACK
               ro_next_headerRx.window_size  <= x"00"
               ro_next_headerRx.urgent_ptr   <= x"00"
               o_forwardTX        <= '1';          -- signat to Tx TO transmit THE SEGMENT      
              
               
               next_state <= SYN_RCVD;
               -- NO TIMER HERE
            else 
               next_state <= LISTEN;
            end if;
            
            
         when SYN_SENT =>
            ------------------------
            -- 
            -----------------------
            if i_open = '0' or timeout then  --  if appl_close or timeout
               next_state <= CLOSED;
               ------------------------
               -- At this point ,i cannot receive out of order data so i might omit the if at line 196 ????
               -----------------------
            elsif i_valid = '1' and i_header.flags = "00010010"  then --  !! Here the src dest ip,ports,seq_number should be checked SYN ACK recieved
               if (ro_headerApp.src_ip = i_header.dst_ip) and (ro_headerApp.dst_ip = i_header.src_ip)
                  and (ro_headerApp.dst_port = i_header.src_port) and (ro_headerApp.src_port = i_header.dst_port) then
                  if (ro_headerApp.seq_num = i_header.ack_num) then 
                     ro_next_headerApp.seq_num <= ro_headerApp.seq_num + '1';
                     ro_next_headerApp.ack_num <= i_header.seq_num;
                     ro_next_headerApp.flag <= "000100000";
                     o_forwardTX <= '1';
                     next_state <= ESTABLISHED;
                  else
                     o_discard <= '1';
                     next_state <= SYN_SENT;
                  
                  end if;
               else
                  o_discard <= '1';
                  next_state <= SYN_SENT;
               end if;   
          
            
            else 
               next_state<= SYN_SENT;              
            
            end if;
            
         when SYN_RCVD =>
            if time out go to CLOSED ?????
            if appl_close = '1'  then
               next_state <= FIN_WAIT_1;
               construct packet with Fin
            elsif i_valid  = '1' then
               if i_source_ip = ri_source_ip and sequence number what i expect... then --Generally same port and ips
                  if i_ack = '1';
                     next_state <= ESTABLISHED;
                     ------------------------
                     -- ?????????????????????????????????????????????????????????
                     In the event that a connection request arrives on the server and 
                     that no application is listening on the requested port, a segment 
                     with flag RST (reset) is sent to the client by the server, 
                     the connection attempt is immediately terminated.
                     maybe discard and not take it into consideration?                     
                     ----------------------
                  elsif i_flags = RST  then
                     next_state <= LISTEN;
                  end if;
               else 
                  discard packet -- when discard do i sent a signal back to RX engine?
                  next_state <= SYN_RCVD
               end if;
            elsif time out 
               next_state <= LISTEN ; -- ARE YOU SURE?
            else 
               next_state <= SYN_RCVD;
            end if;
            
         when ESTABLISHED =>
            -- time out is restarting every time a packet is received even if this packet is out of order?
            ------------------------
            -- PASSIVE OPEN
            -----------------------
            if timer out then
               next_state <= LISTEN ,CLOSED ???
            
            elsif i_valid = '1'  then
               if header is ok then
                  if flag has FIN
                     construct header for (send ack) TO TX ENGINE
                     next_state <= CLOSE_WAIT;
                  else
                     -- pass packet to application
                     o_ready_RX_engine <= '1';                  
                     next_state <= ESTABLISHED;                     
                  end if;
            else 
               next_state <= ESTABLISHED;
               end if;
               
            end if;
            
            ------------------------
            -- APP IS SENDING PARALLELY SEQUENCE NUMBER LAST PACKET + 1 ?? CONFLICT DUE TO CHANGING SEQ NUMBER HERE AND LINE 196??
            -----------------------
            if want to send from app 
               build o_header 
               o_ready_TX_engine <= '1';
            end if; 
               
         when FIN_WAIT_1 =>
            ------------------------
            -- ACTIVE OPEN
            -----------------------
            if timeout go to? ??? CLOSED??
            elsif i_valid
               if received FIN 
                  send ack 
                  next_state <= CLOSING;
               elsif received ack of fin in established state
                  next_state <= FIN_WAIT_2;
               elsif receivedfin,ack
                  send ack
                  next_state <= TIME_WAIT;
               else 
                  next_state <= FIN_WAIT_1;
            end if;
         when FIN_WAIT_2 =>
            ------------------------
            -- ACTIVE OPEN
            -----------------------
            if timeout go to? ??? CLOSED??
            elsif i_valid
               if received fin
                  send ack
                  next_state <= TIME_WAIT;
            else 
               next_state <= FIN_WAIT_2;
         when CLOSING =>
            if timeout go to? ??? CLOSED??
            elsif i_valid then
               if receive ack 
               next_state <=TIME_WAIT;
            else 
               next_state <= LAST_ACK;
         
         when TIME_WAIT =>
            wait for some time the go to closed state
         when CLOSE_WAIT =>
            if timeout go to? ??? CLOSED??
            elsif appl_close then
               send FIN
               next_state <=LAST_ACK;
            else
               next_state <= CLOSE_WAIT;
            end if;
         
         when LAST_ACK =>
            if timeout go to? ??? CLOSED??
            elsif i_valid then
               if receive ack 
               next_state <=CLOSED;
            else 
               next_state <= LAST_ACK;
         when others =>
            
         
      end case;
   end process comb_logic;
  
  
  






   clk_logic : process(clk)
      begin
         if rising_edge(clk) then
            if reset = '1' then 
               ri_header   <= (others => '0');.
               ro_header   <= (others => '0');
               
            else
               ri_header   <= ri_next_header;
               ro_header   <= ro_next_header;
               
            
            
            end if;
         end if;
      end process clk_logic;


end rtl;
