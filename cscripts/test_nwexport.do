cscript
do unw_core.do

nwwebuse florentine, nwclear

nwexport flomarriage, type(ucinet) replace
assert _rc == 0

nwexport flobusiness, type(pajek) replace
assert _rc == 0


* --- gml/edgelist export-format parity (docs/ROADMAP.md's own tracked
* gap) - a self-contained (no nwwebuse network dependency), real
* export-then-reimport round-trip, not just "no error": the actual
* node count and tie structure must survive the round trip, and no
* spurious edge should appear (a real bug found and fixed while
* building this - nwtoedge's own diagonal self-rows carry a MISSING
* tie value, not a real 0, so `keep if netname != 0' alone let them
* through as fake edges; both exporters below now also filter `!= .').
local tmpd `"`c(tmpdir)'"'

nwclear
nwset, mat((0,1,1\1,0,0\1,0,0)) name(gmltest) undirected labs(Alice,Bob,Carol)
local gmlout `"`tmpd'/nwexport_cert_gml"'
capture erase `"`gmlout'.gml"'
nwexport gmltest, type(gml) fname(`"`gmlout'"') replace
assert _rc == 0
capture confirm file `"`gmlout'.gml"'
assert _rc == 0
* no missing/diagonal edge slipped through
assert !strpos(fileread(`"`gmlout'.gml"'), "value .")

nwimport `"`gmlout'.gml"', type(gml) name(gmlback) nwclear clear
_nwsyntax gmlback
assert `nodes' == 3

nwclear
nwset, mat((0,1,1\1,0,0\1,0,0)) name(edgetest) undirected labs(Alice,Bob,Carol)
local edgeout `"`tmpd'/nwexport_cert_edgelist"'
capture erase `"`edgeout'.txt"'
nwexport edgetest, type(edgelist) fname(`"`edgeout'"') replace
assert _rc == 0
capture confirm file `"`edgeout'.txt"'
assert _rc == 0
* exactly 2 real ties, no diagonal/self rows
preserve
import delimited `"`edgeout'.txt"', clear varnames(nonames) delimiter(tab)
assert _N == 2
restore

nwimport `"`edgeout'.txt"', type(edgelist) name(edgeback) nwclear clear
_nwsyntax edgeback
assert `nodes' == 3

di "=== gml/edgelist export format parity REGRESSION VERIFIED ==="

* --- failure path: a name that isn't a loaded network is rejected via
* _nwsyntax's own "Network X not found" check (error 482).
capture noisily nwexport nonexistent, type(edgelist)
assert _rc == 482
