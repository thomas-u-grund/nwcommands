* nwcoefplot: coefficient plot of stored and active estimation results; nwcompare, graph; error paths
* Fake fits that set e() the way the model packages do always run. Real nwergm and nwlsm fits run when the packages are found next to the core
* (../nwergm, ../nwlsm or the directory in the environment variable NWPKGS; their lib/plugins/macos or unix or windows on the adopath); otherwise that part is reported as skipped.
cscript
do unw_core.do
capture program drop nwinstall
set graphics off
run nwcoefplot.ado
run nwcompare.ado

local nfail = 0
local tmp "`c(tmpdir)'/nwcoefplot_test"
capture mkdir "`tmp'"

capture program drop fake_fit
* fake_fit cmd eqs: three coefficients per equation, the second with a very large variance
program fake_fit, eclass
    args cmd e1 e2
    local k = cond("`e2'" == "", 3, 6)
    matrix b = J(1, `k', 0.4)
    matrix V = I(`k') * 0.04
    local cn "edges mutual tie"
    local cn "`cn' edges mutual tie"
    local names ""
    local eqs ""
    forvalues j = 1/3 {
        local names `names' `: word `j' of `cn''
        local eqs `eqs' `e1'
    }
    if "`e2'" != "" {
        forvalues j = 4/6 {
            local names `names' `: word `j' of `cn''
            local eqs `eqs' `e2'
        }
    }
    matrix b[1, 2] = -0.3
    matrix colnames b = `names'
    matrix colnames V = `names'
    matrix rownames V = `names'
    matrix coleq b = `eqs'
    matrix coleq V = `eqs'
    matrix roweq V = `eqs'
    ereturn post b V, obs(50)
    ereturn local cmd "`cmd'"
end
capture program drop clear_e
program clear_e, eclass
    ereturn clear
end
capture program drop chk
program chk
    args what ok
    if `ok' di as txt "  ok   `what'"
    else {
        di as err "  FAIL `what'"
        global NWC_FAIL = $NWC_FAIL + 1
    }
end
global NWC_FAIL = 0

* ---- fake fits ---------------------------------------------------------------------------------------------------
fake_fit nwergm _
estimates store f1
fake_fit nwergm _
nwcoefplot, eform export("`tmp'/a.png", width(800)) name(cp_a, replace)
confirm file "`tmp'/a.png"
chk "one model, one equation: one panel" `=(r(n_panels) == 1 & r(n_models) == 1 & r(n_coef) == 3)'
chk "level default 95" `=(r(level) == 95)'
nwcoefplot f1, level(90) noconstant keep(edges mut*)
chk "keep(): two coefficients" `=(r(n_coef) == 2 & r(level) == 90)'
nwcoefplot f1, drop(tie)
chk "drop(): two coefficients" `=(r(n_coef) == 2)'
nwcoefplot f1 ., xtitle("my axis") ylabel(, labsize(small))
chk "twoway options passed through; stored model and active results" `=(r(n_models) == 2 & r(n_coef) == 6)'
nwcoefplot f1 ., common legend(position(3))
chk "common" `=(r(n_coef) == 6)'

* two equations: one panel each by default, one axis with mixeq
fake_fit nwdynam rate choice
nwcoefplot, eform export("`tmp'/b.png", width(800)) title("Rate and choice")
confirm file "`tmp'/b.png"
chk "two equations: two panels, rate ratios" `=(r(n_panels) == 2 & r(n_coef) == 6)'
nwcoefplot, mixeq
chk "mixeq: one panel" `=(r(n_panels) == 1)'
nwcoefplot, byeq keep(choice:*)
chk "keep(eq:*): one equation" `=(r(n_panels) == 1 & r(n_coef) == 3)'
estimates store f2
nwcoefplot f2 f1, keep(edges)
chk "models with different equations" `=(r(n_models) == 2 & r(n_coef) == 3)'

* axis range: a panel whose intervals lie on one side of the reference line (one positive, one negative coefficient)
* is drawn with the reference line inside the range and with room left of the first interval, on both scales
nwcoefplot f1, keep(edges) export("`tmp'/c1.png", width(600)) name(cp_c1, replace)
confirm file "`tmp'/c1.png"
chk "single coefficient, linear axis" `=(r(n_coef) == 1)'
nwcoefplot f1, keep(mutual) eform export("`tmp'/c2.png", width(600)) name(cp_c2, replace)
confirm file "`tmp'/c2.png"
chk "single coefficient, eform (log axis)" `=(r(n_coef) == 1)'
nwcoefplot f1, keep(edges) eform name(cp_c3, replace)
chk "eform with the interval right of 1" `=(r(n_coef) == 1)'
nwcoefplot f1, keep(edges) xscale(range(-5 5)) xlabel(-5(5)5) name(cp_c4, replace)
chk "user xscale and xlabel override the default range" `=(r(n_coef) == 1)'

* nwcompare, graph
nwcompare f1 f2, graph coefopts(keep(edges mutual))
chk "nwcompare graph does not touch the table" `=(rowsof(r(table)) == 2)'
nwcompare f1, graph coefopts(eform)

* ---- error paths ---------------------------------------------------------------------------------------------------
fake_fit nwsaom _
capture nwcoefplot, eform
chk "eform after nwsaom: r(198)" `=(_rc == 198)'
nwcoefplot
chk "nwsaom without eform works" `=(r(n_coef) == 3)'
capture nwcoefplot nosuchmodel
chk "unknown model: r(111)" `=(_rc == 111)'
capture nwcoefplot, level(5)
chk "bad level: r(198)" `=(_rc == 198)'
capture nwcoefplot, keep(nothing)
chk "keep() matches nothing: r(198)" `=(_rc == 198)'
capture nwcoefplot, drop(*)
chk "drop(*): r(198)" `=(_rc == 198)'
capture nwcoefplot, byeq mixeq
chk "byeq and mixeq: r(198)" `=(_rc == 198)'
capture nwcoefplot f1 f1 f1 f1 f1 f1 f1 f1 f1
chk "more than 8 models: r(198)" `=(_rc == 198)'
fake_fit nwergm _
fake_fit nwsaom _
estimates store f3
fake_fit nwdynam a b
estimates store f4
capture nwcoefplot f3 f1, common
chk "common shares edges: ok" `=(_rc == 0)'
capture nwcoefplot f3 f4, common keep(nomatch)
chk "common, no shared coefficient name: r(198)" `=(_rc == 198)'
* results without e(b)
ereturn clear
clear_e
capture nwcoefplot
chk "no active results: r(301)" `=(_rc == 301)'
capture program drop fake_scalar
program fake_scalar, eclass
    ereturn clear
    ereturn scalar N = 10
    ereturn local cmd "nwsbm"
end
fake_scalar
capture nwcoefplot
chk "no e(b)/e(V): r(321)" `=(_rc == 321)'
fake_fit nwergm _
estimates store ok1
fake_scalar
capture nwcoefplot . ok1
chk "active without e(b) among models: r(321)" `=(_rc == 321)'
fake_scalar
nwcoefplot . ok1, skipmissing
chk "skipmissing leaves it out" `=(r(n_models) == 1)'
* the active results survive
fake_fit nwergm _
nwcoefplot f1
chk "active e() unchanged" `=("`e(cmd)'" == "nwergm")'

* ---- real fits ------------------------------------------------------------------------------------------------------
local pkgs : env NWPKGS
if `"`pkgs'"' == "" local pkgs "`c(pwd)'/.."
local ergmdir "`pkgs'/nwergm"
local lsmdir "`pkgs'/nwlsm"
capture confirm file "`ergmdir'/nwergm.ado"
local have_ergm = (_rc == 0)
capture confirm file "`lsmdir'/nwlsm.ado"
local have_lsm = (_rc == 0)
if `have_ergm' {
    adopath ++ "`ergmdir'"
    adopath ++ "`ergmdir'/lib"
    foreach os in macos unix windows {
        adopath ++ "`ergmdir'/lib/plugins/`os'"
    }
}
if `have_lsm' {
    adopath ++ "`lsmdir'"
    adopath ++ "`lsmdir'/lib"
    foreach os in macos unix windows {
        adopath ++ "`lsmdir'/lib/plugins/`os'"
    }
}
nwclear
nwuse data/florentine
if `have_ergm' {
    quietly nwergm flomarriage, edges triangle
    estimates store r0
    quietly nwergm flomarriage, edges gwesp(.5)
    estimates store r1
    matrix B = e(b)
    nwcoefplot r0 r1, eform export("`tmp'/ergm.png", width(1000))
    confirm file "`tmp'/ergm.png"
    chk "nwergm: three coefficients over two models" `=(r(n_models) == 2 & r(n_coef) == 4)'
    nwcoefplot r1, noconstant
    chk "nwergm: gwesp and edges" `=(r(n_coef) == 2)'
    nwcompare r0 r1, graph coefopts(export("`tmp'/ergm2.png", width(1000)))
    confirm file "`tmp'/ergm2.png"
    chk "nwcompare, graph after nwergm" `=(rowsof(r(table)) == 2)'
}
else di as txt "  skipped: nwergm fits (package not found next to the core)"
if `have_lsm' {
    set seed 5
    preserve
    clear
    set obs 16
    gen y = rnormal()
    gen ylag = rnormal()
    gen x = rnormal()
    tempfile act
    save `act'
    restore
    quietly nwlsm flomarriage, sociality dim(2) nsample(200) burnin(200) pilot(1) plen(40) seed(1)
    estimates store s1
    nwcoefplot s1, eform
    chk "nwlsm: constant" `=(r(n_coef) == 1)'
    preserve
    use `act', clear
    quietly nwlsm flomarriage, dim(2) influence(y ylag x) neighbors(5) nsample(200) burnin(200) pilot(1) plen(40) seed(1)
    restore
    nwcoefplot, eform export("`tmp'/lsm.png", width(900))
    confirm file "`tmp'/lsm.png"
    chk "nwlsm with influence: two panels" `=(r(n_panels) == 2 & r(n_coef) == 5)'
    capture nwcoefplot, mixeq eform
    chk "eform with mixeq and an outcome equation: r(198)" `=(_rc == 198)'
    nwcoefplot, keep(ylag x influence) mixeq
    chk "mixeq with keep" `=(r(n_coef) == 3 & r(n_panels) == 1)'
    estimates store s2
    if `have_ergm' {
        nwcompare r1 s1 s2, graph
        chk "nwcompare, graph across families does not stop" `=(rowsof(r(table)) == 3)'
    }
}
else di as txt "  skipped: nwlsm fits (package not found next to the core)"

* ---- shared plot convention: default names, implied replace, title(""), saving/export, errors
capture graph drop coefplot
capture graph drop compare
nwcoefplot f1
graph describe coefplot
nwcoefplot f1, name(cp_x) saving("`tmp'/cp_x.gph") export("`tmp'/cp_x.png", width(400))
nwcoefplot f1, name(cp_x) saving("`tmp'/cp_x.gph") export("`tmp'/cp_x.png", width(400))
confirm file "`tmp'/cp_x.gph"
confirm file "`tmp'/cp_x.png"
nwcoefplot f1, title("")
nwcoefplot f1, title("My title") name(cp_y, replace) saving("`tmp'/cp_y", replace)
confirm file "`tmp'/cp_y.gph"
fake_fit nwergm _
estimates store g1
estimates store g2
nwcompare g1 g2, graph
graph describe compare
nwcompare g1 g2, plot name(cmp_z) saving("`tmp'/cmp_z.gph")
graph describe cmp_z
confirm file "`tmp'/cmp_z.gph"
capture nwcompare g1 g2, name(cmp_z)
chk "nwcompare name() without graph: r(198)" `=(_rc == 198)'
capture nwcoefplot f1, name(cp_x, keep)
chk "nwcoefplot name(, keep): r(198)" `=(_rc == 198)'
capture nwcoefplot f1, saving("`tmp'/nodir/x.gph")
chk "nwcoefplot saving() into a missing directory: r(603)" `=(_rc == 603)'
foreach f in cp_x.gph cp_x.png cp_y.gph cmp_z.gph {
	capture erase "`tmp'/`f'"
}

