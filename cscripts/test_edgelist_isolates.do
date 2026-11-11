// Isolates in an edge list: a row with one identifier missing ("" or .) declares the other one as a node
// without a tie from that row; a row with both identifiers missing is ignored. Up to 3.18.0 such a row was
// stored as a tie with a missing end: nwsummarize reported one arc too many and, with numeric identifiers,
// nwtomata failed with r(3200).
cscript
nwclear
do unw_core.do

capture program drop _iso_check
program _iso_check
	args net nodes ties density labs mat
	qui nwsummarize `net'
	assert r(nodes) == `nodes'
	if "`r(directed)'" == "true" assert r(arcs) == `ties'
	else assert r(edges) == `ties'
	assert reldif(r(density), `density') < 1e-8
	assert `"`r(labs)'"' == `"`labs'"'
	qui nwtomata `net', mat(__iso_M)
	mata: __iso_E = `mat'
	mata: _diag(__iso_E, .)
	mata: assert(__iso_M == __iso_E)
	mata: mata drop __iso_M __iso_E
end

// expected matrices (nodes in sorted order of the identifiers)
// strings: Anna Fion Gwen Leh Sophie
mata: __iso_S = (0,0,0,0,1 \ 0,0,0,0,0 \ 1,0,0,1,0 \ 0,0,0,0,0 \ 0,0,1,0,0)
// numbers: 1 2 3 4 5
mata: __iso_N = (0,1,0,0,0 \ 0,0,1,0,0 \ 1,0,0,1,0 \ 0,0,0,0,0 \ 0,0,0,0,0)

// the four ties (Anna>Sophie, Sophie>Gwen, Gwen>Anna, Gwen>Leh; 1>2, 2>3, 3>1, 3>4)
capture program drop _iso_strdata
program _iso_strdata
	clear
	qui set obs 4
	gen str6 ego = word("Anna Sophie Gwen Gwen", _n)
	gen str6 alter = word("Sophie Gwen Anna Leh", _n)
end
capture program drop _iso_numdata
program _iso_numdata
	clear
	qui set obs 4
	gen ego = real(word("1 2 3 3", _n))
	gen alter = real(word("2 3 1 4", _n))
end

// 1. string ids, nwset edgelist and nwfromedge, sender-only row
_iso_strdata
set obs 5
replace ego = "Fion" in 5
nwset ego alter, edgelist directed name(s1)
_iso_check s1 5 4 .2 "Anna,Fion,Gwen,Leh,Sophie" __iso_S
nwload s1
assert _N == 5
assert _nwnode[2] == "Fion"
assert Fion == 0 | _n == 2
_iso_strdata
set obs 5
replace ego = "Fion" in 5
nwfromedge ego alter, directed name(s2)
_iso_check s2 5 4 .2 "Anna,Fion,Gwen,Leh,Sophie" __iso_S

// 2. numeric ids, sender-only row (Stata route); the same list without the row (fast route) gives the 4 x 4 block
_iso_numdata
nwfromedge ego alter, directed name(n0)
_iso_check n0 4 4 `=4/12' "n1,n2,n3,n4" __iso_N[1..4,1..4]
_iso_numdata
set obs 5
replace ego = 5 in 5
nwset ego alter, edgelist directed name(n1)
_iso_check n1 5 4 .2 "n1,n2,n3,n4,n5" __iso_N
_iso_numdata
set obs 5
replace ego = 5 in 5
nwfromedge ego alter, directed name(n2)
_iso_check n2 5 4 .2 "n1,n2,n3,n4,n5" __iso_N

// 3. receiver-only rows ("" Fion, . 5): the same networks
_iso_strdata
set obs 5
replace alter = "Fion" in 5
nwfromedge ego alter, directed name(s3)
_iso_check s3 5 4 .2 "Anna,Fion,Gwen,Leh,Sophie" __iso_S
_iso_numdata
set obs 5
replace alter = 5 in 5
nwfromedge ego alter, directed name(n3)
_iso_check n3 5 4 .2 "n1,n2,n3,n4,n5" __iso_N

// 4. an isolate in the middle of the order, non-consecutive ids: 10 20 / 20 40 / 30 .
clear
input ego alter
10 20
20 40
30 .
end
nwfromedge ego alter, directed name(n4)
_iso_check n4 4 2 `=2/12' "n10,n20,n30,n40" "(0,1,0,0 \ 0,0,0,1 \ 0,0,0,0 \ 0,0,0,0)"

// 5. a node with ties that also has an isolate row is not duplicated; rows with both ids missing are ignored
_iso_strdata
set obs 8
replace ego = "Fion" in 5
replace ego = "Gwen" in 6
replace alter = "Anna" in 7
nwfromedge ego alter, directed name(s5)
_iso_check s5 5 4 .2 "Anna,Fion,Gwen,Leh,Sophie" __iso_S
_iso_numdata
set obs 8
replace ego = 5 in 5
replace ego = 3 in 6
replace alter = 1 in 7
nwfromedge ego alter, directed name(n5)
_iso_check n5 5 4 .2 "n1,n2,n3,n4,n5" __iso_N

// 6. undirected
_iso_numdata
set obs 5
replace ego = 5 in 5
nwset ego alter, edgelist undirected name(u1)
_iso_check u1 5 4 .4 "n1,n2,n3,n4,n5" "(__iso_N + __iso_N') :> 0"
_iso_strdata
set obs 5
replace ego = "Fion" in 5
nwfromedge ego alter, undirected name(u2)
_iso_check u2 5 4 .4 "Anna,Fion,Gwen,Leh,Sophie" "(__iso_S + __iso_S') :> 0"

// 7. valued (the value on an isolate row is ignored)
_iso_numdata
gen w = _n + 1
set obs 5
replace ego = 5 in 5
replace w = 9 in 5
nwfromedge ego alter w, directed name(v1)
_iso_check v1 5 4 .2 "n1,n2,n3,n4,n5" "(0,2,0,0,0 \ 0,0,3,0,0 \ 4,0,0,5,0 \ 0,0,0,0,0 \ 0,0,0,0,0)"
qui nwsummarize v1
assert "`r(valued)'" == "true"
assert r(maxval) == 5

// 8. mixed types (numeric ego, string alter): the missing ego is not a node "."
clear
input ego str4 alter
1 "2"
2 "3"
5 ""
. "7"
end
nwfromedge ego alter, directed name(m1)
_iso_check m1 5 2 .1 "1,2,3,5,7" "(0,1,0,0,0 \ 0,0,1,0,0 \ J(3,5,0))"

// 9. only isolate rows: nodes, no ties; all ids missing: the clean error
clear
input str6 ego str6 alter
Fion ""
"" Anna
end
nwfromedge ego alter, directed name(o1)
_iso_check o1 2 0 0 "Anna,Fion" "J(2,2,0)"
clear
input ego alter
. .
. .
end
capture nwfromedge ego alter, name(o2)
assert _rc == 2000

mata: mata drop __iso_S __iso_N
di "PASS test_edgelist_isolates"
