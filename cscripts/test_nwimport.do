cscript

do unw_core.do

* --- type(matrix) regression, self-contained (no external host needed,
* unlike every other case in this file - see the file's own tail for the
* existing external-dependency gap). Covers a real bug found via the
* alpha audit: the delimiter-guessing loop inside _nwimport_matrix tried
* "tab" first regardless of the file's real delimiter, and its own
* space-split "recovery" attempt could spuriously report success on a
* wrong guess whenever the misparsed single column happened to contain
* any whitespace at all (e.g. a trailing attribute column) - silently
* continuing with garbled data instead of correctly trying the real
* delimiter next. A stray, non-functional "names" token appended to
* every insheet call compounded this. Both removed; this network's own
* header-row-plus-attribute shape (a space inside "the sex value") is
* exactly what used to trigger the false "success".
tempfile matcsv
qui {
	clear
	set obs 4
	gen str6 v1 = "thomas"
	replace v1 = "peter" in 2
	replace v1 = "susan" in 3
	replace v1 = "kim" in 4
	gen v2 = 0 in 1
	replace v2 = 1 in 2
	replace v2 = 0 in 3
	replace v2 = 0 in 4
	gen v3 = 1 in 1
	replace v3 = 0 in 2
	replace v3 = 0 in 3
	replace v3 = 1 in 4
	gen v4 = 1 in 1
	replace v4 = 0 in 2
	replace v4 = 1 in 3
	replace v4 = 0 in 4
	gen v5 = 0 in 1
	replace v5 = 0 in 2
	replace v5 = 1 in 3
	replace v5 = 0 in 4
	export delimited using `"`matcsv'.csv"', novarnames delimiter(",") replace
}
nwclear
nwimport `"`matcsv'.csv"', type(matrix, rownames) name(rowlabtest)
assert _rc == 0
mata: __p = nw.nws.pdefs[nw.nws.get_index_of("rowlabtest")]
mata: st_matrix("__rowlabnames", J(1,1,1))
mata: st_local("__n1", __p->get_nodenames()[1,1])
mata: st_local("__n2", __p->get_nodenames()[1,2])
assert "`__n1'" == "thomas"
assert "`__n2'" == "peter"
mata: st_numscalar("__v12", __p->edge_weight(1,2))
assert __v12 == 1
mata: mata drop __p
di "=== type(matrix, rownames) SELF-CONTAINED REGRESSION VERIFIED ==="

* header-row-only shape (node names in row 1, no row-label column) -
* auto-detected correctly with NO type_sub at all; this is the shape
* nwimport.sthlp's own Example 2 documents.
tempfile matcsv2
qui {
	clear
	set obs 4
	gen thomas = 0 in 1
	replace thomas = 1 in 2
	replace thomas = 0 in 3
	replace thomas = 0 in 4
	gen peter = 1 in 1
	replace peter = 0 in 2
	replace peter = 0 in 3
	replace peter = 1 in 4
	gen susan = 1 in 1
	replace susan = 0 in 2
	replace susan = 1 in 3
	replace susan = 0 in 4
	gen kim = 0 in 1
	replace kim = 0 in 2
	replace kim = 1 in 3
	replace kim = 0 in 4
	export delimited using `"`matcsv2'.csv"', replace
}
nwclear
nwimport `"`matcsv2'.csv"', type(matrix) name(headertest)
assert _rc == 0
mata: __p2 = nw.nws.pdefs[nw.nws.get_index_of("headertest")]
mata: st_local("__hn1", __p2->get_nodenames()[1,1])
assert "`__hn1'" == "thomas"
mata: mata drop __p2
di "=== type(matrix), header-row auto-detection SELF-CONTAINED REGRESSION VERIFIED ==="

* type(edgelist) and type(compressed), self-contained (no external host
* needed) - moderate-severity pass, import_export group: neither of these
* two import_type variants had any regression coverage at all before this
* (only ucinet/pajek/matrix were exercised), using this package's own
* long-standing local example fixtures under data/.
nwclear
nwimport "data/edgelist_example.txt", type(edgelist) name(edgetest)
assert _rc == 0
nwname
assert `"`r(netname)'"' == `"edgetest"'
assert         r(nodes) == 4
di "=== type(edgelist) SELF-CONTAINED REGRESSION VERIFIED ==="

nwclear
nwimport "data/compressed_example.txt", type(compressed) name(comptest)
assert _rc == 0
nwname
assert `"`r(netname)'"' == `"comptest"'
assert         r(nodes) == 4
di "=== type(compressed) SELF-CONTAINED REGRESSION VERIFIED ==="

