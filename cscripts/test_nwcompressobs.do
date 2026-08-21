cscript

do unw_core.do

* nwcompressobs had zero test coverage before this session - fixed
* alongside the nwdropnodes/nwkeepnodes/nwreplacemat chain (see those
* files' own test coverage): its own "capture encode" probe against
* an already-numeric variable ALWAYS legitimately fails with r(107)
* ("not possible with numeric variable"), leaving _rc stale for the
* rest of the program since the file's own trailing "qui drop if"
* never refreshes it (quietly-prefixed commands don't update _rc even
* on success, see nwbrokerage.ado's own certified row for the fuller
* explanation of this Stata behavior) - meaning nwcompressobs, on
* literally any dataset containing at least one numeric variable
* (every real network's own _nwinclude column already guarantees
* this), silently returned with _rc==107 even though it had actually
* succeeded. This is a genuinely package-wide latent bug:
* nwcompressobs is called by nwreplacemat's own size-changing path on
* every single invocation, so every caller of that path was affected.
* Fixed with an explicit, silent "capture local __nw_rcreset = 1" at
* the end of the program.

* --- direct regression test for the _rc staleness bug itself: a
* dataset with both a string and a numeric variable (mirroring real
* network storage's own _nwnode/_nwinclude columns) must leave
* _rc==0, not the stale 107 left behind by the internal "capture
* encode" probe against the numeric variable.
clear
set obs 3
gen str1 _nwnode = "A" in 1
replace _nwnode = "B" in 2
replace _nwnode = "C" in 3
gen float _nwinclude = 1
nwcompressobs
assert _rc == 0
assert _N == 3

* --- functional check: a row must be dropped only when EVERY single
* variable is missing for it (an empty string counts as missing,
* confirmed via a direct encode probe: encode maps "" to a missing
* encoded value, not its own category) - a row with a non-missing
* value in even one variable must survive, regardless of whether
* other variables are missing for that same row.
clear
input str1 lab val
"A" 1
"B" .
"C" 3
end
nwcompressobs
assert _rc == 0
assert _N == 3

* --- a genuinely all-missing row (empty string label AND missing
* numeric value) must be dropped, and surviving rows must keep their
* original order and values.
clear
input str1 lab val
"A" 1
"" .
"C" 3
end
nwcompressobs
assert _rc == 0
assert _N == 2
assert lab[1] == "A"
assert lab[2] == "C"
assert val[1] == 1
assert val[2] == 3
