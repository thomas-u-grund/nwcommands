cscript

clear mata
do unw_core.do
set more off

* nwmatching: maximum-cardinality bipartite matching via
* NWdef::calculate_bipartite_matching() (reduction to max-flow: virtual
* source/sink, capacity 1 throughout - the classical unit-capacity
* integrality argument guarantees ordinary Edmonds-Karp finds an
* optimal integral matching directly, no separate matching-specific
* algorithm needed).

* mode-1 {A,B,C}, mode-2 {D,E,F}; ties A-D, A-E, B-E, C-F.
* Maximum matching = 3 (e.g. A-D, B-E, C-F - a perfect matching exists).
nwclear
nwset, mat((0,0,0,1,1,0\0,0,0,0,1,0\0,0,0,0,0,1\1,0,0,0,0,0\1,1,0,0,0,0\0,0,1,0,0,0)) name(bipnet) labs(A,B,C,D,E,F)
_nwsyntax bipnet
mata: `netobj'->set_2mode(1)
mata: `netobj'->set_modes(("1","1","1","2","2","2"))

nwmatching bipnet, generate(match) silent
assert r(matched) == 3
* every matched pair must be a REAL existing tie, not an invented one.
forvalues i = 1/3 {
	local partner = match[`i']
	if `partner' > 0 {
		mata: st_numscalar("__ok", (*`netobj'->get_matrix())[`i',`partner'] > 0)
		assert __ok == 1
		scalar drop __ok
	}
}
di "=== nwmatching: perfect matching case REGRESSION VERIFIED ==="

* the SAME network, built through the real nwset `twomode' edgelist
* path (not hand-built via set_2mode()/set_modes() directly) - confirms
* the command works on an ordinarily-declared two-mode network, not
* just a manually-annotated one.
nwclear
clear
input str10 person str10 org
"A" "X"
"A" "Y"
"B" "Y"
"C" "Z"
end
nwset person org, twomode name(realbip)
nwmatching realbip, generate(match2) silent
assert r(matched) == 3

* error: requires a two-mode network.
nwclear
nwset, mat((0,1\1,0)) name(onemode) labs(A,B)
capture nwmatching onemode
assert _rc == 6556

di "=== nwmatching REGRESSION VERIFIED ==="

* --- BUGFIX regression (adversarial-input pressure test): the active
* dataset was never synced to the target network before st_store() -
* a bare `clear' immediately before the call crashed with a raw
* "argument out of range" (r3300).
nwclear
nwset, mat((1,0,1\0,1,0\1,0,0)) name(bipnet2) bipartite
clear
capture noisily nwmatching bipnet2
assert _rc == 0
assert _N >= 6
di "=== nwmatching: dataset-sync-after-clear REGRESSION VERIFIED ==="

* --- failure paths: a name that isn't a loaded network is rejected via
* _nwsyntax's own "Network X not found" check (error 482); the target
* variable already existing without replace is rejected (err 99).
capture noisily nwmatching nonexistent
assert _rc == 482

nwclear
nwset, mat((1,0,1\0,1,0\1,0,0)) name(bipnet3) bipartite
qui nwmatching bipnet3
capture noisily nwmatching bipnet3
assert _rc == 99
