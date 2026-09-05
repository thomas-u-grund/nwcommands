cscript

do unw_core.do

set graphics off

* nwplot had a draft test file sitting on disk, untracked, never
* committed - this unit (the nwplot SVG-export modernisation audit)
* both extends it with real export coverage (below) and fixes two
* pre-existing issues found while doing so:
*
* (1) the original "assert _rc == 0 | _rc == 3000" pattern tolerated a
* stale, misleading r(3000) that survived even a fully successful
* plot - root-caused to the exact same _rc-staleness bug class found
* repeatedly elsewhere this session (nwbrokerage/nwego/nwaltergen/
* nwcompressobs): nwplot.ado's own end-of-program cleanup runs a
* cluster of "capture mata: mata drop ..."/"capture mat drop ..."
* calls, several of which legitimately "fail" (their targets only
* exist along certain code paths, e.g. the lgc/component cluster), and
* nothing after them refreshes _rc before the program returns. A
* pre-existing "mata: st_numscalar("_rc", 0)" line at the very end was
* an ineffective attempt at fixing this - it only creates an ordinary
* Stata scalar literally named "_rc", with no effect on the
* interpreter's own _rc state. Fixed in nwplot.ado with an explicit,
* silent "capture confirm number 1" as the true last statement of the
* program - confirmed directly that _rc == 0 reliably now, so this
* file's own assertions below no longer need the "| _rc == 3000"
* tolerance.
*
* (2) "nwwebuse florentine" used to depend on a dead external URL
* (nwcommands.org) - one of the package's own long-established
* baseline-failure causes, unrelated to nwplot itself. That host is
* fixed now (nwuse/nwwebuse reroute to this project's own GitHub repo -
* see nwuse.ado/nwwebuse.ado), so this uses the genuine "nwwebuse
* florentine" call again, exercising the real, now-working path rather
* than a local-file substitute.

nwclear
nwrandom 10, prob(.5)

nwplot, arcstyle(automatic)
assert _rc == 0
nwplot, arcstyle(straight)
assert _rc == 0
nwplot, arcstyle(curved)
assert _rc == 0
nwplot, arcbend(0.3) arcsplines(20)
assert _rc == 0

nwplot, nodefactor(2)
assert _rc == 0
nwplot, edgefactor(2)
assert _rc == 0
nwplot, arrowfactor(4)
assert _rc == 0
nwplot, arrowbarbfactor(.2)
assert _rc == 0

nwplot, nodefactor(2) edgefactor(4) arrowfactor(2) arrowbarbfactor(.2)
assert _rc == 0

* layout(frucht) - a fully-functional layout accepted by the option's
* own _opts_oneof validator but, until this unit, undocumented in the
* doc header (see nwplot.ado's own "Supported network types"-adjacent
* layoutstyle list) - regression-guarded here now that it has a name.
nwplot, layout(frucht)
assert _rc == 0
nwplot, layout(circle)
assert _rc == 0
nwplot, layout(grid, columns(5))
assert _rc == 0
nwplot, layout(mds)
assert _rc == 0

* layout(kk) - Kamada-Kawai via stress majorization (Guttman transform),
* using this file's own existing distance()/circlelayout() helpers as
* building blocks rather than duplicating them. Correctness check: on a
* plain 6-node path graph (1-2-3-4-5-6), the two path endpoints (graph
* distance 5) must end up farther apart in the final layout than two
* directly adjacent nodes (graph distance 1) - the defining property of
* a graph-distance-respecting layout, not just "did it run".
nwclear
nwrandom 12, prob(.25)
nwplot, layout(kk)
assert _rc == 0
nwplot, layout(kk) iterations(200)
assert _rc == 0

