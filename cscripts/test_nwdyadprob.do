cscript

clear mata
do unw_core.do
set more off

nwclear
nwdyadprob, mat(J(5,5,1)) name(mynet)
nwvalue mynet[1,2]
assert r(value) == 1

nwdyadprob mynet
nwvalue mynet[1,2]
assert r(value) == 1