* size options pass through (single panel, two panels, nwcompare) and the export keeps the aspect ratio
run cscripts/nw_pngwidth.do
fake_fit nwdynam rate choice
foreach v in single multi cmp {
	capture erase "`tmp'/sz_`v'.png"
}
capture nwcoefplot f1, ysize(2.6) xsize(3.6) export("`tmp'/sz_single.png", width(1080)) name(sz1, replace)
chk "nwcoefplot ysize() xsize() single panel: rc 0" `=(_rc == 0)'
nw_pngwidth "`tmp'/sz_single.png"
chk "single panel: width 1080, height 780 (aspect 3.6:2.6)" `=(r(w) == 1080 & abs(r(h) - 780) <= 2)'
capture nwcoefplot, ysize(2.6) xsize(3.6) export("`tmp'/sz_multi.png", width(1080)) name(sz2, replace)
chk "nwcoefplot ysize() xsize() two panels: rc 0" `=(_rc == 0)'
nw_pngwidth "`tmp'/sz_multi.png"
chk "two panels: width 1080, height 780" `=(r(w) == 1080 & abs(r(h) - 780) <= 2)'
capture nwcoefplot f1, aspectratio(0.5) scale(1.2) name(sz3, replace)
chk "nwcoefplot aspectratio() scale(): rc 0" `=(_rc == 0)'
fake_fit nwergm _
estimates store h1
estimates store h2
capture nwcompare h1 h2, plot coefopts(ysize(2.6) xsize(3.6)) export("`tmp'/sz_cmp.png", width(1080)) name(sz4, replace)
chk "nwcompare plot ysize() xsize(): rc 0" `=(_rc == 0)'
nw_pngwidth "`tmp'/sz_cmp.png"
chk "nwcompare plot: width 1080, height 780" `=(r(w) == 1080 & abs(r(h) - 780) <= 2)'
foreach v in single multi cmp {
	capture erase "`tmp'/sz_`v'.png"
}

