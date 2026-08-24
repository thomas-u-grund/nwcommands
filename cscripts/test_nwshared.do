cscript

do unw_core.do

nwwebuse florentine, nwclear
nwshared flomarriage, name(shared)
nwload shared
assert peruzzi[15] == 2
assert pazzi[14] == 0



* --- alpha-audit regression: `undirected' was documented but never
* declared in the syntax line (rejected outright), and its own body
* passed nwsym's output-name option as name() instead of the real
* generate() - both fixed.
nwclear
nwset, mat((0,1,0,1\0,0,1,0\0,0,0,1\1,0,0,0)) name(dnet2) directed
capture noisily nwshared dnet2, name(sharedundir) undirected
assert _rc == 0
di "=== undirected REGRESSION VERIFIED ==="
