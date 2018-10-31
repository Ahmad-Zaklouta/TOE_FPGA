-- -----------------------------------------------------------------------------
--
--  Title      :  Edge-Detection design project - task 2.
--             :
--  Developers :  YOUR NAME HERE - s??????@student.dtu.dk
--             :  YOUR NAME HERE - s??????@student.dtu.dk
--             :
--  Purpose    :  This design contains an entity for the accelerator that must be build
--             :  in task two of the Edge Detection design project. It contains an
--             :  architecture skeleton for the entity as well.
--             :
--  Revision   :  1.0   ??-??-??     Final version
--             :
--
-- -----------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- The entity for task two. Notice the additional signals for the memory.
-- reset is active high.
--------------------------------------------------------------------------------

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
      last           :  in  -- send data
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
-- Signals for Rx engine
--------------------------------------------------------------------------------
signal   ri_header, ri_next_header ;
signal   ri_source_port, ri_next_source_port          :  t_tcp_header.src_port;
signal   ri_source_ip, ri_next_source_ip              :  t_tcp_header.src_ip;
signal   ri_dest_ip, ri_next_dest_ip                  :  t_tcp_header.dst_ip;
signal   ri_dest_port, ri_next_dest_port              :  t_tcp_header.dst_port;
signal   ri_sequence_number, ri_next_sequence_number  :  t_tcp_header.seq_num;
signal   ri_ack_num, ri_next_ack_num                  :  t_tcp_header.ack_num;
signal   ri_data_offset, ri_next_data_offset          :  t_tcp_header.data_offset;
signal   ri_reserved, ri_next_reserved                :  t_tcp_header.reserved;
signal   ri_flags, ri_next_flags                      :  t_tcp_header.flags;
signal   ri_window_size, ri_next_window_size          :  t_tcp_header.window_size;
--- checksum not neseccary on this entity
signal   ri_urgent_ptr, ri_next_urgent_ptr            :  t_tcp_header.urgent_ptr;
--signal   wi_valid                                     :  std_ulogic;
--signal   wo_forwardRX                                 :  std_ulogic;
--signal   wo_ discard                                  :  std_ulogic;
--------------------------------------------------------------------------------
-- Signals for Tx engine
--------------------------------------------------------------------------------
signal   ro_clheader, ro_next_clheader      :  t_tcp_header;
signal   ro_svrheader, ro_next_svrheader    :  t_tcp_header;

signal   wo_header    :  t_tcp_header;
signal   ro_source_port, ro_next_source_port          :  t_tcp_header.src_port;
signal   ro_source_ip, ro_next_source_ip              :  t_tcp_header.src_ip;
signal   ro_dest_ip, ro_next_dest_ip                  :  t_tcp_header.dst_ip;
signal   ro_dest_port, ro_next_dest_port              :  t_tcp_header.dst_port;
signal   ro_sequence_number, ro_next_sequence_number  :  t_tcp_header.seq_num;
signal   ro_ack_num, ro_next_ack_num                  :  t_tcp_header.ack_num;
signal   ro_data_offset, ro_next_data_offset          :  t_tcp_header.data_offset;
signal   ro_reserved, ro_next_reserved                :  t_tcp_header.reserved;
signal   ro_flags, ro_next_flags                      :  t_tcp_header.flags;
signal   ro_window_size, ro_next_window_size          :  t_tcp_header.window_size;
--- checksum not neseccary on this entity
signal   ro_urgent_ptr, ro_next_urgent_ptr            :  t_tcp_header.urgent_ptr;
--signal   wi_data_size                               :  --Register

   
--------------------------------------------------------------------------------
-- Procedure signals
--------------------------------------------------------------------------------
signal   r_counter, r_next_counter                        :

-- All internal signals are defined here



-- mux me next_reg

begin

   o_header <= ro_header;
   
   
   
   comb_logic: process()     
   begin
      ri_next_header <= ri_header;
      ro_next_header <= ro_header;           
      
      case state is
         when CLOSED =>            
            if i_open = '1'  then  -- active_open
               ------------------------
               --construct header sent SYN
               -----------------------
               next_state <=  SYN_SENT;
               ro_next_clheader.src_ip    <= ???????????;
               ro_next_clheader.dst_ip    <= ?????????;
               ro_next_clheader.seq_num   <= x"0001";
               -- omit o_header.ack_num 
               ro_next_clheader.reserved  <= "000";
               ro_next_clheader.flags     <= "00000010";  --  SENT SYN,ACK
               ro_next_clheader.window_size  <= x"00"
               ro_next_clheader.urgent_ptr   <= x"00"
               o_forwardTX        <= '1';          -- signat to Tx TO transmit THE SEGMENT 
               
             
            elsif i_open = '0' then  -- passive_open
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
            elsif i_valid = '1' and i_header.flags = "000000010" then --- SYN is high
               ri_next_header <= i_header;
               --ri_next_header <= ri_header; SAVE THE HEADER
               ro_next_svrheader.src_ip    <= i_header.dst_ip;
               ro_next_svrheader.dst_ip    <= i_header.src_ip;
               ro_next_svrheader.seq_num   <= x"0001";
               ro_next_svrheader.ack_num   <= i_header.seq_num;
               ro_next_svrheader.reserved  <= "000";
               ro_next_svrheader.flags     <= "000010010";  --  SENT SYN,ACK
               ro_next_svrheader.window_size  <= x"00"
               ro_next_svrheader.urgent_ptr   <= x"00"
               o_forwardTX        <= '1';          -- signat to Tx TO transmit THE SEGMENT      
              
               
               next_state <= SYN_RCVD;
               -- NO TIMER HERE
            else 
               next_state <= LISTEN;
            end if;
            
            
         when SYN_SENT =>
            ------------------------
            -- ACTIVE OPEN
            -----------------------
            if i_open = '0' or timeout then  --  if appl_close or timeout
               next_state <= CLOSED;
               ------------------------
               -- At this point ,i cannot receive out of order data so i might omit if at line 196 ????
               -----------------------
            elsif i_valid = '1' and i_header.flags = "00010010"  then --  !! Here the src dest ip,ports,seq_number should be checked SYN ACK recieved
               if (ro_clheader.src_ip = i_header.dst_ip) and (ro_clheader.dst_ip = i_header.src_ip)
                  and (ro_clheader.dst_port = i_header.src_port) and (ro_clheader.src_port = i_header.dst_port) then
                  if (ro_header.seq_num = i_header.ack_num) then 
                     ro_next_clheader.seq_num <= ro_clheader.seq_num + '1';
                     ro_next_clheader.ack_num <= i_header.seq_num;
                     ro_next_clheader.flag <= "000100000";
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
