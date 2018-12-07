use std.textio.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library vunit_lib;
context vunit_lib.vunit_context;

library work;
use work.tcp_common.all;

entity tx_engine_tb is
	generic (
		runner_cfg : string
	);
end tx_engine_tb;

architecture behaviour of tx_engine_tb is
	component tx_engine
	port (
		--Clocked on rising edge
		clock : in std_ulogic;
		--Synchronous reset
		i_reset : in std_ulogic;

		--AXI stream for input data from application
		i_app_axi_data : in std_ulogic_vector(DATA_WIDTH - 1 downto 0);
		i_app_axi_valid : in std_ulogic;
		o_app_axi_ready : out std_ulogic;
		--Last signal will indicate TCP engine should flush buffer ASAP
		i_app_axi_last : in std_ulogic;

		--AXI stream outputting to network interface
		o_net_axi_data : out std_ulogic_vector(DATA_WIDTH - 1 downto 0);
		o_net_axi_valid : out std_ulogic;
		i_net_axi_ready : in std_ulogic;
		--Last signal will indicate the end of a packet
		o_net_axi_last : out std_ulogic;

		--Sequence number acknowledged by reciever. When this value increases,
		--space in the buffer is freed.
		i_ctrl_ack_num : in t_seq_num;
		--Header with the packet to send. Must be valid for one clock cycle with
		--when i_tx_start is high.
		i_ctrl_packet_header : in t_tcp_header;
		--Length of data to insert in packet.  Must be valid for one clock cycle
		--with when i_tx_start is high.
		i_ctrl_packet_data_length : in unsigned(APP_BUF_WIDTH - 1 downto 0);
		--Set high for a single clock cycle to start transmission of a packet.
		i_ctrl_tx_start : in std_ulogic;
		--Outputs how many bytes are available in the buffer to transmit.
		o_ctrl_data_bytes_available : out unsigned(APP_BUF_WIDTH - 1 downto 0);
		--Outputs high only when the TX engine is free to send another packet.
		o_ctrl_ready : out std_ulogic
	);
	end component;


	signal clock : std_ulogic := '0';
	signal clock_period : delay_length := 1 us;

	--Synchronous reset
	signal i_reset : std_ulogic;

	--AXI stream for input data from application
	signal i_app_axi_data : std_ulogic_vector(DATA_WIDTH - 1 downto 0);
	signal i_app_axi_valid : std_ulogic;
	signal o_app_axi_ready : std_ulogic;
	--Last signal will indicate TCP engine should flush buffer ASAP
	signal i_app_axi_last : std_ulogic;

	--AXI stream outputting to network interface
	signal o_net_axi_data : std_ulogic_vector(DATA_WIDTH - 1 downto 0);
	signal o_net_axi_valid : std_ulogic;
	signal i_net_axi_ready : std_ulogic;
	--Last signal will indicate the end of a packet
	signal o_net_axi_last : std_ulogic;

	--Sequence number acknowledged by reciever. When this value increases,
	--space in the buffer is freed.
	signal i_ctrl_ack_num : t_seq_num;
	--Header with the packet to send. Must be valid for one clock cycle with
	--when i_tx_start is high.
	signal i_ctrl_packet_header : t_tcp_header;
	--Length of data to insert in packet.  Must be valid for one clock cycle
	--with when i_tx_start is high.
	signal i_ctrl_packet_data_length : unsigned(APP_BUF_WIDTH - 1 downto 0);
	--Set high for a single clock cycle to start transmission of a packet.
	signal i_ctrl_tx_start : std_ulogic;
	--Outputs how many bytes are available in the buffer to transmit.
	signal o_ctrl_data_bytes_available : unsigned(APP_BUF_WIDTH - 1 downto 0);
	--Outputs high only when the TX engine is free to send another packet.
	signal o_ctrl_ready : std_ulogic;

begin
	tx : tx_engine port map(
		clock => clock,
		i_reset => i_reset,
		i_app_axi_data => i_app_axi_data,
		i_app_axi_valid => i_app_axi_valid,
		o_app_axi_ready => o_app_axi_ready,
		i_app_axi_last => i_app_axi_last,
		o_net_axi_data => o_net_axi_data,
		o_net_axi_valid => o_net_axi_valid,
		i_net_axi_ready => i_net_axi_ready,
		o_net_axi_last => o_net_axi_last,
		i_ctrl_ack_num => i_ctrl_ack_num,
		i_ctrl_packet_header => i_ctrl_packet_header,
		i_ctrl_packet_data_length => i_ctrl_packet_data_length,
		i_ctrl_tx_start => i_ctrl_tx_start,
		o_ctrl_data_bytes_available => o_ctrl_data_bytes_available,
		o_ctrl_ready => o_ctrl_ready
	);

	process
	begin
		loop
			clock <= '1';
			wait for clock_period / 2;
			clock <= '0';
			wait for clock_period / 2;
		end loop;
	end process;

	process
		variable i : integer;
	begin
		test_runner_setup(runner, runner_cfg);

		while test_suite loop
			if run("simple") then
				i_reset <= '1';
				i_ctrl_tx_start <= '0';
				i_app_axi_valid <= '0';
				i_ctrl_ack_num <= (others => '0');
				i_ctrl_packet_header <= c_default_tcp_header;
				i_ctrl_packet_header.src_ip <= ipv4_address(192, 168, 0, 1);
				i_ctrl_packet_header.dst_ip <= ipv4_address(10,0,0,100);
				i_ctrl_packet_header.src_port <= X"0102";
				i_ctrl_packet_header.dst_port <= X"0304";
				i_ctrl_packet_header.seq_num <= X"FF05FF04";
				i_ctrl_packet_header.ack_num <= X"06FF07FF";
				i_net_axi_ready <= '1';

				wait until rising_edge(clock);
				i_reset <= '0';
				wait until rising_edge(clock);

				i := 0;
				while i < 16 loop
					if o_app_axi_ready = '1' then
						i_app_axi_valid <= '1';
						i_app_axi_data <= std_ulogic_vector(to_unsigned((i mod 255) + 128, 8));
						i := i + 1;
					else
						i_app_axi_valid <= '0';
					end if;
					wait until rising_edge(clock);
				end loop;
				i_app_axi_valid <= '0';
				wait until rising_edge(clock);
				wait until rising_edge(clock);

				i_ctrl_packet_data_length <= (X"10");
				i_ctrl_tx_start <= '1';
				wait until rising_edge(clock);
				i_ctrl_tx_start <= '0';
				wait until rising_edge(clock);
				for i in 0 to 255 loop
					wait until rising_edge(clock);
				end loop;
			end if;
		end loop;
		test_runner_cleanup(runner);
	end process;
end behaviour;
