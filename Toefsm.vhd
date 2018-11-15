
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

use work.tcp_common.all;

entity toefsm is
   
   port(
      --------------------------------------------------------------------------------
      -- Inputs from Application
      --------------------------------------------------------------------------------
      clk            :  in  std_ulogic;
      reset          :  in  std_ulogic;
      start          :  in  std_ulogic;
      i_active_mode  :  in  std_ulogic;
      last           :  in  std_ulogic; -- send data
      i_open         :  in  std_ulogic;     -- shall i save this to registers?
      i_timeout      :  in  unsigned (10 downto 0);
      o_close        :  out  std_ulogic;
      --------------------------------------------------------------------------------
      -- SRC IP,PORT / DST IP,PORT defined by App 
      --------------------------------------------------------------------------------
      i_src_ip       :  in  t_ipv4_address;
      i_dst_ip       :  in  t_ipv4_address;
      i_src_port     :  in  t_tcp_port;
      i_dst_port     :  in  t_tcp_port;
      --------------------------------------------------------------------------------
      -- Inputs from Rx engine
      --------------------------------------------------------------------------------
      i_header       :  in t_tcp_header;
      i_valid        :  in std_ulogic;
      i_data_sizeRx  :  in unsigned(31 downto 0);
      
      --------------------------------------------------------------------------------
      -- Outputs for Rx engine
      --------------------------------------------------------------------------------
      o_forwardRX :  out std_ulogic;
      o_discard   :  out std_ulogic;

      --------------------------------------------------------------------------------
      -- Inputs from Tx engine
      --------------------------------------------------------------------------------
      i_data_inbuffer :  in std_ulogic;
      i_data_sizeApp  :  in unsigned(31 downto 0);
      --------------------------------------------------------------------------------
      -- Outputs for Tx engine
      --------------------------------------------------------------------------------
      o_Txsenddata : out std_ulogic; -- to say to the Tx when doing the handshake not to send data that may be stored in the buffer
      o_header    :  out t_tcp_header;
      o_forwardTX :  out std_ulogic
 
    );
end toefsm;

--------------------------------------------------------------------------------
-- The desription of the accelerator.
--------------------------------------------------------------------------------

architecture rtl of toefsm is

constant ACK_TIMEOUT : integer := 4;
constant CONNECTION_TIMEOUT : integer := 15;
type state_type is ( CLOSED, LISTEN, SYN_SENT, SYN_RCVD, ESTABLISHED, FIN_WAIT_1, FIN_WAIT_2,
                     CLOSE_WAIT, LAST_ACK, CLOSING, TIME_WAIT);
signal state, next_state : state_type;

--------------------------------------------------------------------------------
-- HEADER REGISTERS
--------------------------------------------------------------------------------
signal   r_header, r_next_header      :  t_tcp_header; -- CREATE HEADER ,REPLY TO RECEIVED PACKETs  and transmit
signal   r_headerApp_seq_num, r_next_headerApp_seq_num    :  t_seq_num;
-- r_headerApp.seq_num keeps track of the sequence from our APP 
--while for checking the seq num from the other side we have the ack_num
signal   r_previous_ack_num, r_next_previous_ack_num     :  t_seq_num;
  ----- ACK FIELD THAT NI HAS SENT 
--------------------------------------------------------------------------------
-- other Procedure signals
--------------------------------------------------------------------------------
signal   w_waitforack   : std_ulogic;
signal   r_acktimerApp, r_next_acktimerApp  : unsigned (10 downto 0); -- Increased when ack has not been received 
signal   r_timeout, r_next_timeout : unsigned (10 downto 0);  --defined by application (how long to wait for a response before closing connection)
signal   r_open, r_next_open : std_ulogic;



-- mux me next_reg

