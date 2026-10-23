* nwsaom multinet with a co-evolving behavior: behavior effects of both networks (beheff12(), beheff21()), covariate / shape / network effects named family:variable in
* beheff1() / beheff2(), network effects of the behavior as covariate (netbeh:), endowment and creation of behavior effects, missing behavior values (missbeh()).
* The observed statistics (e(target), summed over the periods) equal siena07's targets (dev/saom_rsiena_mnbeh*.R, s50 + a second network + alcohol; the numbers
* below are siena07's); estimates agree with siena07 in dev/saom_rsiena_mnbeh.R/.do.
cscript
do unw_core.do
do unw_ergm.do
do unw_saom.do
nwclear
* the data (siena07's s50 friendship waves, a second network, a non-directed network, alcohol, smoking): cscripts/mnbeh_ties.csv (net: 1 friendship, 2 second, 3 non-directed; wave; i; j)
* and cscripts/mnbeh_actors.csv (a1-a3 alcohol, s1 smoking, ma1-ma3 alcohol with missing values, m1-m3 their missing indicators)
import delimited "cscripts/mnbeh_ties.csv", clear varnames(1)
mata:
void mnbeh_mats() {
	real matrix ties, M, T
	string rowvector nm
	real scalar nt, w, r
	ties = st_data(., ("net", "wave", "i", "j"))
	nm = ("W", "B", "S")
	for (nt=1; nt<=3; nt++) for (w=1; w<=3; w++) {
		M = J(50, 50, 0)
		T = select(ties, (ties[., 1] :== nt) :& (ties[., 2] :== w))
		for (r=1; r<=rows(T); r++) M[T[r,3], T[r,4]] = 1
		st_matrix(nm[nt] + strofreal(w), M)
	}
}
mnbeh_mats()
end
import delimited "cscripts/mnbeh_actors.csv", clear varnames(1)
gen double xa = mod(_n * 7, 5)
forvalues w = 1/3 {
	nwset, mat(W`w') directed name(na`w') nooutput
	nwset, mat(B`w') directed name(nb`w') nooutput
	nwset, mat(S`w') undirected name(ns`w') nooutput
}

* runs the fit with the given effect lists and fixes every effect but the two outdegrees; T_<coefficient> = the observed statistic summed over the periods
capture program drop mnt
program define mnt
	syntax , [B1(string) B2(string) B12(string) B21(string) N1(string) N2(string) FIX(string) MISSBEH(string)]
	nwsaom multinet, net1(na1 na2 na3) net2(nb1 nb2 nb3) behavior(a1 a2 a3) eff1(outdegree reciprocity `n1') eff2(outdegree reciprocity `n2') ///
		beheff1(linear quadratic `b1') beheff2(`b2') beheff12(`b12') beheff21(`b21') `=cond("`missbeh'" != "", "missbeh(`missbeh')", "")' ///
		k0(3) k3(10) fix(net1_reciprocity net2_reciprocity beh_linear beh_quadratic `fix') seed(1)
	matrix tg = e(target)
	local cn : colnames tg
	forvalues j = 1/`=colsof(tg)' {
		local s = 0
		forvalues pd = 1/`=rowsof(tg)' {
			local s = `s' + tg[`pd',`j']
		}
		local nm : word `j' of `cn'
		scalar T_`nm' = `s'
	}
end
capture program drop chk
program define chk
	args name value
	assert reldif(scalar(T_`name'), `value') < 2e-3
end

* behavior effects of both networks: (first network, second network) as siena07's interaction1, interaction2
mnt, b12(ffdeg bbdeg fbdeg frdeg brdeg) fix(beh12_ffdeg beh12_bbdeg beh12_fbdeg beh12_frdeg beh12_brdeg)
chk beh12_ffdeg 25.2867
chk beh12_bbdeg 32.2867
chk beh12_fbdeg 14.0267
chk beh12_frdeg 9.56
chk beh12_brdeg 8.56
mnt, b21(indegmixedpop outdegmixedpop) fix(beh21_indegmixedpop beh21_outdegmixedpop)
chk beh21_indegmixedpop 202.7733
chk beh21_outdegmixedpop 209.72
mnt, b12(indegmixedpop outdegmixedpop ffdeg:2) b21(bbdeg:2) fix(beh12_indegmixedpop beh12_outdegmixedpop beh12_ffdeg2 beh21_bbdeg2)
chk beh12_indegmixedpop 237.807
chk beh12_outdegmixedpop 293.72
chk beh12_ffdeg2 -26.76
chk beh21_bbdeg2 -49.1
di as text "PASS behavior effects of both networks (statistics equal siena07)"

* a non-directed second network (sym2): BFDeg exists only there (siena07: behaviorOneModeSym objective); the density of the non-directed network is held at 0.045
nwsaom multinet, net1(na1 na2 na3) net2(ns1 ns2 ns3) sym2 behavior(a1 a2 a3) eff2(outdegree) beheff1(linear quadratic avalt) beheff12(bfdeg ffdeg indegmixedpop) k0(3) k3(10) ///
	theta0(-2.3 2.8 0.045 0 0 0 0 0 0) fix(net1_reciprocity net2_outdegree beh_linear beh_quadratic beh_avalt beh12_bfdeg beh12_ffdeg beh12_indegmixedpop) seed(1)
matrix tg = e(target)
local cn : colnames tg
foreach x in "beh12_bfdeg 7.96" "beh12_ffdeg 8.96" "beh12_indegmixedpop 286.347" {
	gettoken nm v : x
	local j : list posof "`nm'" in cn
	assert reldif(tg[1,`j'] + tg[2,`j'], `v') < 2e-3
}
di as text "PASS behavior effects with a non-directed network (statistics equal siena07)"

* covariate effects of the behavior (driven by network 1 or by network 2), the network effects of the behavior as covariate
mnt, b1(from:s1 avxalt:s1) b2(avxinalt:xa totsimaltx:xa) fix(beh_from_s1 beh_avxalt_s1 beh2_avxinalt_xa beh2_totsimaltx_xa)
chk beh_from_s1 28.26
chk beh_avxalt_s1 20.9767
chk beh2_avxinalt_xa -18.3339
chk beh2_totsimaltx_xa 1.2391
mnt, b1(indeg outdeg isolate totalt) b2(indeg avaltpop) fix(beh_indeg beh_outdeg beh_isolate beh_totalt beh2_indeg beh2_avaltpop)
chk beh_indeg 51.0467
chk beh_outdeg 52.0467
chk beh_isolate -0.2467
chk beh_totalt 141.3747
chk beh2_indeg 81.3867
chk beh2_avaltpop 38.3198
mnt, n1(netbeh:egosqx netbeh:totgroupegox netbeh:simdist2) n2(netbeh:absdiffx netbeh:avgroupegox netbeh:simdist2) ///
	fix(net1_bv_egosqx net1_natb_totgroupegox net1_natb_simdist2 net2_bv_absdiffx net2_natb_avgroupegox net2_natb_simdist2)
chk net1_bv_egosqx 364.977
chk net1_natb_totgroupegox -1434.667
chk net1_natb_simdist2 55.6282
chk net2_bv_absdiffx 608
chk net2_natb_avgroupegox -55.6533
chk net2_natb_simdist2 78.136
mnt, b1(constant) fix(beh_constant)
chk beh_constant -60
di as text "PASS covariate, shape and network effects (statistics equal siena07)"

* endowment and creation of behavior effects
mnt, b1(linearendow quadraticendow avaltendow avsimendow) b2(avaltendow) fix(beh_linear_endow beh_linear_creation beh_quadratic_endow beh_quadratic_creation beh_avalt_endow beh_avalt_creation beh_avsim_endow beh_avsim_creation beh2_avalt_endow beh2_avalt_creation)
chk beh_linear_creation 42
chk beh_quadratic_endow -3.92
chk beh_quadratic_creation 106.48
chk beh_avalt_endow -10.4589
chk beh_avalt_creation 26.5128
chk beh_avsim_endow 3.1667
chk beh_avsim_creation 25.3167
chk beh2_avalt_endow -2.9203
di as text "PASS endowment and creation of behavior effects (statistics equal siena07)"

* interactions of behavior effects (behint(); siena07: includeInteraction() of behavior effects, the unspecified interaction behUnspInt)
nwsaom multinet, net1(na1 na2 na3) net2(nb1 nb2 nb3) behavior(a1 a2 a3) beheff1(linear quadratic avalt avsim) beheff2(avalt) ///
	behint(beh_quadratic#beh_avalt beh_avalt#beh2_avalt beh_linear#beh_quadratic#beh_avalt beh_avalt#beh_avsim) k0(3) k3(10) ///
	fix(net1_reciprocity net2_reciprocity beh_linear beh_quadratic beh_avalt beh_avsim beh2_avalt beh_quadratic_x_avalt beh_avalt_x_avalt@2 beh_linear_x_quadratic_x_avalt beh_avalt_x_avsim) seed(1)
matrix tg = e(target)
local cn : colnames tg
foreach x in "beh_quadratic_x_avalt 40.0069" "beh_avalt_x_avalt@2 11.2151" "beh_linear_x_quadratic_x_avalt 40.0069" "beh_avalt_x_avsim -0.195" {
	gettoken nm v : x
	local j : list posof "`nm'" in cn
	assert `j' > 0
	assert reldif(tg[1,`j'] + tg[2,`j'], `v') < 2e-3
}
capture noisily nwsaom multinet, net1(na1 na2 na3) net2(nb1 nb2 nb3) behavior(a1 a2 a3) beheff1(linear quadratic avalt) behint(beh_avalt#beh_nosuch) k3(10)
assert _rc == 198
capture noisily nwsaom multinet, net1(na1 na2 na3) net2(nb1 nb2 nb3) behavior(a1 a2 a3) beheff1(linear quadratic avalt indeg) behint(beh_avalt#beh_indeg) k3(10)
assert _rc == 198
di as text "PASS interactions of behavior effects (statistics equal siena07)"

* missing behavior values: siena07's target of avAlt with the same missing values
nwsaom multinet, net1(na1 na2 na3) net2(nb1 nb2 nb3) behavior(ma1 ma2 ma3) missbeh(m1 m2 m3) beheff1(linear quadratic avalt) k0(3) k3(10) fix(net1_reciprocity net2_reciprocity beh_linear beh_quadratic) seed(1)
matrix tg = e(target)
local cn : colnames tg
local j : list posof "beh_avalt" in cn
assert reldif(tg[1,`j'] + tg[2,`j'], 41.363) < 1e-3
capture nwsaom multinet, net1(na1 na2 na3) net2(nb1 nb2 nb3) behavior(ma1 ma2 ma3) beheff1(linear) k3(10)
assert _rc == 198
di as text "PASS missing behavior values (statistic equals siena07)"

* a non-directed second network with a free density (one coefficient in the network)
capture nwsaom multinet, net1(na1 na2 na3) net2(ns1 ns2 ns3) sym2 eff2(outdegree) k0(30) k3(150) seed(2)
assert _rc == 0
assert abs(_b[net1_outdegree] + 2.36) < 0.4 & abs(_b[net2_outdegree]) < 0.5
di as text "PASS a single coefficient in the second network"

* estimates: the well-identified effects agree with siena07 (dev/saom_rsiena_mnbeh.R: siena07 -0.044 / -0.025 / 0.85)
capture nwsaom multinet, net1(na1 na2 na3) net2(nb1 nb2 nb3) behavior(a1 a2 a3) beheff1(linear quadratic avalt) beheff12(ffdeg) beheff21(indegmixedpop outdegmixedpop) k0(40) k3(400) seed(5)
assert inlist(_rc, 0, 498, 505)
if _rc == 0 {
	assert "`e(engine)'" == "native" & colsof(e(b)) == 10
	assert abs(_b[net1_outdegree] + 2.36) < 0.4 & abs(_b[beh21_indegmixedpop] + 0.044) < 0.3
}
di as text "PASS estimates"

* syntax
capture noisily nwsaom multinet, net1(na1 na2 na3) net2(nb1 nb2 nb3) behavior(a1 a2 a3) beheff12(nosuch) k3(10)
assert _rc == 198
capture noisily nwsaom multinet, net1(na1 na2 na3) net2(nb1 nb2 nb3) behavior(a1 a2 a3) beheff12(ffdeg:3) k3(10)
assert _rc == 198
capture noisily nwsaom multinet, net1(na1 na2 na3) net2(nb1 nb2 nb3) behavior(a1 a2 a3) beheff1(from) k3(10)
assert _rc == 198
capture noisily nwsaom multinet, net1(na1 na2 na3) net2(nb1 nb2 nb3) behavior(a1 a2 a3) eff1(netbeh:nosuch) k3(10)
assert _rc == 198
capture noisily nwsaom multinet, net1(na1 na2 na3) net2(nb1 nb2 nb3) beheff12(ffdeg) k3(10)
assert _rc != 0
di as text "PASS multinet behavior syntax"
