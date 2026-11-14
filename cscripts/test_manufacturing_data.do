* Example data set manufacturing (emails in a manufacturing company, 2010) and
* manufacturing_nodes (reporting hierarchy). Both are plain Stata data sets, not
* networks. Loaded from the local data folder (nwwebuse only prepends the web
* path). Run from the repository root.

do unw_core.do

* ---------------- manufacturing (events) ----------------
use data/manufacturing, clear
assert _N == 50233
describe, short
assert r(k) == 3
confirm string variable sender receiver
confirm numeric variable t
assert "`: variable label sender'"   == "Employee who sends the email"
assert "`: variable label receiver'" == "Employee who receives it"
assert "`: variable label t'" == "Time: days since 1 January 2010, 00:00"
assert sender != "" & receiver != "" & !missing(t)
assert sender != receiver
assert t >= 0
* sorted by time
assert t >= t[_n-1] if _n > 1
qui sum t
assert abs(r(min) - 3.235255) < 1e-5
assert abs(r(max) - 272.9224) < 1e-4

* number of distinct actors (senders and receivers together)
preserve
keep sender
rename sender actor
tempfile snd
save `snd'
restore, preserve
keep receiver
rename receiver actor
append using `snd'
duplicates drop
assert _N == 144
tempfile actors
save `actors'
restore

* declare the event network
nwclear
use data/manufacturing, clear
nwset sender receiver, eventtime(t) name(mail)
nwsummarize mail
assert r(nodes) == 144
assert "`r(directed)'" == "true"
assert "`r(temporaltype)'" == "event"

* small window: the first two weeks
nwclear
use data/manufacturing, clear
keep if t < 14
assert _N == 2738
nwset sender receiver, eventtime(t) name(early)
nwsummarize early
assert r(nodes) == 129

* ---------------- manufacturing_nodes ----------------
use data/manufacturing_nodes, clear
assert _N == 154
describe, short
assert r(k) == 4
assert "`: variable label label'" == "Employee (E + identifier of the source data)"
assert "`: variable label supervisor'" == "Direct supervisor (empty for the CEO, E86)"
assert "`: variable label level'" == "Steps to the CEO in the reporting hierarchy (0 = CEO)"
assert "`: variable label division'" == "Branch of the CEO the employee belongs to (E86 for the CEO)"
isid label
assert label != "" & !missing(level) & division != ""
count if supervisor == ""
assert r(N) == 1
assert label == "E86" if supervisor == ""
count if level == 0
assert r(N) == 1
* every supervisor is an employee of the file
tempfile nodes
save `nodes'
keep label
rename label supervisor
tempfile labs
save `labs'
use `nodes', clear
drop if supervisor == ""
merge m:1 supervisor using `labs', keep(master) nogen
assert _N == 0

* all actors of the events are in the nodes file (154 employees, 144 of them act)
use `actors', clear
rename actor label
merge 1:1 label using `nodes', keep(master match)
assert _merge == 3
drop _merge

* the recipe of netexample: merge the node data onto the declared network
nwclear
use data/manufacturing, clear
nwset sender receiver, eventtime(t) name(mail)
rename _nwnode label
merge 1:1 label using data/manufacturing_nodes, keep(master match) nogen
rename label _nwnode
assert _N == 144
assert level != . & division != ""

di "PASS test_manufacturing_data"
