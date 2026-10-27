* nwsaom tutorial 11: simulation and what-if analysis
* Requires the core nwcommands and the package nwsaom.

nwwebuse glasgow, nwclear

* A fitted model over one period
nwsaom, wave1(glasgow1) wave2(glasgow2) outdegree reciprocity transtrip seed(4)
matrix b = e(b)
matrix list b

* Simulate the fitted model 100 times, starting from the observed first wave
estat simulate, nsim(100) seed(5)
matrix list r(obs)
matrix S = r(sim)
mata:
S = st_matrix("S")
printf("ties:       mean %5.1f, sd %5.1f\n", mean(S[., 3]), sqrt(variance(S[., 3])))
printf("mutual:     mean %5.1f, sd %5.1f\n", mean(S[., 4]), sqrt(variance(S[., 4])))
printf("transitive: mean %5.1f, sd %5.1f\n", mean(S[., 5]), sqrt(variance(S[., 5])))
end

* Save the simulated end networks and compare one with the observed
* second wave
estat simulate, nsim(3) seed(5) generate(sim)
nwsaom describe, waves(glasgow2 sim_1_p1)

* ---------------------------------------------------------------
* Simulation at chosen coefficients, without any estimation.
* theta() is in the order of the coefficient table: outdegree,
* reciprocity, transtrip; rates() has one rate per period.
* ---------------------------------------------------------------
nwsaom simulate, wave1(glasgow1) wave2(glasgow2) outdegree reciprocity transtrip theta(-2.7 2.4 0.6) rates(6) nsim(100) seed(5)

* The same world without any tendency to reciprocate
nwsaom simulate, wave1(glasgow1) wave2(glasgow2) outdegree reciprocity transtrip theta(-2.7 0 0.6) rates(6) nsim(100) seed(5)

* ---------------------------------------------------------------
* What if an effect did not operate? 'estat mems' switches one
* coefficient off and compares a network summary that you define.
* ---------------------------------------------------------------
capture program drop mutualties
program define mutualties, rclass
    args netname
    nwtomata `netname', mat(MM)
    mata: st_numscalar("__mut", sum(MM :* MM') / 2)
    return scalar stat = scalar(__mut)
end
quietly nwsaom, wave1(glasgow1) wave2(glasgow2) outdegree reciprocity transtrip seed(4)
estat mems, effect(reciprocity) macro(mutualties) nsim(100) seed(1)
