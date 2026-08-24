cscript

do unw_core.do

* nwtostata had no test coverage at all before this - added while
* writing its first-ever .sthlp (alpha-pass unit, missing_doc critical
* finding) and fixing a real (if previously inert) bug found alongside
* it: opts_exclusive referenced the undefined local `sub' (the real
* option is named `stub'), so the mutual-exclusivity check was always a
* no-op - harmless only because a separate, correct manual check right
* after it already enforced the real rule.

clear
mata: m = (1,2 \ 3,4 \ 5,6)
nwtostata, mat(m) gen(a b)
assert _rc == 0
assert a[1] == 1 & b[1] == 2
assert a[2] == 3 & b[2] == 4
assert a[3] == 5 & b[3] == 6

clear
mata: m2 = (1,2 \ 3,4 \ 5,6)
nwtostata, mat(m2) stub(col)
assert _rc == 0
assert col1[1] == 1 & col2[1] == 2
assert col1[3] == 5 & col2[3] == 6

* gen() and stub() are mutually exclusive.
clear
mata: m3 = (1,2 \ 3,4)
capture noisily nwtostata, mat(m3) gen(a b) stub(s)
assert _rc != 0

* exactly one of gen()/stub() is required.
clear
mata: m4 = (1,2 \ 3,4)
capture noisily nwtostata, mat(m4)
assert _rc != 0

di "=== nwtostata REGRESSION VERIFIED ==="