begin  
  
   o_header <= r_header;   
   -- DISCARD SHOULD BE HIGH WHEN NOT NEED TO PROCESS DATA
   
   
   comb_logic: process(r_header, r_headerApp_seq_num, i_header, state, i_open, i_src_ip, i_dst_ip, i_src_port, i_dst_port,
                       i_data_sizeApp, i_data_sizeRx, i_valid, i_timeout, i_active_mode, r_acktimerApp, r_timeout, last, start
                       , r_previous_ack_num)     
   begin
      r_next_header <= r_header;
      r_next_headerApp_seq_num <= r_headerApp_seq_num; 
      r_next_previous_ack_num <= r_previous_ack_num;      
      o_forwardRX <= '0';
      o_forwardTX <= '0';
      o_discard <= '0';
      r_next_acktimerApp <= r_acktimerApp;
      r_next_timeout <= r_timeout;
      case state is
         when CLOSED =>            
            if i_active_mode = '1' and start = '1' then  -- active_open
               ------------------------
               --construct header sent SYN
               -----------------------
               
               r_next_header.src_ip    <= i_src_ip; -- fed by App
               r_next_header.dst_ip    <= i_dst_ip;  -- fed by App
               r_next_header.src_port  <= i_src_port; -- fed by App
               r_next_header.dst_port  <= i_dst_port;  -- fed by App
               r_next_header.seq_num   <= x"00000001";
               -- omit o_header.ack_num 
               r_next_header.reserved  <= "000";
               r_next_header.flags     <= "000000010";  --  SENT SYN
               r_next_header.window_size  <= x"0000";
               r_next_header.urgent_ptr   <= x"0000";
               o_forwardTX        <= '1';          -- signat to Tx TO transmit THE SEGMENT 
               next_state <=  SYN_SENT;
             
            elsif i_active_mode = '0' and start = '1' then  -- passive_open               
               r_next_header.src_ip <= i_src_ip; -- fed by App
               r_next_header.src_port <= i_src_port; -- fed by App
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
               o_discard <= '1'; -- for karol to move to next state
            elsif i_valid = '1' and i_header.flags(1 downto 0) =  "10" then --- SYN RECEIVED              
               if (r_header.src_ip = i_header.dst_ip) and (r_header.src_port = i_header.dst_port)   then                  
               r_next_header.dst_port     <= i_header.src_port;
               r_next_header.dst_ip       <= i_header.src_ip;
               r_next_header.seq_num      <= x"00000001";
               r_next_header.ack_num      <= i_header.seq_num + 1; -- should be one
               r_next_header.reserved     <= "000";
               r_next_header.flags        <= '0'&x"12";  --  SENT SYN,ACK
               r_next_header.window_size  <= x"0000";
               r_next_header.urgent_ptr   <= x"0000";
               o_forwardTX        <= '1';          -- signat to Tx TO transmit THE SEGMENT              
               next_state <= SYN_RCVD;
               
               -- NO TIMER HERE
               else
               o_discard <= '1';
               next_state <= LISTEN;
               end if;
            else                   
               next_state <= LISTEN;
            end if;            
            
         when SYN_SENT =>
            
            r_next_acktimerApp <= r_acktimerApp + 1;
            r_next_timeout <= r_timeout +1;
            
            if i_open = '0' or r_timeout = CONNECTION_TIMEOUT then  --  if appl_close or timeout
               next_state <= CLOSED;
            elsif r_acktimerApp = ACK_TIMEOUT then -- if no ack received send again the SYN              
               --  SENT SYN AGAIN               
               o_forwardTX <= '1';
               r_next_acktimerApp <= (others => '0');
               ------------------------
               -- At this point ,i cannot receive out of order data 
               -----------------------
            elsif i_valid = '1' and i_header.flags = '0' & x"12"  then -- SYN ACK recieved           
               if (r_header.src_ip = i_header.dst_ip) and (r_header.dst_ip = i_header.src_ip)
                  and (r_header.dst_port = i_header.src_port) and (r_header.src_port = i_header.dst_port) then
                  if (i_header.ack_num = r_header.seq_num + 1) then 
                     r_next_header.seq_num <= i_header.ack_num; -- update App so tha next time he sends to know the seq_num
                     r_next_headerApp_seq_num <= i_header.ack_num;
                     r_next_header.ack_num <= i_header.seq_num + 1;                   
                     r_next_header.flags <= '0'&x"10";   --  SENT ACK                      
                     o_forwardTX <= '1';
                     next_state <= ESTABLISHED;
                     r_next_previous_ack_num <= i_header.ack_num; 
                     r_next_timeout   <= (others => '0'); --reset timeout
                     r_next_acktimerApp <= (others => '0'); --reset acktimer
                     
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
            r_next_acktimerApp <= r_acktimerApp +1;
            r_next_timeout <= r_timeout +1;
            -- ADD CASE WHEN OUR APP WANTS TO CLOSE
            if r_timeout = CONNECTION_TIMEOUT  then
               o_discard <= '1'; -- to prevent conflict if i receive a segment here
               r_next_timeout <= (others => '0');
               next_state <= LISTEN;               
            elsif r_acktimerApp = ACK_TIMEOUT    then
               ------------------------
               -- Send SYN_ACK AGAIN
               -----------------------
               -- ro_headeRx ,control 0
               o_forwardTX        <= '1';          -- signat to Tx TO transmit THE SEGMENT             
               r_next_acktimerApp <= (others => '0');
               o_discard <= '1'; -- to prevent conflict if i receive ack here
               next_state <= SYN_RCVD;            
            elsif i_valid  = '1' and i_header.flags = '0' & x"10" then --ACK received
               if r_header.dst_ip = i_header.src_ip and r_header.dst_port = i_header.src_port and 
                  r_header.src_port = i_header.dst_port and r_header.src_ip = i_header.dst_ip and
                  r_header.seq_num +1 = i_header.ack_num then 
                  -- only here i know his next seq number MUST BE +1                  
                  r_next_header.seq_num <= i_header.ack_num; --update     
                   r_next_headerApp_seq_num <= i_header.ack_num;  --update
                  next_state <= ESTABLISHED;                      
                  r_next_acktimerApp <= (others => '0');
                  r_next_timeout <= (others => '0');                  
               
               else 
                  o_discard <= '1';
                  next_state <= SYN_RCVD;
               end if;           
            else 
               o_discard <= '1';
               next_state <= SYN_RCVD;
            end if;
        
         when ESTABLISHED =>
            
            -- ack timer is reseting every time an ack is received 
            -- we start the counter only when our side waits an ack
            if w_waitforack = '1' then
            r_next_acktimerApp <= r_acktimerApp +1; 
            end if;
            r_next_timeout <= r_timeout +1;
            ------------------------
            -- RESPONSE TO App
            -----------------------
            if i_open = '0'   then                         
               next_state <= FIN_WAIT_1;                
              
               r_next_header.flags   <= '0' & x"01"; --  SENT FIN                  
               r_next_header.ack_num <= r_header.ack_num; 
               o_forwardTX        <= '1';                    
               r_next_acktimerApp <= (others => '0');
               r_next_timeout <= (others => '0');
               -- UPDATE Rx
               r_next_headerApp_seq_num   <= r_header.seq_num + 1;    
               
            elsif r_timeout = CONNECTION_TIMEOUT then
               next_state <= CLOSED;
               
            elsif r_acktimerApp = ACK_TIMEOUT then            
              
               r_next_header.seq_num   <= r_header.seq_num;     
               r_next_header.ack_num   <= r_header.ack_num;             
               r_next_header.flags     <= r_header.flags;                
               o_forwardTX        <= '1';          -- signat to Tx TO transmit THE SEGMENT                
               r_next_acktimerApp <= (others => '0');
               next_state <= ESTABLISHED;         
    
            ------------------------
            -- YOU RECEIVE A PACKET BUT DONT WANT TO SEND DATA FROM YOUR SIDE AT THE SAME TIME
            -----------------------   
            elsif i_valid = '1' and last = '0'  then                 
               if r_header.dst_ip = i_header.src_ip and r_header.dst_port = i_header.src_port and  
                  r_header.src_port = i_header.dst_port and r_header.src_ip = i_header.dst_ip then                   
                  ------------------------------------------
                  -- ACKNOWLEDGE FOR PACKET SENT BY OUR APP  
                  ------------------------------------------                    
                  if i_header.flags ='0' & x"10"  then   --ACK  of packet that i have send
                     next_state <= ESTABLISHED;
                     
                     r_next_acktimerApp <= (others => '0');
                     
                     if i_data_sizeRx ='0' & x"0000" and i_header.ack_num = r_headerApp_seq_num and i_header.ack_num /= r_previous_ack_num then           --expected         
                        r_next_previous_ack_num <= i_header.ack_num;   
                        r_next_header.seq_num <= i_header.ack_num; --UPDATE seq_num 
                        w_waitforack <='0';                                               
                        -- DISCARD OR FORWARD TO RX for driving it to change state
                        ------------------------
                        -- IF I RECEIVE ALSO DATA UPDATE ACK NUM too
                        -----------------------                        
                     elsif i_data_sizeRx /='0' & x"0000"  and i_header.ack_num = r_headerApp_seq_num then --r_expectedheader.seq_num  
                        --ack of packet that i have send plus his data        
                        r_next_previous_ack_num <= i_header.ack_num;
                        r_next_header.ack_num <= i_header.seq_num + i_data_sizeRx; -- update both and send ack of data                          
                        r_next_header.seq_num <= i_header.ack_num; --UPDATE seq_num                                        
                        r_next_header.flags <='0'& x"10"; --SEND ACK 
                        o_forwardRX <= '1'; 
                        o_forwardTX <= '1';
                        w_waitforack <='1';
                     ------------------------
                     -- HERE IF I RECEIVE PREVIOUS SEGMENT's ACK
                     -----------------------      
                     elsif (i_header.ack_num = r_previous_ack_num )then                     
                        o_discard <= '1';    
                        o_forwardTX <= '1'; --SEND ACK AGAIN   
                      ------------------------
                     else
                        o_discard <= '1';
                 
                     end if;
                  ------------------------
                  -- HERE IF I RECEIVE PREVIOUS SEGMENT
                  -----------------------      
                  elsif (i_header.seq_num = r_previous_ack_num )then                     
                        o_discard <= '1';    
                        o_forwardTX <= '1'; --SEND ACK AGAIN
                        next_state <= ESTABLISHED;
                  ------------------------
                  -- RECEIVE FIN
                  -----------------------  
                  elsif i_header.flags = '0'& x"01" and i_header.ack_num = r_headerApp_seq_num  then    --FIN               
                     o_forwardTX <= '1';        --construct header for (send ack) TO TX ENGINE
                     --o_close <= '1'; -- infrom APP AND WAITS FOR CLOSING SINGAL BY APP IN CLOSE WAIT STATE , i do that in closewait state.
                     --r_next_seq_num <= ro_next_headerRx.ack_num + 1;
                     r_next_header.ack_num <= r_header.ack_num + 1; 
                     r_next_header.seq_num <= r_header.seq_num;  -- when y send ack you dont increase this field
                     r_next_header.flags <= '0'& x"10"; --SEND ACK                     
                     r_next_timeout <= (others => '0');
                     next_state <= CLOSE_WAIT;
                  ------------------------
                  -- RECEIVE ONLY DATA    if i receive the others side expected seq (cause i have acked it)
                  -----------------------                 
                 
                  elsif  r_header.ack_num = i_header.seq_num then                          
                    
                     r_next_header.ack_num <= i_header.seq_num + i_data_sizeRx; -- update App              
                     r_next_header.flags <= '0'& x"10"; --SEND ACK 
                     o_forwardRX <= '1'; 
                     o_forwardTX <= '1';
                     --r_next_headerApp_seq_num <= r_header.seq_num;
                     next_state <= ESTABLISHED; 
                  else 
                     o_discard <= '1';
                     next_state <= ESTABLISHED;
                  end if;
          
               else 
                  o_discard <= '1';
               end if;   





               
            elsif i_valid = '1' and last = '1'  then ---!!!!GO TO ONLY THIS AAAADDED
               if r_header.dst_ip = i_header.src_ip and r_header.dst_port = i_header.src_port and  
                  r_header.src_port = i_header.dst_port then          
                  
                  
                  ------------------------------------------
                  -- ACKNOWLEDGE FOR PACKET SEND BY OUR APP   -- if its seq_num is equal to the packets that i have ack..
                  ------------------------------------------  
                  if i_header.flags ='0'& x"10"  then   --ACK  of packet that i have send
                     next_state <= ESTABLISHED;
                     r_next_acktimerApp <= (others => '0');
                     if i_data_sizeRx = 0 and i_header.ack_num = r_headerApp_seq_num then           --r_expectedheader.seq_num          
                        r_next_acktimerApp <= (others => '0');                        
                        r_next_header.seq_num <= i_header.ack_num; --UPDATE seq_num    
                        r_next_headerApp_seq_num <= r_header.seq_num + i_data_sizeApp; ---!!!!ONLY THIS AAAADDED
                        o_forwardTX <= '1';        ---!!!!ONLY THIS AAAADDED
                        w_waitforack <= '0';
                        -- discard maybe for karol?? 
                        ------------------------
                        -- IF I RECEIVE ALSO DATA UPDATE ACK NUM too
                        -----------------------                        
                     elsif i_data_sizeRx /= 0  and i_header.ack_num = r_headerApp_seq_num then --r_expectedheader.seq_num  
                        --ack of packet that i have send plus his data             
                        r_next_headerApp_seq_num <= r_header.seq_num + i_data_sizeApp; ---!!!!ONLY THIS AAAADDED
                        r_next_header.ack_num <= i_header.seq_num + i_data_sizeRx; -- update both and send ack of data                          
                        r_next_header.seq_num <= i_header.ack_num; --UPDATE seq_num                                        
                        r_next_header.flags <='0'& x"10"; --SEND ACK 
                        o_forwardTX <= '1'; 
                        o_forwardRX <= '1';
                        w_waitforack <= '1';
                       ------------------------
                     -- HERE IF I RECEIVE PREVIOUS SEGMENT's ACK
                     -----------------------      
                     elsif (i_header.ack_num = r_header.seq_num )then                     
                        o_discard <= '1';    
                        o_forwardTX <= '1'; --SEND ACK AGAIN   
                      ------------------------
                 
                     end if;
                  ------------------------
                  -- HERE IF I RECEIVE PREVIOUS SEGMENT
                  -----------------------      
                  elsif (i_header.seq_num /= r_header.ack_num )then                     
                        o_discard <= '1';    
                        o_forwardTX <= '1'; --SEND ACK AGAIN
                  ------------------------
                  -- RECEIVE FIN
                  -----------------------   NA TO TSEKARW TO STATE
                  elsif i_header.flags <='0'& x"01" and i_header.ack_num = r_headerApp_seq_num  then    --FIN        --r_expectedheader.seq_num           
                     o_forwardTX <= '1';        --construct header for (send ack) TO TX ENGINE
                     o_close <= '1'; -- infrom APP AND WAITS FOR CLOSING SINGAL BY APP IN CLOSE WAIT STATE
                     --r_next_seq_num <= ro_next_headerRx.ack_num + 1;
                     r_next_header.ack_num <= r_header.ack_num + 1; 
                     r_next_header.seq_num <= r_header.seq_num;  -- when y send ack you dont increase this field
                     r_next_header.flags <='0'& x"10"; --SEND ACK 
                     r_next_headerApp_seq_num <= r_header.seq_num + i_data_sizeApp; ---!!!!ONLY THIS AAAADDED                    
                     
                     next_state <= CLOSE_WAIT;
                  ------------------------
                  -- RECEIVE ONLY DATA    if i receive the others side expected seq (cause i have acked it)
                  -----------------------                        
                  elsif  r_header.ack_num = i_header.seq_num then                          
                     r_next_headerApp_seq_num <= r_header.seq_num + i_data_sizeApp; ---!!!!ONLY THIS AAAADDED
                     r_next_header.ack_num <= i_header.seq_num + i_data_sizeRx; -- update App              
                     r_next_header.flags <='0'& x"10"; --SEND ACK 
                     o_forwardRX <= '1'; 
                     o_forwardTX <= '1';
                     next_state <= ESTABLISHED;                      
                  else 
                     o_discard <= '1';
                  end if;
          
               else 
                  o_discard <= '1';
               end if;             
               
               
               
               
               
               
               
               
               
               
               
               
            ------------------------
            -- APP IS SENDING PARALLELY  
            -----------------------            
            elsif last = '1' and r_header.seq_num = r_previous_ack_num then           --if app wants to send              
               r_next_headerApp_seq_num <= r_header.seq_num + i_data_sizeApp;           
               o_forwardTX <= '1';
               w_waitforack <= '1';
               r_next_header.flags <= (others => '0');  
             
               next_state <= ESTABLISHED;               
            else 
               next_state <= ESTABLISHED; 
            end if; 
           
           
         when FIN_WAIT_1 =>        
            r_next_acktimerApp <= r_acktimerApp + 1;
            r_next_timeout <= r_timeout +1;
            
            if r_timeout = CONNECTION_TIMEOUT then  --  if appl_close or timeout
               next_state <= CLOSED;
            elsif r_acktimerApp = ACK_TIMEOUT then -- if no ack received send again the SYN               
               --  SENT FIN AGAIN               
               o_forwardTX <= '1';
               r_next_acktimerApp <= (others => '0');    
        
            elsif i_valid = '1' and r_header.dst_ip = i_header.src_ip and r_header.dst_port = i_header.src_port 
               and  r_header.dst_ip = i_header.src_ip and r_header.dst_port = i_header.src_port 
               and  i_header.ack_num = r_headerApp_seq_num  then
               r_next_acktimerApp <= (others => '0');    -- check
               r_next_header.seq_num <= r_headerApp_seq_num;
               if i_header.flags = '0'&x"01" then -- FIN RECEIVED
                  r_next_header.ack_num <= r_header.ack_num + 1;
                  r_next_header.flags <= '0'&x"10";  --SENT ACK
                  o_forwardTX <= '1';
                  r_next_timeout <= (others => '0');   
                  next_state <= CLOSING;
               elsif i_header.flags ='0'&x"11" then -- FIN ACK REVEIVED   
                  r_next_header.ack_num <= r_header.ack_num + 1;
                  r_next_header.flags <='0'& x"10";  --SENT ACK
                  o_forwardTX <= '1';
                  r_next_timeout <= (others => '0'); 
                  next_state <= TIME_WAIT;
               elsif i_header.flags ='0'& x"10" then
                  r_next_timeout <= (others => '0'); 
                  next_state <= FIN_WAIT_2;
               else 
               r_next_acktimerApp <= r_acktimerApp + 1;
               next_state <= FIN_WAIT_1;
               end if;
            else 
               next_state <= FIN_WAIT_1;
            end if;   
             
         when FIN_WAIT_2 =>             
            r_next_timeout <= r_timeout +1;
            
            if r_timeout = CONNECTION_TIMEOUT then  --  if appl_close or timeout
               next_state <= CLOSED;            
            elsif i_valid = '1' and r_header.dst_ip = i_header.src_ip and r_header.dst_port = i_header.src_port 
               and  r_header.dst_ip = i_header.src_ip and r_header.dst_port = i_header.src_port 
               and  i_header.ack_num = r_headerApp_seq_num  then
               if i_header.flags ='0'& x"01" then -- FIN RECEIVED
                  r_next_header.ack_num <= r_header.ack_num + 1;
                  r_next_header.flags <= '0'&x"10";  --SENT ACK
                  o_forwardTX <= '1';
                  r_next_timeout <= (others => '0'); 
                  next_state <= TIME_WAIT;
               else
                  o_discard <='1';
                  next_state <= FIN_WAIT_2;
               end if;   
            else 
               next_state <= FIN_WAIT_2;
            end if;  
            
         when CLOSING =>  
            r_next_acktimerApp <= r_acktimerApp + 1;
            r_next_timeout <= r_timeout +1;
            
            if r_timeout = CONNECTION_TIMEOUT then  --  if appl timeouts
               next_state <= CLOSED;
            elsif r_acktimerApp = ACK_TIMEOUT then -- if no ack received send again the ACK               
               --  SENT ACK AGAIN               
               o_forwardTX <= '1';               
            elsif i_valid = '1' and r_header.dst_ip = i_header.src_ip and r_header.dst_port = i_header.src_port 
               and  r_header.dst_ip = i_header.src_ip and r_header.dst_port = i_header.src_port 
               and  i_header.ack_num = r_headerApp_seq_num  then --ACK OF MY FIN FROM ESTABL. MODE
               next_state <= TIME_WAIT;
               r_next_timeout <= (others => '0');  
               r_next_acktimerApp <= (others => '0'); 
            else 
               next_state <= CLOSING;
            end if;
         
         when TIME_WAIT =>
            r_next_timeout <= r_timeout +1;
            if r_timeout = 2*CONNECTION_TIMEOUT then  --  2MSL? CHECK RFC
               r_next_timeout <= (others => '0');                
               next_state <= CLOSED;
            else
                next_state <= TIME_WAIT;
            end if;
         when CLOSE_WAIT =>
         
           -- INFORM APP THAT THE CONNECTION WILL BE TERMINATED
            o_close <= '1';  
            r_next_headerApp_seq_num <= r_header.seq_num + 1;
            r_next_header.flags  <= '0'& x"01";           --send FIN
            o_forwardTX <= '1';           
            next_state <=LAST_ACK;            
         
         when LAST_ACK =>
         
            r_next_acktimerApp <= r_acktimerApp +1;
            r_next_timeout <= r_timeout +1;
            
            if r_timeout = CONNECTION_TIMEOUT  then
               r_next_timeout <= (others => '0');
               next_state <=CLOSED;
               
            elsif r_acktimerApp = ACK_TIMEOUT    then
               ------------------------
               -- Send FIN AGAIN
               -----------------------
               o_forwardTX <= '1';
            elsif i_valid = '1' and r_header.dst_ip = i_header.src_ip and r_header.dst_port = i_header.src_port and 
                  r_header.src_port = i_header.dst_port  and i_header.flags = '0'& x"10" and i_header.seq_num = r_headerApp_seq_num then                  
                  next_state <= CLOSED;
                  r_next_timeout <= (others => '0');           
            else 
               next_state <= LAST_ACK;
            end if;   
         when others =>
            next_state <= CLOSED;
         
      end case;
   end process comb_logic;
  
  
  






   clk_logic : process(clk)
      begin
         if rising_edge(clk) then
            if reset = '1' then 
               r_header.src_ip       <= (others => '0');
               r_header.dst_ip       <= (others => '0');
               r_header.src_port     <= (others => '0');
               r_header.dst_port     <= (others => '0');
               r_header.length       <= (others => '0');
               r_header.seq_num      <= (others => '0');
               r_header.ack_num      <= (others => '0');
               r_header.data_offset  <= (others => '0');
               r_header.reserved     <= (others => '0');
               r_header.flags        <= (others => '0');
               r_header.window_size  <= (others => '0');
               r_header.urgent_ptr   <= (others => '0');
               r_header.checksum     <= (others => '0');
               
               
               r_headerApp_seq_num  <= (others => '0');
               state                <= CLOSED;
               r_timeout            <= (others => '0');
               r_acktimerApp        <= (others => '0');
               r_previous_ack_num   <= (others => '0');
               r_open               <= '0';
            else
               r_header              <= r_next_header;
               r_headerApp_seq_num   <= r_next_headerApp_seq_num;
               state                 <= next_state;
               r_timeout             <= r_next_timeout;
               r_acktimerApp         <= r_next_acktimerApp;
               r_previous_ack_num    <= r_next_previous_ack_num;  
               r_open                <= r_next_open;
            end if;
         end if;
      end process clk_logic;


end rtl;
