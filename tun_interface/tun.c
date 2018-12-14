#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <fcntl.h>
#include <error.h>
#include <unistd.h>
#include <sys/stat.h>
#include <sys/ioctl.h>
#include <linux/if.h>
#include <linux/if_tun.h>

static int tun_alloc(char *dev, int flags) {
	struct ifreq ifr;
	int fd, err;
	char *clonedev = "/dev/net/tun";

	/* Arguments taken by the function:
	 *
	 * char *dev: the name of an interface (or '\0'). MUST have enough
	 *   space to hold the interface name if '\0' is passed
	 * int flags: interface flags (eg, IFF_TUN etc.)
	 */

	 /* open the clone device */
	 if ((fd = open(clonedev, O_RDWR)) < 0) {
		 return fd;
	 }

	 /* preparation of the struct ifr, of type "struct ifreq" */
	 memset(&ifr, 0, sizeof(ifr));

	 ifr.ifr_flags = flags;   /* IFF_TUN or IFF_TAP, plus maybe IFF_NO_PI */

	 if (*dev) {
		 /* if a device name was specified, put it in the structure; otherwise,
			* the kernel will try to allocate the "next" device of the
			* specified type */
		 strncpy(ifr.ifr_name, dev, IFNAMSIZ);
	 }

	 /* try to create the device */
	 if ((err = ioctl(fd, TUNSETIFF, (void *) &ifr)) < 0) {
		 close(fd);
		 return err;
	 }

	/* if the operation was successful, write back the name of the
	 * interface to the variable "dev", so the caller can know
	 * it. Note that the caller MUST reserve space in *dev (see calling
	 * code below) */
	strcpy(dev, ifr.ifr_name);

	/* Make read operations nonblocking */
	int fd_flags = fcntl(fd, F_GETFL, 0);
	fcntl(fd, F_SETFL, fd_flags | O_NONBLOCK);

	/* this is the special file descriptor that the caller will use to talk
	 * with the virtual interface */
	return fd;
}

int tun_fd = -1;

void tun_init() {
	if (tun_fd < 0) {
		printf("Initializing\n");
		printf("Current tun_fd %d\n", tun_fd);
		printf("Creating tunnel\n");
		char tun_name[64] = "\0";
		tun_fd = tun_alloc(tun_name, IFF_TUN | IFF_NO_PI);
		if (tun_fd < 0) {
			printf("Failed to create tunnel: %s\n", strerror(tun_fd));
		}
		printf("Tunnel name is %s\n", tun_name);
		char command[128];
		snprintf(command, sizeof(command), "ip link set %s up", tun_name);
		system(command);
		snprintf(command, sizeof(command), "ip addr add 10.0.0.1/24 dev %s", tun_name);
		system(command);
	}
	else {
		printf("Already initialized\n");
	}
}

static uint8_t rx_packet[65536];
static size_t rx_offset;
static size_t rx_packet_size;
static uint8_t tx_packet[65536 - 20];
static size_t tx_offset = 0;

#define REJECT(reason) do { printf("Rejected packet: %s\n", reason); return -1; } while(0)
#define BE_READ16(ptr, offset) ( (uint16_t)( ((ptr)[(offset)+0] << 8) | ((ptr)[(offset)+1] << 0) ) )
#define BE_READ32(ptr, offset) ( (uint32_t)( ((ptr)[(offset)+0] << 24) | ((ptr)[(offset)+1] << 16) | ((ptr)[(offset)+2] << 8) | ((ptr)[(offset)+3]) ) )

#define BIT_READ(value, bit) ( (((value) >> (bit)) & 1) )

void print_tcp_packet(const uint8_t const* packet) {
	const uint8_t const* tcp_data = packet + 8;
	printf("\tSrc IP: %u.%u.%u.%u\n", packet[0], packet[1], packet[2], packet[3]);
	printf("\tDst IP: %u.%u.%u.%u\n", packet[4], packet[5], packet[6], packet[7]);
	printf("\tSrc Port: %u\n", BE_READ16(tcp_data, 0));
	printf("\tDst Port: %u\n", BE_READ16(tcp_data, 2));
	printf("\tSeq Num: %u\n", BE_READ32(tcp_data, 4));
	printf("\tAck Num: %u\n", BE_READ32(tcp_data, 8));
	printf("\tTCP Flags: %s%s%s%s\n",
		BIT_READ(tcp_data[13], 1) ? "SYN " : "",
		BIT_READ(tcp_data[13], 4) ? "ACK " : "",
		BIT_READ(tcp_data[13], 0) ? "FIN " : "",
		BIT_READ(tcp_data[13], 2) ? "RST " : ""
	);
}