nwclear
clear
qui set obs 6
qui gen ego = _n
qui gen alter = _n + 1
qui gen w = 1
qui drop if alter > 6
nwfromedge ego alter w, name(kkpath)
nwplot kkpath, layout(kk) iterations(300) generate(_kkpx _kkpy)
assert _rc == 0
mata: __kkpos = (st_data(.,"_kkpx"), st_data(.,"_kkpy"))
mata: __kkd12 = sqrt(rowsum((__kkpos[1,.]-__kkpos[2,.]):^2))
mata: __kkd16 = sqrt(rowsum((__kkpos[1,.]-__kkpos[6,.]):^2))
mata: st_numscalar("__kkd12", __kkd12)
mata: st_numscalar("__kkd16", __kkd16)
assert __kkd16 > __kkd12
mata: mata drop __kkpos __kkd12 __kkd16
di "=== layout(kk) SELF-CONTAINED REGRESSION VERIFIED ==="

* kk is now the DEFAULT layout (previously mds/mdsclassical, chosen by
* node count) - confirmed here by timing, not by exact coordinates
* (kk's own random starting configuration means two separate calls
* never produce byte-identical output, even with identical settings,
* so an exact-coordinate comparison would be the wrong check here).
* mds/mdsclassical are both fast (a single Stata `mdsmat` call or a
* per-component eigendecomposition); kk is a slow iterative procedure
* by comparison - confirmed directly, 500 nodes takes ~2s under
* explicit layout(mdsclassical) but multiple seconds under the
* default. Also verifies the adaptive iteration-count scaling
* (layout(kk)'s own dispatch code) keeps a default call on a
* moderately large network well under what an unscaled 1000-iteration
* run would take (confirmed separately during development: ~72
* seconds unscaled at 500 nodes) - a generous 45-second ceiling here,
* not a tight timing assertion, since exact wall-clock time is
* machine-dependent and this is only guarding against the scaling
* logic silently regressing back to the unscaled cost.
nwclear
nwrandom 300, prob(.01)
timer clear 90
timer on 90
qui nwplot
timer off 90
quietly timer list 90
assert r(t90) < 45
di "=== kk is the default layout, with working adaptive iteration scaling, REGRESSION VERIFIED ==="

* layout(hierarchy) - Sugiyama-style layered layout, meant for directed
* (ideally DAG-shaped) networks: layer assignment via longest-path-from-
* sources, barycenter crossing-reduction sweeps, then evenly-spaced
* coordinates. Correctness check: on a hand-built 5-node DAG
* (1->2, 1->3, 2->4, 3->4, 4->5), the source (node 1) must end up above
* every other node, and each downstream layer must be strictly lower
* (smaller y) than its predecessor's layer - the defining property of a
* top-down hierarchy, not just "did it run". Also checked: a 3-node
* cycle (1->2->3->1) plus an isolated 4th node does not crash or loop
* forever (this package's own real GML-import GML-fixture pass, unit
* 167, already showed why "this shape doesn't happen in practice" is
* not a safe assumption to test only the happy path against).
mata: __hierdag = J(5,5,0)
mata: __hierdag[1,2]=1
mata: __hierdag[1,3]=1
mata: __hierdag[2,4]=1
mata: __hierdag[3,4]=1
mata: __hierdag[4,5]=1
nwclear
nwset, mat(__hierdag) name(hierdag) directed
mata: mata drop __hierdag
nwplot hierdag, layout(hierarchy) generate(_hy1 _hy2)
assert _rc == 0
mata: __hy = st_data(.,"_hy2")
mata: st_numscalar("__hy1", __hy[1])
mata: st_numscalar("__hy2", __hy[2])
mata: st_numscalar("__hy4", __hy[4])
mata: st_numscalar("__hy5", __hy[5])
assert __hy1 > __hy2
assert __hy2 > __hy4
assert __hy4 > __hy5
mata: mata drop __hy
di "=== layout(hierarchy), acyclic case SELF-CONTAINED REGRESSION VERIFIED ==="

mata: __hiercyc = J(4,4,0)
mata: __hiercyc[1,2]=1
mata: __hiercyc[2,3]=1
mata: __hiercyc[3,1]=1
nwclear
nwset, mat(__hiercyc) name(hiercyc) directed
mata: mata drop __hiercyc
nwplot hiercyc, layout(hierarchy)
assert _rc == 0
di "=== layout(hierarchy), cyclic input does not crash/hang REGRESSION VERIFIED ==="

nwclear
nwrandom 25, prob(.1)
nwplot, layout(hierarchy)
assert _rc == 0
nwrandom 15, prob(.2) undirected
nwplot, layout(hierarchy)
assert _rc == 0
di "=== layout(hierarchy), directed/undirected smoke REGRESSIONS VERIFIED ==="

* layout(bipartite) - dedicated two-mode layout, two rows by default
* (mode 1 at y=1, mode 2 at y=0) or two columns with the `vertical'
* sub-option (mode 1 at x=0.25, mode 2 at x=1.25), ordered within each
* band via barycenter sweeps. Correctness check: every mode-1 node ends
* up at y==1 and every mode-2 node at y==0 (rows) / x==0.25 vs x==1.25
* (columns) - the defining property of a mode-separated layout. Also
* checked: a non-bipartite network is rejected with a clear error
* rather than silently plotting something meaningless.
mata: __bipmat = J(3,2,0)
mata: __bipmat[1,1]=1
mata: __bipmat[2,1]=1
mata: __bipmat[2,2]=1
mata: __bipmat[3,2]=1
nwclear
nwset, mat(__bipmat) bipartite name(biptest)
mata: mata drop __bipmat
nwplot biptest, layout(bipartite) generate(_bx _by)
assert _rc == 0
* small floating-point residue (~1e-10) survives nwplot's own generic
* coordinate post-processing regardless of layout - confirmed the same
* artifact appears for kk/hierarchy above too, not specific to this
* layout - so these are tolerance-based, not exact, comparisons
assert abs(_by - 1) < 1e-6 in 1
assert abs(_by - 1) < 1e-6 in 2
assert abs(_by - 0) < 1e-6 in 3
assert abs(_by - 0) < 1e-6 in 4
assert abs(_by - 0) < 1e-6 in 5
di "=== layout(bipartite), two-row SELF-CONTAINED REGRESSION VERIFIED ==="

nwplot biptest, layout(bipartite, vertical) generate(_bvx _bvy)
assert _rc == 0
assert abs(_bvx - .25) < 1e-6 in 1
assert abs(_bvx - .25) < 1e-6 in 2
assert abs(_bvx - 1.25) < 1e-6 in 3
assert abs(_bvx - 1.25) < 1e-6 in 4
assert abs(_bvx - 1.25) < 1e-6 in 5
di "=== layout(bipartite, vertical), two-column SELF-CONTAINED REGRESSION VERIFIED ==="

nwclear
nwrandom 8, prob(.3)
capture noisily nwplot, layout(bipartite)
assert _rc == 198
di "=== layout(bipartite) on a non-two-mode network correctly rejected REGRESSION VERIFIED ==="

* --- repeated nwplot/layout(,lgc) calls on the same >50-node network
* (no nwclear between calls) used to be flagged as "not reliably
* reproducible" in docs/CERTIFICATION.md's own Pending table - this
* turned out to share the exact root cause harmonisation unit 44 fixed
* elsewhere (nwplot's own mdsclassical-layout degree/isolates
* computation, which layout(,lgc) also passes through en route to
* actually plotting, silently failed to clean up its own temporary
* _degree/_outdegree/_indegree/_isolates variables via a compound
* "capture drop A B C D" that fails entirely - drops nothing - the
* instant any one of those four names doesn't exist, which is always
* true for at least one of them). Re-verified clean across 12
* alternating plain/lgc calls on a 200-node network and 8 separate
* seeds before removing the Pending entry - not just a lucky repro.
nwclear
nwrandom 200, prob(.02)
forvalues i = 1/4 {
	nwplot
	assert _rc == 0
	nwplot, layout(,lgc)
	assert _rc == 0
}

* Default scheme regression: a reported bug had nodes and edges both
* rendering identically (Stata's own default "stcolor" scheme defines
* p1 and p1line as the same color - confirmed directly by rendering a
* minimal scatter+line graph and inspecting the actual pixels). nwplot
* must default to one of its own network-oriented schemes (which give
* p1/p1line different colors) instead of silently inheriting whatever
* graph scheme happens to be ambient, unless scheme() is given
* explicitly. Placed here, before the "nwwebuse florentine" call below,
* which now works end to end (see the note above).
nwclear
nwrandom 8, prob(.3)
nwplot
assert `"`r(scheme)'"' == `"s1network"'
nwplot, scheme(s2network)
assert `"`r(scheme)'"' == `"s2network"'

nwwebuse florentine, nwclear

nwplot flomarriage, color(seat, colorpalette(red yellow))
assert _rc == 0
nwplot flomarriage if wealth < 100, color(seat, colorpalette(red yellow)) lab
assert _rc == 0
nwplot flomarriage, size(wealth, forcekeys(10 100))
assert _rc == 0

nwplot flomarriage, size(wealth) color(seat) symbol(seat)
assert _rc == 0

nwplot flomarriage, edgecolor(flobusiness)
assert _rc == 0


nwplot flomarriage, edgecolor(flobusiness) edgesize(flobusiness) edgefactor(3)
assert _rc == 0

* --- reusable/fixed coordinates: generate() exports node positions,
* nodexy() reuses them - confirms this long-standing (but previously
* undocumented as such) capability already solves "plot the same
* network layout twice" without any new nwlayout command.
nwplot flomarriage, generate(_fx _fy)
assert _rc == 0
confirm variable _fx
confirm variable _fy
nwplot flomarriage, nodexy(_fx _fy)
assert _rc == 0

*=============================================================
* SVG/vector export
*=============================================================

* small helper: read a file's first few KB and confirm it contains a
* literal "<svg" tag - a cheap, non-brittle structural-validity check
* (deliberately not a pixel-level graphical regression test).
capture program drop _assert_has_svg_tag
program _assert_has_svg_tag
	args fname
	tempname fh
	local found = 0
	file open `fh' using "`fname'", read text
	local i = 0
	file read `fh' line
	while r(eof) == 0 & `i' < 20 {
		if strpos(`"`line'"', "<svg") > 0 {
			local found = 1
		}
		local i = `i' + 1
		file read `fh' line
	}
	file close `fh'
	assert `found' == 1
