version 12
clear all
capture mata: mata clear

* This time: cd directly into lib/ so "." matches where the mlib/index live
* (matches how it was built), and add PROJECT root to adopath for .ado files.
cd "/Users/tgrund/FILES_NEW/RESEARCH/nwcommands_2016/lib"
adopath + "/Users/tgrund/FILES_NEW/RESEARCH/nwcommands_2016"

capture mata: nw_def
di "rc for nw_def before any command: " _rc

nwclear
nwset, mat((.,4,4,0,0,0\4,.,2,1,1,0\4,2,.,0,0,0\0,1,0,.,0,0\0,1,0,0,.,7\0,0,0,0,7,.)) undirected labs(A, B, C, D, E, F)
qui nwdegree, alpha(0) generate(deg0)
list deg0

di "=== SUCCESS if no errors above ==="
