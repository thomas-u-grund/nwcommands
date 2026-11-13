cscript

* A tie observed at several times keeps all of them: nwset ..., time() and interval() stored one time per pair
* (the last row), so a tie present at waves 1 and 3 was missing from the wave-1 slice. Also nwsummarize,
* save(file, replace), which wrote a file named "file, replace.dta".
clear mata
do unw_core.do
set more off
clear all

* 1 snapshot, undirected, string ids: Anna-Sophie at waves 1 and 3, absent at wave 2
nwclear
clear
input str8 ego str8 alter wave
"Anna" "Sophie" 1
"Sophie" "Gwen" 1
"Gwen" "Anna" 1
"Gwen" "Leh" 2
"Anna" "Leh" 2
"Anna" "Sophie" 3
"Leh" "Sophie" 3
end
nwset ego alter, edgelist undirected time(wave) name(evolving)
foreach t in 1 2 3 {
	nwattime evolving, at(`t') name(s`t')
	nwsummarize s`t'
	local e`t' = r(edges)
}
assert `e1' == 3
assert `e2' == 2
assert `e3' == 2
nwtoedge s3
quietly count if s3 == 1 & ((_ego == "Anna" & _alter == "Sophie") | (_ego == "Sophie" & _alter == "Anna"))
assert r(N) >= 1
nwattime evolving, at(4) name(s4)
nwsummarize s4
assert r(edges) == 0

* 2 snapshot, directed, numeric ids, a tie repeated in the same wave counts once
nwclear
clear
input ego alter wave
1 2 1
1 2 1
2 3 1
1 2 2
3 1 2
end
nwset ego alter, edgelist directed time(wave) name(d)
nwattime d, at(1) name(d1)
nwsummarize d1
assert r(arcs) == 2
nwattime d, at(2) name(d2)
nwsummarize d2
assert r(arcs) == 2

* 3 interval: Anna-Sophie in [1,3) and again in [5,7)
nwclear
clear
input str8 ego str8 alter start end
"Anna" "Sophie" 1 3
"Anna" "Sophie" 5 7
"Sophie" "Gwen" 2 6
end
nwset ego alter, edgelist undirected interval(start end) name(iv)
local want1 1
local want2 2
local want4 1
local want5 2
local want7 0
foreach t in 1 2 4 5 7 {
	nwattime iv, at(`t') name(i`t')
	nwsummarize i`t'
	assert r(edges) == `want`t''
}

* 4 nwsummarize, save(file, replace) writes file.dta
capture erase __nws_save_test.dta
nwsummarize iv, save(__nws_save_test, replace)
confirm file __nws_save_test.dta
nwsummarize iv, save(__nws_save_test)
confirm file __nws_save_test.dta
use __nws_save_test, clear
assert _N == 1
erase __nws_save_test.dta
capture noisily nwsummarize iv, save(, replace)
assert _rc == 198

display "test_nwattime_multi: PASS"
