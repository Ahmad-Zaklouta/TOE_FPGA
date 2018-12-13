CFLAGS=-I. -fPIC -Og
DEPS =
OBJ = ghdl_tun.c

PHONY = run clean

build/c/%.o: %.c
	mkdir -p build/c
	gcc -c -o $@ $^ $(CFLAGS)

build/libtun.a: build/c/tun.o
	mkdir -p build/c
	ar rcs $@ $^

build/vhdl/work-obj08.cf: ../src/gray_code.vhdl ../src/dual_port_ram.vhdl ../src/tcp_common.vhdl ../src/tcp_engine.vhdl tun.vhdl tun_main.vhdl
	mkdir -p build/vhdl
	ghdl -a -g --std=08 --workdir=build/vhdl $^

build/main: build/vhdl/work-obj08.cf build/libtun.a
	ghdl -e --std=08 --workdir=build/vhdl -Wl,build/libtun.a -o $@ tun_main

run: build/main
	sudo build/main

clean:
	rm -rf build
