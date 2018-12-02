--library ieee;
--use ieee.std_logic_1164.all;
--use ieee.numeric_std.all;
--use work.tcp_common.all;
--
--entity TCPbench is
--end TCPbench;
--
--ARCHITECTURE bvr OF TCPbench IS
--
-- component toefsm
--    port ( 
--    clk            : in std_ulogic;
--    reset          : in std_ulogic;    
--    start          :  in  std_ulogic;
--    ----------------------------------------------------------------------------
--     --  Inputs from Application
--    ----------------------------------------------------------------------------      
--    i_active_mode  :  in  std_ulogic;
--    last           :  in  std_ulogic; -- send data
--    i_open         :  in  std_ulogic;      --shall i save this to registers?
--    i_timeout      :  in  unsigned (10 downto 0);
--    o_close        :  out std_ulogic;
--    i_src_ip       :  in  t_ipv4_address;
--    i_dst_ip       :  in  t_ipv4_address;
--    i_src_port     :  in  t_tcp_port;
--    i_dst_port     :  in  t_tcp_port;      
--    ----------------------------------------------------------------------------
--    --Inputs from Rx engine
--    ----------------------------------------------------------------------------
--    i_header       :  in t_tcp_header;
--    i_valid        :  in std_ulogic;
--    i_data_sizeRx  :  in unsigned(31 downto 0);
--     
--    ----------------------------------------------------------------------------
--    --Outputs for Rx engine
--    ----------------------------------------------------------------------------
--    o_forwardRX :  out std_ulogic;
--    o_discard   :  out std_ulogic;
--    ----------------------------------------------------------------------------
--    --Inputs from Tx engine
--    ----------------------------------------------------------------------------
--    i_data_inbuffer : in std_ulogic;
--    i_data_sizeApp :  in  unsigned(31 downto 0);
--    ----------------------------------------------------------------------------
--    --Outputs for Tx engine
--    ----------------------------------------------------------------------------
--    o_Txsenddata : out std_ulogic;
--    o_header    :  out t_tcp_header;
--    o_forwardTX :  out std_ulogic
--    );
-- end component;
--
-- --Inputs
-- signal reset               : std_ulogic := '0';
-- signal clk                 : std_ulogic := '0';
-- signal start                 : std_ulogic := '0';
-- signal i_active_mode       : std_ulogic ;
-- signal last                : std_ulogic ;
-- signal i_open              : std_ulogic ;
-- signal i_timeout           :  unsigned (10 downto 0);
-- signal i_src_ip            :    t_ipv4_address;
-- signal i_dst_ip            :    t_ipv4_address;
-- signal i_src_port          :    t_tcp_port;
-- signal i_dst_port          :    t_tcp_port;
-- signal i_header            : t_tcp_header;
-- signal i_valid             : std_ulogic;
-- signal i_data_sizeRx       : unsigned(31 downto 0);  -- data size 1480 bytes equals 11.840bits my vector (16.384)
-- signal i_data_sizeApp      : unsigned(31 downto 0);
-- signal i_data_inbuffer     : std_ulogic;
--   
--     
---- Outputs 
-- signal o_forwardRX         : std_ulogic ;
-- signal o_discard           : std_ulogic ;
-- signal o_header            : t_tcp_header ;
-- signal o_forwardTX         : std_ulogic ;
-- signal o_close             : std_ulogic;
-- signal o_Txsenddata        : std_ulogic;
----Clock period 
--constant clk_period : time := 10 ns;
--
--begin 
--
---- Unit Under Test
-- uut1 : toefsm
-- port map (clk, reset,start, i_active_mode, last, i_open, i_timeout, o_close, 
--          i_src_ip, i_dst_ip, i_src_port, i_dst_port, i_header, i_valid,
--          i_data_sizeRx, o_forwardRX, o_discard, i_data_inbuffer, 
--          i_data_sizeApp,o_Txsenddata,o_header, o_forwardTX); 
--          
---- Generate clock write
-- clk_proc1 : process
-- begin    
--    clk <= '1';      
--    wait for clk_period / 2;
--    clk <= '0';      
--    wait for clk_period / 2;
-- end process; 
--
---- Stimulus
-- stim_proc : process
-- begin
--    reset <= '0';
--    wait for clk_period;
--    reset <= '1';   
--    wait for clk_period;    
--    reset <= '0'; 
--    wait for clk_period;
--    i_active_mode <= '0';
--    start <= '1'; 
--    i_src_ip    <=  x"00000002" ; 
--    i_src_port  <=  x"0002";
--
--    wait for clk_period;
--    start <= '0';
--    --RECEIVE SYN
--    i_valid <= '1';
--    i_header.src_ip      <= x"f0000000" ; 
--    i_header.dst_ip      <=  x"00000002" ; 
--    i_header.src_port    <= x"0f00";
--    i_header.length      <= (others => '0');
--    i_header.dst_port    <= x"0002";
--    i_header.seq_num     <= (others => '0');
--    i_header.ack_num     <= (others => '0');
--    i_header.data_offset <= (others => '0');
--    i_header.reserved    <= (others => '0');
--    i_header.flags       <= "000000010";
--    i_header.window_size <= (others => '0');
--    i_header.checksum    <= (others => '0');
--    i_header.urgent_ptr  <= (others => '0');
--    
--    wait for clk_period;
--    --RECEIVE WRONG PACKET
--    i_valid <= '1';
--    i_header.src_ip      <= x"f0000000" ; 
--    i_header.dst_ip      <=  x"00000004" ; 
--    i_header.src_port    <= x"0f00";
--    i_header.length      <= (others => '0');
--    i_header.dst_port    <= x"0002";
--    i_header.seq_num     <= (others => '0');
--    i_header.ack_num     <= (others => '0');
--    i_header.data_offset <= (others => '0');
--    i_header.reserved    <= (others => '0');
--    i_header.flags       <= "000000010";
--    i_header.window_size <= (others => '0');
--    i_header.checksum    <= (others => '0');
--    i_header.urgent_ptr  <= (others => '0');
--    
--    --UNCOMMENT TO CHECK ACKTIMER AND TIMEOUT
--    -- loop
--      -- wait for clk_period;
--    -- end loop;
--    
--    
--    wait for clk_period;
--    
--    
--    --RECEIVE ACK
--    i_valid <= '1';
--    i_header.src_ip      <= x"f0000000" ; 
--    i_header.dst_ip      <=  x"00000002" ; 
--    i_header.src_port    <= x"0f00";
--    i_header.length      <= (others => '0');
--    i_header.dst_port    <= x"0002";
--    i_header.seq_num     <= x"00000001";
--    i_header.ack_num     <= x"00000002";
--    i_header.data_offset <= (others => '0');
--    i_header.reserved    <= (others => '0');
--    i_header.flags       <= "000010000";
--    i_header.window_size <= (others => '0');
--    i_header.checksum    <= (others => '0');
--    i_header.urgent_ptr  <= (others => '0');
--    
--    wait for clk_period;
--    --RECEIVE FRAME
--    i_data_sizeRx <= x"0000000f";
--    i_open <='1';
--    last <= '0';
--    i_valid <= '1';
--    i_header.src_ip      <= x"f0000000" ; 
--    i_header.dst_ip      <=  x"00000002" ; 
--    i_header.src_port    <= x"0f00";
--    i_header.length      <= (others => '0');
--    i_header.dst_port    <= x"0002";
--    i_header.seq_num     <= x"00000001";
--    i_header.ack_num     <= x"00000002";
--    i_header.data_offset <= (others => '0');
--    i_header.reserved    <= (others => '0');
--    i_header.flags       <= "000000000";  -- NO ACK ,ACTUAL DATA SENT FROM OTHER SIDE
--    i_header.window_size <= (others => '0');
--    i_header.checksum    <= (others => '0');
--    i_header.urgent_ptr  <= (others => '0');
--    
--    wait for clk_period;
--    --RECEIVE SAME FRAME  (ack triggered)
--    i_data_sizeRx <= x"0000000f";
--    i_open <='1';
--    last <= '0';
--    i_valid <= '1';
--    i_header.src_ip      <= x"f0000000" ; 
--    i_header.dst_ip      <=  x"00000002" ; 
--    i_header.src_port    <= x"0f00";
--    i_header.length      <= (others => '0');
--    i_header.dst_port    <= x"0002";
--    i_header.seq_num     <= x"00000001";
--    i_header.ack_num     <= x"00000002";
--    i_header.data_offset <= (others => '0');
--    i_header.reserved    <= (others => '0');
--    i_header.flags       <= "000000000";  -- NO ACK ,ACTUAL DATA SENT FROM OTHER SIDE
--    i_header.window_size <= (others => '0');
--    i_header.checksum    <= (others => '0');
--    i_header.urgent_ptr  <= (others => '0');
--    
--    wait for clk_period;
--    --RECEIVE NEXT FRAME
--    i_data_sizeRx <= x"0000000f";
--    last <= '0';
--    i_valid <= '1';
--    i_header.src_ip      <= x"f0000000" ; 
--    i_header.dst_ip      <=  x"00000002" ; 
--    i_header.src_port    <= x"0f00";
--    i_header.length      <= (others => '0');
--    i_header.dst_port    <= x"0002";
--    i_header.seq_num     <= x"00000010";
--    i_header.ack_num     <= x"00000002";
--    i_header.data_offset <= (others => '0');
--    i_header.reserved    <= (others => '0');
--    i_header.flags       <= "000000000";  -- NO ACK ,ACTUAL DATA SENT FROM OTHER SIDE
--    i_header.window_size <= (others => '0');
--    i_header.checksum    <= (others => '0');
--    i_header.urgent_ptr  <= (others => '0');
--    
--    wait for clk_period;
--    --RECEIVE FIN
--    i_data_sizeRx <= x"00000000";
--    last <= '0';
--    i_valid <= '1';
--    i_header.src_ip      <= x"f0000000" ; 
--    i_header.dst_ip      <=  x"00000002" ; 
--    i_header.src_port    <= x"0f00";
--    i_header.length      <= (others => '0');
--    i_header.dst_port    <= x"0002";
--    i_header.seq_num     <= x"0000001f";
--    i_header.ack_num     <= x"00000002";
--    i_header.data_offset <= (others => '0');
--    i_header.reserved    <= (others => '0');
--    i_header.flags       <= "000000001";  -- FIN 
--    i_header.window_size <= (others => '0');
--    i_header.checksum    <= (others => '0');
--    i_header.urgent_ptr  <= (others => '0');
--    
--    
--    
--    
--    --UNCOMMENT TO CHECK TIMEOUT
--    --loop
--     -- wait for clk_period;
--    --end loop;
--    wait for clk_period;
--    
--    
--    
--    wait;
-- end process;
--
--   
--END;
--
     --------------------------------------------------------------------------------
     -- TestCASE 2
     --------------------------------------------------------------------------------
