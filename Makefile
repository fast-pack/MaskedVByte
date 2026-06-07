# minimalist makefile
.SUFFIXES:
#
.SUFFIXES: .cpp .o .c .h

# Select architecture-specific SIMD flags: SSE4.1 on x86-64; on 64-bit ARM the
# NEON baseline (incl. vqtbl/AdvSIMD) is always available, so no extra flag.
ARCH := $(shell uname -m)
ifneq (,$(filter $(ARCH),x86_64 amd64))
ARCHFLAGS = -msse4.1
else ifneq (,$(filter $(ARCH),arm64 aarch64))
ARCHFLAGS =
else
ARCHFLAGS = -msse4.1
endif

CFLAGS = -fPIC $(ARCHFLAGS) -std=c99 -O3 -Wall -Wextra -pedantic -Wshadow
LDFLAGS = -shared
LIBNAME=libmaskedvbyte.so.0.0.1
all:  unit $(LIBNAME)
test: 
	./unit
install: $(OBJECTS)
	cp $(LIBNAME) /usr/local/lib
	ln -s /usr/local/lib/$(LIBNAME) /usr/local/lib/libmaskedvbyte.so
	ldconfig
	cp $(HEADERS) /usr/local/include



HEADERS=./include/varintdecode.h ./include/varintencode.h

uninstall:
	for h in $(HEADERS) ; do rm  /usr/local/$$h; done
	rm  /usr/local/lib/$(LIBNAME)
	rm /usr/local/lib/libmaskedvbyte.so
	ldconfig


OBJECTS= varintdecode.o varintencode.o


varintencode.o: ./src/varintencode.c $(HEADERS)
	$(CC) $(CFLAGS) -c ./src/varintencode.c -Iinclude  

varintdecode.o: ./src/varintdecode.c $(HEADERS)
	$(CC) $(CFLAGS) -c ./src/varintdecode.c -Iinclude  



$(LIBNAME): $(OBJECTS)
	$(CC) $(CFLAGS) -o $(LIBNAME) $(OBJECTS)  $(LDFLAGS) 




example: ./examples/example.c    $(HEADERS) $(OBJECTS)
	$(CC) $(CFLAGS) -o example ./examples/example.c -Iinclude  $(OBJECTS)

benchmark: ./benchmarks/benchmark.c    $(HEADERS) $(OBJECTS)
	$(CC) $(CFLAGS) -o benchmark ./benchmarks/benchmark.c -Iinclude  $(OBJECTS)

unit: ./tests/unit.c    $(HEADERS) $(OBJECTS)
	$(CC) $(CFLAGS) -o unit ./tests/unit.c -Iinclude  $(OBJECTS)
dynunit: ./tests/unit.c    $(HEADERS) $(LIBNAME)
	$(CC) $(CFLAGS) -o dynunit ./tests/unit.c -Iinclude  -lmaskedvbyte 

clean:
	rm -f unit *.o $(LIBNAME) example benchmark
