/*
	nwtypes.h -- integer types of the native kernels.

	RULE: no plain `long' for sizes, indices, counters, offsets or products of them.  `long' is 32 bits
	under MSVC (the Windows build, `cl /LD /DSYSTEM=STWIN32') and 64 bits under gcc and clang on macOS and
	Linux, so a value above 2^31 (n*n at n > 46,340; the sum of the squared degrees of a large star; an offset
	into an n x count result) wraps silently on Windows only.  Use

	  nwint     (int64_t)   node ids, tie counts, indices, loop counters, array offsets, any product of those
	  size_t               byte counts and sizes handed to malloc / calloc / memset / memcpy; cast EACH factor
	                       before multiplying: (size_t)a * (size_t)b * sizeof(x), never (size_t)(a * b)
	  uint64_t             bit sets, hash and random-number state (write constants with the ULL suffix)
	  double               counts that are only summed or divided (exact up to 2^53)

	`int' is for flags, small enumerations, node ids that are known to stay below 2^31 and arrays of them
	(documented where it happens), and values handed to the Stata plugin interface (ST_int).  Never print a
	nwint with %ld: cast to (long long) and use %lld.  `long double' is 64 bits under MSVC and on arm64
	macOS: results that must agree across platforms must not depend on its extra precision.

	native/test/test_kernels.c checks this on every push (see .github/workflows/test-kernels.yml).
*/
#ifndef NWTYPES_H
#define NWTYPES_H

#include <stddef.h>
#include <stdint.h>

typedef int64_t nwint;

/*
	Row and column numbers of the Stata plugin interface are ST_int (32 bits): Stata's own limit.  The kernels
	count in nwint and narrow only here, once, so that the conversion is explicit (no MSVC C4244, no
	-Wshorten-64-to-32 noise at 20 call sites).
*/
#define NW_VDATA(i, j, d)   SF_vdata((ST_int)(i), (ST_int)(j), (d))
#define NW_VSTORE(i, j, v)  SF_vstore((ST_int)(i), (ST_int)(j), (v))

/* compile-time checks (a negative array size is a compile error) */
typedef char nwtypes_check_nwint_is_64_bit[(sizeof(nwint) == 8) ? 1 : -1];
typedef char nwtypes_check_size_t_holds_nwint[(sizeof(size_t) >= 4) ? 1 : -1];

#endif