--library ieee;
--use ieee.std_logic_1164.all;
--use ieee.numeric_std.all;
--use work.tcp_common.all;
--
--entity TCPbench is
--end TCPbench;
--
--ARCHITECTURE bvr OF TCPbench IS
--
--component toefsm
--  port ( 
--  clk            : in std_ulogic;
--  reset          : in std_ulogic;  
--  start          :  in  std_ulogic;
--  ----------------------------------------------------------------------------
--    ----------------- Inputs from Application
--     ----------------------------------------------------------------------------      
--  i_active_mode  :  in  std_ulogic;
--  last           :  in  std_ulogic; -- send data
--  i_open         :  in  std_ulogic;      --shall i save this to registers?
--  i_timeout      :  in  unsigned (10 downto 0);
--  o_close        :  out std_ulogic;
--  i_src_ip       :  in  t_ipv4_address;
--  i_dst_ip       :  in  t_ipv4_address;
--  i_src_port     :  in  t_tcp_port;
--  i_dst_port     :  in  t_tcp_port;      
--  ----------------------------------------------------------------------------
--  ----------------Inputs from Rx engine
--  ----------------------------------------------------------------------------
--  i_header       :  in t_tcp_header;
--  i_valid        :  in std_ulogic;
--  i_data_sizeRx  :  in unsigned(31 downto 0);
--   
--  ----------------------------------------------------------------------------
--  ----------------Outputs for Rx engine
--  ----------------------------------------------------------------------------
--  o_forwardRX :  out std_ulogic;
--  o_discard   :  out std_ulogic;
--  ----------------------------------------------------------------------------
-- ------------------ Inputs from Tx engine
--  ----------------------------------------------------------------------------
--  i_data_inbuffer : in std_ulogic;
--  i_data_sizeApp :  in  unsigned(31 downto 0);
--  ----------------------------------------------------------------------------
-- --------------- Outputs for Tx engine
--  ----------------------------------------------------------------------------
--  o_Txsenddata : out std_ulogic;
--  o_header    :  out t_tcp_header;
--  o_forwardTX :  out std_ulogic
--  );
--end component;
--
------------------Inputs
--signal reset               : std_ulogic := '0';
--signal clk                 : std_ulogic := '0';
--signal start                 : std_ulogic := '0';
--signal i_active_mode       : std_ulogic ;
--signal last                : std_ulogic ;
--signal i_open              : std_ulogic ;
--signal i_timeout           :  unsigned (10 downto 0);
--signal i_src_ip            :    t_ipv4_address;
--signal i_dst_ip            :    t_ipv4_address;
--signal i_src_port          :    t_tcp_port;
--signal i_dst_port          :    t_tcp_port;
--signal i_header            : t_tcp_header;
--signal i_valid             : std_ulogic;
--signal i_data_sizeRx       : unsigned(31 downto 0);  -- data size 1480 bytes equals 11.840bits my vector (16.384)
--signal i_data_sizeApp      : unsigned(31 downto 0);
--signal i_data_inbuffer     : std_ulogic;
-- 
--   
---------------Outputs 
--signal o_forwardRX         : std_ulogic ;
--signal o_discard           : std_ulogic ;
--signal o_header            : t_tcp_header ;
--signal o_forwardTX         : std_ulogic ;
--signal o_close             : std_ulogic;
--signal o_Txsenddata        : std_ulogic;
------------------Clock period 
--constant clk_period : time := 10 ns;
--
--begin 
--
--------------Unit Under Test
--uut1 : toefsm
--port map (clk, reset,start, i_active_mode, last, i_open, i_timeout, o_close, 
--        i_src_ip, i_dst_ip, i_src_port, i_dst_port, i_header, i_valid,
--        i_data_sizeRx, o_forwardRX, o_discard, i_data_inbuffer, 
--        i_data_sizeApp,o_Txsenddata,o_header, o_forwardTX); 
--        
---------------------Generate clock write
--clk_proc1 : process
--begin    
--  clk <= '1';      
--  wait for clk_period / 2;
--  clk <= '0';      
--  wait for clk_period / 2;
--end process; 
--
-----------------Stimulus
--stim_proc : process
--begin
--  reset <= '0';
--  wait for clk_period;
--  reset <= '1';   
--  wait for clk_period;    
--  reset <= '0'; 
--  wait for clk_period;
--  ----------SENT SYN
--  start <= '1';
--  i_active_mode <= '1';
--  i_src_ip    <=  x"00000002" ; 
--  i_src_port  <=  x"0002";
--  i_dst_ip    <=  x"f0000000";
--  i_dst_port  <=  x"0f00"; 
--  
--  ------------------ UNCOMMENT TO CHECK TIMEOUT
--  -------------wait for clk_period;
--  ------------ start <= '0';      
--  ------------ loop
--   ----------- wait for clk_period;
--  ---------- end loop;
--  ----------- wait for clk_period;
--
--  wait for clk_period;
----------------RECEIVE ACK
--  start <= '0';
--  i_valid <= '1';
--  i_header.src_ip      <= x"f0000000" ; 
--  i_header.dst_ip      <=  x"00000002" ; 
--  i_header.src_port    <= x"0f00";
--  i_header.length      <= (others => '0');
--  i_header.dst_port    <= x"0002";
--  i_header.seq_num     <= (others => '0');
--  i_header.ack_num     <= x"00000002";
--  i_header.data_offset <= (others => '0');
--  i_header.reserved    <= (others => '0');
--  i_header.flags       <= "000010010";
--  i_header.window_size <= (others => '0');
--  i_header.checksum    <= (others => '0');
--  i_header.urgent_ptr  <= (others => '0');
--  
--  wait for clk_period;
--
--
--
-- ----------- SENT 1st FRAME 
--  i_data_sizeApp <= x"0000000f"; 
--  last <= '1';
--  i_valid <= '0';
--  --------------1st ACK RECEIVED
--  wait for clk_period;
--  i_data_sizeRx <= (others => '0');
--  last <= '0';
--  i_valid <= '1';
--  i_header.src_ip      <= x"f0000000" ; 
--  i_header.dst_ip      <=  x"00000002" ; 
--  i_header.src_port    <= x"0f00";
--  i_header.length      <= (others => '0');
--  i_header.dst_port    <= x"0002";
--  i_header.seq_num     <= x"00000001";
--  i_header.ack_num     <= x"00000011";
--  i_header.data_offset <= (others => '0');
--  i_header.reserved    <= (others => '0');
--  i_header.flags       <= "000010000";  -- ACK RECEIVED
--  i_header.window_size <= (others => '0');
--  i_header.checksum    <= (others => '0');
--  i_header.urgent_ptr  <= (others => '0');    
--  
--  wait for clk_period;
--  ---------------SENT  2nd FRAME
--  i_data_sizeApp <= x"00000010";
--  last <= '1';
--  i_valid <= '0';
--  wait for clk_period;
-- ---------------------2nd ACK RECEIVED
--  i_data_sizeRx <= (others => '0');
--  last <= '0';
--  i_valid <= '1';
--  i_header.src_ip      <= x"f0000000" ; 
--  i_header.dst_ip      <=  x"00000002" ; 
--  i_header.src_port    <= x"0f00";
--  i_header.length      <= (others => '0');
--  i_header.dst_port    <= x"0002";
--  i_header.seq_num     <= x"00000001";
--  i_header.ack_num     <= x"00000021";
--  i_header.data_offset <= (others => '0');
--  i_header.reserved    <= (others => '0');
--  i_header.flags       <= "000010000";  -- ACK RECEIVED
--  i_header.window_size <= (others => '0');
--  i_header.checksum    <= (others => '0');
--  i_header.urgent_ptr  <= (others => '0'); 
--  
--  wait for clk_period;
--  ----------------SENT  3rd FRAME
--  i_data_sizeApp <= x"00000010";
--  last <= '1';
--  i_valid <= '0';
--  
--  ----------------2nd ACK RECEIVED again
--   wait for clk_period;
--  i_data_sizeRx <= (others => '0');
--  last <= '0';
--  i_valid <= '1';
--  i_header.src_ip      <= x"f0000000" ; 
--  i_header.dst_ip      <=  x"00000002" ; 
--  i_header.src_port    <= x"0f00";
--  i_header.length      <= (others => '0');
--  i_header.dst_port    <= x"0002";
--  i_header.seq_num     <= x"00000001";
--  i_header.ack_num     <= x"00000021";
--  i_header.data_offset <= (others => '0');
--  i_header.reserved    <= (others => '0');
--  i_header.flags       <= "000010000";  -- ACK RECEIVED
--  i_header.window_size <= (others => '0');
--  i_header.checksum    <= (others => '0');
--  i_header.urgent_ptr  <= (others => '0'); 
--  
--  --------------2nd ACK RECEIVED again
--  wait for clk_period;
--  i_data_sizeRx <= (others => '0');
--  last <= '0';
--  i_valid <= '1';
--  i_header.src_ip      <= x"f0000000" ; 
--  i_header.dst_ip      <=  x"00000002" ; 
--  i_header.src_port    <= x"0f00";
--  i_header.length      <= (others => '0');
--  i_header.dst_port    <= x"0002";
--  i_header.seq_num     <= x"00000001";
--  i_header.ack_num     <= x"00000021";
--  i_header.data_offset <= (others => '0');
--  i_header.reserved    <= (others => '0');
--  i_header.flags       <= "000010000";  -- ACK RECEIVED
--  i_header.window_size <= (others => '0');
--  i_header.checksum    <= (others => '0');
--  i_header.urgent_ptr  <= (others => '0'); 
--  
--  --------------WRONG RANDOM ACK RECEIVED
--  wait for clk_period;
--  i_data_sizeRx <= (others => '0');
--  last <= '0';
--  i_valid <= '1';
--  i_header.src_ip      <= x"f0000000" ; 
--  i_header.dst_ip      <=  x"00000002" ; 
--  i_header.src_port    <= x"0f00";
--  i_header.length      <= (others => '0');
--  i_header.dst_port    <= x"0002";
--  i_header.seq_num     <= x"00000001";
--  i_header.ack_num     <= x"00000023";
--  i_header.data_offset <= (others => '0');
--  i_header.reserved    <= (others => '0');
--  i_header.flags       <= "000010000";  -- ACK RECEIVED
--  i_header.window_size <= (others => '0');
--  i_header.checksum    <= (others => '0');
--  i_header.urgent_ptr  <= (others => '0'); 
--  
--  -----------------3rd ACK RECEIVED
--  wait for clk_period;
--  i_data_sizeRx <= (others => '0');
--  last <= '0';
--  i_valid <= '1';
--  i_header.src_ip      <= x"f0000000" ; 
--  i_header.dst_ip      <=  x"00000002" ; 
--  i_header.src_port    <= x"0f00";
--  i_header.length      <= (others => '0');
--  i_header.dst_port    <= x"0002";
--  i_header.seq_num     <= x"00000001";
--  i_header.ack_num     <= x"00000031";
--  i_header.data_offset <= (others => '0');
--  i_header.reserved    <= (others => '0');
--  i_header.flags       <= "000010000";  -- ACK RECEIVED
--  i_header.window_size <= (others => '0');
--  i_header.checksum    <= (others => '0');
--  i_header.urgent_ptr  <= (others => '0');
--  
--   wait for clk_period;
--  --------SENT  2nd FRAME
--  i_data_sizeApp <= x"00000110";
--  last <= '1';
--  i_valid <= '0';
--  
--  
--  
--  
--  wait for clk_period;
--  last <= '0';
--  
--  wait;
--end process;
--
-- 
--END;
--


  --------------------------------------------------------------------------
 ----------------------------- TestCASE 3
  --------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.tcp_common.all;

