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

use work.types.all;

entity acc is
   
   port(
      i_active_open        :
      i_passive_open       :
      --signals to RX engine
      clk                  :  in  std_logic;             -- The clock.
      reset                :  in  std_logic;             -- The reset signal. Active high.
      i_source_ip          :   
      i_dest_ip            :
      i_source_port        :
      i_dest_port          :
      i_flags              :
      i_sequence_number    :
      i_data_size          :
      i_valid              :
   -- signals to TX engine
      o_ready              :
      o_source_ip          :
      o_dest_ip            :
      o_flags              :
      o_sequence_number
      o_ack                :
      o_header             :
      o_data_size          :
      o_sent               :
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
signal   ri_source_port, ri_next_source_port          :  
signal   ri_source_ip, ri_next_source_ip              : 
signal   ri_dest_ip, ri_next_dest_ip                  :
signal   ri_dest_port, ri_next_dest_port              :
signal   wo_dest_ip, wo_next_dest_ip                  :
signal   ri_sequence_number, ri_next_sequence_number  :
signal   ro_sequence_number, ro_next_sequence_number  :
signal   ri_header, ri_next_header                    :
signal   ro_header, ro_next_header                    :

signal   counter, next_counter                        :

-- All internal signals are defined here



-- mux me next_reg

begin
   
   
   comb_logic: process()     
   begin
      i_dest_ip <= ri_dest_ip;
      i_source_ip <= ri_source_ip;
      i_source_port <= ri_source_port;
      i_dest_port <= ri_dest_port;
      
      i_sequence_number <= ri_sequence_number;
      
      case state is
         when CLOSED =>
            if i_active_open = '1'  then
               next_state <=  SYN_SENT;
               build header sent SYN
            elsif i_passive_open = '1' then
               next_state <=  LISTEN;
            end if;
            
         when LISTEN =>
            ------------------------
            -- PASSIVE OPEN
            -----------------------
            if appl_close = '1'  then
               next_state <= CLOSED;
            elsif i_valid = '1' and i_flags = "000000010" then --- SYN is high
               --ri_next_header <= ri_header; SAVE THE HEADER
               ri_next_dest_ip <= ri_dest_ip;
               ri_next_dest_port <= ri_dest_port;
               ri_next_source_ip <= 
               
               ri_next_sequence_number
               SENT SYN,ACK
               o_header <= i_dest_ip & i_source_ip ..... --counstruct the header for send the SYN,ACK
               o_ready_TX_engine <= '1'; -- signat to Tx TO SEND THE SEGMENT
               
               next_state <= SYN_RCVD;
               -- NO TIMER HERE
            else 
               next_state <= LISTEN;
            end if;
            
            
         when SYN_SENT =>
            ------------------------
            -- ACTIVE OPEN
            -----------------------
            if appl_close or timeout then
               next_state <= CLOSED;
               
            elsif i_valid = '1' and i_flags = "000000010" !! Here the src dest ip,ports,seq_number should be checked then --- SYN is high
               --ri_next_header <= ri_header; SAVE THE HEADER !! if wrong ip or port send rst ?
               ri_next_dest_ip <= ri_dest_ip;
               ri_next_dest_port <= ri_dest_port;
               ri_next_source_ip <= 
               
               ri_next_sequence_number
               
               o_header <= i_dest_ip & i_source_ip ..... --counstruct the header for send the SYN,ACK
               o_ready_TX_engine <= '1'; -- signat to Tx TO SEND THE SEGMENT
               SEND SYN,ACK 
               next_state <= SYN_RCVD;
               
            elsif i_valid, synack received , sent ack and goto ESTABLISHED
            
            else next_state<= SYN_SENT;
               
               
            
            end if;
            
         when SYN_RCVD =>
         
            if appl_close = '1'  then
               next_state <= FIN_WAIT_1;
               --construct packet with Fin
            elsif i_valid  = '1' then
               if i_source_ip = ri_source_ip and sequence number what i expect... then --Generally same port and ips
                  if i_ack = '1';
                     next_state <= ESTABLISHED;
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
            else 
               next_state <= ESTABLISHED;
               end if;
               
            end if;
            
            ------------------------
            -- ACTIVE OPEN
            -----------------------
            if want to send from app 
               build o_header 
               o_ready_TX_engine <= '1';
               
               
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
            
            end if;
         end if;
      end process clk_logic;


end rtl;
