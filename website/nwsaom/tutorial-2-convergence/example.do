* nwsaom tutorial 2: reading convergence, and what to do when it fails
* Requires the core nwcommands and the package nwsaom.

nwwebuse glasgow, nwclear

* A rich model estimated with a deliberately short third phase (k3(100)):
* the estimates are noisy and the run does not converge
nwsaom, waves(glasgow1 glasgow2 glasgow3) outdegree reciprocity gwesp(.69) indegpopularity outactivity egox(alcohol1) altx(alcohol1) simx(alcohol1) samex(smoke1) transtrip cycle3 seed(1) k3(100) detail

* The convergence t-ratios are stored
matrix list e(tconv)

* Restart from the estimates: nwsaom refit reruns the last command with the
* estimates as starting values; k3(1000) restores the default third phase,
* and maxruns(3) repeats it until the fit has converged (at most three runs)
nwsaom refit, seed(2) k3(1000) maxruns(3)

* Wald tests with Stata's own commands
test egox_alcohol1 = altx_alcohol1
lincom egox_alcohol1 - altx_alcohol1
