* _nwlibcheck: clear message (r(3499)) when the core Mata library is missing or was built by a newer Stata
* Run from the repository root with the repository (and its lib folder) on the adopath.
capture program drop nwinstall
clear all
global NW_LIBCHECK_OK ""

* 1. normal case: the check passes, sets the session flag, and a command works
_nwlibcheck
assert "$NW_LIBCHECK_OK" == "1"
nwwebuse florentine, nwclear
nwsummarize
display "PASS libcheck normal"

* 2. library function not visible (simulated by looking for a function that does not exist): the message and r(3499)
global NW_LIBCHECK_OK ""
global NW_LIBCHECK_TEST "nws_function_that_does_not_exist"
capture noisily _nwlibcheck
assert _rc == 3499
assert "$NW_LIBCHECK_OK" == ""
capture noisily nwwebuse florentine
assert _rc == 3499
capture noisily nwsummarize
assert _rc == 3499
display "PASS libcheck missing library gives r(3499) and the message"

* 3. back to normal
global NW_LIBCHECK_TEST ""
_nwlibcheck
assert "$NW_LIBCHECK_OK" == "1"
nwwebuse florentine, nwclear
display "PASS libcheck recovers"

* 4. when the flag is set the check does nothing (speed): 20000 calls
timer clear 1
timer on 1
forvalues i = 1/20000 {
	_nwlibcheck
}
timer off 1
quietly timer list 1
display "20000 calls: " r(t1) " seconds"
assert r(t1) < 5
display "PASS libcheck is cheap"
display "ALL OK"
