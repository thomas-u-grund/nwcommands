cscript

* Temporal networks (event times, snapshot times, intervals) in the load, save, import, export and copy commands:
* nwsave/nwuse/nwwebuse/nwappend keep them, nwtoedge lists them (option time), nwexport (type(edgelist)) writes
* them and nwimport reads them back, nwduplicate and nwdropnodes keep them, the formats that cannot hold times
* refuse unless aggregate is given.
clear all
set more off
capture program drop nwinstall
unw_defs

tempfile __tio
local dir "`__tio'_dir"
capture mkdir "`dir'"

* ---------------------------------------------------------------------------------------------
* helpers: the temporal data of a network as labels, times and values, read straight from the network object
capture program drop tstash
program tstash
	args net tag
	qui _nwsyntax `net'
	mata: st_local("ty", `netobj'->get_temporal_type())
	mata: st_local("nn", strofreal(`netobj'->get_nodes()))
	mata: st_local("dir", strofreal(`netobj'->is_directed_boolean()))
	mata: tio_nn_`tag' = (`netobj'->get_nodenames())'
	if "`ty'" == "event" {
		mata: tio_E_`tag' = *`netobj'->get_eventlist()
		mata: tio_l1_`tag' = tio_nn_`tag'[tio_E_`tag'[., 1]]
		mata: tio_l2_`tag' = tio_nn_`tag'[tio_E_`tag'[., 2]]
		mata: tio_X_`tag' = tio_E_`tag'[., (3, 4)]
	}
	else if "`ty'" == "snapshot" {
		mata: tio_E_`tag' = *`netobj'->get_edge_time()
		mata: tio_l1_`tag' = tio_nn_`tag'[tio_E_`tag'[., 1]]
		mata: tio_l2_`tag' = tio_nn_`tag'[tio_E_`tag'[., 2]]
		mata: tio_X_`tag' = tio_E_`tag'[., 3]
	}
	else {
		mata: tio_E_`tag' = *`netobj'->get_edge_start()
		mata: tio_S_`tag' = *`netobj'->get_edge_end()
		mata: tio_l1_`tag' = tio_nn_`tag'[tio_E_`tag'[., 1]]
		mata: tio_l2_`tag' = tio_nn_`tag'[tio_E_`tag'[., 2]]
		mata: tio_X_`tag' = (tio_E_`tag'[., 3], tio_S_`tag'[., 3])
	}
	* the rows in a fixed order (labels, then times), so that only the content is compared
	mata: tio_o_`tag' = order((tio_l1_`tag', tio_l2_`tag'), (1, 2))
	mata: tio_k_`tag' = rows(tio_l1_`tag')
end
* the temporal data of net equal those stored under tag: same rows in the same order (the order of events is part of the data)
capture program drop tsame
program tsame
	args net tag
	tstash `net' `tag'_new
	mata: st_local("same", strofreal(tio_k_`tag' == tio_k_`tag'_new & all(tio_l1_`tag' :== tio_l1_`tag'_new) & all(tio_l2_`tag' :== tio_l2_`tag'_new) & all(tio_X_`tag' :== tio_X_`tag'_new)))
	assert `same' == 1
	foreach v in nn E l1 l2 X o k S {
		capture mata: mata drop tio_`v'_`tag'_new
	}
end
capture program drop tstatic
program tstatic
	* the aggregated ties of a network: its tie list as a string, for exact comparison
	args net tag
	qui _nwsyntax `net'
	mata: tio_M_`tag' = *`netobj'->get_matrix()
end
capture program drop tdyadeq
program tdyadeq
	args net tag
	qui _nwsyntax `net'
	mata: st_local("same", strofreal(all((*`netobj'->get_matrix()) :== tio_M_`tag')))
	assert `same' == 1
end
capture program drop tflags
program tflags
	args net ty
	qui nwname `net'
	assert "`r(temporal)'" == "true"
	assert "`r(temporaltype)'" == "`ty'"
end

