CFLAGS=-I. -fPIC -Og
DEPS =
OBJ = ghdl_tun.c

PHONY = run clean

DUT_FILES = dual_port_ram memory_large tcp_common toefsm tcp_checksum_unit rx_buffer rx_engine RX tx_engine tcp_engine

build/c/%.o: %.c
	mkdir -p build/c
	gcc -c -o $@ $^ $(CFLAGS)

build/libtun.a: build/c/tun.o
	mkdir -p build/c
	ar rcs $@ $^

build/vhdl/work-obj08.cf: $(addprefix ../src/, $(addsuffix .vhdl, $(DUT_FILES))) tun.vhdl tun_main.vhdl
	mkdir -p build/vhdl
	ghdl -a -g --std=08 --workdir=build/vhdl $^

build/main: build/vhdl/work-obj08.cf build/libtun.a
	ghdl -e --std=08 --workdir=build/vhdl -Wl,build/libtun.a -o $@ tun_main

run: build/main
	sudo build/main --wave=signals.ghw

clean:
	rm -rf build
