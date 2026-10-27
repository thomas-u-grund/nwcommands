* A user's own Mata variables never disturb nwcommands. The registry of networks is the Mata global __nw (it was "nw" until 3.10.0:
* a user variable called nw, defined before or after the first nwset, replaced the registry and broke every command with
* "type mismatch: exp.exp: transmorphic found where struct expected").
cscript

do unw_core.do

* names a user typically uses in a Mata session, defined BEFORE any network exists
mata: A = J(3, 3, 7)
mata: D = "text"
mata: p = (1, 2, 3)
mata: nw = 12345
mata: nws = "mine"
mata: util = 1
nwclear
nwset, mat((0,1,0\1,0,1\0,1,0)) name(path3)
nwdegree path3, generate(o1 i1)
nwsummarize path3
* ... and AFTER the network exists
mata: nw = J(2, 2, 0)
mata: A = 99
nwset, mat((0,1,1\1,0,0\1,0,0)) name(star3)
nwdegree star3, generate(o2 i2)
nwdrop star3
nwset
* the user's variables are untouched
mata: st_numscalar("sa", A)
mata: st_numscalar("sn", rows(nw))
mata: st_local("sd", D)
assert scalar(sa) == 99 & scalar(sn) == 2 & "`sd'" == "text"
mata: mata drop A D p nw nws util
di as text "user Mata variables do not disturb nwcommands PASS"
