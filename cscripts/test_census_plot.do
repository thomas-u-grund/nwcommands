cscript
nwclear
do unw_core.do

* 3.20.0: nwdyads, plot and nwtriads, plot draw the census as pictures with counts;
* nwsummarize reports the mean degree; nwgeodesic reports connected-pair distances and
* overwrites its default output network.

set graphics off

// every drawn triad type is the type nwtriads assigns to it (A=1, B=2, C=3; "=" mutual)
local cats "012 102 021D 021U 021C 111D 111U 030T 030C 201 120D 120U 120C 210 300"
local e1  "A-B"
local e2  "A=B"
local e3  "B-A B-C"
local e4  "A-B C-B"
local e5  "A-B B-C"
local e6  "A=B C-B"
local e7  "A=B B-C"
local e8  "A-B C-B A-C"
local e9  "B-A C-B A-C"
local e10 "A=B B=C"
local e11 "B-A B-C A=C"
local e12 "A-B C-B A=C"
local e13 "A-B B-C A=C"
local e14 "A-B B=C A=C"
local e15 "A=B B=C A=C"
local A 1
local B 2
local C 3
forvalues k = 1/15 {
	mata: M = J(3, 3, 0)
	foreach t of local e`k' {
		local f = substr("`t'", 1, 1)
		local g = substr("`t'", 3, 1)
		mata: M[``f'', ``g''] = 1
		if strpos("`t'", "=") mata: M[``g'', ``f''] = 1
	}
	nwclear
	qui nwset, mat(M) name(t) directed
	qui nwtriads t
	local want : word `k' of `cats'
	assert r(_`want') == 1
}
// the definitions above must be the ones drawn
qui findfile _nwcensusplot.ado
local src "`r(fn)'"
forvalues k = 1/15 {
	local want : word `k' of `cats'
	tempname fh
	file open `fh' using "`src'", read text
	local found 0
	file read `fh' line
	while r(eof) == 0 {
		if strpos(`"`line'"', `"local e`=`k'+1' "') & strpos(`"`line'"', `""`e`k''""') local found 1
		file read `fh' line
	}
	file close `fh'
	assert `found' == 1
}

// plots on a directed and an undirected network; r() kept
nwclear
nwrandom 20, prob(.2) name(d) directed
qui nwdyads d
local m = r(_100)
nwdyads d, plot name(dp)
assert r(_100) == `m'
graph describe dp
qui nwtriads d
local t = r(_300)
nwtriads d, plot name(tp)
assert r(_300) == `t'
graph describe tp
nwrandom 15, prob(.2) name(u) undirected
nwdyads u, plot
graph describe dyads
nwtriads u, plot
graph describe triads

// mean degree
nwsummarize d
qui nwsummarize d
assert reldif(r(meandegree), r(arcs) / r(nodes)) < 1e-12
qui nwsummarize u
assert reldif(r(meandegree), 2 * r(edges) / r(nodes)) < 1e-12

// nwgeodesic on a disconnected network: two components 1-2-3 and 4-5
nwclear
mata: M = J(5, 5, 0)
mata: M[1, 2] = M[2, 1] = M[2, 3] = M[3, 2] = M[4, 5] = M[5, 4] = 1
nwset, mat(M) name(two) undirected
nwgeodesic two
assert r(avgpath) == -1
assert r(unconnected) == 6
assert reldif(r(connected), 4 / 10) < 1e-12
assert reldif(r(avgpath_connected), (1 + 1 + 2 + 1) / 4) < 1e-12
assert r(diameter_connected) == 2
// the default output network is overwritten, a named one is protected
nwgeodesic two
nwgeodesic two, name(g2)
capture nwgeodesic two, name(g2)
assert _rc == 99
nwgeodesic two, name(g2) nwreplace

// lazega has office, practice and status also as labeled numbers (3.20.0); the data of this checkout
capture confirm file "data/lazega.nwdta"
if !_rc global nwwebpath "`c(pwd)'/data"
nwwebuse lazega, nwclear
confirm numeric variable officenum practicenum partner
assert officenum == 1 if office == "Boston"
assert officenum == 3 if office == "Providence"
assert practicenum == 2 if practice == "litigation"
assert partner == (status == "partner")
assert "`: label (officenum) 2'" == "Hartford"
// the encode of the string variables still works (names not taken)
encode office, generate(officen)
assert officen == officenum