tempfile gmlfix
qui {
	file open gmlh using `"`gmlfix'"', write text replace
	file write gmlh `"Creator "me""' _n
	file write gmlh `"Version "xx""' _n
	file write gmlh "graph [" _n
	file write gmlh `" comment "This is a sample graph""' _n
	file write gmlh " directed 1" _n
	file write gmlh " IsPlanar 1" _n
	file write gmlh " pos  [ x 0 y 1 ]" _n
	file write gmlh " node [" _n
	file write gmlh "   id 1" _n
	file write gmlh `"   label "Node 1""' _n
	file write gmlh "   pos [ x 1 y 1 ]" _n
	file write gmlh " ]" _n
	file write gmlh " node [" _n
	file write gmlh "    id 2" _n
	file write gmlh "    pos [ x 1 y 2 ]" _n
	file write gmlh `"    label "Node 2""' _n
	file write gmlh "    ]" _n
	file write gmlh "  node [" _n
	file write gmlh "    id 3" _n
	file write gmlh `"    label "Node 3""' _n
	file write gmlh "    pos [ x 1 y 3 ]" _n
	file write gmlh "  ]" _n
	file write gmlh "  edge [" _n
	file write gmlh "    source 1" _n
	file write gmlh "    target 2" _n
	file write gmlh `"    label "Edge from node 1 to node 2""' _n
	file write gmlh `"    color [line "blue" thickness 3]"' _n
	file write gmlh "" _n
	file write gmlh "  ]" _n
	file write gmlh "  edge [" _n
	file write gmlh "    source 2" _n
	file write gmlh "    target 3" _n
	file write gmlh `"    label "Edge from node 2 to node 3""' _n
	file write gmlh "  ]" _n
	file write gmlh "  edge [" _n
	file write gmlh "    source 3" _n
	file write gmlh "    target 1" _n
	file write gmlh `"    label "Edge from node 3 to node 1""' _n
	file write gmlh "  ]" _n
	file write gmlh "]" _n
	file close gmlh
}
nwclear

* type(gml), self-contained (no external host needed) - real bug, real
* fixture: this exact GML content is networkx's own test_gml.py
* `simple_data' fixture (not this package's self-generated exporter
* output, which never happened to exercise either bug below). Two real
* bugs found and fixed here:
*  (1) _nwimport_gml's own `while `"`line'"' != ""' loop condition
*      treated ANY blank line as end-of-file - this fixture has one
*      inside its first `edge [...]' block, which silently truncated
*      parsing to a fragment of the first edge with no error. Fixed to
*      `while r(eof) == 0'.
*  (2) even after (1), import still failed with a generic "Loading
*      networks... failed" (r(6750)) wrapper error. Root cause: multi-
*      word GML node labels (e.g. "Node 1") were being accumulated into
*      `labs' as space-separated, individually double-quoted tokens
*      (` "Node 1" "Node 2"'), but get_nodenames_from_string()
*      (unw_core.do) tokenizes `labs' on COMMA, not whitespace or
*      quotes - every OTHER importer already used the comma-delimited,
*      unquoted convention. The embedded quotes then broke nwfromedge's
*      own `if "`labs'" == ""' emptiness check with a genuine "type
*      mismatch" (r(109)), traced via `set trace on' since the outer
*      `capture' swallowed the real error. Fixed to match the
*      comma-delimited convention: `local labs `"`labs'`nextlab',"''.
nwimport `"`gmlfix'"', type(gml) name(gmltest) nwclear clear
assert _rc == 0
nw_syntax gmltest
assert `nodes' == 3
assert "`directed'" == "true"
mata: __pg = nw.nws.pdefs[nw.nws.get_index_of("gmltest")]
mata: st_local("__gn1", __pg->get_nodenames()[1,1])
mata: st_local("__gn2", __pg->get_nodenames()[1,2])
mata: st_local("__gn3", __pg->get_nodenames()[1,3])
assert "`__gn1'" == "Node 1"
assert "`__gn2'" == "Node 2"
assert "`__gn3'" == "Node 3"
mata: st_numscalar("__ge12", __pg->edge_weight(1,2))
mata: st_numscalar("__ge23", __pg->edge_weight(2,3))
mata: st_numscalar("__ge31", __pg->edge_weight(3,1))
mata: st_numscalar("__ge21", __pg->edge_weight(2,1))
assert __ge12 == 1
assert __ge23 == 1
assert __ge31 == 1
assert __ge21 == 0
mata: mata drop __pg
di "=== type(gml), real externally-sourced fixture (blank line + multi-word labels) SELF-CONTAINED REGRESSION VERIFIED ==="

