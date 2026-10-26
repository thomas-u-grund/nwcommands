cscript

* nwplot and the network types: valued ties set the edge widths (binary switches it off), signed ties are drawn in two
* colours with line patterns and a legend (nosign switches it off), two-mode networks get a symbol and a colour per mode.
* The checks are on the returned settings (r(edgewidth), r(signcolor), r(modesymbols)) and on the interactive page,
* not on pixels. Run from the repository root.

set graphics off
tempfile dummy
local tmp "`c(tmpdir)'"

nwuse data/gang, nwclear
nwuse data/davis, nwappend
nwuse data/senate114, nwappend

* a valued two-mode network (davis ties 1 to 4)
nwduplicate davis, name(davis_v)
nwtomata davis_v, mat(M)
mata: M = editmissing(M, 0); M = M :* (1 :+ mod(rowshape(1::rows(M)*cols(M), rows(M)), 4))
mata: M = lowertriangle(M, 0); M = M + M'
nwreplacemat davis_v, newmat(M)

* ---- valued: widths from the values by default
nwplot gang_valued
assert "`r(edgewidth)'" == "values"
assert r(signcolor) == 0 & r(modesymbols) == 0
nwplot gang_valued, binary
assert "`r(edgewidth)'" == "binary"
nwplot gang
assert "`r(edgewidth)'" == "binary"
nwplot gang_valued, edgesize(gang)
assert "`r(edgewidth)'" == "edgesize"
nwplot gang_valued, edgesizeraw edgesize(gang_valued)
assert "`r(edgewidth)'" == "edgesize"

* with if (an old typo made edgesize() fail together with if)
nwload gang_valued, xvars
gen byte keepit = _n <= 40
nwplot gang_valued if keepit, edgesize(gang_valued)
assert "`r(edgewidth)'" == "edgesize"
nwplot gang_valued if keepit
assert "`r(edgewidth)'" == "values"

* ---- signed: two colours, legend, line patterns
nwplot senate114
assert r(signcolor) == 1
assert "`r(edgewidth)'" == "values"
nwplot senate114, nosign
assert r(signcolor) == 0
nwplot senate114, binary
assert r(signcolor) == 1 & "`r(edgewidth)'" == "binary"
nwplot senate114, binary nosign
assert r(signcolor) == 0 & "`r(edgewidth)'" == "binary"
nwplot senate114, edgecolor(senate114)
assert r(signcolor) == 0
nwplot gang_valued
assert r(signcolor) == 0

* a signed network whose ties are all -1 or all +1 keeps the default width and does not stop
nwduplicate senate114, name(neg1)
nwtomata neg1, mat(N)
mata: N = -abs(editmissing(N, 0))
nwreplacemat neg1, newmat(N)
nwplot neg1
assert r(signcolor) == 1

* ---- two-mode
nwplot davis
assert r(modesymbols) == 1
nwplot davis_v
assert r(modesymbols) == 1 & "`r(edgewidth)'" == "values"
nwplot davis, layout(bipartite)
assert r(modesymbols) == 1
nwplot davis, color(, legendoff) symbol(, legendoff)
assert r(modesymbols) == 0
nwplot gang
assert r(modesymbols) == 0

* ---- the interactive page carries the signed legend and the widths
nwplot senate114, interactive noopen fname("`tmp'plotfix_s.html")
mata: st_local("found", strofreal(any(strpos(cat("`tmp'plotfix_s.html"), "negative tie") :> 0)))
assert `found' == 1
nwplot senate114, interactive noopen nosign fname("`tmp'plotfix_s2.html")
mata: st_local("found", strofreal(any(strpos(cat("`tmp'plotfix_s2.html"), "negative tie") :> 0)))
assert `found' == 0

* ---- nwmovie passes binary and nosign on
nwuse data/glasgow, nwappend
capture noisily nwmovie glasgow1 glasgow2, binary nosign noopen fname("`tmp'plotfix_m.html")
assert _rc == 0

* ---- dialog
capture db nwplot
assert _rc == 0

di "test_plotfix: all passed"