capture erase "`tmp'/a.png"
capture erase "`tmp'/b.png"
capture erase "`tmp'/ergm.png"
capture erase "`tmp'/ergm2.png"
capture erase "`tmp'/lsm.png"
* ---- msymbol(): one marker symbol per model; the default picture is unchanged
nwcoefplot g1 g2, export("`tmp'/ms_def.png", width(600))
nwcoefplot g1 g2, msymbol(O O) export("`tmp'/ms_oo.png", width(600))
quietly checksum "`tmp'/ms_def.png"
local c1 = r(checksum)
quietly checksum "`tmp'/ms_oo.png"
chk "msymbol(O O) gives the default picture byte for byte" `=(`c1' == r(checksum))'
nwcoefplot g1 g2, msymbol(O D) export("`tmp'/ms_od.png", width(600))
quietly checksum "`tmp'/ms_od.png"
chk "msymbol(O D) changes the picture" `=(`c1' != r(checksum))'
nwcoefplot g1 g2, msymbol(D) name(ms_cyc, replace)
chk "msymbol with fewer symbols than models cycles" `=(r(n_models) == 2)'
capture nwcoefplot g1 g2, msymbol(O D T)
chk "msymbol with more symbols than models: r(198)" `=(_rc == 198)'
capture nwcoefplot g1 g2, msymbol(O banana)
chk "msymbol with a bad symbol name: r(198)" `=(_rc == 198)'
capture nwcoefplot g1, msymbol(O Dh)
chk "msymbol with two symbols for one model: r(198)" `=(_rc == 198)'
nwcoefplot g1 g2, msymbol(Oh Th) title("") name(ms_hol, replace)
graph describe ms_hol

if $NWC_FAIL == 0 di as txt "PASS nwcoefplot plots, nwcompare graph and error paths"
else di as err "FAIL nwcoefplot: $NWC_FAIL checks"
