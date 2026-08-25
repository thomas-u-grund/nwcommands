cscript
do unw_core.do

nwwebuse florentine, nwclear

nwexport flomarriage, type(ucinet) replace
assert _rc == 0

nwexport flobusiness, type(pajek) replace
assert _rc == 0
