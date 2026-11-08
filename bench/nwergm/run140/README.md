# nwergm 1.4.0 against 1.3.7 and ergm 4.12.0 (8 November 2026)

The eight benchmark models of the nwergm article and manual, seven seeds each. For every seed and model the three
programs ran in turn (ergm, nwergm 1.3.7, nwergm 1.4.0), each fit in its own process after one untimed warm-up fit
(seed 99); the time is that of the estimation call alone. Apple M5 Pro, macOS, Stata 18 BE, R 4.6.0, nwcommands
core 3.17.1. The machine was not idle: the one-minute load average before each fit (`load_before_each_fit.txt`)
was 3.1 to 6.3, median 4.6.

- `results.csv`: program, model, seed, seconds, Monte Carlo iterations (168 fits).
- `postestimation.csv`: single runs of 1.3.7 and 1.4.0 of `estat gof`, `nwergm simulate, nsim(100)` and the fit by
  stochastic approximation (`postestimation.do`, models `lazega`, `mesa`, `p1000`).
- `b8.do`, `b8.R`, `run8.sh`: the scripts. `run8.sh` expects the subfolders `base` and `new`, each with a `hdr.do`
  that puts the core and the nwergm version to be timed on the adopath; the networks are those of `../networks`
  (gunzip the three `.gz` files first).
