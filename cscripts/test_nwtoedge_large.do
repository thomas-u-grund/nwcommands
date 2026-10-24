cscript
nwclear

do unw_core.do

* Edge-list and save/load round trips at a size where the old routes failed
* (dense N x N dyad list in nwtoedge; macros of 30,000 modes/labels in
* nwsave/nwuse; r(920) in Stata/BE).  30,000 nodes / ~150,000 ties, plus
* isolated nodes, must survive nwtoedge -> nwfromedge, nwsave -> nwuse and
* nwappend with the same node count, tie count and degrees, and never
* allocate a dense matrix.

local n 30000
clear
set seed 4711
set obs `=5*`n''
gen long from = ceil(runiform()*`n')
gen long to = ceil(runiform()*`n')
drop if from == to
duplicates drop from to, force
* three nodes that occur only in a self-loop: isolates once self-loops are dropped
local iso1 = `n' + 1
local iso2 = `n' + 2
local iso3 = `n' + 3
local N1 = _N + 3
set obs `N1'
replace from = `iso1' in `=_N-2'
replace to = `iso1' in `=_N-2'
replace from = `iso2' in `=_N-1'
replace to = `iso2' in `=_N-1'
replace from = `iso3' in `=_N'
replace to = `iso3' in `=_N'
local ties = _N - 3
tempfile data
save `data'

nwfromedge from to, name(g1) directed
nwdegree g1, generate(od id) silent
quietly summarize od
assert r(sum) == `ties'
mata: g1p = nw.nws.pdefs[nw.nws.get_index_of("g1")]
mata: st_numscalar("nodes1", g1p->get_nodes())
local nodes1 = scalar(nodes1)
assert `nodes1' >= `n'

* ---- nwtoedge (compress) -> nwfromedge
timer clear 1
timer on 1
nwtoedge g1, compress
timer off 1
quietly timer list 1
display "nwtoedge compress: " r(t1) " s, `=_N' rows"
assert r(t1) < 60
* the listed ties plus one blanked-diagonal row per node
assert _N == `ties' + `nodes1'
nwfromedge _ego _alter, name(g2) directed
nwname g2
assert r(nodes) == `nodes1'
nwdegree g2, generate(od2 id2) silent
quietly summarize od2
assert r(sum) == `ties'
mata: g2p = nw.nws.pdefs[nw.nws.get_index_of("g2")]
mata: st_numscalar("isdense", g1p->is_dense_built() + g2p->is_dense_built())
assert scalar(isdense) == 0

* ---- nwsave -> nwuse
nwclear
nwclear
use `data', clear
nwfromedge from to, name(g1) directed
tempfile f
timer clear 2
timer on 2
nwsave `f', replace
timer off 2
quietly timer list 2
display "nwsave: " r(t2) " s"
assert r(t2) < 60
nwclear
timer clear 3
timer on 3
nwuse `f', nwclear
timer off 3
quietly timer list 3
display "nwuse: " r(t3) " s"
assert r(t3) < 60
nwname g1
assert r(nodes) == `nodes1'
nwdegree g1, generate(od3 id3) silent
quietly summarize od3
assert r(sum) == `ties'
mata: g1p = nw.nws.pdefs[nw.nws.get_index_of("g1")]
mata: st_numscalar("isdense", g1p->is_dense_built())
assert scalar(isdense) == 0

* ---- nwappend: a second network under another name
nwclear
use `data', clear
nwfromedge from to, name(g1b) directed noclear
nwname g1b
assert r(nodes) == `nodes1'
nwappend using `f', force
nwset
assert wordcount("`r(nets)'") == 2
nwclear
display "test_nwtoedge_large: all checks passed"
