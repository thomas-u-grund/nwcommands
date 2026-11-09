* Table 3 and Figure 6, Stata side: one timed nwergm fit of benchmark <id> with seed <r>, after one untimed
* warm-up fit.   stata -e do stata/03_benchmark_fit.do Lazega 1
* Writes "@@B8 <id> <seed> <seconds> <iterations>" to the log. tools/run_benchmark.sh runs all models and seeds.
args id r
do stata/setup.do
include stata/benchmark_models.do
quietly nwergm `net', `cmd' seed(99)
timer clear 8
timer on 8
quietly nwergm `net', `cmd' seed(`r')
timer off 8
quietly timer list 8
di "@@B8 `id' `r' " %9.3f r(t8) " " e(mcmle_iterations)
