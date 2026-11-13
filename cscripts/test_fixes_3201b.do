cscript
nwclear
do unw_core.do

* 3.20.1: nwsubset with a compound if condition; nwinstall reports parts it could not install.

capture confirm file "data/usair.nwdta"
if !_rc global nwwebpath "`c(pwd)'/data"

// nwsubset: the whole condition selects the nodes (used to negate only its last term)
nwwebuse usair, nwclear
count if Lat < 50 & Lon > -125
local want = r(N)
nwsubset usair if Lat < 50 & Lon > -125, name(main48)
nwsummarize main48
assert r(nodes) == `want'
assert r(nodes) == 48
nwsubset usair if Lat >= 50 | Lon <= -125, name(outside)
nwsummarize outside
assert r(nodes) == 2
nwsubset usair if !(Lat < 50) | Lon > -60, name(neg)
nwsummarize neg
local got = r(nodes)
quietly count if !(Lat < 50) | Lon > -60
assert `got' == r(N)
di "PASS nwsubset compound if"

// nwinstall_chunks: number of chunks from stata.toc, failures reported in r(failed)
quietly run nwinstall.ado
tempfile base
local repo "`base'_repo"
local plus "`base'_plus"
mkdir "`repo'"
mkdir "`plus'"
local oldplus : sysdir PLUS
sysdir set PLUS "`plus'"
tempname fh
file open `fh' using "`repo'/stata.toc", write text replace
file write `fh' "v 3" _n "d test" _n "p nwcommands-tst1" _n "d part 1" _n "p nwcommands-tst2" _n "d part 2" _n "p nwcommands-tst3" _n "d part 3" _n
file close `fh'
foreach i in 1 3 {
	file open `fh' using "`repo'/nwcommands-tst`i'.pkg", write text replace
	file write `fh' "v 3" _n "d nwcommands-tst`i'" _n "f zz_nwtst`i'.ado" _n
	file close `fh'
	file open `fh' using "`repo'/zz_nwtst`i'.ado", write text replace
	file write `fh' "program zz_nwtst`i'" _n "end" _n
	file close `fh'
}
// part 2 is listed but missing: parts 1 and 3 install, part 2 is reported
quietly net from "`repo'"
nwinstall_chunks, kind(tst) src("`repo'")
assert "`r(failed)'" == "nwcommands-tst2"
capture findfile zz_nwtst3.ado
assert _rc == 0
// all present: nothing reported
file open `fh' using "`repo'/nwcommands-tst2.pkg", write text replace
file write `fh' "v 3" _n "d nwcommands-tst2" _n "f zz_nwtst1.ado" _n
file close `fh'
nwinstall_chunks, kind(tst) src("`repo'")
assert "`r(failed)'" == ""
foreach i in 1 3 {
	capture ado uninstall nwcommands-tst`i'
}
capture ado uninstall nwcommands-tst2
sysdir set PLUS "`oldplus'"
di "PASS nwinstall_chunks"
