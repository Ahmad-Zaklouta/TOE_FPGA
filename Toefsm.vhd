
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
      i_timerApp
      --------------------------------------------------------------------------------
      -- Inputs from Rx engine
      --------------------------------------------------------------------------------
      i_header       :  in t_tcp_header;
      i_valid        :  in std_ulogic;
      i_data_sizeRx  : in std_ulogic;
      
      --------------------------------------------------------------------------------
      -- Outputs for Rx engine
      --------------------------------------------------------------------------------
      o_forwardRX :  out std_ulogic;
      o_discard   :  out std_ulogic;

      --------------------------------------------------------------------------------
      -- Inputs from Tx engine
      --------------------------------------------------------------------------------
      i_data_sizeApp :  in  --register
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

constant ACK_TIMEOUT : integer := xxxxxx;
constant CONNECTION_TIMEOUT : integer := xxxxxx;
type state_type is ( CLOSED, LISTEN, SYN_SENT, SYN_RCVD, ESTABLISHED, FIN_WAIT_1, FIN_WAIT_2,
                     CLOSE_WAIT, LAST_ACK, CLOSING, TIME_WAIT);
signal state, next_state : state_type;

--------------------------------------------------------------------------------
-- Signals to Tx engine
--------------------------------------------------------------------------------
signal   ro_headerRx, ro_next_headerRx      :  t_tcp_header; -- CREATE HEADER ,REPLY TO RECEIVED PACKETs 
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

signal   r_acktimerRx, r_next_acktimerRx  : unsigned (10 downto 0); -- Increased when ack has not been received 
signal   r_timeout, r_next_timeout : unsigned (10 downto 0);  --defined by application (how long to wait for a response before closing connection)
signal   control  :  std_ulogic;



-- mux me next_reg