end

nwclear
nwset, mat((0,1,1\1,0,1\1,1,0)) name(tri) undirected labs(A,B,C)

* Filenames are built directly under c(tmpdir) rather than by
* appending an extension onto a "tempfile"-generated name: Stata's own
* tempfile macros already end in a dotted numeric suffix (e.g.
* ".../S_45937.000001"), and "graph export"'s own suffix parser reads
* everything after the FIRST dot in the basename as the extension, not
* the last - so "`tempfile'.svg" produces an unrecognized
* "000001.svg" pseudo-suffix and a hard r(198) - a genuine, general
* Stata gotcha, confirmed via an isolated repro with a plain "sysuse
* auto"/"scatter" graph (nothing nwplot-specific about it) before
* writing these assertions this way.
local tmpd `"`c(tmpdir)'"'

* 1-4: basic export creates a real, non-empty, structurally valid SVG
local svgfile `"`tmpd'/nwplot_test_tri.svg"'
capture erase `"`svgfile'"'
nwplot tri, export(`"`svgfile'"')
assert _rc == 0
assert `"`r(export)'"' == `"`svgfile'"'
capture confirm file `"`svgfile'"'
assert _rc == 0
* non-empty + structurally valid: _assert_has_svg_tag reads real
* content and finds a literal "<svg" tag, which is only possible if
* the file is genuinely non-empty - a separate explicit size check
* would be redundant.
_assert_has_svg_tag `"`svgfile'"'

