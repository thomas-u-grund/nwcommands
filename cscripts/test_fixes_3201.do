cscript

* Fixes of 3.20.1: nwbridges symmetrizes the result of an undirected network; nwcontext, stat(sum) prints no
* matrices; nwkeep, clean without if/in; weights() that do not sum to one in nwring, nwsmall, nwpref and
* nwdyadprob; nwexpand ... if keeps the data in memory.
clear mata
do unw_core.do
set more off
clear all
set seed 12345

* 1 nwbridges: result of an undirected network is symmetric
foreach t in global local distance {
    nwclear
    nwrandom 30, prob(.08) undirected name(u)
    nwbridges u, type(`t') name(br)
    nwtomata br, mat(B)
mata: _editmissing(B, 0)
    mata: assert(mreldif(B, B') == 0)
}
di "PASS bridges"

* 2 nwcontext stat(sum) prints no matrices
nwclear
clear
nwrandom 8, prob(.4) name(c)
gen a = _n
tempfile ctxlog
log using `ctxlog', text replace name(ctx)
nwcontext c, attribute(a) stat(sum) generate(s)
log close ctx
tempname fh
file open `fh' using `ctxlog', read
local nl 0
file read `fh' line
while r(eof) == 0 {
    local ++nl
    file read `fh' line
}
file close `fh'
di "lines: `nl'"
assert `nl' < 20
* result equals A * a
nwtomata c, mat(A)
mata: _editmissing(A, 0)
mata: assert(mreldif(A * (1::8), st_data((1::8), "s")) < 1e-12)
di "PASS context"

* 3 nwkeep, clean
nwclear
clear
nwrandom 10, prob(.3) name(k1)
nwrandom 10, prob(.3) name(k2)
nwkeep k1, clean
nwset
assert r(networks) == 1
nwkeep k1 if _n <= 5, clean
assert _N == 5
di "PASS keep"

* 4 weights() not summing to 1
foreach c in "nwring 12, k(2)" "nwsmall 12, k(2) prob(.1)" "nwpref 12," "nwdyadprob, mat(J(12,12,.5))" {
    nwclear
    `c' weights(1, 3) name(w)
    nwtomata w, mat(M)
mata: _editmissing(M, 0)
    mata: assert(all(M :== 0 :| M :== 1 :| M :== 2))
    mata: assert(any(M :== 2))
}
* sums to one: tie values 1 and 2 as before
nwclear
nwring 12, k(2) weights(.5, .5) name(w)
nwtomata w, mat(M)
mata: _editmissing(M, 0)
mata: assert(all(M :== 0 :| M :== 1 :| M :== 2))
di "PASS weights"

* 5 nwexpand if keeps the data
nwclear
clear
set obs 20
gen x = mod(_n, 3)
nwexpand x if _n <= 10, name(e)
assert _N == 20
nwsummarize e
assert r(nodes) == 10
nwexpand x if x == 1, name(e1)
nwsummarize e1
assert r(nodes) == 7
assert _N == 20
di "PASS expand"

di "PASS test_fixes_3201"
