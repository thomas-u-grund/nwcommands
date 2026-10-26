/*
	stub/stplugin.h -- a stand-in for StataCorp's Stata Plugin Interface, used ONLY by the Stata-free test
	harness (native/test/test_kernels.c).  nwgraph.c includes "stplugin.h"; the harness puts this directory
	before native/spi on the include path, so the kernels compile and run without Stata.  The five SF_
	functions the kernels use are implemented by the harness over plain arrays (variables = columns of
	doubles, scalars = a small table).  Nothing here is part of any shipped binary.
*/
#ifndef NW_STUB_STPLUGIN_H
#define NW_STUB_STPLUGIN_H

#include <math.h>

typedef double ST_double;
typedef int    ST_int;
typedef int    ST_retcode;
typedef unsigned char ST_boolean;

#define STDLL ST_retcode

/* Stata's missing value ".": 2^1023 */
#define SV_missval 8.9884656743115795386e307
#define SF_is_missing(x) ((x) >= SV_missval)

extern ST_retcode nwt_vdata(ST_int i, ST_int j, ST_double *d);
extern ST_retcode nwt_vstore(ST_int i, ST_int j, ST_double v);
extern ST_retcode nwt_scal_save(char *name, ST_double v);
extern ST_retcode nwt_message(const char *s);

#define SF_vdata(i, j, d)     nwt_vdata((i), (j), (d))
#define SF_vstore(i, j, v)    nwt_vstore((i), (j), (v))
#define SF_scal_save(s, d)    nwt_scal_save((s), (d))
#define SF_error(s)           nwt_message((s))
#define SF_display(s)         nwt_message((s))

#endif