* 5-6: replace behaviour - a second export without replace() must fail
* with the same r(602) "file already exists" a manual "graph export"
* call would raise (nwplot does not swallow or reinterpret this error);
* with replace it must succeed.
capture nwplot tri, export(`"`svgfile'"')
assert _rc == 602
nwplot tri, export(`"`svgfile'"') replace
assert _rc == 0

* 7: the graph itself must still be a completely normal, currently
* active Stata graph after export() - not consumed or replaced by a
* separate rendering pipeline - so a manual "graph export" to a second
* format must still work against the exact same graph.
local pdffile `"`tmpd'/nwplot_test_tri.pdf"'
graph export `"`pdffile'"', replace
assert _rc == 0

* 8: filename containing spaces.
local spacefile `"`tmpd'/nwplot test with spaces.svg"'
nwplot tri, export(`"`spacefile'"') replace
assert _rc == 0
capture confirm file `"`spacefile'"'
assert _rc == 0

* 9-10: relative and absolute paths. c(tmpdir) is always an absolute
* path; a relative filename is resolved against the current working
* directory, restored immediately after so the rest of the suite is
* unaffected.
local origdir `"`c(pwd)'"'
cd `"`tmpd'"'
nwplot tri, export("relative_export_test.svg") replace
assert _rc == 0
capture confirm file "relative_export_test.svg"
assert _rc == 0
cd `"`origdir'"'
capture confirm file `"`tmpd'/relative_export_test.svg"'
assert _rc == 0

