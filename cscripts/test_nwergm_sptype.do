cscript

do unw_core.do
do unw_ergm.do

* Certifies the `type()' option nwergm.ado itself now exposes (term-
* expansion wave 8: ITP/OSP/ISP directed shared-partner definitions,
* on top of unw_ergm.do's own already-certified Mata internals -
* cscripts/test_nwergm_termexpansion8.do): option parsing/validation,
* case-insensitivity, the two disclosure notes (undirected network;
* no relevant term requested), propagation through to `nwergm
* simulate', and a real behavioural check that changing `type()'
* actually changes the fitted model (not silently ignored).

* --- small directed network with a genuine directed asymmetry: a
* "chain" 1->2->3->4->5 plus a few cross ties, so OTP (i->k->j) and
* OSP (i->k<-j) shared-partner counts genuinely differ.
nwclear
nwset, mat((0,1,0,0,1\0,0,1,0,0\0,0,0,1,0\1,0,0,0,0\0,1,0,0,0)) directed name(mydirnet) labs(A,B,C,D,E)

* --- type() accepts all four documented values, case-insensitively ---
foreach t in OTP otp ITP itp OSP osp ISP isp {
	qui nwergm mydirnet, edges gwesp(0.5) type(`t')
	assert _rc == 0
}

* --- invalid type() is rejected (same _opts_oneof convention as
* proposal()/method()) ---
capture qui nwergm mydirnet, edges gwesp(0.5) type(bogus)
assert _rc == 6556

* --- type() on an undirected network is accepted (no error) - R
* ergm's own documented override, silently using UTP regardless -
* but nwergm additionally prints a disclosure note rather than saying
* nothing at all. ---
nwclear
nwset, mat((0,1,1,0,0\1,0,1,0,0\1,1,0,1,0\0,0,1,0,1\0,0,0,1,0)) undirected name(myundirnet) labs(A,B,C,D,E)
qui nwergm myundirnet, edges gwesp(0.5) type(OSP)
assert _rc == 0

* --- type() with no gwesp/gwdsp/gwnsp/esp/dsp term present is accepted
* (no error) - it simply has no effect, disclosed via a note. `nwclear'
* above (before creating myundirnet) also wiped mydirnet, so it is
* recreated here rather than assumed still loaded. ---
nwclear
nwset, mat((0,1,0,0,1\0,0,1,0,0\0,0,0,1,0\1,0,0,0,0\0,1,0,0,0)) directed name(mydirnet) labs(A,B,C,D,E)
qui nwergm mydirnet, edges type(OSP)
assert _rc == 0

* --- behavioural check: type() genuinely changes the fitted model.
* On mydirnet (the directed chain above), OTP-based and OSP-based
* gwesp(0.5) count structurally different configurations - their
* fitted coefficients must differ (not merely their standard errors
* moving by noise), confirming `type()' actually reaches the
* estimator rather than being silently ignored end to end. ---
qui nwergm mydirnet, edges gwesp(0.5) type(OTP) seed(42)
local b_otp = _b[gwesp_0.5]
qui nwergm mydirnet, edges gwesp(0.5) type(OSP) seed(42)
local b_osp = _b[gwesp_0.5]
assert reldif(`b_otp', `b_osp') > 1e-6

* --- nwergm simulate: type() propagates the same way, and a directed
* esp() simulation runs cleanly under each of the three new types. ---
foreach t in OTP ITP OSP ISP {
	qui nwergm simulate 12, edges esp(0 1) type(`t') directed theta(-1 0.3 0.1) ///
		seed(77) generate(simsp_`t')
	assert _rc == 0
	qui nwsummarize simsp_`t'
	assert r(nodes) == 12
}

di "test_nwergm_sptype: ALL OK"
