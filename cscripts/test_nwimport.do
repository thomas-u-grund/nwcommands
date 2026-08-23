cscript

do unw_core.do

nwclear

nwimport "http://vlado.fmf.uni-lj.si/pub/networks/data/ucinet/prison.dat", type(ucinet)
assert _rc == 0
nwname
assert `"`r(valued)'"'   == `"false"'
assert `"`r(mode2)'"'    == `"false"'
assert `"`r(netname)'"'  == `"prison"'
assert `"`r(directed)'"' == `"true"'
assert `"`r(selfloop)'"' == `"false"'

capture nwimport "http://vlado.fmf.uni-lj.si/pub/networks/data/ucinet/zachary.dat", type(ucinet)
assert _rc != 0
nwimport "http://vlado.fmf.uni-lj.si/pub/networks/data/ucinet/zachary.dat", type(ucinet) nwappend
assert _rc == 0
nwset
assert `"`r(nets)'"' == `" prison ZACHE ZACHC"'
assert         r(networks) == 3


nwimport "http://vlado.fmf.uni-lj.si/pub/networks/data/ucinet/prison.dat", nwappend name(prison2) forceundirected type(ucinet)

assert _rc == 0

nwimport "http://vlado.fmf.uni-lj.si/pub/networks/data/ucinet/prison.dat", type(ucinet) nwclear
assert _rc == 0
nwset
assert `"`r(nets)'"' == `" prison"'
assert         r(networks) == 1

nwimport "http://vlado.fmf.uni-lj.si/pub/networks/data/ucinet/prison.dat", type(ucinet) forcedirected nwclear
assert _rc == 0
nwsummarize

assert `"`r(valued)'"'   == `"false"'
assert `"`r(mode2)'"'    == `"false"'
assert `"`r(netname)'"'  == `"prison"'
assert `"`r(name)'"'     == `"prison"'
assert `"`r(directed)'"' == `"true"'
assert `"`r(selfloop)'"' == `"false"'


nwimport "http://vlado.fmf.uni-lj.si/pub/networks/data/ucinet/prison.dat", type(ucinet) nwappend
assert _rc == 0
nwsummarize

nwimport "http://vlado.fmf.uni-lj.si/pub/networks/data./sport/football.net", type(pajek) nwclear
assert _rc == 0

nwimport "http://vlado.fmf.uni-lj.si/pub/networks/data/ucinet/prison.dat", nwclear type(ucinet) name(blabla) forcedirected
nwname
assert `"`r(directed)'"' == `"true"'

nwimport "http://vlado.fmf.uni-lj.si/pub/networks/data/ucinet/prison.dat", nwclear type(ucinet) name(blabla2) forceundirected
nwname
assert `"`r(directed)'"' == `"false"'





