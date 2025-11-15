MaskedVByte
===========
[![Ubuntu](https://github.com/fast-pack/MaskedVByte/actions/workflows/ubuntu.yml/badge.svg)](https://github.com/fast-pack/MaskedVByte/actions/workflows/ubuntu.yml)

Fast, vectorized VByte decoding for 32‑bit integers in C, with optional differential (delta) coding.

- Requires x86-64 with SSE4.1 (available on virtually all modern x64 CPUs)
- C99 compatible


Build and test
--------------

```sh
make        # builds the library and the test binary
./unit      # runs a quick correctness test
```

CMake build (alternative)
------------------------

```sh
mkdir -p build
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release \
      -DMASKEDVBYTE_BUILD_TESTS=ON \
      -DMASKEDVBYTE_BUILD_EXAMPLES=ON
cmake --build build -j
ctest --test-dir build --output-on-failure   # optional

# run the example built by CMake
./build/example
```

Install with CMake (optional):

```sh
cmake --install build --prefix /usr/local
```

Build and run the example
-------------------------

```sh
make example
./example
```

You should see something like:

```
Compressed 5000 integers down to 5000 bytes.
```

Embedded example, explained
---------------------------
The example allocates input/output buffers, encodes a flat array of integers with classic VByte, then decodes it back with the masked (vectorized) decoder and verifies the sizes match.

```c
#include <stdio.h>
#include <stdlib.h>
#include <assert.h>

#include "varintencode.h"
#include "varintdecode.h"

int main() {
            int N = 5000;
            uint32_t * datain = malloc(N * sizeof(uint32_t));
            uint8_t * compressedbuffer = malloc(N * sizeof(uint32_t));
            uint32_t * recovdata = malloc(N * sizeof(uint32_t));
            for (int k = 0; k < N; ++k)
                        datain[k] = 120; // constant value fits in one VByte
            size_t compsize = vbyte_encode(datain, N, compressedbuffer); // encoding
            // result is stored in 'compressedbuffer' using 'compsize' bytes
            size_t compsize2 = masked_vbyte_decode(compressedbuffer, recovdata, N); // fast decoding
            assert(compsize == compsize2); // sanity check
            free(datain);
            free(compressedbuffer);
            free(recovdata);
            printf("Compressed %d integers down to %d bytes.\n", N, (int)compsize);
            return 0;
}
```

What’s happening:
- VByte uses a continuation bit; small values like 120 encode to a single byte, so 5000 values compress to 5000 bytes.
- `masked_vbyte_decode` is a vectorized decoder using SSE4.1 for speed.
- Differential coding variants are available when your data is sorted or has small gaps.

API at a glance
---------------
Headers are in `include/`.

- Encoding
      - `size_t vbyte_encode(const uint32_t* in, size_t length, uint8_t* bout);`
      - `size_t vbyte_encode_delta(const uint32_t* in, size_t length, uint8_t* bout, uint32_t prev);`

- Decoding
      - `size_t masked_vbyte_decode(const uint8_t* in, uint32_t* out, uint64_t length);`
      - `size_t masked_vbyte_decode_delta(const uint8_t* in, uint32_t* out, uint64_t length, uint32_t prev);`
      - `size_t masked_vbyte_decode_fromcompressedsize(const uint8_t* in, uint32_t* out, size_t inputsize);`
      - `size_t masked_vbyte_decode_fromcompressedsize_delta(const uint8_t* in, uint32_t* out, size_t inputsize, uint32_t prev);`
      - Random access helpers for delta streams:
            - `uint32_t masked_vbyte_select_delta(const uint8_t *in, uint64_t length, uint32_t prev, size_t slot);`
            - `int masked_vbyte_search_delta(const uint8_t *in, uint64_t length, uint32_t prev, uint32_t key, uint32_t *presult);`

Tips
----
- Prefer delta coding when your sequence is sorted or has small differences; it often reduces the number of bytes per integer.
- If you know the compressed byte length, use the `*_fromcompressedsize` functions to decode exactly that many bytes.


Use from your CMake project
---------------------------

After installation (see above):

```cmake
find_package(maskedvbyte CONFIG REQUIRED)
target_link_libraries(your_target PRIVATE maskedvbyte::maskedvbyte)
```

Or as a subdirectory (vendored):

```cmake
add_subdirectory(path/to/MaskedVByte)
target_link_libraries(your_target PRIVATE maskedvbyte::maskedvbyte)
```


Interesting applications 
-----------------------

- [Greg Bowyer has integrated Masked VByte into Lucene, for higher speeds](https://github.com/GregBowyer/lucene-solr/tree/intrinsics).
- Our fast function is also used by [PISA: Performant Indexes and Search for Academia](https://github.com/pisa-engine/pisa).

Reference
-------------

* Daniel Lemire, Nathan Kurz, Christoph Rupp, Stream VByte: Faster Byte-Oriented Integer Compression, Information Processing Letters 130, February 2018, Pages 1-6 https://arxiv.org/abs/1709.08990
* Jeff Plaisance, Nathan Kurz, Daniel Lemire, Vectorized VByte Decoding,  International Symposium on Web Algorithms 2015, 2015. http://arxiv.org/abs/1503.07387


See also
------------

* SIMDCompressionAndIntersection: A C++ library to compress and intersect sorted lists of integers using SIMD instructions https://github.com/lemire/SIMDCompressionAndIntersection
* The FastPFOR C++ library : Fast integer compression https://github.com/lemire/FastPFor
* High-performance dictionary coding https://github.com/lemire/dictionary
* LittleIntPacker: C library to pack and unpack short arrays of integers as fast as possible https://github.com/lemire/LittleIntPacker
* The SIMDComp library: A simple C library for compressing lists of integers using binary packing https://github.com/lemire/simdcomp
* StreamVByte: Fast integer compression in C using the StreamVByte codec https://github.com/lemire/streamvbyte
* CSharpFastPFOR: A C#  integer compression library  https://github.com/Genbox/CSharpFastPFOR
* JavaFastPFOR: A java integer compression library https://github.com/lemire/JavaFastPFOR
* Encoding: Integer Compression Libraries for Go https://github.com/zhenjl/encoding
* FrameOfReference is a C++ library dedicated to frame-of-reference (FOR) compression: https://github.com/lemire/FrameOfReference
* libvbyte: A fast implementation for varbyte 32bit/64bit integer compression https://github.com/cruppstahl/libvbyte
* TurboPFor is a C library that offers lots of interesting optimizations. Well worth checking! (GPL license) https://github.com/powturbo/TurboPFor
* Oroch is a C++ library that offers a usable API (MIT license) https://github.com/ademakov/Oroch


License
-------
See `LICENSE` for details.