entity TCPbench is
end TCPbench;

ARCHITECTURE bvr OF TCPbench IS

  component toefsm
     port ( 
     clk            : in std_ulogic;
     reset          : in std_ulogic;    
     start          :  in  std_ulogic;
     ------------------------------------------------------------------------
     -- Inputs from Application
     ------------------------------------------------------------------------      
     i_active_mode  :  in  std_ulogic;    
     i_open         :  in  std_ulogic;      --shall i save this to registers?
     i_timeout      :  in  unsigned (10 downto 0);
     o_established        :  out std_ulogic;
     i_src_ip       :  in  t_ipv4_address;
     i_dst_ip       :  in  t_ipv4_address;
     i_src_port     :  in  t_tcp_port;
     i_dst_port     :  in  t_tcp_port;      
     ------------------------------------------------------------------------
     -- Inputs from Rx engine
     ------------------------------------------------------------------------
     i_header       :  in t_tcp_header;
     i_valid        :  in std_ulogic;
     i_data_sizeRx  :  in unsigned(31 downto 0);
      
     ------------------------------------------------------------------------
     -- Outputs for Rx engine
     ------------------------------------------------------------------------
     o_forwardRX :  out std_ulogic;
     o_discard   :  out std_ulogic;
     ------------------------------------------------------------------------
     -- Inputs from Tx engine
     ------------------------------------------------------------------------
     i_data_inbuffer : in std_ulogic;
     i_data_sizeApp :  in  unsigned(31 downto 0);
     i_readytoSend  :  in  std_ulogic; -- send data
     ------------------------------------------------------------------------
     -- Outputs for Tx engine
     ------------------------------------------------------------------------
     o_Txsenddata : out std_ulogic;
     o_header    :  out t_tcp_header;
     o_forwardTX :  out std_ulogic
     );
  end component;

  -- Inputs
  signal reset               : std_ulogic := '0';
  signal clk                 : std_ulogic := '0';
  signal start                 : std_ulogic := '0';
  signal i_active_mode       : std_ulogic ;
  signal i_readytoSend                : std_ulogic ;
  signal i_open              : std_ulogic ;
  signal i_timeout           :  unsigned (10 downto 0);
  signal i_src_ip            :    t_ipv4_address;
  signal i_dst_ip            :    t_ipv4_address;
  signal i_src_port          :    t_tcp_port;
  signal i_dst_port          :    t_tcp_port;
  signal i_header            : t_tcp_header;
  signal i_valid             : std_ulogic;
  signal i_data_sizeRx       : unsigned(31 downto 0);  -- data size 1480 bytes equals 11.840bits my vector (16.384)
  signal i_data_sizeApp      : unsigned(31 downto 0);
  signal i_data_inbuffer     : std_ulogic;
    
      
  -- Outputs 
  signal o_forwardRX         : std_ulogic ;
  signal o_discard           : std_ulogic ;
  signal o_header            : t_tcp_header ;
  signal o_forwardTX         : std_ulogic ;
  signal o_established             : std_ulogic;
  signal o_Txsenddata        : std_ulogic;
 -- Clock period 
 constant clk_period : time := 10 ns;
 
 begin 
 
 -- Unit Under Test
  uut1 : toefsm
  port map (clk, reset,start, i_active_mode,i_open, i_timeout, o_established, 
           i_src_ip, i_dst_ip, i_src_port, i_dst_port, i_header, i_valid,
           i_data_sizeRx, o_forwardRX, o_discard, i_data_inbuffer, 
           i_data_sizeApp, i_readytoSend ,o_Txsenddata,o_header, o_forwardTX); 
        
