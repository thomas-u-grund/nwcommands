cscript

do unw_core.do

* nwtomata had no dedicated test coverage of its own - it only forwards
* to _nwtomata's own mat() branch, and was only ever exercised
* incidentally as a helper inside other commands' own test files
* (test_nwconstraint.do, test_nwdropnodes.do, etc.).

nwclear
nwset, mat((0,1,1\1,0,0\1,0,0)) name(starnet) undirected labs(A,B,C)

nwtomata starnet, mat(M)
assert _rc == 0
* undirected networks store a [symmetric] matrix with a missing (not
* zero) diagonal - checked cell-by-cell rather than via a full-matrix
* literal comparison to avoid depending on that storage detail.
mata: assert(M[2,1] == 1)
mata: assert(M[3,1] == 1)
mata: assert(M[3,2] == 0)

* the returned matrix is a COPY, not a live view - altering it must not
* alter the underlying network.
mata: M[2,1] = 99
nwtomata starnet, mat(M2)
mata: assert(M2[2,1] == 1)

* moderate-severity pass, utilities_state group: a misspelled/
* nonexistent network name crashed with a raw Mata error (r3301, via
* the shared _nwtomata helper) instead of a clean message - the same
* misspelled-network-name crash class fixed independently in several
* other commands this pass; found here while writing this file's own
* first-ever test coverage, exactly the kind of gap a dedicated test
* file is meant to catch.
capture noisily nwtomata bogusnet123, mat(M3)
assert _rc == 482
di "=== nwtomata REGRESSION VERIFIED ==="
