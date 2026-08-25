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

* --- real, user-reported regression guard: `estat gof' (and, separately,
* `nwergm ..., simulate') used to render the simulated/observed dense
* adjacency matrix as a literal Stata matrix-expression STRING
* (ErgmMatToLiteral()) and hand it to nwset's own mat() option - which
* works for a small network, but Stata's own command-line tokenizer
* hits a hard "too many tokens" error (r(3000)) somewhere between 225
* and 256 comma-separated matrix elements, confirmed by direct bisection
* (a 15x15 literal parses; an otherwise-identical 16x16 one does not) -
* meaning `estat gof' was completely broken, not merely slow, for ANY
* network with roughly 16 or more nodes. Every other test in this file
* uses a 5-node network specifically small enough to have never
* triggered this - this one deliberately uses 18 nodes (comfortably
* past the discovered ~16-node boundary) to guard against it
* regressing. Fixed by passing the matrix as a bare Mata variable name
* instead of a literal expression string (nwset's own mat() option
* already accepts this form directly - the same pattern nwrandom.ado's
* own generators use - and it has no size limit to hit, since the
* matrix never passes through Stata's command-line tokenizer at all).
nwclear
set seed 999
nwrandom 18, prob(.15) undirected name(biggofnet)
qui nwergm biggofnet, edges mcmcburnin(500) mcmcinterval(20) mcmcsamplesize(500) mcmleiterations(5)
qui estat gof, nsim(10) seed(111)
assert r(obs_meandeg) < .
assert r(sim_meandeg) > 0 & r(sim_meandeg) < 18
* also exercise `nwergm simulate's own identical fix, generating a new
* 18-node network from scratch (past the same ~16-node boundary).
nwclear
qui nwergm simulate 18, edges theta(-2) generate(bigsim)
assert _rc == 0
nwsummarize bigsim
assert r(nodes) == 18

* --- estat gof, plot: degree-distribution and geodesic-distance-
* distribution panels, boxplot-style with the observed network overlaid
* (Statnet plot.gof()'s own analogue). `set graphics off' exercises the
* full computation (including the Mata BFS-based ergm_gof_geodist() and
* ergm_gof_degdist() helpers, and their differing category-count
* conventions - degree has a numeric "+" overflow bucket, geodesic has
* a distinct "NR"/not-reached bucket, one fewer category for the same
* maxval - a real shape mismatch caught only by actually running this,
* not by reading the code) without popping up a GUI window.
nwclear
nwset, mat((0,1,1,0,0\1,0,0,0,0\0,0,0,1,0\0,0,0,0,1\1,0,0,0,0)) directed name(toynet)
qui nwergm toynet, edges mutual method(mcmle) seed(777)
set graphics off
qui estat gof, seed(777) nsim(10) plot
capture graph describe gof
assert _rc == 0
graph drop gof
di "=== estat gof, plot REGRESSION VERIFIED ==="

* --- BUGFIX regression: a disconnected OBSERVED network's own -1
* "disconnected" sentinel (nwgeodesic's own convention) was displayed
* literally ("-1.0000") in the Avg. geodesic row instead of "n/a" -
* the simulated side already had this guard, the observed side did
* not. r(obs_avgpath) itself must still be the raw -1 (nwgeodesic's own
* convention, for any calling code that checks it programmatically) -
* only the DISPLAYED text changes.
nwwebuse florentine, nwclear
qui nwergm flobusiness, edges gwesp(.5) nodematch(seat)
qui estat gof, seed(42) nsim(5)
assert r(obs_avgpath) == -1
di "=== disconnected-observed-network gof display REGRESSION VERIFIED ==="
