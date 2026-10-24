* RSiena 1.6.12-1.6.14 effects: toU (the networks of the two steps were exchanged), the covariate x network effects of the regrouped effect groups, WXX / XWX / WXZX in two-mode and one-mode networks.
* References: siena07 of RSiena 1.6.14 (dev/saom_rsiena_r1614.R for the cross-network statistics on the deterministic networks of test_nwsaom_mnnet.do, dev/saom_rsiena_r1614_dyadx.R / .do for WXX, XWX, WXZX).
* The statistics are the targets of the effect, summed over the periods.
cscript
do unw_core.do
do unw_saom.do
nwclear
clear
* a fit that may need another seed (a very short run can end in a singular covariance matrix)
capture program drop mnt
program define mnt
	forvalues sd = 1/6 {
		capture `0' seed(`sd')
		if _rc == 0 exit
	}
	`0' seed(1)
end
mata:
mata set matastrict off
void mnnet_data() {
	nA = 20
	nE = 10
	for (w=1; w<=3; w++) {
		B = J(nA, nE, 0)
		F = J(nA, nA, 0)
		H = J(nA, nA, 0)
		S = J(nA, nA, 0)
		for (i=1; i<=nA; i++) {
			for (j=1; j<=nE; j++) B[i,j] = mod((mod(i*7 + j*13 + i*j, 11) < 3) + (mod(i*3 + j*5 + w*(i+j), 23) == 0), 2)
			for (j=1; j<=nA; j++) {
				if (i == j) continue
				F[i,j] = mod((mod(i*5 + j*11 + i*j, 17) < 3) + (mod(i*2 + j*3 + w*(i+2*j), 29) == 0), 2)
				H[i,j] = mod((mod(i*3 + j*7 + 2*i*j, 19) < 3) + (mod(i*4 + j*5 + w*(i+j), 31) == 0), 2)
				S[i,j] = mod((mod((i+j)*3 + i*j, 13) < 2) + (mod((i+j)*2 + w*(i*j), 27) == 0), 2)
			}
		}
		st_matrix("__B" + strofreal(w), B)
		st_matrix("__F" + strofreal(w), F)
		st_matrix("__H" + strofreal(w), H)
		st_matrix("__S" + strofreal(w), S)
	}
	cv = J(nA, 1, 0)
	dy = J(nA, nA, 0)
	dyE = J(nA, nE, 0)
	for (i=1; i<=nA; i++) {
		cv[i] = mod(i*3, 4) + 1
		for (j=1; j<=nA; j++) if (i != j) dy[i,j] = mod(i*3 + j*5, 4)
		for (j=1; j<=nE; j++) dyE[i,j] = mod(i*2 + j*7, 4)
	}
	st_matrix("__cv", cv)
	st_matrix("__dy", dy)
	st_matrix("__dyE", dyE)
}
mnnet_data()
end
forvalues w = 1/3 {
	nwset, mat(__B`w') bipartite name(nb`w') nooutput
	nwset, mat(__F`w') directed name(nf`w') nooutput
	nwset, mat(__H`w') directed name(nh`w') nooutput
	nwset, mat(__S`w') undirected name(ns`w') nooutput
}
clear
set obs 20
gen double cv = .
mata: st_store(., "cv", st_matrix("__cv"))

global R_sfx ""
capture program drop chkrefs
program define chkrefs
local nchecked = 0
local nbad = 0
foreach row of local 0 {
	gettoken grp row : row, parse("|")
	gettoken rest row : row, parse("|")
	gettoken rs row : row, parse("|")
	gettoken rest row : row, parse("|")
	gettoken nwtk row : row, parse("|")
	gettoken rest row : row, parse("|")
	local val `row'
	local n1 n`=lower(substr("`grp'", 1, 1))'$R_sfx
	local n2 n`=lower(substr("`grp'", 2, 1))'$R_sfx
	local s1 = ("`=substr("`grp'", 1, 1)'" == "S")
	local s2 = ("`=substr("`grp'", 2, 1)'" == "S")
	local e1 = cond(`s1' | "`=substr("`grp'", 1, 1)'" == "B", "outdegree", "outdegree reciprocity")
	local e2 = cond(`s2' | "`=substr("`grp'", 2, 1)'" == "B", "outdegree", "outdegree reciprocity")
	local nb1 = wordcount("`e1'")
	local cmd nwsaom multinet, net1(`n1'1 `n1'2 `n1'3) net2(`n2'1 `n2'2 `n2'3) eff1(`e1') eff2(`e2') cross1(`nwtk') fix(_all) k0(10) k3(40)
	if `s1' local cmd `cmd' sym1
	if `s2' local cmd `cmd' sym2
	capture noisily mnt `cmd'
	if _rc {
		di as err "no fit for `grp' `rs'"
		exit 9
	}
	matrix __tg = e(target)
	mata: st_numscalar("__cross", colsum(st_matrix("__tg"))[`nb1' + 1])
	if abs(scalar(__cross) - `val') > 5e-4 * max(1, abs(`val')) {
		di as err "`grp' `rs': nwsaom " scalar(__cross) " siena07 `val'"
		local ++nbad
		continue
	}
	local ++nchecked
}
di as text "`nchecked' cross-network statistics equal siena07 (1.6.14)"
assert `nbad' == 0
global R_nchecked = `nchecked'
end
local refs `refs' BF|diffWXClosure:0:cv|diffwxclosure:cv:0|80.000000
local refs `refs' BF|inActIntnX:1:cv|inactintnx:cv:1|-48.500000
local refs `refs' BF|outActIntnX:1:cv|outactintnx:cv:1|39.500000
local refs `refs' BF|sameXInActIntn:1:cv|samexinactintn:cv:1|68.000000
local refs `refs' BF|sameXInActIntn:2:cv|samexinactintn:cv:2|62.727922
local refs `refs' BF|sameXOutActIntn:1:cv|samexoutactintn:cv:1|63.000000
local refs `refs' BF|sameXOutActIntn:2:cv|samexoutactintn:cv:2|55.384776
local refs `refs' BF|altDist2W:1:cv|altdist2w:cv:1|-2.050000
local refs `refs' BF|totDist2W:1:cv|totdist2w:cv:1|-3.500000
local refs `refs' BF|simDist2W:1:cv|simdist2w:cv:1|21.345029
local refs `refs' BF|sameWXClosure:0:cv|samewxclosure:cv:0|15.000000
local refs `refs' BF|toU:0:dy|tou:__dy:0|21.000000
local refs `refs' BF|sharedToU:1:dy|sharedtou:__dy:1|40.947368
local refs `refs' BF|avAltU.2M.tie:1:dy|avaltutie:__dy:1|37.942988
local refs `refs' FB|covNetNet:0:cv|covnetnet:cv:0|13.000000
local refs `refs' FB|toU:0:dyE|tou:__dyE:0|22.500000
local refs `refs' FH|diffWXClosure:0:cv|diffwxclosure:cv:0|69.000000
local refs `refs' FH|toU:0:dy|tou:__dy:0|1.210526
local refs `refs' FS|toU:0:dy|tou:__dy:0|8.421053
local refs `refs' SF|toU:0:dy|tou:__dy:0|7.631579
chkrefs `refs'
local ntot = $R_nchecked
assert `ntot' >= 20
di "PASS r1614 cross-network statistics"

* covariates of the events of the two-mode network (RSiena: a covariate of the second node set), given in the node data of the two-mode network (values for the events only)
clear
nwset, mat(__B1) bipartite name(nbq) nooutput
gen double cvE = .
mata: md = st_sdata(., "_nwmode"); ie = selectindex(md :!= "2"); st_store(ie, "cvE", mod((1::10) :* 3, 4) :+ 1)
local ev `ev' FB|altDist2W:1:cvE|altdist2w:cvE:1|30.300000
local ev `ev' FB|totDist2W:1:cvE|totdist2w:cvE:1|72.200000
local ev `ev' FB|simDist2W:1:cvE|simdist2w:cvE:1|36.203704
chkrefs `ev'
assert $R_nchecked == 3
di "PASS r1614 covariates of the events"

* more events than actors (8 actors, 14 events): the effects that read the covariate of the events with the index of an actor (RSiena: outActIntnX, outPopIntnX)
mata:
mata set matastrict off
void r1614_data2() {
	nA = 8
	nE = 14
	for (w=1; w<=3; w++) {
		B = J(nA, nE, 0)
		F = J(nA, nA, 0)
		for (i=1; i<=nA; i++) {
			for (j=1; j<=nE; j++) B[i,j] = mod((mod(i*7 + j*13 + i*j, 11) < 3) + (mod(i*3 + j*5 + w*(i+j), 23) == 0), 2)
			for (j=1; j<=nA; j++) {
				if (i == j) continue
				F[i,j] = mod((mod(i*5 + j*11 + i*j, 17) < 3) + (mod(i*2 + j*3 + w*(i+2*j), 29) == 0), 2)
			}
		}
		st_matrix("__Be" + strofreal(w), B)
		st_matrix("__Fe" + strofreal(w), F)
	}
	dy = J(nA, nA, 0)
	cv = J(nA, 1, 0)
	for (i=1; i<=nA; i++) {
		cv[i] = mod(i*3, 4) + 1
		for (j=1; j<=nA; j++) if (i != j) dy[i,j] = mod(i*3 + j*5, 4)
	}
	st_matrix("__cve", cv)
	st_matrix("__dye", dy)
}
r1614_data2()
end
clear
forvalues w = 1/3 {
	nwset, mat(__Be`w') bipartite name(nbe`w') nooutput
	nwset, mat(__Fe`w') directed name(nfe`w') nooutput
}
clear
set obs 8
gen double cv = .
mata: st_store(., "cv", st_matrix("__cve"))
matrix __dy = __dye
global R_sfx "e"
local refs2 ""
local refs2 `refs2' BF|diffWXClosure:0:cv|diffwxclosure:cv:0|24.000000
local refs2 `refs2' BF|inActIntnX:1:cv|inactintnx:cv:1|13.000000
local refs2 `refs2' BF|outActIntnX:1:cv|outactintnx:cv:1|18.000000
local refs2 `refs2' BF|toU:0:dy|tou:__dy:0|2.857143
local refs2 `refs2' FB|covNetNet:0:cv|covnetnet:cv:0|0.000000
chkrefs `refs2'
clear
nwset, mat(__Be1) bipartite name(nbq2) nooutput
gen double cvE = .
mata: md = st_sdata(., "_nwmode"); ie = selectindex(md :!= "2"); st_store(ie, "cvE", mod((1::14) :* 3, 4) :+ 1)
local ev2 ""
local ev2 `ev2' FB|altDist2W:1:cvE|altdist2w:cvE:1|3.052381
local ev2 `ev2' FB|totDist2W:1:cvE|totdist2w:cvE:1|12.642857
local ev2 `ev2' FB|simDist2W:1:cvE|simdist2w:cvE:1|5.393468
local ev2 `ev2' FB|outActIntnX:1:cvE|outactintnx:cvE:1|7.642857
local ev2 `ev2' FB|outPopIntnX:1:cvE|outpopintnx:cvE:1|12.642857
chkrefs `ev2'
assert $R_nchecked == 5
global R_sfx ""
di "PASS r1614 more events than actors"

* RSiena indexes the actors of one network by the events of the other in these effects: refused where the index would run beyond the other mode
capture nwsaom multinet, net1(nbe1 nbe2 nbe3) net2(nfe1 nfe2 nfe3) cross1(altdist2w:cv:1) k3(20)
assert _rc == 198
di "PASS r1614 refusals"

* ---------------------------------------------------------------- dyadx(): WXX / XWX / XWX1 / XWX2 / WXZX in a two-mode network, WXZX in a one-mode network
* RSiena 1.6.13/1.6.14 (dev/saom_rsiena_r1614_dyadx.R; the estimates of two seeds agree, dev/saom_rsiena_r1614_dyadx.do)
clear
capture program drop dxstat
program define dxstat
	args nw dx col ref
	capture nwsaom, waves(`nw'1 `nw'2 `nw'3) outdegree `=cond("`nw'" == "om", "reciprocity", "")' dyadx(`dx') k0(5) k3(20) seed(1)
	assert _rc == 0
	mata: st1 = __nwsaom_last_M.full_statistic(__nwsaom_last_G2); st2 = __nwsaom_last_M.full_statistic(__nwsaom_last_G3); st_numscalar("__dxs", (st1 + st2)[`col'])
	di "`dx': " scalar(__dxs) " (siena07 `ref')"
	assert reldif(scalar(__dxs), `ref') < 1e-9
end
forvalues w = 1/3 {
	import delimited "dev/saom_twomode_w`w'.csv", clear varnames(1)
	mkmat v1-v20, matrix(T`w')
	import delimited "dev/saom_r1614_s50_w`w'.csv", clear varnames(1)
	mkmat v1-v50, matrix(S`w')
	import delimited "dev/saom_rsiena_symmulti_w`w'.csv", clear varnames(1) case(preserve)
	mkmat V1-V50, matrix(Y`w')
}
import delimited "dev/saom_r1614_w40.csv", clear varnames(1)
mkmat v1-v40, matrix(W40)
import delimited "dev/saom_r1614_z20.csv", clear varnames(1)
mkmat v1-v20, matrix(Z20)
import delimited "dev/saom_r1614_z50.csv", clear varnames(1)
mkmat v1-v50, matrix(Z50)
import delimited "dev/saom_rsiena_dyadx_w.csv", clear varnames(1)
mkmat v1-v50, matrix(W50)
clear
forvalues w = 1/3 {
	nwset, mat(T`w') bipartite name(tm`w') nooutput
	nwset, mat(S`w') directed name(om`w') nooutput
	nwset, mat(Y`w') undirected name(sy`w') nooutput
}
dxstat tm wxx:W40 2 1752
dxstat tm xwx:Z20 2 858
dxstat tm xwx1:Z20 2 858
dxstat tm xwx2:Z20 2 858
dxstat tm wxzx:W40:Z20 2 4507
dxstat om wxx:W50 3 146
dxstat om wxzx:W50:Z50 3 961
dxstat om wxzx:Z50:W50 3 979
dxstat sy wxzx:W50:Z50 2 1738
dxstat sy wxx:W50 2 240
* the estimates of a short run are finite and the effects are named by their matrices
nwsaom, waves(tm1 tm2 tm3) outdegree dyadx(wxzx:W40:Z20) k0(20) k3(200) seed(2)
assert "`e(engine)'" == "native" & e(twomode) == 1 & colsof(e(b)) == 2 & !missing(el(e(b),1,2))
assert strpos("`: colnames e(b)'", "wxzx_W40_Z20") > 0
di "PASS r1614 dyadx"

* refusals: wxzx needs two matrices, a two-mode network takes only the effects RSiena has for it, the matrices have the size of the modes
capture nwsaom, waves(om1 om2 om3) outdegree dyadx(wxzx:W50) k3(20)
assert _rc == 198
capture nwsaom, waves(om1 om2 om3) outdegree dyadx(wxx:W50:Z50) k3(20)
assert _rc == 198
capture nwsaom, waves(tm1 tm2 tm3) outdegree dyadx(wwx:W40) k3(20)
assert _rc == 198
capture nwsaom, waves(tm1 tm2 tm3) outdegree dyadx(wxx:Z20) k3(20)
assert _rc == 198
capture nwsaom, waves(tm1 tm2 tm3) outdegree dyadx(wxzx:Z20:W40) k3(20)
assert _rc == 198
di "PASS r1614 dyadx refusals"

* ---------------------------------------------------------------- the degree effects whose internal parameter is 1 by default (RSiena 1.6.13): the observed statistics of the current degrees
* RSiena 1.6.14 on s50: outPop.c 119.08, outPopSqrt 386.6856, outPopMore 443 (parameter 2: 245), outPopSqrtMore 153.6856 (71.6713), outPopThreshold 198 (138), inAct.c 119.08, inActSqrt 378.5651
clear
nwwebuse glasgow, nwclear
capture program drop popstat
program define popstat
	args spec ref
	nwsaom, waves(glasgow1 glasgow2 glasgow3) outdegree `spec' k0(5) k3(20) seed(1)
	mata: st1 = __nwsaom_last_M.full_statistic(__nwsaom_last_G2); st2 = __nwsaom_last_M.full_statistic(__nwsaom_last_G3); st_numscalar("__pps", (st1 + st2)[2])
	di "`spec': " scalar(__pps) " (siena07 `ref')"
	assert abs(scalar(__pps) - `ref') < 1e-3
end
popstat outpopc 119.08
popstat outpopularity 386.6856
popstat ownx(outpopmore) 443
popstat ownx(outpopmore:2) 245
popstat ownx(outpopsqrtmore) 153.6856
popstat ownx(outpopsqrtmore:2) 71.6713
popstat ownx(outpopthreshold) 198
popstat ownx(outpopthreshold:2) 138
popstat inactc 119.08
popstat inactivity 378.5651
* RSiena stops with an internal parameter below 1 for outPopMore, outPopSqrtMore and outPopThreshold
foreach ef in outpopmore outpopsqrtmore outpopthreshold {
	capture nwsaom, waves(glasgow1 glasgow2 glasgow3) outdegree ownx(`ef':0) k3(20)
	assert _rc == 198
}
di "PASS r1614 degree effects"
