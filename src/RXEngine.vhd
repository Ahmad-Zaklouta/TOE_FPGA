use std.textio.all;
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.tcp_common.all;

entity rx_engine is
  generic(
      memory_address_bits: natural := 14
	);
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
	o_address   : out std_ulogic_vector(memory_address_bits downto 0);
	o_data      : out std_ulogic_vector(7 downto 0);
	o_we        : out std_ulogic;
	i_address_r : in  std_ulogic_vector(memory_address_bits downto 0)
  );
end rx_engine;


architecture rx_engine_behaviour of rx_engine is
  
  component tcp_checksum_unit is
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
  end component;


  type state_t is (await, pseudo_header_read, header_read, read_data, wait_toe, wait_checksum);
  type header_buffer_t is array(0 to 27) of std_ulogic_vector(7 downto 0);
  
  signal header_register, header_register_next: t_tcp_header;
  signal header_buffer: header_buffer_t;
  signal state, state_next: state_t;
  signal count, count_next, header_count, header_count_next: std_ulogic_vector(15 downto 0) := (others => '0');
  signal header13,header14, header15, header16, header17, header18, header19, header20: std_ulogic_vector(7 downto 0);
  signal checksum_en, checksum_valid, checksum_last: std_ulogic := '0';
  signal checksum_error, checksum_finished: std_ulogic;
  signal byte_buffer, byte_buffer_next: std_ulogic_vector(7 downto 0);
  
  signal address_read, address_write, address_init, address_write_next, address_init_next: std_ulogic_vector(memory_address_bits downto 0); 
  signal full, full_wait, full_wait_next: std_ulogic;
  
