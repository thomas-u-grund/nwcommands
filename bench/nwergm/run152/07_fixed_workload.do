* Reviewer note, measurement 2, Stata side: one MCMLE iteration from the MPLE with a fixed sample (4,000 draws,
* interval 1,024, burn-in 16,384), the adaptive sample size switched off and no log-likelihood. With these settings
* nwergm calls its sampler twice: for the sample of the iteration, and for a fresh sample at the final coefficients
* from which the covariance matrix is computed. For the second sample it doubles the interval while the sample is
* strongly autocorrelated; e(mcmc_interval_final) reports the interval it used. The proposals are therefore
* (16,384 + 4,000 x 1,024) + (16,384 + 4,000 x e(mcmc_interval_final)).
* Prints the seconds, the proposals and the microseconds per proposal.   stata -e do stata/07_fixed_workload.do Lazega
args id
do stata/setup.do
include stata/benchmark_models.do
local opts "mcmleeffectivesize(0) mcmcsamplesize(4000) mcmcinterval(1024) mcmcburnin(16384) mcmleiterations(1) nologlik"
capture quietly nwergm `net', `cmd' `opts' seed(99)
timer clear 7
timer on 7
capture quietly nwergm `net', `cmd' `opts' seed(1)
timer off 7
quietly timer list 7
local props = (16384 + 4000 * 1024) + (16384 + 4000 * e(mcmc_interval_final))
display "@@FIXED nwergm `id' " %9.3f r(t7) " `props' " %9.3f 1e6 * r(t7) / `props'