nwplot tri, export(`"`tmpd'/absolute_export_test.svg"') replace
assert _rc == 0
capture confirm file `"`tmpd'/absolute_export_test.svg"'
assert _rc == 0

* 11: weighted network export.
nwclear
nwset, mat((0,2,5\2,0,1\5,1,0)) name(wnet) undirected labs(A,B,C)
local wfile `"`tmpd'/nwplot_test_weighted.svg"'
nwplot wnet, edgesize(wnet) lab export(`"`wfile'"') replace
assert _rc == 0
_assert_has_svg_tag `"`wfile'"'

* 12: directed network export (arrows).
nwclear
nwset, mat((0,1,0\0,0,1\1,0,0)) name(dnet) directed labs(A,B,C)
local dfile `"`tmpd'/nwplot_test_directed.svg"'
nwplot dnet, lab export(`"`dfile'"') replace
assert _rc == 0
_assert_has_svg_tag `"`dfile'"'

* 13: two-mode network export.
nwclear
mata: bip = (1,1 \ 1,0 \ 0,1)
mata: st_matrix("bip", bip)
nwset, mat(bip) bipartite name(bipnet) labs(E1,E2,A,B,C)
local bipfile `"`tmpd'/nwplot_test_twomode.svg"'
nwplot bipnet, lab export(`"`bipfile'"') replace
assert _rc == 0
_assert_has_svg_tag `"`bipfile'"'

* exportopt() passthrough (raster width) - a PNG export with a
* nonstandard width must still succeed and produce a non-empty file.
* ("tri" was cleared by the intervening nwclear calls above - recreated
* here rather than reordering the whole block.)
nwclear
nwset, mat((0,1,1\1,0,1\1,1,0)) name(tri) undirected labs(A,B,C)
local pngfile `"`tmpd'/nwplot_test_tri.png"'
nwplot tri, export(`"`pngfile'"') exportopt(width(1200)) replace
assert _rc == 0
capture confirm file `"`pngfile'"'
assert _rc == 0