begin
  checksum_unit: tcp_checksum_unit port map(clk => clk, reset => reset,
     i_data => tdata, i_valid=>checksum_valid, i_checksum_en => checksum_en, i_end_checksum => checksum_last, o_checksum_comp_finished => checksum_finished, o_checksum => open, o_error => checksum_error);
  
  
  full <= '1' when ((address_write(memory_address_bits) /= address_write(memory_address_bits) )and (address_write(memory_address_bits - 1 downto 0) = address_read(memory_address_bits downto 0))) else
           '0';
  
  address_read <= i_address_r;
  o_address <= address_write;
  
  comb: process(state, tvalid, tlast, tdata, i_forwardRX, i_discard, checksum_error, checksum_finished, address_write, address_read, address_init)
  begin
    tready <= '1';
	o_valid <= '0';
	o_data <= tdata;
	header13 <= header_buffer(20);
	header14 <= header_buffer(21);
	header15 <= header_buffer(22);
	header16 <= header_buffer(23);
	header17 <= header_buffer(24);
	header18 <= header_buffer(25);
	header19 <= header_buffer(26); 
	header20 <= header_buffer(27);
	checksum_en <= '0';
	checksum_valid <= '0';
	checksum_last  <= tlast;
	full_wait_next <= '0';
	
    case state is
	  when await =>
	    -- await for data from AXI bus
	    if (tvalid = '1') then
		  count_next <= std_ulogic_vector(unsigned(count) + 1);
		  header_count_next <= std_ulogic_vector(unsigned(header_count) + 1);
          header_buffer(0) <= tdata;
		  state_next <= pseudo_header_read;
		  checksum_en <= '1';
	      checksum_valid <= '1';
		end if;
	  when pseudo_header_read =>
	    -- read the pseudo header
	    if (tvalid = '1') then
		  checksum_en <= '1';
	      checksum_valid <= '1';
		  count_next <= std_ulogic_vector(unsigned(count) + 1);
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
	    -- 
	    if(tvalid = '1') then  
		  checksum_en <= '1';
	      checksum_valid <= '1';
		  count_next <= std_ulogic_vector(unsigned(count) + 1);
		  if (unsigned(count) < 31) then
		    header_buffer(to_integer(unsigned(header_count))) <= tdata;
		    header_count_next <= std_ulogic_vector(unsigned(header_count) + 1);
		  else
		    header_buffer(to_integer(unsigned(header_count))) <= tdata;
		    header_count_next <= std_ulogic_vector(unsigned(header_count) + 1);
			header_register_next.src_ip      <= header_buffer(0) & header_buffer(1) & header_buffer(2) & header_buffer(3);
			header_register_next.dst_ip      <= header_buffer(4) & header_buffer(5) & header_buffer(6) & header_buffer(7);
			header_register_next.src_port    <= unsigned(header_buffer(8)) & unsigned(header_buffer(9));
			header_register_next.dst_port    <= unsigned(header_buffer(10)) & unsigned(header_buffer(11));
			header_register_next.seq_num     <= unsigned(header_buffer(12)) & unsigned(header_buffer(13)) & unsigned(header_buffer(14)) & unsigned(header_buffer(15));
			header_register_next.ack_num     <= unsigned(header_buffer(16)) & unsigned(header_buffer(17)) & unsigned(header_buffer(18)) & unsigned(header_buffer(19));
			header_register_next.data_offset <= unsigned(header13(7 downto 4));
			header_register_next.reserved    <= header13(3 downto 1);
			header_register_next.flags       <= header13(0) & header14;
			header_register_next.window_size <= unsigned(header15) & unsigned(header16);
			header_register_next.checksum    <= header17 & header18;
			header_register_next.urgent_ptr  <= unsigned(header_buffer(26)) & unsigned(tdata);
			-- create a header
	        if(tlast = '1') then
			  state_next <= wait_checksum;
		    else
			  state_next <= read_data;
			  address_init_next <= address_write;
			  address_write_next <= std_ulogic_vector(unsigned(address_write) + 1);
		    end if;
		  end if;
		end if;
	  when read_data =>
	    if(tvalid = '1') then
		  checksum_en <= '1';
	      checksum_valid <= '1';
		  
		  if(full = '1' and full_wait = '0') then --first time wait
		    tready <= '0';
			byte_buffer_next <= tdata;
			full_wait_next <= '1';
	      elsif(full = '1' and full_wait = '1') then --still full, deactivate the checksum
		    checksum_en <= '0';
			checksum_valid <= '0';
		  elsif(full = '0' and full_wait = '1') then --can receive again, but still old data present
		    tready <= '1';
			full_wait_next <= '0';
			checksum_en <= '0';
			checksum_valid <= '0';
			o_data <= byte_buffer;
			address_write_next <= std_ulogic_vector(unsigned(address_write) + 1);
		  else
		    address_write_next <= std_ulogic_vector(unsigned(address_write) + 1);
		  end if;
		  
		  if (tlast = '1') then
		    state_next <= wait_toe;
			tready <= '0';
		  end if;
		end if;
	  when wait_checksum =>
	    if(checksum_error ='0' and checksum_finished = '1') then
		  o_valid <= '1';
		  state_next <= wait_toe;
		elsif(checksum_error = '1' and checksum_finished ='1') then
		  address_write_next <= address_init;
		  state_next <= await;
		end if;
	  when wait_toe =>
	    --check the checksum here
		o_valid <= '1';
		tready <= '0';
		if(i_forwardRX = '1') then
		  state_next <= await;
		elsif(i_discard = '1') then
		  state_next <= await;
		  address_write_next <= address_init;
		end if;
	end case;
  end process;  

  seq: process(clk)
  begin
    if (rising_edge(clk) and reset = '1') then
	  state <= await;
	  count <= (others => '0');
	  header_count <= (others => '0');
	  address_init <= (others => '0');
	  address_write <= (others => '0');
	elsif (rising_edge(clk)) then
	  byte_buffer <= byte_buffer_next;
	  address_init <= address_init_next;
	  address_write <= address_write_next;
	  state <= state_next;
	  count <= count_next;
	  header_count <= header_count_next;
	  header_register <= header_register_next;
	end if;
  end process;
  
  
end rx_engine_behaviour;