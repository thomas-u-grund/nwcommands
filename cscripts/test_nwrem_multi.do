cscript

do unw_rem.do

* Certifies unw_rem.do's generalized multi-effect engine (units 2 + 5 +
* unit 4's static covariates - CovSnd/CovRec/CovInt/CovEvent - and unit
* 3's recency-rank effects RSndSnd/RRecSnd, docs/REM_ROADMAP.md):
* consistency with the already-certified unit-1 engine when configured
* identically, and exact analytic-vs-numerical gradient agreement for
* every one of the 14 effects individually and in combination - the same
* rigor Test 3 of test_nwrem_mata.do applied to unit 1, extended here
* rather than assuming it still holds.

di as text "{hline 60}"
di as text "Test 1: multi-engine with active=(NODSnd,NIDRec) matches RemFitUnit1 exactly"
di as text "{hline 60}"

mata:
mata set matastrict off

toy_events = (1,2,1 \ 1,3,2 \ 2,1,3 \ 1,2,4 \ 3,2,5 \ 2,3,6 \ 1,3,7 \ 3,1,8 \ 2,1,9 \ 1,3,10)
S1 = RemState()
S1.init(toy_events, 3)
S1.build_degree_accumulators()
nodummy = J(1,3,0)   // dummy per-actor covariate vector, reused for every call below where covariates are inactive
noevdummy = J(3,3,0)   // dummy n x n CovEvent matrix, reused where CovEvent is inactive

theta_test = (0.5, -0.3)
ll_unit1 = .
grad_unit1 = J(1,2,0)
rem_loglik_grad_unit1(theta_test, &S1, ll_unit1, grad_unit1)

active_12 = (1,1,0,0,0,0,0,0,0,0,0,0,0,0)
ll_multi = .
grad_multi = J(1,2,0)
rem_loglik_grad_multi(theta_test, active_12, nodummy, nodummy, nodummy, noevdummy, &S1, ll_multi, grad_multi)

printf("  unit1 ll=%14.10f  multi ll=%14.10f  diff=%g\n", ll_unit1, ll_multi, abs(ll_unit1-ll_multi))
printf("  unit1 grad=(%12.8f,%12.8f)  multi grad=(%12.8f,%12.8f)\n", grad_unit1[1], grad_unit1[2], grad_multi[1], grad_multi[2])
assert(reldif(ll_unit1, ll_multi) < 1e-10)
assert(max(abs(grad_unit1 - grad_multi)) < 1e-10)
end

di as text "{hline 60}"
di as text "Test 2: exact analytic-vs-numerical gradient match for every effect, one at a time"
di as text "{hline 60}"

mata:
effect_names = ("NODSnd","NIDRec","NIDSnd","NODRec","NTDegSnd","NTDegRec","FrPSndSnd","FrRecSnd","CovSnd","CovRec","CovInt","CovEvent","RSndSnd","RRecSnd")
h = 1e-6
maxerr_overall = 0
covtest = (0.7, -1.2, 0.4)   // a fixed, arbitrary per-actor covariate used to exercise effects 9-11
covevtest = (0,1.1,-0.6 \ 0.9,0,0.3 \ -0.4,0.7,0)   // a fixed, arbitrary n x n pairwise covariate (diagonal never read - excluded from the risk set) used to exercise effect 12

