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

nwclear

nwimport "http://vlado.fmf.uni-lj.si/pub/networks/data/ucinet/prison.dat", type(ucinet)
assert _rc == 0
nwname
assert `"`r(valued)'"'   == `"false"'
assert `"`r(mode2)'"'    == `"false"'
assert `"`r(netname)'"'  == `"prison"'
assert `"`r(directed)'"' == `"true"'
assert `"`r(selfloop)'"' == `"false"'

capture nwimport "http://vlado.fmf.uni-lj.si/pub/networks/data/ucinet/zachary.dat", type(ucinet)
assert _rc != 0
nwimport "http://vlado.fmf.uni-lj.si/pub/networks/data/ucinet/zachary.dat", type(ucinet) nwappend
assert _rc == 0
nwset
assert `"`r(nets)'"' == `" prison ZACHE ZACHC"'
assert         r(networks) == 3


nwimport "http://vlado.fmf.uni-lj.si/pub/networks/data/ucinet/prison.dat", nwappend name(prison2) forceundirected type(ucinet)

assert _rc == 0

nwimport "http://vlado.fmf.uni-lj.si/pub/networks/data/ucinet/prison.dat", type(ucinet) nwclear
assert _rc == 0
nwset
assert `"`r(nets)'"' == `" prison"'
assert         r(networks) == 1

nwimport "http://vlado.fmf.uni-lj.si/pub/networks/data/ucinet/prison.dat", type(ucinet) forcedirected nwclear
assert _rc == 0
nwsummarize

assert `"`r(valued)'"'   == `"false"'
assert `"`r(mode2)'"'    == `"false"'
assert `"`r(netname)'"'  == `"prison"'
assert `"`r(name)'"'     == `"prison"'
assert `"`r(directed)'"' == `"true"'
assert `"`r(selfloop)'"' == `"false"'


nwimport "http://vlado.fmf.uni-lj.si/pub/networks/data/ucinet/prison.dat", type(ucinet) nwappend
assert _rc == 0
nwsummarize

nwimport "http://vlado.fmf.uni-lj.si/pub/networks/data./sport/football.net", type(pajek) nwclear
assert _rc == 0

nwimport "http://vlado.fmf.uni-lj.si/pub/networks/data/ucinet/prison.dat", nwclear type(ucinet) name(blabla) forcedirected
nwname
assert `"`r(directed)'"' == `"true"'

nwimport "http://vlado.fmf.uni-lj.si/pub/networks/data/ucinet/prison.dat", nwclear type(ucinet) name(blabla2) forceundirected
nwname
assert `"`r(directed)'"' == `"false"'





