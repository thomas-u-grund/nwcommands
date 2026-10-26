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

* ---- nwplotmatrix: legend and a line between the modes (runs; legend(off) still possible)
nwplotmatrix davis, lab
nwplotmatrix davis_v
nwplotmatrix gang_valued
nwplotmatrix davis, legend(off)

* ---- nwturnover on two-mode networks counts only ties between the modes (hand-computed)
nwduplicate davis, name(davis2)
nwtomata davis, mat(D)
_nwsyntax davis
mata:
md = strtoreal(`netobj'->get_modes()')
i1 = selectindex(md :== 1)
i2 = selectindex(md :== 2)
D2 = D
// remove the first tie of the first two nodes of mode 1 that have one
done = 0
for (k = 1; k <= rows(i1) & done < 2; k++) {
	cs = select(i2, (D[i1[k], i2]' :== 1))
	if (rows(cs) > 0) {
		D2[i1[k], cs[1]] = 0
		D2[cs[1], i1[k]] = 0
		done++
	}
}
// add one tie of the last node of mode 1 that is not there
cs = select(i2, (D[i1[rows(i1)], i2]' :== 0))
D2[i1[rows(i1)], cs[1]] = 1
D2[cs[1], i1[rows(i1)]] = 1
end
nwreplacemat davis2, newmat(D2)
nwturnover davis davis2, generate(tov)
assert r(stable) == 87 & r(dissolved) == 2 & r(formed) == 1
nwturnover davis davis, generate(tov2) silent
assert r(stable) == 89 & r(formed) == 0 & r(dissolved) == 0 & r(jaccard) == 1

* ---- nwdyadprob: density() without a weight network says so
capture nwdyadprob, density(0.1) name(dpx)
assert _rc == 198

* ---- nwaltergen wmean: one note on a signed network, none on a positive one
log using "`tmp'plotfix_note.log", text replace
nwload senate114, xvars
gen xx = mod(_n, 4)
nwaltergen wmsn = wmean(alter.xx), net(senate114)
nwaltergen wmgv = wmean(alter.xx), net(gang_valued)
log close
mata: st_local("nnote", strofreal(sum(strpos(cat("`tmp'plotfix_note.log"), "note: wmean on a signed network") :> 0)))
assert `nnote' == 1

* ---- dialog
capture db nwplot
assert _rc == 0

di "test_plotfix: all passed"

* ---- nwplotmatrix: binary network legend names the two classes (no error), two-mode network runs
nwuse davis, nwclear
nwplotmatrix davis
graph drop _all