for (e=1; e<=14; e++) {
	active_e = J(1,14,0)
	active_e[e] = 1
	theta_e = (0.4)

	// effects 9/10/11 (CovSnd/CovRec/CovInt) need covtest in the matching
	// slot to have anything to differentiate with respect to; effect 12
	// (CovEvent) needs covevtest instead; effects 13/14 (RSndSnd/RRecSnd)
	// need no extra argument at all - their own gradient comes entirely
	// from toy_events' own real prior-contact history (S1), same as
	// effects 1-8; every other effect ignores whichever covariate
	// argument(s) it is passed.
	csv = nodummy
	crv = nodummy
	civ = nodummy
	cev = noevdummy
	if (e == 9) csv = covtest
	if (e == 10) crv = covtest
	if (e == 11) civ = covtest
	if (e == 12) cev = covevtest

	ll0 = .
	g0 = J(1,1,0)
	rem_loglik_grad_multi(theta_e, active_e, csv, crv, civ, cev, &S1, ll0, g0)

	llp = .
	gp = J(1,1,0)
	rem_loglik_grad_multi((theta_e[1]+h), active_e, csv, crv, civ, cev, &S1, llp, gp)
	llm = .
	gm = J(1,1,0)
	rem_loglik_grad_multi((theta_e[1]-h), active_e, csv, crv, civ, cev, &S1, llm, gm)

	numgrad = (llp - llm) / (2*h)
	err = abs(numgrad - g0[1])
	printf("  %-10s analytic=%12.8f  numerical=%12.8f  diff=%g\n", effect_names[e], g0[1], numgrad, err)
	if (err > maxerr_overall) maxerr_overall = err
}
printf("  max abs difference across all 14 effects: %g\n", maxerr_overall)
assert(maxerr_overall < 1e-5)
end

di as text "{hline 60}"
di as text "Test 3: exact analytic-vs-numerical gradient match with ALL 14 effects active together"
di as text "{hline 60}"

mata:
active_all = J(1,14,1)
theta_all = (0.3,-0.2,0.1,-0.15,0.25,-0.1,0.4,-0.3,0.2,-0.25,0.15,-0.2,0.1,-0.1)
csv = covtest
crv = covtest :+ 0.3   // deliberately a DIFFERENT vector from csv/civ, confirming CovSnd/CovRec/CovInt genuinely read their own independent argument, not accidentally sharing one
civ = covtest :- 0.5
cev = covevtest

ll0 = .
g0 = J(1,14,0)
rem_loglik_grad_multi(theta_all, active_all, csv, crv, civ, cev, &S1, ll0, g0)

numgrad_all = J(1,14,0)
for (e=1; e<=14; e++) {
	tp = theta_all
	tp[e] = tp[e] + h
	tm = theta_all
	tm[e] = tm[e] - h
	llp = .
	gp = J(1,14,0)
	rem_loglik_grad_multi(tp, active_all, csv, crv, civ, cev, &S1, llp, gp)
	llm = .
	gm = J(1,14,0)
	rem_loglik_grad_multi(tm, active_all, csv, crv, civ, cev, &S1, llm, gm)
	numgrad_all[e] = (llp - llm) / (2*h)
}
maxerr_all = max(abs(numgrad_all - g0))
"analytic:"
g0
"numerical:"
numgrad_all
printf("  max abs difference: %g\n", maxerr_all)
assert(maxerr_all < 1e-5)
end

di as text "{hline 60}"
di as text "Test 4: FrPSndSnd (inertia) recovers a known strong preference for a fixed partner"
di as text "{hline 60}"

* Simple, deterministic (not simulated) check: build a sequence where
* actor 1 sends to actor 2 far more often than to actor 3, and confirm
* a positive FrPSndSnd coefficient fits better than a negative one -
* the qualitative direction check this project's own established
* precedent uses for effects where tight point-recovery is not a
* reliable bar (docs/REM_R_STUDY.md section 3a-ii's own reasoning
* applies here too: inertia is itself a running-fraction statistic).

mata:
inertia_events = J(20, 3, 0)
for (t=1; t<=20; t++) {
	inertia_events[t,3] = t
	if (mod(t,4) == 0) {
		inertia_events[t,1] = 1
		inertia_events[t,2] = 3
	}
	else {
		inertia_events[t,1] = 1
		inertia_events[t,2] = 2
	}
}
// interleave a few events from other senders so actor 1 is not the only sender
inertia_events[2,1] = 2
inertia_events[2,2] = 3
inertia_events[6,1] = 3
inertia_events[6,2] = 2

