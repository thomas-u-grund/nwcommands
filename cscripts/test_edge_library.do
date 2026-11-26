* Fixes in the shared Mata library: values of snapshot and interval networks per time, missing ties in nwturnover and
* nwkcomponents, node names with commas in two-mode files, reserved network names.  Run from the repository root.
clear all
do unw_core.do

capture program drop _mkt
program _mkt
	clear
	set obs 5
	gen str1 a = word("a a a b b", _n)
	gen str1 b = word("b b b c c", _n)
	gen val = real(word("5 2 9 4 7", _n))
	gen wave = real(word("1 2 3 1 2", _n))
end
capture program drop _cell
program _cell
	args net i j want
	nwtomata `net', mat(__C)
	mata: st_local("__v", strofreal(__C[`i', `j']))
	if "`__v'" != "`want'" {
		di as err "`net'[`i',`j'] is `__v', expected `want'"
		exit 9
	}
end

foreach dir in directed undirected {
	nwclear
	_mkt
	nwset a b val, time(wave) name(s) `dir'
	foreach w in "1 5 4" "2 2 7" "3 9 0" {
		tokenize `w'
		nwattime s, at(`1') name(w`1')
		_cell w`1' 1 2 `2'
		_cell w`1' 2 3 `3'
	}
	* copy, drop a node, save and load: the values per time stay
	nwduplicate s, name(copy)
	nwattime copy, at(1) name(c1)
	_cell c1 1 2 5
	tempfile f
	nwsave "`f'", replace
	nwclear
	nwuse "`f'", nwclear
	nwattime s, at(2) name(u2)
	_cell u2 1 2 2
	_cell u2 2 3 7
	nwdropnodes s, nodes(c)
	nwattime s, at(1) name(d1)
	_cell d1 1 2 5
	* export of the times and back
	clear
	nwtoedge s, time
	confirm variable _value
	tempfile times
	save "`times'"
	nwclear
	use "`times'", clear
	nwset _ego _alter _value, time(_time) name(back) `dir'
	nwattime back, at(2) name(b2)
	_cell b2 1 2 2
}

* intervals: the value of the interval that contains the time
nwclear
clear
set obs 2
gen str1 a = "a"
gen str1 b = "b"
gen val = cond(_n == 1, 5, 2)
gen t0 = cond(_n == 1, 1, 4)
gen t1 = cond(_n == 1, 3, 6)
nwset a b val, interval(t0 t1) name(iv) directed
nwattime iv, at(2) name(i2)
_cell i2 1 2 5
nwattime iv, at(5) name(i5)
_cell i5 1 2 2

* without a value variable every tie is 1, and the list of times has no value column
nwclear
_mkt
* the values are not used: they are discarded
nwset a b, time(wave) name(s) directed dropvars
nwattime s, at(2) name(w2)
_cell w2 1 2 1
nwtoedge s, time
capture confirm variable _value
assert _rc == 111

* turnover and k-components: a missing tie is no tie
foreach v in 0 . {
	nwclear
	mata: A = J(4, 4, 0)
	mata: A[1,2] = A[2,1] = 1
	mata: B = A
	mata: A[3,4] = A[4,3] = `v'
	nwset, mat(A) name(t1) undirected
	nwset, mat(B) name(t2) undirected
	clear
	set obs 4
	nwturnover t1 t2, generate(turn)
	local s`=cond("`v'" == "0", "z", "m")' "`r(stable)' `r(formed)' `r(dissolved)'"
}
assert "`sz'" == "1 0 0" & "`sm'" == "`sz'"
foreach v in 0 . {
	nwclear
	mata: A = J(4, 4, 0)
	mata: for (i=1; i<=3; i++) A[i,i+1] = A[i+1,i] = 1
	mata: A[1,4] = A[4,1] = `v'
	nwset, mat(A) name(k) undirected
	clear
	set obs 4
	nwkcomponents k, k(2) generate(kc)
	qui count if kc != 0 & kc < .
	assert r(N) == 0
}

* a two-mode network with a comma in a label keeps its modes through save and use
nwclear
clear
set obs 3
gen str12 p = word("Smith~Ann Bob Bob", _n)
replace p = subinstr(p, "~", ", ", 1)
gen str3 e = word("e1 e1 e2", _n)
nwset p e, twomode name(tm)
nwsummarize tm
local m1 = r(nodes)
mata: st_local("before", __nw.nws.pdefs[1]->get_modes_labeled_string())
tempfile g
nwsave "`g'", replace
nwclear
nwuse "`g'", nwclear
mata: st_local("after", __nw.nws.pdefs[1]->get_modes_labeled_string())
assert `"`before'"' == `"`after'"'

* reserved words are refused by the library itself
foreach x in _all _N if _nwnode str5 {
	capture mata: nw_assert_netname("`x'")
	assert _rc == 198
}
mata: nw_assert_netname("friends")

* nwdrop, nwkeep and nwsubset with a condition: the values per time follow the nodes
foreach cmd in drop keep {
	foreach kind in snapshot interval event {
		nwclear
		clear
		set obs 4
		gen str1 e = word("a b c d", _n)
		gen str1 a = word("b c d b", _n)
		gen double v = real(word("5 3 4 2", _n))
		gen t = cond(_n == 1, 1, 2)
		gen t1 = t + 1
		if "`kind'" == "snapshot" nwset e a v, time(t) name(N) directed dropvars
		if "`kind'" == "interval" nwset e a v, interval(t t1) name(N) directed dropvars
		if "`kind'" == "event" nwset e a, eventtime(t) name(N) directed dropvars
		clear
		if "`cmd'" == "drop" nwdrop N if _n == 1
		else nwkeep N if _n != 1
		* node a and with it its tie a-b are gone
		nwattime N, at(1) name(S1)
		nwsummarize S1
		assert r(arcs) == 0
		nwattime N, at(2) name(S2)
		nwsummarize S2
		assert r(arcs) == 3 & r(nodes) == 3
		local w = cond("`kind'" == "event", "1 1 1", "3 4 2")
		_cell S2 1 2 `: word 1 of `w''
		_cell S2 2 3 `: word 2 of `w''
		_cell S2 3 1 `: word 3 of `w''
		clear
		nwtoedge N, time
		assert _N == 3
		tempfile h
		nwsave "`h'", replace
	}
}

* nwrecode and nwdichotomize: a rule that changes the value of some time ends the temporal state, one that changes none keeps it
nwclear
clear
set obs 2
gen str1 a = "a"
gen str1 b = "b"
gen val = cond(_n == 1, 5, 1)
gen wave = _n
nwset a b val, time(wave) name(s) directed
nwrecode s (99=98)
nwattime s, at(1) name(k1)
_cell k1 1 2 5
nwdichotomize s, threshold(.5)
capture nwattime s, at(1) name(k2)
assert _rc != 0

* nwkcomponents and nwcohesion: a missing value in one direction does not remove the tie of the other
nwclear
mata: M = (0,.,1,0 \ 1,0,1,0 \ 1,1,0,0 \ 0,0,0,0)
nwset, mat(M) name(A) directed
clear
set obs 4
nwkcomponents A, k(2) generate(kc) sym
qui count if kc > 0 & kc < .
assert r(N) == 3
mata: assert(*nw_undirected01((0, . \ 1, 0), 1) == (0, 1 \ 1, 0))
mata: assert(*nw_undirected01((0, -1 \ 1, 0), 1) == (0, 1 \ 1, 0))
mata: assert(*nw_undirected01((0, . \ ., 0), 0) == J(2, 2, 0))

* modes: many nodes with commas in their names, read back in one pass
mata:
n = 40000
lab = "x, " :+ strofreal(1..n)
s = invtokens(lab :+ "=" :+ strofreal(1 :+ (mod(1..n, 2) :== 0)), ",")
t = tokeninit("", ",", "", 0, 0)
tokenset(t, s)
timer_clear(1)
timer_on(1)
res = nw_join_modepairs(tokengetall(t))
timer_off(1)
assert(cols(res) == n)
assert(res == lab :+ "=" :+ strofreal(1 :+ (mod(1..n, 2) :== 0)))
assert(timer_value(1)[1] < 5)
assert(cols(nw_join_modepairs(J(1, 0, ""))) == 0)
end

display "PASS test_edge_library"
