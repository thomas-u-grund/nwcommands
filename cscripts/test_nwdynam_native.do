cscript

do unw_core.do
do unw_ergm.do
do unw_dynam.do

/*
	Certifies the native (C) DyNAM log-likelihood/gradient plugin
	(native/dynam_sim.c) against its own Mata reference implementation.
	Like nwgraph.c's own betweenness kernel (cscripts/test_nwgraph_native.do)
	and UNLIKE nwergm's own stochastic MCMC backend, this is a
	DETERMINISTIC, exact numerical computation - native and Mata must
	agree up to ordinary floating-point summation-order noise, not a
	statistical tolerance (see dynam_sim.c's own header CERTIFICATION
	CONTRACT).

	(1) DynamNativeAvailable()/DynamNativePluginPath() resolve to a
	    real, existing file on this platform (macOS, built via
	    native/Makefile's own `make macos-dynam_sim` target).
	(2) The native evaluator (dynam_choice_eval_unit1_native()/
	    dynam_rate_eval_unit1_native()) reproduces the Mata evaluator
	    (dynam_choice_loglik_grad_unit1()/dynam_rate_loglik_grad_unit1())
	    EXACTLY (ll to 1e-9, gradient to 1e-9) at several different theta
	    vectors - not just at the eventual MLE - on a small hand-built
	    event stream with repeat contacts (so inertia/recip/indeg are
	    all genuinely exercised, not left at their all-zero first-event
	    values throughout).
	(3) DynamFitUnit1()/DynamFitRateUnit1() (the full fit, not just one
	    evaluation) converge to the same coefficients whether native is
	    available or not - confirmed by forcing the Mata fallback path
	    directly (temporarily renaming the plugin file) and comparing
	    against the native-backed default run on identical data, same
	    pattern test_nwgraph_native.do's own part (3) uses.
*/

mata: mata set matastrict off
mata: printf("DynamNativeAvailable() = %g (path: %s)\n", DynamNativeAvailable(), DynamNativePluginPath())
mata: assert(DynamNativeAvailable() == 1)

// Small hand-built event stream, 5 actors, repeat contacts included
// (1->2 happens twice, 3->1 happens twice) so inertia/recip/indeg are
// all genuinely nonzero and exercised by event 5 onward, not just the
// trivial all-zero first-event case every effect starts at.
mata:
S = DynamState()
S.init((1,2,1 \ 2,1,2 \ 3,1,3 \ 1,2,4 \ 3,1,5 \ 4,3,6 \ 2,4,7 \ 5,1,8), 5)
end

// --- (2) choice sub-model: several theta vectors, not just the MLE ---
mata:
ll_mata = .
ll_native = .
grad_mata = J(1,3,.)
grad_native = J(1,3,.)
dummyH = J(1,1,.)

thetas_choice = (0,0,0 \ 0.5,-0.3,0.2 \ -1.1,2.4,-0.6 \ 3,3,3)
for (row=1; row<=rows(thetas_choice); row++) {
	theta = thetas_choice[row,.]
	dynam_choice_loglik_grad_unit1(theta, &S, ll_mata, grad_mata)

	origframe = st_framecurrent()
	stata("capture frame drop __nwdynam_native")
	stata("frame create __nwdynam_native")
	st_framecurrent("__nwdynam_native")
	st_addobs(max((S.nevents, 4)))
	__j1 = st_addvar("double", "v1")
	__j2 = st_addvar("double", "v2")
	__j3 = st_addvar("double", "v3")
	st_store((1::S.nevents), ("v1","v2"), S.events[.,(1,2)])
	stata("capture program dynamnative, plugin using(" + char(34) + DynamNativePluginPath() + char(34) + ")")
	dynam_choice_eval_unit1_native(1, theta, &S, ll_native, grad_native, dummyH)
	st_framecurrent(origframe)
	stata("capture frame drop __nwdynam_native")

	printf("choice row %g: |ll diff|=%g  |grad diff|=%g\n", row, abs(ll_mata - ll_native), max(abs(grad_mata - grad_native)))
	assert(abs(ll_mata - ll_native) < 1e-9)
	assert(max(abs(grad_mata - grad_native)) < 1e-9)
}
end

