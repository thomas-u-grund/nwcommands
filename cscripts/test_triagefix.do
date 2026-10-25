* Regression tests for the fixes of the book-code triage (2026-10).
* Run with the usual wrapper (adopath to the repo, scratch PLUS).
clear all
set more off

* 1. nwmixing permutations(1): silent under quietly, no stray error line
nwwebuse lazega, nwclear
tempfile lg
log using "`lg'", text replace name(tf1)
quietly nwmixing lazega_adv, attribute(practice) permutations(1)
log close tf1
file open fh using "`lg'", read text
file read fh line
local bad 0
while r(eof) == 0 {
    if strpos(`"`macval(line)'"', "invalid syntax") local bad 1
    file read fh line
}
file close fh
assert `bad' == 0
quietly nwmixing lazega_adv, attribute(practice) permutations(1)
assert r(EI_index) < .
* with permutations the p-value is still returned and printed
nwmixing lazega_adv, attribute(practice) permutations(20)
assert r(EI_pvalue) < .
display "test_triagefix: PASS"
