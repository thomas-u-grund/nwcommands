cscript

do unw_core.do

nwwebuse florentine, nwclear
nwsimmelian flomarriage, name(simmel)
nwload simmel
assert peruzzi[15] == 1
assert pazzi[14] == 0


