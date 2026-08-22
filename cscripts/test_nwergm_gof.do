cscript

do unw_core.do
do unw_ergm.do

* Certifies nwergm_estat.ado's `estat gof' (Part XX of the governing
* nwergm task: basic simulation-based goodness of fit, reusing this
* package's own existing nwgeodesic/nwtriads commands rather than
* duplicating their algorithms). Exercises the REAL Stata `estat'
* dispatch mechanism, both the method(mcmle) and method(mple) paths, and
* TWO SEPARATE nwergm fits in one session (a genuine bug was found and
* fixed here: nwtriads.ado crashes with "n not found - data already
* wide" (r(111)) on a zero-tie network - a real, pre-existing bug in
* nwtriads.ado itself, confirmed via an isolated repro independent of
* nwergm entirely, and NOT fixed at the source since it is out of this
* subsystem's scope - see docs/CERTIFICATION.md. `estat gof' defends
* against it with `capture' around every nwtriads/nwgeodesic call on a
* simulated network, exactly the discipline this test certifies).

nwclear
nwset, mat((0,1,1,0,0\1,0,1,0,0\1,1,0,1,0\0,0,1,0,1\0,0,0,1,0)) undirected name(mynet) labs(A,B,C,D,E)

* --- MCMLE path: dyad-dependent model (gwesp), real MCMC simulation.
set seed 555
qui nwergm mynet, edges gwesp(.5) mcmcburnin(1000) mcmcinterval(20) mcmcsamplesize(1000) mcmleiterations(10)
qui estat gof, nsim(20) seed(777)
assert r(obs_meandeg) == 2*5/5
assert r(sim_meandeg) > 0 & r(sim_meandeg) < 8
assert r(obs_avgpath) < .
assert r(obs_triad300) < .

* --- MPLE path (dyad-independent, no MCMC ever run before estat gof
* triggers its own first-ever simulation for this fit) on a SECOND,
* separately-built network in the SAME session - the exact sequence
* that originally surfaced the nwtriads.ado zero-tie crash.
nwclear
nwset, mat((0,1,1,0,0\1,0,1,0,0\1,1,0,1,0\0,0,1,0,1\0,0,0,1,0)) undirected name(mynet2) labs(A,B,C,D,E)
qui nwergm mynet2, edges method(mple)
qui estat gof, nsim(10) seed(888)
assert r(sim_meandeg) > 0
assert r(obs_meandeg) == 2*5/5

* --- no fitted model available: informative error, not a crash.
ereturn clear
capture noisily estat gof
assert _rc == 301

* --- network no longer loaded under its fitted name: informative error.
nwclear
nwset, mat((0,1,1,0,0\1,0,1,0,0\1,1,0,1,0\0,0,1,0,1\0,0,0,1,0)) undirected name(mynet3) labs(A,B,C,D,E)
qui nwergm mynet3, edges
nwclear
capture noisily estat gof
assert _rc == 498
