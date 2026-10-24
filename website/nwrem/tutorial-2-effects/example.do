* nwrem tutorial 2: covariates, pair covariates and recency
* Requires the core nwcommands and the package nwrem.
* Run from this folder; the data are in ../data.

* --- declare the events (see tutorial 1) ---
import delimited "../data/calls_actors.csv", clear
tempfile actors
save `actors'
import delimited "../data/calls_events.csv", clear
levelsof sender, local(a) clean
levelsof receiver, local(b) clean
local all : list a | b
local miss
forvalues i = 1/84 {
    if !`: list i in all' local miss `miss',`i'
}
local miss = substr("`miss'", 2, .)
nwset sender receiver, directed eventtime(eventtime) name(calls)
nwaddnodes calls, nodenames(`miss')

* --- actor attributes, one row per actor in the actor order of the network ---
nwload calls, xvars
gen long actor = real(subinstr(_nwnode, "n", "", 1))
gen long row = _n
merge m:1 actor using `actors', keep(master match) nogenerate
sort row
list _nwnode actor floor in 1/4
list _nwnode actor floor in 55/58

* --- pair covariate: 1 if two students live on the same floor ---
mata:
F = st_data(., "floor")
n = rows(F)
S = J(n, n, 0)
for (i = 1; i <= n; i++) {
    for (j = 1; j <= n; j++) S[i, j] = (i != j) & (F[i] == F[j])
}
end
nwset, mat(S) name(sameflr) directed
nwset

* --- history of the pair (the model of tutorial 1) and actor covariates ---
nwrem calls, frpsndsnd frrecsnd
estimates store hist
nwrem calls, frpsndsnd frrecsnd covsnd(floor) covrec(floor)
estimates store floors
nwrem calls, frpsndsnd frrecsnd covevent(sameflr)
estimates store samefloor

* --- recent instead of frequent ---
nwrem calls, rsndsnd rrecsnd
estimates store recent
nwrem calls, frpsndsnd frrecsnd rsndsnd rrecsnd
estimates store both

estimates table hist floors samefloor recent both, b(%9.3f) stats(ll N)
lrtest floors hist
lrtest both hist
