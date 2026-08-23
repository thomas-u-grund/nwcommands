cscript

do unw_core.do

nwwebuse florentine, nwclear
nwshared flomarriage, name(shared)
nwload shared
assert peruzzi[15] == 2
assert pazzi[14] == 0


