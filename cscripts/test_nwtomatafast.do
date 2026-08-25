cscript

do unw_core.do

* nwtomatafast had no dedicated test coverage of its own - it was only
* ever exercised incidentally as a helper inside other commands' own
* test files (test_nwcorrelate.do, test_nwdissimilar.do).

nwclear
nwset, mat((0,1,1\1,0,0\1,0,0)) name(starnet) undirected labs(A,B,C)

nwtomatafast starnet
assert _rc == 0
* undirected networks store a [symmetric] matrix with a missing (not
* zero) diagonal - checked cell-by-cell rather than via a full-matrix
* literal comparison to avoid depending on that storage detail.
mata: F = `r(mata)'
mata: assert(F[2,1] == 1)
mata: assert(F[3,1] == 1)
mata: assert(F[3,2] == 0)

* unlike nwtomata's own mat() copy, nwtomatafast's r(mata) is a direct
* dereference of the LIVE network matrix (its own header comment says
* so explicitly) - confirmed directly: a change made through
* nwreplace is visible in a freshly re-fetched r(mata) expression. A
* directed network is used here (rather than reusing starnet above) to
* keep the bracket-write's row/column pairing unambiguous - undirected
* bracket-write's own triangle-side requirements are a separate matter
* outside this file's own scope.
nwclear
nwset, mat((0,1,1\0,0,0\0,0,0)) directed name(dirnet) labs(A,B,C)
nwreplace dirnet[1,2] = 77
nwtomatafast dirnet
mata: F2 = `r(mata)'
mata: assert(F2[1,2] == 77)

* moderate-severity pass, utilities_state group: a misspelled/
* nonexistent network name crashed with a raw Mata error (r3301)
* instead of a clean message - the same misspelled-network-name crash
* class fixed independently in several other commands this pass; found
* here while writing this file's own first-ever test coverage.
capture noisily nwtomatafast bogusnet123
assert _rc == 482
di "=== nwtomatafast REGRESSION VERIFIED ==="