// --- (2) rate sub-model: several theta vectors ---
mata:
ll_mata = .
ll_native = .
grad_mata = J(1,2,.)
grad_native = J(1,2,.)
dummyH = J(1,1,.)

thetas_rate = (0,0 \ 0.5,-0.3 \ -1.1,2.4 \ 3,3)
for (row=1; row<=rows(thetas_rate); row++) {
	theta = thetas_rate[row,.]
	dynam_rate_loglik_grad_unit1(theta, &S, ll_mata, grad_mata)

	origframe = st_framecurrent()
	stata("capture frame drop __nwdynam_native")
	stata("frame create __nwdynam_native")
	st_framecurrent("__nwdynam_native")
	st_addobs(max((S.nevents, 3)))
	__j1 = st_addvar("double", "v1")
	__j2 = st_addvar("double", "v2")
	__j3 = st_addvar("double", "v3")
	st_store((1::S.nevents), ("v1","v2"), S.events[.,(1,2)])
	stata("capture program dynamnative, plugin using(" + char(34) + DynamNativePluginPath() + char(34) + ")")
	dynam_rate_eval_unit1_native(1, theta, &S, ll_native, grad_native, dummyH)
	st_framecurrent(origframe)
	stata("capture frame drop __nwdynam_native")

	printf("rate row %g: |ll diff|=%g  |grad diff|=%g\n", row, abs(ll_mata - ll_native), max(abs(grad_mata - grad_native)))
	assert(abs(ll_mata - ll_native) < 1e-9)
	assert(max(abs(grad_mata - grad_native)) < 1e-9)
}
end

// --- (3) full nwdynam.ado fits, native vs. forced-Mata-fallback,
//     identical data ---
nwclear
clear
set obs 200
gen long sender = .
gen long receiver = .
gen eventtime = _n
mata:
rseed(20260902)
n = 8
for (i=1; i<=200; i++) {
	pair = runiformint(1, 2, 1, n)
	while (pair[1] == pair[2]) pair = runiformint(1, 2, 1, n)
	st_store(i, "sender", pair[1])
	st_store(i, "receiver", pair[2])
}
end
nwset sender receiver, eventtime(eventtime) name(cmpnet)

nwdynam cmpnet
matrix b_native_choice = e(b)
nwdynam cmpnet, submodel(rate)
matrix b_native_rate = e(b)

mata: st_local("pluginpath", DynamNativePluginPath())
local movedplugin "`pluginpath'.disabled_for_test"
capture erase "`movedplugin'"
qui copy "`pluginpath'" "`movedplugin'", replace
qui erase "`pluginpath'"

nwdynam cmpnet
matrix b_mata_choice = e(b)
nwdynam cmpnet, submodel(rate)
matrix b_mata_rate = e(b)

qui copy "`movedplugin'" "`pluginpath'", replace
qui erase "`movedplugin'"

mata: assert(max(abs(st_matrix("b_native_choice") - st_matrix("b_mata_choice"))) < 0.01)
mata: assert(max(abs(st_matrix("b_native_rate") - st_matrix("b_mata_rate"))) < 0.01)
di as text "choice: native=" b_native_choice[1,1] " " b_native_choice[1,2] " " b_native_choice[1,3] "   mata=" b_mata_choice[1,1] " " b_mata_choice[1,2] " " b_mata_choice[1,3]
di as text "rate:   native=" b_native_rate[1,1] " " b_native_rate[1,2] "   mata=" b_mata_rate[1,1] " " b_mata_rate[1,2]

di "test_nwdynam_native: ALL OK"