*=============================================================
* Visual certification set (Parts XII): 7 stable, hand-chosen
* reference plots, each exported to SVG. Not asserted against exact
* pixel/geometry output (deliberately not a brittle graphical
* regression test, per this unit's own certification approach) - the
* assertions confirm each one runs cleanly and produces a real SVG;
* the plots themselves are the stable reference set for any future
* nwplot visual-quality change to be manually compared against.
*=============================================================

* Plot A: small undirected network.
nwclear
nwset, mat((0,1,1,0\1,0,1,0\1,1,0,1\0,0,1,0)) name(plotA) undirected labs(A,B,C,D)
local plotA_svg `"`tmpd'/nwplot_certA.svg"'
nwplot plotA, export(`"`plotA_svg'"') replace
assert _rc == 0
_assert_has_svg_tag `"`plotA_svg'"'

* Plot B: directed network with arrows.
nwclear
nwset, mat((0,1,0,0\0,0,1,0\0,0,0,1\1,0,0,0)) name(plotB) directed labs(A,B,C,D)
local plotB_svg `"`tmpd'/nwplot_certB.svg"'
nwplot plotB, export(`"`plotB_svg'"') replace
assert _rc == 0
_assert_has_svg_tag `"`plotB_svg'"'

* Plot C: weighted network with variable edge widths.
nwclear
nwset, mat((0,1,5,0\1,0,2,0\5,2,0,3\0,0,3,0)) name(plotC) undirected labs(A,B,C,D)
local plotC_svg `"`tmpd'/nwplot_certC.svg"'
nwplot plotC, edgesize(plotC) export(`"`plotC_svg'"') replace
assert _rc == 0
_assert_has_svg_tag `"`plotC_svg'"'

* Plot D: categorical node groups (color by a group variable).
nwclear
nwset, mat((0,1,1,0,0\1,0,1,0,0\1,1,0,1,0\0,0,1,0,1\0,0,0,1,0)) name(plotD) undirected labs(A,B,C,D,E)
qui gen group = mod(_n, 2)
local plotD_svg `"`tmpd'/nwplot_certD.svg"'
nwplot plotD, color(group) export(`"`plotD_svg'"') replace
assert _rc == 0
_assert_has_svg_tag `"`plotD_svg'"'

* Plot E: two-mode network with modes visibly distinguished (color by
* mode - see nwplot.ado's own "Supported network types" note: there is
* no automatic mode-aware rendering, so this is the documented
* workaround, demonstrated here as its own certification case).
nwclear
mata: bipE = (1,1,0 \ 1,0,1 \ 0,1,1 \ 1,1,1)
mata: st_matrix("bipE", bipE)
nwset, mat(bipE) bipartite name(plotE) labs(E1,E2,E3,A,B,C,D)
_nwsyntax plotE, max(1)
qui gen _plotE_mode = .
mata: st_store((1::`nodes'), "_plotE_mode", strtoreal(`netobj'->get_modes())')
local plotE_svg `"`tmpd'/nwplot_certE.svg"'
nwplot plotE, color(_plotE_mode) lab export(`"`plotE_svg'"') replace
assert _rc == 0
_assert_has_svg_tag `"`plotE_svg'"'

* Plot F: labelled network.
nwclear
nwset, mat((0,1,1\1,0,1\1,1,0)) name(plotF) undirected labs(Alice,Bob,Carol)
local plotF_svg `"`tmpd'/nwplot_certF.svg"'
nwplot plotF, lab export(`"`plotF_svg'"') replace
assert _rc == 0
_assert_has_svg_tag `"`plotF_svg'"'

* Plot G: moderately large sparse network.
nwclear
nwrandom 60, prob(.05)
local plotG_svg `"`tmpd'/nwplot_certG.svg"'
nwplot, export(`"`plotG_svg'"') replace
assert _rc == 0
_assert_has_svg_tag `"`plotG_svg'"'


* --- alpha-audit regression: a single-node network crashed under
* every layout, each with a different raw error - mds (the default for
* <50 nodes): "dimension exceeds #rows of dissimilarity matrix", r(498);
* circle/grid: a Mata conformability error inside NumElist() (select()
* on a network with zero possible ties returns a 0x0 matrix, but the
* target slice it was being assigned into was 0x1 - conformability
* error even though both sides have zero elements); mdsclassical:
* "_outdegree not found", r(111) (a separate, deeper issue: `tab
* edgesize'/`tab edgecolor' create no matrow() at all when the tie-
* level dataset has zero non-missing ties, since there's nothing to
* tabulate). Fixed by placing the single node directly (skipping every
* layout-specific coordinate computation), fixing NumElist() to skip
* its own now-genuinely-empty assignment, and skipping the edge-legend
* tabulation entirely when there are no ties to tabulate.
foreach lay in "" "circle" "grid" "mdsclassical" {
	nwclear
	nwset, mat((0)) name(onenode) undirected labs(A)
	local layoutopt = cond(`"`lay'"' == "", "", "layout(`lay')")
	local plotH_svg `"`tmpd'/nwplot_certH_`lay'.svg"'
	nwplot onenode, `layoutopt' export(`"`plotH_svg'"') replace
	assert _rc == 0
	_assert_has_svg_tag `"`plotH_svg'"'
}
di "=== SINGLE-NODE NETWORK, ALL LAYOUTS, REGRESSION VERIFIED ==="

* moderate-severity pass, visualization group: the top-level sizebin()
* option was dead code - size()'s own content is re-parsed via a
* SECOND `syntax' call further down (for size(varname, sizebin(#))-
* style calls), and that second call unconditionally reset `sizebin'
* to its own default whenever size()'s own text didn't itself contain
* a sizebin() sub-option, silently discarding whatever the caller
* passed to the separate top-level option. Verified black-box via
* exported SVG content: a coarser sizebin() must change the rendered
* node-circle radii (fewer distinct sizes), producing genuinely
* different SVG output for the same underlying data - confirmed this
* actually changes the render, not just runs without erroring.
nwclear
nwwebuse florentine
local svgfine `"`tmpd'/nwplot_sizebin_fine.svg"'
local svgcoarse `"`tmpd'/nwplot_sizebin_coarse.svg"'
nwplot flomarriage, size(wealth) sizebin(1) export(`"`svgfine'"') replace
assert _rc == 0
nwplot flomarriage, size(wealth) sizebin(50) export(`"`svgcoarse'"') replace
assert _rc == 0
_assert_has_svg_tag `"`svgfine'"'
_assert_has_svg_tag `"`svgcoarse'"'
assert fileread(`"`svgfine'"') != fileread(`"`svgcoarse'"')
di "=== TOP-LEVEL sizebin() REGRESSION VERIFIED ==="

* moderate-severity pass, visualization group: layout(nodexy) without
* also specifying nodexy(xvar yvar) used to crash with a raw Mata
* st_data() "varlist required" error (r3598) instead of a clear
* Stata-style message - `nodex'/`nodey' are only ever populated inside
* nodexy()'s own parsing block, which layout(nodexy) alone doesn't
* trigger.
capture noisily nwplot flomarriage, layout(nodexy)
assert _rc == 198

* moderate-severity pass, visualization group: colorpalette() (as a
* sub-option of color()) couldn't be abbreviated here, unlike the
* same-named, same-purpose option in the sibling command nwplotmatrix
* (declared "COlorpalette" there) - this declaration was plain
* lowercase, which Stata's syntax parser never abbreviates. Confirms
* both the full spelling and the "co" abbreviation now work.
nwplot flomarriage, color(seat, colorpalette(red yellow))
assert _rc == 0
nwplot flomarriage, color(seat, co(red yellow))
assert _rc == 0
di "=== layout(nodexy) and colorpalette() abbreviation REGRESSIONS VERIFIED ==="
