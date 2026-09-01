version 12
clear all
capture mata: mata clear

* Simulate a fresh Stata session: project root on adopath for .ado files,
* lib/ added for the compiled Mata library. No "do unw_core.do" anywhere.
cd "/Users/tgrund/FILES_NEW/SOFTWARE/nwcommands"
adopath + "/Users/tgrund/FILES_NEW/SOFTWARE/nwcommands/lib"

di "=== confirm classes are NOT already in memory ==="
capture mata: nw_def
di "rc for nw_def before any command: " _rc

nwclear
nwset, mat((.,4,4,0,0,0\4,.,2,1,1,0\4,2,.,0,0,0\0,1,0,.,0,0\0,1,0,0,.,7\0,0,0,0,7,.)) undirected labs(A, B, C, D, E, F)

nwset, detail

qui nwdegree, alpha(0) generate(deg0)
qui nwdegree, alpha(0.5) generate(deg0_5)
qui nwdegree, alpha(1) generate(deg1)
qui nwdegree, alpha(1.5) generate(deg1_5)

list deg*

di "=== SUCCESS if no errors above ==="