Sin = RemState()
Sin.init(inertia_events, 3)
Sin.build_degree_accumulators()

active_7 = (0,0,0,0,0,0,1,0,0,0,0,0,0,0)
ll_pos = rem_loglik_multi((1.5), active_7, nodummy, nodummy, nodummy, noevdummy, &Sin)
ll_neg = rem_loglik_multi((-1.5), active_7, nodummy, nodummy, nodummy, noevdummy, &Sin)
printf("  ll at FrPSndSnd=+1.5: %10.4f    ll at FrPSndSnd=-1.5: %10.4f\n", ll_pos, ll_neg)
assert(ll_pos > ll_neg)
end

di as text "{hline 60}"
di as text "Test 5: CovSnd recovers a known strong preference driven by an actor attribute"
di as text "{hline 60}"

* Same qualitative-direction design as Test 4: give actor 2 a much
* higher covariate value than actors 1/3, build a sequence where actor
* 2 sends far more often than the others, and confirm a positive
* CovSnd coefficient fits better than a negative one.

mata:
covdir_events = J(18, 3, 0)
for (t=1; t<=18; t++) {
	covdir_events[t,3] = t
	if (mod(t,3) == 0) {
		covdir_events[t,1] = 1
		covdir_events[t,2] = 3
	}
	else {
		covdir_events[t,1] = 2
		covdir_events[t,2] = 3
	}
}
Scov = RemState()
Scov.init(covdir_events, 3)
Scov.build_degree_accumulators()

covdir_vec = (0, 5, 0)   // actor 2's covariate value is far higher than 1's or 3's
active_9 = (1,0,0,0,0,0,0,0,1,0,0,0,0,0)   // NODSnd + CovSnd together (NODSnd controls for the mechanical fact that actor 2 already sends more in this constructed sequence)
ll_covpos = rem_loglik_multi((0.1, 1.0), active_9, covdir_vec, nodummy, nodummy, noevdummy, &Scov)
ll_covneg = rem_loglik_multi((0.1, -1.0), active_9, covdir_vec, nodummy, nodummy, noevdummy, &Scov)
printf("  ll at CovSnd=+1.0: %10.4f    ll at CovSnd=-1.0: %10.4f\n", ll_covpos, ll_covneg)
assert(ll_covpos > ll_covneg)
end

di as text "{hline 60}"
di as text "Test 6: CovEvent recovers a known strong preference driven by a PAIRWISE attribute"
di as text "{hline 60}"

