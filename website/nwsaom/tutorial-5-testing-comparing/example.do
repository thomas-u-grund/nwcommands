* nwsaom tutorial 5: testing and comparing effects
* Requires the core nwcommands and the package nwsaom.

nwwebuse glasgow, nwclear

* The full model: its coefficient order gives the theta0() order
nwsaom, waves(glasgow1 glasgow2 glasgow3) outdegree reciprocity transtrip egox(alcohol1) altx(alcohol1) simx(alcohol1) seed(1)
matrix b = e(b)
matrix list b

* Restricted model: the three alcohol effects held at zero
matrix b0 = b
foreach c in egox_alcohol1 altx_alcohol1 simx_alcohol1 {
    matrix b0[1, colnumb(b0, "`c'")] = 0
}
local th
forvalues j = 1/`=colsof(b0)' {
    local th `th' `=b0[1,`j']'
}
nwsaom, waves(glasgow1 glasgow2 glasgow3) outdegree reciprocity transtrip egox(alcohol1) altx(alcohol1) simx(alcohol1) theta0(`th') fix(egox(alcohol1) altx(alcohol1) simx(alcohol1)) seed(1)
estat score

* Time heterogeneity and relative importance in the full model
nwsaom, waves(glasgow1 glasgow2 glasgow3) outdegree reciprocity transtrip egox(alcohol1) altx(alcohol1) simx(alcohol1) seed(1)
estat timetest
estat importance
