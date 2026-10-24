* nwsaom with a two-mode (bipartite) network: actors (the rows of the affiliation matrix given to nwset, bipartite)
* choose among events. Real-data agreement with RSiena (40 x 20, 3 waves; statistics identical, estimates within noise):
* dev/saom_rsiena_twomode_sim.R / dev/saom_rsiena_twomode.do.
cscript
do unw_core.do
do unw_saom.do

nwclear
mata:
mata set matastrict off
void tm_data() {
	na = 24
	ne = 10
	rseed(2468)
	X = (runiform(na, ne) :< 0.15)
	for (w=1; w<=3; w++) {
		st_matrix("__T" + strofreal(w), X)
		F = (runiform(na, ne) :< 0.12)
		X = abs(X - F)
	}
	st_matrix("__CA", rnormal(na, 1, 0, 1))
	st_matrix("__CB", rnormal(ne, 1, 0, 1))
}
tm_data()
mata: CAm = st_matrix("__CA"); CBm = st_matrix("__CB")
end
clear
forvalues w = 1/3 {
	nwset, mat(__T`w') bipartite name(tm`w') nooutput
}
gen double ega = .
gen double altb = .
mata: md = st_sdata(., "_nwmode"); st_store(selectindex(md :== "2"), "ega", CAm); st_store(selectindex(md :== "1"), "altb", CBm)

* three waves: structural effects and both covariate effects
nwsaom, waves(tm1 tm2 tm3) outdegree indegpopularity outactivity cycle4 nodeocov(ega) nodeicov(altb) k0(30) k3(150) seed(3)
assert e(twomode) == 1 & e(n_actors) == 24 & e(n_events) == 10
assert colsof(e(b)) == 6 & !missing(el(e(b),1,1), el(e(b),1,6))
assert "`e(engine)'" == "native"
* two waves
nwsaom, wave1(tm1) wave2(tm2) outdegree indegpopularity cycle4 k0(30) k3(150) seed(3)
assert e(twomode) == 1 & colsof(e(b)) == 3
di as text "two-mode, native PASS"

* the statistics are those of the bipartite graph: density = number of ties, inPopSqrt = sum of indegree^1.5
mata: st2 = __nwsaom_last_M.full_statistic(__nwsaom_last_G2)
mata: st_numscalar("__ties", st2[1]); st_numscalar("__inp", st2[2])
mata: A = __nwsaom_last_G2.to_dense(); st_numscalar("__ip", sum(colsum(A):^1.5)); st_numscalar("__cnt", sum(A))
assert scalar(__ties) == scalar(__cnt) & abs(scalar(__inp) - scalar(__ip)) < 1e-9

* the actors are the other mode with actormode(1): the roles swap (here 10 actors, 24 events)
nwsaom, wave1(tm1) wave2(tm2) outdegree indegpopularity actormode(1) k0(30) k3(150) seed(3)
assert e(n_actors) == 10 & e(n_events) == 24
di as text "two-mode, actormode PASS"

* the Mata engine
global NWSAOM_NONATIVE 1
nwsaom, wave1(tm1) wave2(tm2) outdegree indegpopularity k0(20) k3(60) seed(3)
assert "`e(engine)'" == "mata" & e(twomode) == 1
global NWSAOM_NONATIVE
di as text "two-mode, Mata engine PASS"

* refusals
capture nwsaom, waves(tm1 tm2 tm3) outdegree reciprocity
assert _rc == 198
capture nwsaom, waves(tm1 tm2 tm3) outdegree actormode(3)
assert _rc == 198
capture nwsaom, waves(tm1 tm2 tm3) outdegree nodecov(ega)
assert _rc == 198
capture nwsaom, waves(tm1 tm2 tm3) outdegree behavior(ega ega ega)
assert _rc == 198
di as text "two-mode refusals PASS"