* --- type(ucinet)/type(pajek) regression, self-contained (no external
* host needed): this section used to fetch every fixture from
* http://vlado.fmf.uni-lj.si (Vladimir Batagelj's personal academic
* page, hosting the "prison"/"zachary"/"football" example files this
* section's own assertions are named after) - that host is now dead
* (confirmed directly: DNS resolves, but the TCP connection itself
* times out with no response at all, and a user independently confirmed
* the same from their own network - not a one-off/local blip). Rather
* than deleting this section's own real coverage (single- vs.
* multi-network DL import, nwappend/nwclear/forcedirected/
* forceundirected/name() interaction, Pajek .net import), it now builds
* small local .dl/.net fixtures inline via `file write` (matching this
* file's own already-established "type(matrix)"/"type(gml)" sections'
* self-contained convention above) reproducing the exact DL syntax
* nwimport.sthlp's own Example 1/Example 2 document - a single-network
* directed 4-node fixture standing in for "prison", and a two-network
* fixture with `matrix labels: ZACHE,ZACHC` standing in for "zachary"
* (the embedded matrix labels are what named those two networks in the
* original test, not the filename - `_nwimpdl' sets `nameoff="true"'
* whenever "matrix labels:" is present, so any `name()' passed by the
* caller is correctly ignored for these two, exactly as before).
* "prison" itself is not filename-derived here (an arbitrary Stata
* tempfile path, not literally named prison.dl) - passed explicitly via
* `name(prison)' at every call site instead, decoupling the test from
* any specific local filename.

nwclear

tempfile prisondl
file open dlh using `"`prisondl'"', write replace
file write dlh "dl n=4 format=fullmatrix" _n
file write dlh "data:" _n
file write dlh "0 1 0 0" _n
file write dlh "0 0 1 0" _n
file write dlh "0 0 0 1" _n
file write dlh "1 0 0 0" _n
file close dlh

tempfile zachdl
file open dlh using `"`zachdl'"', write replace
file write dlh "dl n=4 nm=2" _n
file write dlh "matrix labels:" _n
file write dlh "ZACHE,ZACHC" _n
file write dlh "data:" _n
file write dlh "0 1 0 1" _n
file write dlh "1 0 0 0" _n
file write dlh "0 0 1 0" _n
file write dlh "1 0 0 1" _n
file write dlh "" _n
file write dlh "0 1 1 1" _n
file write dlh "1 0 0 0" _n
file write dlh "1 0 0 1" _n
file write dlh "1 0 1 0" _n
file close dlh

tempfile footballnet
file open neth using `"`footballnet'"', write replace
file write neth "*Vertices 4" _n
file write neth `"1 "A""' _n
file write neth `"2 "B""' _n
file write neth `"3 "C""' _n
file write neth `"4 "D""' _n
file write neth "*Edges" _n
file write neth "1 2" _n
file write neth "2 3" _n
file write neth "3 4" _n
file write neth "4 1" _n
file close neth

nwimport `"`prisondl'"', type(ucinet) name(prison)
assert _rc == 0
nwname
assert `"`r(valued)'"'   == `"false"'
assert `"`r(mode2)'"'    == `"false"'
assert `"`r(netname)'"'  == `"prison"'
assert `"`r(directed)'"' == `"true"'
assert `"`r(selfloop)'"' == `"false"'

capture nwimport `"`zachdl'"', type(ucinet)
assert _rc != 0
nwimport `"`zachdl'"', type(ucinet) nwappend
assert _rc == 0
nwset
assert `"`r(nets)'"' == `" prison ZACHE ZACHC"'
assert         r(networks) == 3


nwimport `"`prisondl'"', nwappend name(prison2) forceundirected type(ucinet)

assert _rc == 0

nwimport `"`prisondl'"', type(ucinet) nwclear name(prison)
assert _rc == 0
nwset
assert `"`r(nets)'"' == `" prison"'
assert         r(networks) == 1

nwimport `"`prisondl'"', type(ucinet) forcedirected nwclear name(prison)
assert _rc == 0
nwsummarize

assert `"`r(valued)'"'   == `"false"'
assert `"`r(mode2)'"'    == `"false"'
assert `"`r(netname)'"'  == `"prison"'
assert `"`r(name)'"'     == `"prison"'
assert `"`r(directed)'"' == `"true"'
assert `"`r(selfloop)'"' == `"false"'


nwimport `"`prisondl'"', type(ucinet) nwappend name(prison3)
assert _rc == 0
nwsummarize

nwimport `"`footballnet'"', type(pajek) nwclear
assert _rc == 0

nwimport `"`prisondl'"', nwclear type(ucinet) name(blabla) forcedirected
nwname
assert `"`r(directed)'"' == `"true"'

nwimport `"`prisondl'"', nwclear type(ucinet) name(blabla2) forceundirected
nwname
assert `"`r(directed)'"' == `"false"'
di "=== type(ucinet)/type(pajek), self-contained local .dl/.net fixtures (no external host needed) SELF-CONTAINED REGRESSION VERIFIED ==="

