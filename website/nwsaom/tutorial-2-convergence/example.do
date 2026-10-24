* nwsaom tutorial 2: reading convergence, and what to do when it fails
* Requires the core nwcommands and the package nwsaom.

nwwebuse glasgow, nwclear

* A rich model estimated with a deliberately short third phase (k3(100)):
* the estimates are noisy and the run does not converge
nwsaom, waves(glasgow1 glasgow2 glasgow3) outdegree reciprocity gwesp(.69) indegpopularity outactivity egox(alcohol1) altx(alcohol1) simx(alcohol1) samex(smoke1) transtrip cycle3 seed(1) k3(100) detail

* The convergence t-ratios are stored
matrix list e(tconv)

* Restart from the estimates: pass them as starting values
matrix b = e(b)
local th
forvalues j = 1/`=colsof(b)' {
    local th `th' `=b[1,`j']'
}
display "`th'"
nwsaom, waves(glasgow1 glasgow2 glasgow3) outdegree reciprocity gwesp(.69) indegpopularity outactivity egox(alcohol1) altx(alcohol1) simx(alcohol1) samex(smoke1) transtrip cycle3 seed(2) theta0(`th') detail

* Wald tests with Stata's own commands
test egox_alcohol1 = altx_alcohol1
lincom egox_alcohol1 - altx_alcohol1