* ---------------------------------------------------------------------------------------------
* 1  event network, 439 timestamped calls: nwsave / nwuse
nwclear
use data/socialevolution.dta, clear
nwset sender receiver, eventtime(t) name(calls)
tflags calls event
tstash calls c1
mata: assert(tio_k_c1 == 439)
mata: assert(rows(uniqrows((tio_l1_c1, tio_l2_c1))) < 439)
tstatic calls c1
nwsave "`dir'/calls", replace
nwclear
nwuse "`dir'/calls"
tflags calls event
tsame calls c1
tdyadeq calls c1
qui nwname calls
assert "`r(directed)'" == "false" | "`r(directed)'" == "true"
local dirflag "`r(directed)'"
nwsummarize calls
* the event time variable name
mata: st_local("ev", `nws'.pdefs[1]->get_eventtimevar())
assert "`ev'" == "t"

* nwwebuse and nwappend (via nwuse)
nwclear
global nwwebpath "`dir'"
nwwebuse calls, nwclear
tflags calls event
tsame calls c1
global nwwebpath ""
nwclear
nwuse "`dir'/calls", nwclear
nwuse "`dir'/calls", nwappend force
tflags calls event
tflags calls_1 event
tsame calls_1 c1

* the file holds the temporal rows in columns of their own; the network columns are the ones of any file
preserve
use "`dir'/calls.nwdta", clear
confirm variable _nw_ttype _nw_tvars _nw_tnet _nw_tego _nw_talter _nw_tt1 _nw_tt2 _nw_tval
count if _nw_tnet == 1
assert r(N) == 439
assert _nw_ttype[1] == "event"
restore

* ---------------------------------------------------------------------------------------------
* 2  undirected valued event network with several events per dyad
nwclear
clear
set seed 4711
set obs 300
gen str6 a = "p" + string(ceil(runiform() * 12))
gen str6 b = "p" + string(ceil(runiform() * 12))
drop if a == b
gen double when = floor(runiform() * 50) + runiform() > 0.5
replace when = round(when * 4) / 4
gen val = ceil(runiform() * 5)
nwset a b val, eventtime(when) name(ev2) undirected
tflags ev2 event
tstash ev2 u1
tstatic ev2 u1
qui nwname ev2
assert "`r(directed)'" == "false"
assert "`r(valued)'" == "true"
nwsave "`dir'/ev2", replace
nwclear
nwuse "`dir'/ev2"
tflags ev2 event
tsame ev2 u1
tdyadeq ev2 u1
qui nwname ev2
assert "`r(directed)'" == "false"
assert "`r(valued)'" == "true"

* ---------------------------------------------------------------------------------------------
* 3  snapshot networks: a tie that comes and goes (A-B at waves 1 and 3, not at wave 2)
foreach dd in undirected directed {
	nwclear
	clear
	set obs 5
	gen str5 a = word("A A B C B", _n)
	gen str5 b = word("B B C A C", _n)
	gen w = real(word("1 3 2 3 3", _n))
	nwset a b, time(w) name(waves) `dd'
	tflags waves snapshot
	tstash waves w1
	tstatic waves w1
	nwsave "`dir'/waves_`dd'", replace
	nwclear
	nwuse "`dir'/waves_`dd'"
	tflags waves snapshot
	tsame waves w1
	tdyadeq waves w1
	mata: st_local("tv", `nws'.pdefs[1]->get_timevar())
	assert "`tv'" == "w"
	nwattime waves, at(1) name(s1)
	nwattime waves, at(2) name(s2)
	nwattime waves, at(3) name(s3)
	foreach k in 1 2 3 {
		qui nwsummarize s`k'
		local t`k' = cond("`dd'" == "undirected", r(edges), r(arcs))
	}
	if "`dd'" == "undirected" {
		assert `t1' == 1 & `t2' == 1 & `t3' == 3
	}
	else {
		assert `t1' == 1 & `t2' == 1 & `t3' == 3
	}
	* A-B is present at 1 and 3 and absent at 2
	qui _nwsyntax s2
	mata: st_local("ab2", strofreal(sum((*`netobj'->get_matrix())[1, 2])))
	assert `ab2' == 0
	qui _nwsyntax s1
	mata: st_local("ab1", strofreal(sum((*`netobj'->get_matrix())[1, 2])))
	assert `ab1' == 1
	qui _nwsyntax s3
	mata: st_local("ab3", strofreal(sum((*`netobj'->get_matrix())[1, 2])))
	assert `ab3' == 1
}

* ---------------------------------------------------------------------------------------------
* 4  interval network
nwclear
clear
set obs 4
gen str5 a = word("A A B C", _n)
gen str5 b = word("B B C A", _n)
gen s = real(word("1 5 2 3", _n))
gen e = real(word("3 9 4 8", _n))
nwset a b, interval(s e) name(iv) directed
tflags iv interval
tstash iv i1
tstatic iv i1
nwsave "`dir'/iv", replace
nwclear
nwuse "`dir'/iv"
tflags iv interval
tsame iv i1
tdyadeq iv i1
mata: st_local("sv", `nws'.pdefs[1]->get_startvar() + "," + `nws'.pdefs[1]->get_endvar())
assert "`sv'" == "s,e"

* ---------------------------------------------------------------------------------------------
* 5  several networks in one file: static, event, snapshot (a static network is not changed by the temporal columns)
nwclear
clear
set obs 6
gen str5 a = word("A B C D E A", _n)
gen str5 b = word("B C D E A C", _n)
gen t = _n
tempfile raw
save `raw'
nwset a b, name(stat) directed
tstatic stat k1
use `raw', clear
nwset a b, eventtime(t) name(evt) directed
use `raw', clear
nwset a b, time(t) name(snp) directed
tstash evt k2
tstash snp k3
nwsave "`dir'/multi", replace
nwclear
nwuse "`dir'/multi"
qui nwname stat
assert "`r(temporal)'" == "false"
tdyadeq stat k1
tflags evt event
tflags snp snapshot
tsame evt k2
tsame snp k3

* a file of static networks only has none of the temporal columns (older versions read the same file)
nwclear
clear
set obs 4
gen str5 a = word("A B C D", _n)
gen str5 b = word("B C D A", _n)
nwset a b, name(st1) directed
nwsave "`dir'/static", replace
preserve
use "`dir'/static.nwdta", clear
foreach v in _nw_ttype _nw_tvars _nw_tnet _nw_tego _nw_talter _nw_tt1 _nw_tt2 _nw_tval {
	capture confirm variable `v'
	assert _rc != 0
}
restore

* a file written before temporal networks were saved (an event network as its aggregated ties) loads as that static network
nwclear
nwuse "cscripts/temporal_io_fixture_old.nwdta", nwclear
qui nwsummarize calls
assert r(nodes) == 20
assert r(arcs) == 15
qui nwname calls
assert "`r(temporal)'" == "false"

* two-mode temporal networks: nwsave / nwuse keep the times, the edge list export refuses
nwclear
clear
set obs 7
gen str5 p = word("A A B C B D A", _n)
gen str5 o = word("X Y X Z Z Y X", _n)
gen t = real(word("1 2 3 4 5 6 7", _n))
tempfile raw2
save `raw2'
nwset p o, twomode eventtime(t) name(tm)
use `raw2', clear
nwset p o, twomode time(t) name(tm2)
tstash tm m1
tstash tm2 m2
nwsave "`dir'/tm", replace
nwclear
nwuse "`dir'/tm"
tflags tm event
tflags tm2 snapshot
tsame tm m1
tsame tm2 m2
qui nwname tm
assert "`r(mode2)'" == "true"
capture nwexport tm2, type(edgelist) fname("`dir'/tm2") replace
assert _rc == 198
nwexport tm2, type(edgelist) fname("`dir'/tm2") replace aggregate

* ---------------------------------------------------------------------------------------------
* 6  copies: nwduplicate keeps the temporal data, nwdropnodes / nwkeepnodes keep the events among the remaining nodes
nwclear
use data/socialevolution.dta, clear
nwset sender receiver, eventtime(t) name(calls)
tstash calls d1
nwduplicate calls, name(cp)
tflags cp event
tsame cp d1
nwduplicate calls, name(cp2)
nwdropnodes cp2, nodes(1 2 3)
tflags cp2 event
qui _nwsyntax cp2
mata: st_local("n2", strofreal(`netobj'->get_nodes()))
assert `n2' == 51
mata: E = *`netobj'->get_eventlist()
mata: assert(max(E[., 1]) <= 51 & max(E[., 2]) <= 51 & min(E[., 1]) >= 1 & min(E[., 2]) >= 1)
mata: st_local("nev", strofreal(rows(E)))
* every event of the copy is an event of the original among the same two people
tstash cp2 d2
mata:
dropped = tio_nn_d1[1::3]
keep = J(rows(tio_l1_d1), 1, 1)
for (i = 1; i <= 3; i++) keep = keep :& (tio_l1_d1 :!= dropped[i]) :& (tio_l2_d1 :!= dropped[i])
end
mata: assert(rows(tio_l1_d2) == sum(keep))
mata: assert(all(tio_l1_d2 :== select(tio_l1_d1, keep)))
mata: assert(all(tio_l2_d2 :== select(tio_l2_d1, keep)))
mata: assert(all(tio_X_d2 :== select(tio_X_d1, keep)))
* the original is unchanged
tsame calls d1
nwkeepnodes calls, nodes(1/10) generate(kp)
tflags kp event
tstash kp d3
mata: assert(all(tio_l1_d3 :!= ""))
mata: assert(rows(tio_l1_d3) > 0)
* snapshot network
nwclear
clear
set obs 5
gen str5 a = word("A A B C B", _n)
gen str5 b = word("B B C A C", _n)
gen w = real(word("1 3 2 3 3", _n))
nwset a b, time(w) name(waves) undirected
nwduplicate waves, name(wcp)
tflags wcp snapshot
tstash waves w1
tsame wcp w1
nwdropnodes wcp, nodes(C)
tflags wcp snapshot
tstash wcp w2
mata: assert(tio_k_w2 == 4)

* ---------------------------------------------------------------------------------------------
* 7  nwtoedge, time: event rows <-> network
nwclear
use data/socialevolution.dta, clear
nwset sender receiver, eventtime(t) name(calls)
tstash calls e1
* no option: the aggregated tie list, with a note
nwtoedge calls
nwtoedge calls, aggregate
count if calls != 0 & calls != .
nwclear
use data/socialevolution.dta, clear
nwset sender receiver, eventtime(t) name(calls)
nwtoedge calls, time
assert _N == 439
confirm variable _ego _alter _time
capture confirm variable calls
assert _rc != 0
qui sum _time
assert r(N) == 439
* build the network again from the rows
nwset _ego _alter, eventtime(_time) name(back) directed
tflags back event
tstash back e2
mata: assert(all(tio_l1_e1 :== tio_l1_e2) & all(tio_l2_e1 :== tio_l2_e2) & all(tio_X_e1 :== tio_X_e2))
* option errors
nwclear
use data/socialevolution.dta, clear
nwset sender receiver, eventtime(t) name(calls)
capture nwtoedge calls, time aggregate
assert _rc == 198
capture nwtoedge calls, time compress
assert _rc == 198
nwclear
clear
set obs 3
gen a = _n
gen b = mod(_n, 3) + 1
nwset a b, name(plain)
capture nwtoedge plain, time
assert _rc == 198
nwtoedge plain, aggregate

* ---------------------------------------------------------------------------------------------
* 8  nwexport: type(edgelist) writes the times, the other formats refuse unless aggregate is given; nwimport reads the times
nwclear
use data/socialevolution.dta, clear
nwset sender receiver, eventtime(t) name(calls) directed
tstash calls x1
foreach ty in pajek ucinet gml {
	capture nwexport calls, type(`ty') fname("`dir'/ex_`ty'") replace
	assert _rc == 198
	capture confirm file "`dir'/ex_`ty'.net"
	assert _rc != 0
	nwexport calls, type(`ty') fname("`dir'/ex_`ty'") replace aggregate
}
nwexport calls, type(edgelist) fname("`dir'/ex_el") replace
nwclear
nwimport "`dir'/ex_el.txt", type(edgelist, eventtime directed) name(calls)
tflags calls event
tsame calls x1
* aggregate writes the ties only
nwclear
use data/socialevolution.dta, clear
nwset sender receiver, eventtime(t) name(calls) directed
nwexport calls, type(edgelist) fname("`dir'/ex_agg") replace aggregate
nwclear
nwimport "`dir'/ex_agg.txt", type(edgelist) name(agg)
qui nwsummarize agg
assert r(arcs) == 84
qui nwname agg
assert "`r(temporal)'" == "false"

* valued undirected events and snapshots through nwexport / nwimport
nwclear
clear
set obs 200
set seed 99
gen str6 a = "p" + string(ceil(runiform() * 10))
gen str6 b = "p" + string(ceil(runiform() * 10))
drop if a == b
gen double when = ceil(runiform() * 30)
gen val = ceil(runiform() * 4)
nwset a b val, eventtime(when) name(ev3) undirected
tstash ev3 y1
nwexport ev3, type(edgelist) fname("`dir'/ev3") replace
nwclear
nwimport "`dir'/ev3.txt", type(edgelist, eventtime undirected) name(ev3)
tflags ev3 event
tsame ev3 y1
* without the option a file with a value and a time is not an edge list (four columns)
nwclear
capture nwimport "`dir'/ev3.txt", type(edgelist)
assert _rc != 0
nwclear
clear
set obs 5
gen str5 a = word("A A B C B", _n)
gen str5 b = word("B B C A C", _n)
gen w = real(word("1 3 2 3 3", _n))
nwset a b, time(w) name(waves) undirected
tstash waves z1
nwexport waves, type(edgelist) fname("`dir'/wv") replace
nwclear
nwimport "`dir'/wv.txt", type(edgelist, time undirected) name(waves)
tflags waves snapshot
tsame waves z1
nwclear
clear
set obs 4
gen str5 a = word("A A B C", _n)
gen str5 b = word("B B C A", _n)
gen s = real(word("1 5 2 3", _n))
gen e = real(word("3 9 4 8", _n))
nwset a b, interval(s e) name(iv) directed
tstash iv z2
nwexport iv, type(edgelist) fname("`dir'/ivx") replace
nwclear
nwimport "`dir'/ivx.txt", type(edgelist, interval directed) name(iv)
tflags iv interval
tsame iv z2
capture nwimport "`dir'/ivx.txt", type(edgelist, interval eventtime) name(bad) nwclear
assert _rc != 0

* ---------------------------------------------------------------------------------------------
* 9  nwload and nwsync: the variables hold the aggregated ties; the temporal data are not touched
nwclear
use data/socialevolution.dta, clear
nwset sender receiver, eventtime(t) name(calls) directed
tstash calls l1
nwload calls
tflags calls event
tsame calls l1
nwsync calls
tflags calls event
tsame calls l1
nwsync calls, fromstata
tflags calls event
tsame calls l1

* ---------------------------------------------------------------------------------------------
* 10 non-temporal networks: the commands behave as before (no note, nothing refused)
nwclear
clear
set obs 5
gen str5 a = word("A B C D E", _n)
gen str5 b = word("B C D E A", _n)
nwset a b, name(plain) directed
nwexport plain, type(pajek) fname("`dir'/pl") replace
nwexport plain, type(edgelist) fname("`dir'/pl") replace
nwtoedge plain
nwsave "`dir'/plain", replace
nwclear
nwuse "`dir'/plain"
qui nwname plain
assert "`r(temporal)'" == "false"

* clean up
local files : dir "`dir'" files "*"
foreach f of local files {
	erase "`dir'/`f'"
}
capture rmdir "`dir'"
di "test_temporal_io: all checks passed"