begin  
   o_header <= ro_headerApp WHEN control = '1' ELSE ro_headerRx;   
  
   comb_logic: process()     
   begin
      ro_next_headerRx <= ro_headerRx;
      ro_next_headerApp <= ro_headerApp;    
      control <= '0';
      o_forwardRX <= '0';
      o_forwardTX <= '0';
      w_activ_timerapp <= '1';
      
      case state is
         when CLOSED =>            
            if i_open = '1'  then  -- active_open
               ------------------------
               --construct header sent SYN
               -----------------------
               control <= '1';
               next_state <=  SYN_SENT;
               ro_next_headerApp.src_ip    <= ???????????; -- fed by App
               ro_next_headerApp.dst_ip    <= ?????????;  -- fed by App
               ro_next_headerApp.src_port    <= ???????????;  -- fed by App
               ro_next_headerApp.dst_port    <= ?????????;  -- fed by App
               ro_next_headerApp.seq_num   <= x"0001";
               -- omit o_header.ack_num 
               ro_next_headerApp.reserved  <= "000";
               ro_next_headerApp.flags     <= "00000010";  --  SENT SYN
               ro_next_headerApp.window_size  <= x"00";
               ro_next_headerApp.urgent_ptr   <= x"00";
               o_forwardTX        <= '1';          -- signat to Tx TO transmit THE SEGMENT 
               
             
            elsif i_open = '0' then  -- passive_open
               read listesing port and ip from App
               ro_next_headerRx.src_ip <= ??;
               ro_next_headerRx.src_port <= ??;
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
            elsif i_valid = '1' and i_header.flags = x"2" then --- SYN RECEIVED
              
               if (ro_headeRx.src_ip = i_header.dst_ip) and (ro_headeRx.src_port = i_header.dst_port)   then                          
               
               
               ro_next_headerRx.dst_ip    <= i_header.src_ip;
               ro_next_headerRx.seq_num   <= x"0001";
               ro_next_headerRx.ack_num   <= i_header.seq_num + 1; -- i expect the next one
               ro_next_headerRx.reserved  <= "000";
               ro_next_headerRx.flags     <= x"12";  --  SENT SYN,ACK
               ro_next_headerRx.window_size  <= x"00";
               ro_next_headerRx.urgent_ptr   <= x"00";
               o_forwardTX        <= '1';          -- signat to Tx TO transmit THE SEGMENT              
               r_next_counter_1 <= r_counter_1 + 1;
               
               next_state <= SYN_RCVD;
               -- NO TIMER HERE
            else 
               next_state <= LISTEN;
            end if;
            
            
         when SYN_SENT =>
            ------------------------
            -- 
            -----------------------
            r_next_acktimerApp <= r_acktimerApp + 1;
            r_next_timeout <= r_timeout +1;
            
            if i_open = '0' or r_timeout = CONNECTION_TIMEOUT then  --  if appl_close or timeout
               next_state <= CLOSED;
            elsif r_acktimerApp = ACK_TIMEOUT then -- if no ack received send again the SYN
               
               --  SENT SYN AGAIN               
               o_forwardTX <= '1';
               r_next_acktimerApp <= (others => '0');
               ------------------------
               -- At this point ,i cannot receive out of order data so i might omit the if at line 196 ????
               -----------------------
            elsif i_valid = '1' and i_header.flags = x"12"  then -- SYN ACK recieved
               if (ro_headerApp.src_ip = i_header.dst_ip) and (ro_headerApp.dst_ip = i_header.src_ip)
                  and (ro_headerApp.dst_port = i_header.src_port) and (ro_headerApp.src_port = i_header.dst_port) then
                  if (i_header.ack_num = ro_headerApp.seq_num + 1) then 
                     ro_next_headerRx.seq_num <= i_header.ack_num; --- plus data_size in establishment mode ro_headerApp.seq_num + '1';
                     ro_next_headerRx.ack_num <= i_header.seq_num + 1;
                     ro_next_headerRx.flag <= x"10";   --  SENT ACK            
                     
                     
                     o_forwardTX <= '1';
                     next_state <= ESTABLISHED;
                     r_next_timeout   <= (others => '0'); --reset timeout
                     r_next_acktimer <= (others => '0'); --reset acktimer
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
            r_next_acktimerRx <= r_acktimerRx +1;
            r_next_timeout <= r_timeout +1;
            
            if r_timeout = ??  then
               next_state <= LISTEN;
               
            elsif r_acktimerRx = ??    then
               ------------------------
               -- Send SYN_ACK AGAIN
               -----------------------
               -- ro_headeRx ,control 0
               o_forwardTX        <= '1';          -- signat to Tx TO transmit THE SEGMENT        
               
               r_next_acktimerRx <= (others => '0');
               next_state <= SYN_RCVD;
            
            
            elsif i_valid  = '1' and i_header.flags = x"10" then --ACK
               if ro_headeRx.dst_ip = i_header.src_ip and ro_headeRx.dst_port = i_header.src_port and 
                  ro_headeRx.src_port = i_header.dst_port and i_header.ack_num = ro_headerRx.seq_num + 1 and
                  ro_headerRx.ack_num = i_header.seq_num + 1 then 
                  -- only here i know his next seq number MUST BE +1
                  
                  ro_next_headeRx.seq_num <= i_header.ack_num;
                  
                  next_state <= ESTABLISHED;                     
                  r_next_acktimerRx <= (others => '0');
                  r_next_timeout <= (others => '0');
                    
                  --elsif i_flags = RST  then
                  ------------------------
                     -- ?????????????????????????????????????????????????????????
                     --In the event that a connection request arrives on the server and 
                     --that no application is listening on the requested port, a segment  -- for simultaneous connecntions 
                     --with flag RST (reset) is sent to the client by the server, 
                     --the connection attempt is immediately terminated.
                     --maybe discard and not take it into consideration?                     
                     ----------------------
                     --next_state <= LISTEN;
                  end if;
               else 
                  o_discard <= '1';
                  next_state <= SYN_RCVD;
               end if;
            
            else 
               next_state <= SYN_RCVD;
            end if;
            
         when ESTABLISHED =>
            -- time out is reseting every time a packet is received 
            r_next_acktimerRx <= r_acktimerRx +1;
            
            r_next_timeout <= r_timeout +1;
            ------------------------
            -- RESPONSE TO RX
            -----------------------
            if i_open = '0'   then 
               control <= '0';
               next_state <= FIN_WAIT_1;              
               
               ro_next_headerApp.seq_num   <= ro_next_headeRx.seq_num + 1;         
               ro_next_headerApp.flags     <= x"1"; --  SENT FIN                  
               ro_next_headerApp.ack_num <= ro_headeRx.ack_num; 
               o_forwardTX        <= '1';      
              
               r_next_acktimerRx <= (others => '0');
               r_next_timeout <= (others => '0');
               -- UPDATE Rx
               ro_next_headerRx.seq_num   <= ro_next_headeRx.seq_num + 1;    
               
            elsif r_timeout = CONNECTION_TIMEOUT then
               next_state <= CLOSED;
               
            elsif r_acktimerRx = ACK_TIMEOUT then
            
               ro_next_headerRx.src_ip    <= ro_headerRx.src_ip;
               ro_next_headerRx.dst_ip    <= ro_headerRx.dst_ip;
               ro_next_headerRx.seq_num   <= ro_headerRx.seq_num;      -- OMIT all these ,i have them stored
               ro_next_headerRx.ack_num   <= ro_headerRx.ack_num;
               ro_next_headerRx.reserved  <= ro_headerRx.reserved;
               ro_next_headerRx.flags     <= ro_headerRx.flags;  --  SENT SYN,ACK
               ro_next_headerRx.window_size  <= ro_headerRx.window_size;
               ro_next_headerRx.urgent_ptr   <= ro_headerRx.urgent_ptr;
               o_forwardTX        <= '1';          -- signat to Tx TO transmit THE SEGMENT        
               
               r_next_acktimerRx <= (others => '0');
               next_state <= ESTABLISHED;         
    
            
            elsif i_valid = '1'  then
            
               if ro_headeRx.dst_ip = i_header.src_ip and ro_headeRx.dst_port = i_header.src_port and   -- if header is ok then
                  ro_headeRx.src_port = i_header.dst_port and ro_headerRx.seq_num = i_header.ack_num then
                  
                  ro_next_headeRx.seq_num <= ro_headeRx.seq_num;  -- we can omit this
                  ro_next_headeRx.flags <= x"10"; --SEND ACK                  
                 
                  r_next_acktimerRx <= (others => '0');
                  
                  if i.header.flags <= x"1"  then    --FIN                  
                     ro_next_headeRx.ack_num <= i_header.seq_num + 1;    -- or + datasize but fin should be 1                 
                     o_ready_TX_engine <= '1';                                   --construct header for (send ack) TO TX ENGINE
                     o_close <= '1'  infrom APP AND WAITS FOR CLOSING SINGAL BY APP IN CLOSE WAIT STATE
                     next_state <= CLOSE_WAIT;
                  
                  else                                
                     ro_next_headeRx.ack_num <= i_header.seq_num + i_data_sizeRx;
                     
                     o_ready_RX_engine <= '1'; 
                     o_ready_TX_engine <= '1';
                     next_state <= ESTABLISHED; 
     
                  end if;
               elsif ro_headeRx.dst_ip = i_header.src_ip and ro_headeRx.dst_port = i_header.src_port and   
                     ro_headeRx.src_port = i_header.dst_port and (ro_headerRx.seq_num = i.header.ack_num - i_data_sizeRx)then
                     -- HERE IF I RECEIVE PREVIOUS ACK
                     o_ready_TX_engine <= '1';
                     next_state <= ESTABLISHED;
               
               else 
                  o_discard <= '1';
               end if;
            else 
               next_state <= ESTABLISHED;
               end if;
               
            end if;
            
              
            ------------------------
            -- APP IS SENDING PARALLELY  NEED ROUND ROBIN for cope with conflicts
            -----------------------
            if last = 1 then           --if app wants to send
               
               ro_next_headerApp.seq_num <= ro_headeRx.seq_num + i_data_sizeApp;
               ro_next_headerApp.ack_num <= ro_headeRx.ack_num;
               ro_next_headerRx.seq_num  <= ro_headeRx.seq_num + i_data_sizeApp;
               o_ready_TX_engine <= '1';
               next_state <= ESTABLISHED;
               
            else next_state <= ESTABLISHED; 
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
         
           -- IF RECEIVE PACKET HERE DISCARD??
            r_next_timeout <= r_timeout + 1;  
            if i_open = '0'   then   
              
               ro_next_headerRx.seq_num <= ro_headeRx.seq_num + 1;              
               ro_next_headerRx.flags  <= x"1";           --send FIN
               o_forwardTX <= '1';
               r_next_timeout <= (others => '0');
               next_state <=LAST_ACK;
            elsif r_timeout = ???  then
               next_state <= CLOSE;
            elsif i_valid <= '1';
               o_discard <= '1';
               next_state <= CLOSE_WAIT;
            else
               next_state <= CLOSE_WAIT;
            end if;
         
         when LAST_ACK =>
         
            r_next_acktimerRx <= r_acktimerRx +1;
            r_next_timeout <= r_timeout +1;
            
            if r_timeout = ??  then
               r_next_timeout <= (others => '0');
               next_state <=CLOSED;
               
            elsif r_acktimerRx = ??    then
               ------------------------
               -- Send SYN_ACK AGAIN
               -----------------------
               o_forwardTX <= '1';
            elsif i_valid = '1' and ro_headeRx.dst_ip = i_header.src_ip and ro_headeRx.dst_port = i_header.src_port and 
                  ro_headeRx.src_port = i_header.dst_port  and i_header.flags = x"10" then
                  
                  next_state <= CLOSE;
                  r_next_timeout <= (others => '0');
              
            
            else 
               next_state <= LAST_ACK;
            end if;   
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