int32_t tun_receive_packet() {
	// Read IP packet into buffer
	uint8_t raw_packet[65536];
	int32_t raw_packet_size = read(tun_fd, raw_packet, sizeof(raw_packet));

	if (raw_packet_size < 0) return -1;

	//Ensure a full header is present, or return
	if (raw_packet_size < 20) REJECT("too small");

	//Only handle IPv4 packets
	uint8_t ip_version = raw_packet[0] >> 4;
	if (ip_version != 4) REJECT("not IPv4");

	//Only handle TCP packets
	uint8_t protocol = raw_packet[9];
	if (protocol != 6) REJECT("not TCP");

	//Compute size of data
	int32_t header_length = (raw_packet[0] & 0xF) * 4;
	int32_t total_length = BE_READ16(raw_packet, 2);
	int32_t data_length = total_length - header_length;
	if (total_length != raw_packet_size) REJECT("header reports wrong size");
	if (header_length > total_length) REJECT("header longer than packet");

	//Copy source IP
	memcpy(rx_packet + 0, raw_packet + 12, 4);

	//Copy destination IP
	memcpy(rx_packet + 4, raw_packet + 16, 4);

	//Copy TCP data
	memcpy(rx_packet + 8, raw_packet + header_length, data_length);


	printf("Accepted TCP packet:\n");
	printf("\tIP header: ");
	for (int i = 0; i < 20; i++) printf("%x,", raw_packet[i]);
	printf("\n");
	printf("\tTotal length: %d\n", total_length);
	printf("\tHeader length: %d\n", header_length);
	print_tcp_packet(rx_packet);

	rx_packet_size = data_length + 8;
	rx_offset = 0;

	return data_length + 8;

	//
	//uint8_t ip_version = raw_
	//rx_offset = 0;
}

int32_t tun_read_byte() {
	if (rx_offset < rx_packet_size) {
		uint8_t ret = rx_packet[rx_offset];
		rx_offset++;
		return ret;
	}
	else {
		printf("TUN: Warning: read past end of packet\n");
		return -1;
	}
}

int32_t tun_send_packet() {
	uint8_t raw_packet[65536];
	const uint8_t default_header[12] = {
		0x45, 0, 0, 0,
		0, 0, 0x40, 0,
		0x40, 0x6, 0, 0
	};
	//Stop if packet is too short
	if (tx_offset < 8) return -1;

	//Copy source IP, destionation IP, and TCP data
	memcpy(raw_packet + 12, tx_packet, tx_offset);

	//Copy default header
	memcpy(raw_packet, default_header, 12);

	//Write total length
	uint16_t total_length = tx_offset + 20;
	raw_packet[2] = (total_length >> 8) & 0xFF;
	raw_packet[3] = (total_length >> 0) & 0xFF;

	//Write identification
	uint16_t identification = rand();
	raw_packet[4] = (identification >> 8) & 0xFF;
	raw_packet[5] = (identification >> 0) & 0xFF;

	//Write checksum
	uint32_t header_checksum = 0;
	for (int i = 0; i < 10; i++) {
		header_checksum += ((uint16_t*)raw_packet)[i];
	}
	while (header_checksum >> 16) header_checksum = (header_checksum & 0xFFFF) + ((header_checksum >> 16) & 0xFFFF);
	header_checksum ^= 0xFFFF;
	((uint16_t*)raw_packet)[5] = header_checksum & 0xFFFF;

	//Verify checksum
	header_checksum = 0;
	for (int i = 0; i < 10; i++) {
		header_checksum += ((uint16_t*)raw_packet)[i];
	}
	while (header_checksum >> 16) header_checksum = (header_checksum & 0xFFFF) + ((header_checksum >> 16) & 0xFFFF);
	header_checksum ^= 0xFFFF;

	printf("Sending TCP packet:\n");
	printf("\tIP header checksum result: %s", header_checksum == 0 ? "pass" : "fail");
	print_tcp_packet(tx_packet);
	int write_size = write(tun_fd, raw_packet, total_length);
	tx_offset = 0;
	if (write_size == total_length) return 0;
	else return -1;

}

int32_t tun_write_byte(int32_t byte) {
	if (tx_offset < sizeof(tx_packet)) {
		tx_packet[tx_offset] = (uint8_t)(byte & 0xFF);
		tx_offset++;
		return 0;
	}
	else {
		printf("TUN: Warning: write past end of packet");
		return -1;
	}
}