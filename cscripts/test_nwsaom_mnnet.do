* nwsaom multinet with a TWO-MODE member (actors choose among events) and with non-directed networks: the observed cross-network statistics equal siena07's targets.
* The networks are given by formulas (no random numbers) and built identically by dev/saom_rsiena_mnnet.R, which printed the reference values below (siena07, RSiena 1.6.6;
* the targets of the cross effect, summed over the periods). Estimates against siena07 (two seeds): dev/saom_rsiena_mn2m.R / .do (two-mode) and dev/saom_rsiena_mn1m.R / .do.
cscript
do unw_core.do
do unw_ergm.do
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

* the statistics of the cross-network effects (all fixed at 0: the observed statistics only) against siena07
local refs `refs' BF|inActIntn|inactintn|1.351838
local refs `refs' BF|outActIntn|outactintn|-2.562733
local refs `refs' BF|divOutEgoIntn|divoutegointn|62.776109
local refs `refs' BF|divInEgoIntn|divinegointn|60.555794
local refs `refs' BF|divInAltIntn|divinaltintn|56.681518
local refs `refs' BF|avDegIntn|avdegintn|187.650000
local refs `refs' BF|outOutActIntn|outoutactintn|1.400000
local refs `refs' BF|outOutAvIntn|outoutavintn|-7.483333
local refs `refs' BF|dist2OutInActIntn|dist2outinactintn|130.800000
local refs `refs' BF|outOutDist2ActIntn|outoutdist2actintn|-73.200000
local refs `refs' BF|avAlt.2M.tot|avalt2mtot|-10.435981
local refs `refs' BF|to|to|95.000000
local refs `refs' BF|toBack|toback|95.000000
local refs `refs' BF|toRecip|torecip|16.000000
local refs `refs' BF|sharedTo|sharedto|14.494737
local refs `refs' BF|inPopOutW|inpopoutw|2109.000000
local refs `refs' BF|nDist2ActIntn|ndist2actintn|995.000000
local refs `refs' BF|toAny|toany|75.000000
local refs `refs' BF|JoutMix|joutmix|14.546429
local refs `refs' BF|gwespFBMix|gwespfbmix|60.912702
local refs `refs' BF|avAlt.2M.tie:2|avalt2mtie:2|31.644018
local refs `refs' BF|sharedToU:1:dy|sharedtou:__dy:1|40.947368
local refs `refs' BF|avAltU.2M.tie:1:dy|avaltutie:__dy:1|37.942988
local refs `refs' BF|sameWXClosure:0:cv|samewxclosure:cv:0|15.000000
local refs `refs' FB|outPopIntn|outpopintn|-11.270929
local refs `refs' FB|outActIntn|outactintn|-8.731631
local refs `refs' FB|divOutEgoIntn|divoutegointn|84.857984
local refs `refs' FB|divOutAltIntn|divoutaltintn|84.454360
local refs `refs' FB|avDegIntn|avdegintn|110.950000
local refs `refs' FB|outOutActIntn|outoutactintn|-40.000000
local refs `refs' FB|outOutAvIntn|outoutavintn|-17.700000
local refs `refs' FB|dist2OutInActIntn|dist2outinactintn|240.000000
local refs `refs' FB|absOutDiffIntn|absoutdiffintn|166.000000
local refs `refs' FB|from|from|96.000000
local refs `refs' FB|fromAny|fromany|77.000000
local refs `refs' FB|sharedTo|sharedto|-975.214815
local refs `refs' FB|avAlt.2M.tie:2|avalt2mtie:2|22.643178
local refs `refs' FB|inPopOutW|inpopoutw|1136.000000
local refs `refs' FB|nDist2ActIntn|ndist2actintn|1450.000000
local refs `refs' FB|JoutMix|joutmix|21.319048
local refs `refs' FB|gwespMix|gwespmix|85.970060
local refs `refs' FB|sharedToU:1:dyE|sharedtou:__dyE:1|11.000000
local refs `refs' FB|avAltU.2M.tie:1:dyE|avaltutie:__dyE:1|43.804644
local refs `refs' FB|from.w.ind:1:Bd|fromwindoo:1|614.000000
local refs `refs' FS|toAny|toany|50.000000
local refs `refs' FS|gwespMix|gwespmix|46.734242
local refs `refs' FS|outOutActIntn|outoutactintn|-85.200000
local refs `refs' FS|outOutAvIntn|outoutavintn|-20.150000
local refs `refs' FS|both|both|-7.480000
local refs `refs' FS|avAlt.2M.tie:2|avalt2mtie:2|17.972489
local refs `refs' FS|from.w.ind:1:Fd|fromwindow:1|175.000000
local refs `refs' FS|from.w.ind:1:Sd|fromwindoo:1|194.000000
local refs `refs' FS|toU:0:dy|tou:__dy:0|-8.421053
local refs `refs' FS|to|to|58.000000
local refs `refs' FS|sharedTo|sharedto|-20.508772
local refs `refs' SF|toAny|toany|39.000000
local refs `refs' SF|betweenPop|betweenpop|389.580188
local refs `refs' SF|from.w.ind:1:Sd|fromwindow:1|204.000000
local refs `refs' SF|from.w.ind:1:Fd|fromwindoo:1|240.000000
local refs `refs' SF|avAlt.2M.tie:2|avalt2mtie:2|14.774770
local refs `refs' SF|toU:0:dy|tou:__dy:0|-11.368421
local refs `refs' SF|to|to|49.000000
local refs `refs' SF|sharedTo|sharedto|-25.136842
local refs `refs' FH|toAny|toany|71.000000
local refs `refs' FH|betweenPop|betweenpop|440.404470
local refs `refs' FH|from.w.ind:1:Fd|fromwindow:1|241.000000
local refs `refs' FH|from.w.ind:1:Hd|fromwindoo:1|278.000000
local refs `refs' FH|toU:0:dy|tou:__dy:0|15.578947
local refs `refs' FHo|from.w.ind:1:Hd:Fd|fromwindwo:1|344.000000
local refs `refs' BS|to|to|86.000000
local refs `refs' BS|toAny|toany|56.000000
local refs `refs' BS|sharedTo|sharedto|21.842105
local refs `refs' BS|avAlt.2M.tie:2|avalt2mtie:2|32.512341
local refs `refs' SB|from|from|86.000000
local refs `refs' SB|fromAny|fromany|54.000000
local refs `refs' SB|sharedTo|sharedto|-765.022222
local refs `refs' SB|inPopOutW|inpopoutw|852.000000
local nchecked = 0
foreach row of local refs {
	gettoken grp row : row, parse("|")
	gettoken rest row : row, parse("|")
	gettoken rs row : row, parse("|")
	gettoken rest row : row, parse("|")
	gettoken nwtk row : row, parse("|")
	gettoken rest row : row, parse("|")
	local val `row'
	local n1 n`=lower(substr("`grp'", 1, 1))'
	local n2 n`=lower(substr("`grp'", 2, 1))'
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
		exit 9
	}
	local ++nchecked
}
di as text "`nchecked' cross-network statistics equal siena07"
assert `nchecked' >= 70
di "PASS mnnet statistics"

* a changing covariate (tvcov(), one variable per period) in a cross-network covariate effect: with the same values in both periods it is the constant covariate
gen double ct1 = cv
gen double ct2 = cv
foreach pair in "nb nf" "nf nb" {
	gettoken a b : pair
	local cmd nwsaom multinet, net1(`a'1 `a'2 `a'3) net2(`b'1 `b'2 `b'3) eff1(outdegree) eff2(outdegree) cross1(samewxclosure:cv) fix(_all) k0(10) k3(40)
	if "`a'" == "nf" local cmd nwsaom multinet, net1(nf1 nf2 nf3) net2(nb1 nb2 nb3) eff1(outdegree reciprocity) eff2(outdegree) cross1(samewxclosure:cv) fix(_all) k0(10) k3(40)
	else local cmd nwsaom multinet, net1(nb1 nb2 nb3) net2(nf1 nf2 nf3) eff1(outdegree) eff2(outdegree reciprocity) cross1(samewxclosure:cv) fix(_all) k0(10) k3(40)
	mnt `cmd'
	matrix __t1 = e(target)
	local cmd2 = subinstr("`cmd'", "samewxclosure:cv", "samewxclosure:ct", 1) + " tvcov(ct1 ct2)"
	mnt `cmd2'
	matrix __t2 = e(target)
	assert mreldif(__t1, __t2) < 1e-9
}
di "PASS mnnet changing covariate"

* a two-mode member: results, the actors and events, the estimation itself
mnt nwsaom multinet, net1(nb1 nb2 nb3) net2(nf1 nf2 nf3) cross1(to inactintn) cross2(from) eff1(outdegree indegpop outact cycle4) k0(10) k3(60)
assert e(twomode1) == 1 & e(twomode2) == 0 & e(n_actors) == 20 & e(n_events) == 10
assert "`e(engine)'" == "native" & colsof(e(b)) == 4 + 2 + 2 + 1 + 0
local nm : colnames e(b)
assert strpos("`nm'", "net1_x_to") > 0 & strpos("`nm'", "net1_x_inactintn") > 0 & strpos("`nm'", "net2_x_from") > 0
assert colsof(e(rates)) == 2 & rowsof(e(rates)) == 4 & !missing(e(rates)[1,1], e(rates)[2,2])
* the two-mode network as the second network, and a covariate effect on the actors
mnt nwsaom multinet, net1(nf1 nf2 nf3) net2(nb1 nb2 nb3) cross1(from samewxclosure:cv) eff2(outdegree indegpop) k0(10) k3(60)
assert e(twomode1) == 0 & e(twomode2) == 1
* a non-directed one-mode network with a two-mode one
mnt nwsaom multinet, net1(nb1 nb2 nb3) net2(ns1 ns2 ns3) sym2 cross1(to toany) k0(10) k3(60)
assert e(twomode1) == 1 & e(n_actors) == 20
di "PASS mnnet two-mode fit"