------------------Generate clock write
clk_proc1 : process
begin    
  clk <= '1';      
  wait for clk_period / 2;
  clk <= '0';      
  wait for clk_period / 2;
end process; 

------------------Stimulus
stim_proc : process
begin
  reset <= '0';
  wait for clk_period;
  reset <= '1';   
  wait for clk_period;    
  reset <= '0'; 
  wait for clk_period;
  ------------SENT SYN
  start <= '1';
  i_active_mode <= '1';
  i_src_ip    <=  x"00000002" ; 
  i_src_port  <=  x"0002";
  i_dst_ip    <=  x"f0000000";
  i_dst_port  <=  x"0f00"; 
  
  --------- UNCOMMENT TO CHECK TIMEOUT
  -------- wait for clk_period;
  ------- start <= '0';      
  ----------- loop
  -------- wait for clk_period;
  ------ end loop;
  --------wait for clk_period;

  wait for clk_period;
 ------- RECEIVE ACK
  start <= '0';
  i_valid <= '1';
  i_header.src_ip      <= x"f0000000" ; 
  i_header.dst_ip      <=  x"00000002" ; 
  i_header.src_port    <= x"0f00";
  i_header.length      <= (others => '0');
  i_header.dst_port    <= x"0002";
  i_header.seq_num     <= (others => '0');
  i_header.ack_num     <= x"00000002";
  i_header.data_offset <= (others => '0');
  i_header.reserved    <= (others => '0');
  i_header.flags       <= "000010010";
  i_header.window_size <= (others => '0');
  i_header.checksum    <= (others => '0');
  i_header.urgent_ptr  <= (others => '0');
  
  wait for clk_period;
  i_valid <= '0';
  wait for clk_period;


 ------- SENT 1st FRAME 
  i_data_sizeApp <= x"0000000f"; 
  i_readytoSend <= '1';
  wait for clk_period;
  i_readytoSend <= '0';
  ----------------1st ACK RECEIVED
  wait for clk_period;
  i_data_sizeRx <= (others => '0');
  i_readytoSend <= '0';
  i_valid <= '1';
  i_header.src_ip      <= x"f0000000" ; 
  i_header.dst_ip      <=  x"00000002" ; 
  i_header.src_port    <= x"0f00";
  i_header.length      <= (others => '0');
  i_header.dst_port    <= x"0002";
  i_header.seq_num     <= x"00000001";
  i_header.ack_num     <= x"00000011";
  i_header.data_offset <= (others => '0');
  i_header.reserved    <= (others => '0');
  i_header.flags       <= "000010000";  -- ACK RECEIVED
  i_header.window_size <= (others => '0');
  i_header.checksum    <= (others => '0');
  i_header.urgent_ptr  <= (others => '0');    
  
  wait for clk_period;
  i_valid <= '0';  
  wait for clk_period;
  
 ---------- SENT  2nd FRAME
  i_data_sizeApp <= x"00000010";
  i_readytoSend <= '1';  
  
  wait for clk_period;
  i_readytoSend <= '0';
  wait for clk_period;
  ----------------2nd ACK RECEIVED
  i_data_sizeRx <= (others => '0');
  i_readytoSend <= '0';
  i_valid <= '1';
  i_header.src_ip      <= x"f0000000" ; 
  i_header.dst_ip      <=  x"00000002" ; 
  i_header.src_port    <= x"0f00";
  i_header.length      <= (others => '0');
  i_header.dst_port    <= x"0002";
  i_header.seq_num     <= x"00000001";
  i_header.ack_num     <= x"00000021";
  i_header.data_offset <= (others => '0');
  i_header.reserved    <= (others => '0');
  i_header.flags       <= "000010000";  -- ACK RECEIVED
  i_header.window_size <= (others => '0');
  i_header.checksum    <= (others => '0');
  i_header.urgent_ptr  <= (others => '0'); 
  
  wait for clk_period;
  i_valid <= '0';  
  wait for clk_period;
  
  -------------SENT 3rd FRAME 
  i_data_sizeApp <= x"000000ff"; 
  i_readytoSend <= '1';  
  i_valid <= '0';
  
   wait for clk_period;
   i_readytoSend <= '0';
   wait for clk_period;
  --------Receive frame + ack
  i_data_sizeRx <= x"000000aa";   
  i_valid <= '1';
  i_header.src_ip      <= x"f0000000" ; 
  i_header.dst_ip      <=  x"00000002" ; 
  i_header.src_port    <= x"0f00";
  i_header.length      <= (others => '0');
  i_header.dst_port    <= x"0002";
  i_header.seq_num     <= x"00000001";
  i_header.ack_num     <= x"00000120";
  i_header.data_offset <= (others => '0');
  i_header.reserved    <= (others => '0');
  i_header.flags       <= "000010000";  
  i_header.window_size <= (others => '0');
  i_header.checksum    <= (others => '0');
  i_header.urgent_ptr  <= (others => '0'); 
  
   wait for clk_period;
   i_valid <= '0';
   wait for clk_period;
  -------------ACK of frame that i have sent RECEIVED
  -- i_data_sizeRx <= (others => '0');
  -- last <= '0';
  -- i_valid <= '1';
  -- i_header.src_ip      <= x"f0000000" ; 
  -- i_header.dst_ip      <=  x"00000002" ; 
  -- i_header.src_port    <= x"0f00";
  -- i_header.length      <= (others => '0');
  -- i_header.dst_port    <= x"0002";
  -- i_header.seq_num     <= x"00000001";
  -- i_header.ack_num     <= x"00000120";
  -- i_header.data_offset <= (others => '0');
  -- i_header.reserved    <= (others => '0');
  -- i_header.flags       <= "000010000";  -- ACK RECEIVED
  -- i_header.window_size <= (others => '0');
  -- i_header.checksum    <= (others => '0');
  -- i_header.urgent_ptr  <= (others => '0'); 
  
  
 
  --wait for clk_period;
  --------------frame received + ack of previous sent frame
  -- i_data_sizeRx <=x"00000022"; 
  -- last <= '0';
  -- i_valid <= '1';
  -- i_header.src_ip      <= x"f0000000" ; 
  -- i_header.dst_ip      <=  x"00000002" ; 
  -- i_header.src_port    <= x"0f00";
  -- i_header.length      <= (others => '0');
  -- i_header.dst_port    <= x"0002";
  -- i_header.seq_num     <= x"00000001";
  -- i_header.ack_num     <= x"00000120";
  -- i_header.data_offset <= (others => '0');
  -- i_header.reserved    <= (others => '0');
  -- i_header.flags       <= "000010000";  -- ACK RECEIVED
  -- i_header.window_size <= (others => '0');
  -- i_header.checksum    <= (others => '0');
  -- i_header.urgent_ptr  <= (others => '0'); 
  
  wait for clk_period;
  --------------SENT NEXT FRAME
  i_data_sizeApp <= x"00000100"; 
  i_readytoSend <= '1';
  ----i_header.flags <= (others => '0');
  i_valid <= '0';
  
   wait for clk_period;
    i_readytoSend <= '0';
   wait for clk_period;
   
   --------------ReCEIVE FRAME BEFORE ACK
  i_data_sizeRx <=x"00000003";   
  i_valid <= '1';
  i_header.src_ip      <= x"f0000000" ; 
  i_header.dst_ip      <=  x"00000002" ; 
  i_header.src_port    <= x"0f00";
  i_header.length      <= (others => '0');
  i_header.dst_port    <= x"0002";
  i_header.seq_num     <= x"000000ab";
  i_header.ack_num     <= x"00000120";
  i_header.data_offset <= (others => '0');
  i_header.reserved    <= (others => '0');
  i_header.flags       <= "000000000";  
  i_header.window_size <= (others => '0');
  i_header.checksum    <= (others => '0');
  i_header.urgent_ptr  <= (others => '0'); 
  
  
  wait for clk_period; 
  i_valid <= '0';
  wait for clk_period;   
  
    ------------ReCEIVE ACK 
  i_data_sizeRx <=x"00000000"; 
  i_readytoSend <= '0';
  i_valid <= '1';
  i_header.src_ip      <= x"f0000000" ; 
  i_header.dst_ip      <=  x"00000002" ; 
  i_header.src_port    <= x"0f00";
  i_header.length      <= (others => '0');
  i_header.dst_port    <= x"0002";
  i_header.seq_num     <= x"000000ab";
  i_header.ack_num     <= x"00000220";
  i_header.data_offset <= (others => '0');
  i_header.reserved    <= (others => '0');
  i_header.flags       <= "000010000";  
  i_header.window_size <= (others => '0');
  i_header.checksum    <= (others => '0');
  i_header.urgent_ptr  <= (others => '0');   
  
  wait for clk_period; 
  i_valid <= '0';
  wait for clk_period;   
  
  i_data_sizeApp <= x"00000200"; 
  i_readytoSend <= '1';
  wait for clk_period; 
  i_readytoSend <= '0';
  wait for clk_period; 
   --------------ReCEIVE ACK + data
  i_data_sizeRx <=x"00100000"; 
  
  i_valid <= '1';
  i_header.src_ip      <= x"f0000000" ; 
  i_header.dst_ip      <=  x"00000002" ; 
  i_header.src_port    <= x"0f00";
  i_header.length      <= (others => '0');
  i_header.dst_port    <= x"0002";
  i_header.seq_num     <= x"000000ae";
  i_header.ack_num     <= x"00000220";
  i_header.data_offset <= (others => '0');
  i_header.reserved    <= (others => '0');
  i_header.flags       <= "000000000";  
  i_header.window_size <= (others => '0');
  i_header.checksum    <= (others => '0');
  i_header.urgent_ptr  <= (others => '0'); 
 
   wait for clk_period;   
    i_valid <= '0';
   wait for clk_period;   
  
  
 
   --------------ReCEIVE ACK 
  i_data_sizeRx <=x"00000000"; 
  
  i_valid <= '1';
  i_header.src_ip      <= x"f0000000" ; 
  i_header.dst_ip      <=  x"00000002" ; 
  i_header.src_port    <= x"0f00";
  i_header.length      <= (others => '0');
  i_header.dst_port    <= x"0002";
  i_header.seq_num     <= x"001000ae";
  i_header.ack_num     <= x"00000420";
  i_header.data_offset <= (others => '0');
  i_header.reserved    <= (others => '0');
  i_header.flags       <= "000010000";  
  i_header.window_size <= (others => '0');
  i_header.checksum    <= (others => '0');
  i_header.urgent_ptr  <= (others => '0'); 
 
   wait for clk_period;   
  
   i_valid <= '0';
   i_open <= '0';
   wait for clk_period;
   
   -- i_data_sizeRx <=x"00000000"; 
  
  -- i_valid <= '1';
  -- i_header.src_ip      <= x"f0000000" ; 
  -- i_header.dst_ip      <=  x"00000002" ; 
  -- i_header.src_port    <= x"0f00";
  -- i_header.length      <= (others => '0');
  -- i_header.dst_port    <= x"0002";
  -- i_header.seq_num     <= x"001000ae";
  -- i_header.ack_num     <= x"00000421";
  -- i_header.data_offset <= (others => '0');
  -- i_header.reserved    <= (others => '0');
  -- i_header.flags       <= "000010000";  
  -- i_header.window_size <= (others => '0');
  -- i_header.checksum    <= (others => '0');
  -- i_header.urgent_ptr  <= (others => '0');   
  
   
  i_data_sizeRx <=x"00000000"; 
  
  i_valid <= '1';
  i_header.src_ip      <= x"f0000000" ; 
  i_header.dst_ip      <=  x"00000002" ; 
  i_header.src_port    <= x"0f00";
  i_header.length      <= (others => '0');
  i_header.dst_port    <= x"0002";
  i_header.seq_num     <= x"001000ae";
  i_header.ack_num     <= x"00000421";
  i_header.data_offset <= (others => '0');
  i_header.reserved    <= (others => '0');
  i_header.flags       <= "000010001";  
  i_header.window_size <= (others => '0');
  i_header.checksum    <= (others => '0');
  i_header.urgent_ptr  <= (others => '0'); 
   
   --------------ReCEIVE FIN 
  -- i_data_sizeRx <=x"00000000"; 
  
  -- i_valid <= '1';
  -- i_header.src_ip      <= x"f0000000" ; 
  -- i_header.dst_ip      <=  x"00000002" ; 
  -- i_header.src_port    <= x"0f00";
  -- i_header.length      <= (others => '0');
  -- i_header.dst_port    <= x"0002";
  -- i_header.seq_num     <= x"001000ae";
  -- i_header.ack_num     <= x"00000420";
  -- i_header.data_offset <= (others => '0');
  -- i_header.reserved    <= (others => '0');
  -- i_header.flags       <= "000000001";  
  -- i_header.window_size <= (others => '0');
  -- i_header.checksum    <= (others => '0');
  -- i_header.urgent_ptr  <= (others => '0'); 
  
  wait for clk_period; 
  i_readytoSend <= '0';
  i_valid <= '0';
 
  
  wait;
end process;

 
END;--
--
--------