* Same qualitative-direction design as Test 5, but the driving attribute
* is now dyad-specific (unique to the (1,3) pair itself), not a
* property of either actor alone - exactly the distinction CovEvent
* exists to capture (relevent's own "event-wise"/mode=4 effect, see
* unw_rem.do's own header comment on rem_loglik_grad_multi()). Build a
* sequence where actor 1 sends to actor 3 far more often than to actor
* 2, give the (1,3) pair a much higher CovEvent value than (1,2), and
* confirm a positive CovEvent coefficient fits better than a negative
* one.

mata:
covev_events = J(18, 3, 0)
for (t=1; t<=18; t++) {
	covev_events[t,3] = t
	covev_events[t,1] = 1
	if (mod(t,3) == 0) {
		covev_events[t,2] = 2
	}
	else {
		covev_events[t,2] = 3
	}
}
Scovev = RemState()
Scovev.init(covev_events, 3)
Scovev.build_degree_accumulators()

covev_mat = J(3,3,0)
covev_mat[1,3] = 5   // the (1,3) pair - the one actor 1 favors here - has a far higher CovEvent value than (1,2)
covev_mat[1,2] = 0
active_12only = (1,0,0,0,0,0,0,0,0,0,0,1,0,0)   // NODSnd + CovEvent together (NODSnd controls for actor 1 mechanically sending more overall in this constructed sequence)
ll_covevpos = rem_loglik_multi((0.1, 1.0), active_12only, nodummy, nodummy, nodummy, covev_mat, &Scovev)
ll_covevneg = rem_loglik_multi((0.1, -1.0), active_12only, nodummy, nodummy, nodummy, covev_mat, &Scovev)
printf("  ll at CovEvent=+1.0: %10.4f    ll at CovEvent=-1.0: %10.4f\n", ll_covevpos, ll_covevneg)
assert(ll_covevpos > ll_covevneg)
end

di as text "{hline 60}"
di as text "Test 7: RSndSnd recovers a known strong preference for whoever was contacted MOST RECENTLY"
di as text "{hline 60}"

* RSndSnd is deliberately isolated from FrPSndSnd (frequency): actor 1
* alternates sending to actors 2 and 3 in PAIRS (send to the same
* partner twice in a row, then switch) - actor 1's own total counts to
* 2 and 3 end up TIED, so a frequency-based effect has nothing to latch
* onto, while a recency-based effect (repeat whoever was contacted
* MOST RECENTLY) explains the "send to the same partner twice in a
* row" pattern directly. Confirms RSndSnd captures something
* FrPSndSnd's own fraction-of-past-sends formula structurally cannot.

mata:
recency_events = J(20, 3, 0)
partners = (2,2,3,3,2,2,3,3,2,2,3,3,2,2,3,3,2,2,3,3)
for (t=1; t<=20; t++) {
	recency_events[t,3] = t
	recency_events[t,1] = 1
	recency_events[t,2] = partners[t]
}
// interleave a couple of foreign-sender events so actor 1 is not the only sender
recency_events[5,1] = 2
recency_events[5,2] = 3
recency_events[13,1] = 3
recency_events[13,2] = 2

Srec = RemState()
Srec.init(recency_events, 3)
Srec.build_degree_accumulators()

active_13 = (0,0,0,0,0,0,0,0,0,0,0,0,1,0)
ll_recpos = rem_loglik_multi((1.5), active_13, nodummy, nodummy, nodummy, noevdummy, &Srec)
ll_recneg = rem_loglik_multi((-1.5), active_13, nodummy, nodummy, nodummy, noevdummy, &Srec)
printf("  ll at RSndSnd=+1.5: %10.4f    ll at RSndSnd=-1.5: %10.4f\n", ll_recpos, ll_recneg)
assert(ll_recpos > ll_recneg)

// RRecSnd checks whether a sender tends to send BACK to whoever most
// recently sent TO them - a direct "reply" pattern: actor 1 initiates,
// and the receiver immediately replies to actor 1 (who is, at that
// point, their own most recent incoming contact). Alternates between
// actor 2 and actor 3 replying so no single dyad's own FREQUENCY
// dominates (each of 2->1 and 3->1 happens equally often - only the
// RECENCY-of-being-sent-to explains each reply).
reciprocity_events = J(16, 3, 0)
repl_partners = (2,3,2,3,2,3,2,3)
for (k=1; k<=8; k++) {
	reciprocity_events[2*k-1,.] = (1, repl_partners[k], 2*k-1)   // actor 1 initiates to the partner
	reciprocity_events[2*k,.] = (repl_partners[k], 1, 2*k)       // that partner replies immediately
}

Srecip = RemState()
Srecip.init(reciprocity_events, 3)
Srecip.build_degree_accumulators()

active_14 = (0,0,0,0,0,0,0,0,0,0,0,0,0,1)
ll_recippos = rem_loglik_multi((1.5), active_14, nodummy, nodummy, nodummy, noevdummy, &Srecip)
ll_recipneg = rem_loglik_multi((-1.5), active_14, nodummy, nodummy, nodummy, noevdummy, &Srecip)
printf("  ll at RRecSnd=+1.5: %10.4f    ll at RRecSnd=-1.5: %10.4f\n", ll_recippos, ll_recipneg)
assert(ll_recippos > ll_recipneg)
end

di as text "{hline 60}"
di as result "ALL TESTS PASSED"