* refusals
capture nwsaom multinet, net1(nb1 nb2 nb3) net2(nb1 nb2 nb3) k3(20)
assert _rc == 198
capture nwsaom multinet, net1(nb1 nb2 nb3) net2(nf1 nf2 nf3) eff1(reciprocity) k3(20)
assert _rc == 198
capture nwsaom multinet, net1(nb1 nb2 nb3) net2(nf1 nf2 nf3) cross1(sharedtou:__dyE) k3(20)
assert _rc == 198
capture nwsaom multinet, net1(nb1 nb2 nb3) net2(nf1 nf2 nf3) cross1(sharedtou:nosuchmatrix) k3(20)
assert _rc != 0
capture nwsaom multinet, net1(nb1 nb2 nb3) net2(nf1 nf2 nf3) sym1 k3(20)
assert _rc == 198
capture nwsaom multinet, net1(nb1 nb2 nb3) net2(nf1 nf2 nf3) cross2(toany) k3(20)
assert _rc == 198
* events than actors: RSiena indexes both networks by the same node number in some effects (refused)
mata:
rseed(77)
st_matrix("__b8", (runiform(8, 14) :< 0.25))
f8 = (runiform(8, 8) :< 0.2)
st_matrix("__f8", f8 - diag(diag(f8)))
end
forvalues w = 1/3 {
	nwset, mat(__b8) bipartite name(nb8`w') nooutput
	nwset, mat(__f8) directed name(nf8`w') nooutput
}
capture nwsaom multinet, net1(nb81 nb82 nb83) net2(nf81 nf82 nf83) cross1(divinaltintn) k3(20)
assert _rc == 198
di "PASS mnnet refusals"
