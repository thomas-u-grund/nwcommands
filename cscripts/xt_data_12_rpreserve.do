* xt_data_12_rpreserve.do
* r() and e() around the data-management commands. Every command below runs on a fresh set of networks
* after known values were put into r() (rclass helper) and e() (eclass helper). Then:
*   - e() must be kept by every command (none of them is eclass): hard check;
*   - commands that are not rclass and document no r() ("keep"): no stray r(nodes)/r(id)/r(netname)/
*     r(networks) ([policy]: _nwsyntax leaves r(id)/r(netlist)/r(networks) behind in nearly every command) and the caller's r() kept ([policy]: several commands clear r()
*     on purpose with st_rclear(), e.g. nwdrop, nwkeep, nwclear, nwdropnodes; the owner decides);
*   - commands that document r() ("doc"): only e() is checked here; their r() is tested elsewhere.
* The command must succeed (hard check), so a failure here can also be a plain bug of that command.
clear all
set more off
run cscripts/xt_data_00_helpers.do
xt_init xt_data_12_rpreserve
set seed 20261112
tempfile tf
global XT_SAVE = `"`tf'"' + "_xtr"

capture program drop xt_setup
program xt_setup
	nwclear
	nwset, mat((0,1,0\0,0,1\1,0,0)) name(a) labs(p,q,r)
	nwset, mat((0,1,1\1,0,0\1,0,0)) name(b) undirected labs(p,q,r)
	gen x = _n
	gen grp = cond(_n == 1, 1, 2)
end

capture program drop xt_rrun
program xt_rrun
	args kind label
	xt_emark
	xt_rmark
	capture noisily $XT_CMD
	local rc = _rc
	local okr = (r(xtmark) == 4711 & "`r(xtmarkl)'" == "keep me")
	local stray = ("`r(nodes)'" == "" & "`r(id)'" == "" & "`r(netname)'" == "" & "`r(networks)'" == "")
	local oke = (e(xtmark) == 17 & "`e(xtmarkl)'" == "keep me too")
	xt_chk `=(`rc' == 0)' "`label': runs (got `rc')"
	xt_chk `oke' "`label': e() kept"
	if "`kind'" == "keep" {
		* r(id)/r(netlist)/r(networks) of _nwsyntax are left by nearly every command; owner decides
		xt_chk `stray' "[policy] `label': no stray r(nodes)/r(id)/r(netname)/r(networks)"
		xt_chk `okr' "[policy] `label': the caller's r() kept"
	}
end

* --- A. commands without documented r()
local i 0
foreach c in ///
	"nwset, mat(J(2,2,0)) name(new)" ///
	"nwdrop b" ///
	"nwkeep a" ///
	"nwsym a" ///
	"nwsym a, generate(as)" ///
	"nwtranspose a" ///
	"nwtranspose a, generate(at)" ///
	"nwpermute a, generate(ap)" ///
	"nwduplicate a, name(ad)" ///
	"nwrename a a9" ///
	"nwaddnodes a, nodenames(zz)" ///
	"nwdropnodes a, nodes(1)" ///
	"nwkeepnodes a, nodes(1 2)" ///
	"nwsubset a if x > 1, name(asub)" ///
	"nwexpand x, mode(same) name(ex)" ///
	"nwgen g1 = a" ///
	"nwgen g2 = transpose(a)" ///
	"nwtoedge a" ///
	"nwload a" ///
	"nwsync a" ///
	"nwcollapse a, by(grp) generate(ac)" ///
	"nwsave $XT_SAVE, replace" ///
	"nwclear" {
	local ++i
	xt_setup
	global XT_CMD `"`c'"'
	xt_rrun keep `"`c'"'
}
* nwfromedge and nwuse need their input first
xt_setup
nwtoedge a, compress
keep if a < . & a != 0
global XT_CMD "nwfromedge _ego _alter, name(fe)"
xt_rrun keep "nwfromedge"
xt_setup
nwsave $XT_SAVE, replace
global XT_CMD "nwuse $XT_SAVE, nwclear"
xt_rrun keep "nwuse"
di "PASS A no documented r()"

* --- B. commands with documented r(): e() only
foreach c in ///
	"nwset" ///
	"nwname a" ///
	"nwtomata a, mat(__xt_X)" ///
	"nwsummarize a" ///
	"nwrandom 4, prob(.5) name(r4)" ///
	"nwring 5, k(1) name(rg)" ///
	"nwlattice 2 2, name(lt)" ///
	"nwsmall 6, k(1) prob(.2) name(sm)" ///
	"nwreplacemat a, newmat(J(3,3,0))" ///
	"nwnoderename a, old(p) new(pp)" ///
	"nwreplace a = a * 2" ///
	"nwstack a a, name(st)" ///
	"nwexport a, type(pajek) fname($XT_SAVE) replace" {
	xt_setup
	global XT_CMD `"`c'"'
	xt_rrun doc `"`c'"'
}
xt_setup
nwsave $XT_SAVE, replace
global XT_CMD "nwimport $XT_SAVE.net, type(pajek) name(imp) nwappend"
nwexport a, type(pajek) fname($XT_SAVE) replace
xt_rrun doc "nwimport"
di "PASS B documented r()"

* --- C. nwreplacemat documents r(directed) (help); nwnoderename r(success)
xt_setup
mata: __xt_S = (0,1,1\1,0,1\1,1,0)
nwreplacemat a, newmat(__xt_S)
xt_chk `=(r(directed) == 0)' "nwreplacemat with a symmetric matrix: r(directed) = 0"
xt_setup
nwnoderename a, old(p) new(pp)
xt_chk `=(r(success) == 1)' "nwnoderename: r(success) = 1"
xt_setup
nwrandom 3, prob(.5) name(rr)
xt_chk `=("`r(netlist)'" == "rr")' "nwrandom: r(netlist)"
di "PASS C documented values"

capture erase `"$XT_SAVE.nwdta"'
capture erase `"$XT_SAVE.net"'
capture mata: mata drop __xt_X __xt_S
xt_end
di "ALL PASS"
