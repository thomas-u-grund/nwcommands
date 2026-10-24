* nwdynam tutorial 2: effects, covariates and comparing models
* Requires the core nwcommands and the package nwdynam.
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

* --- put the actor attributes into the data, in the actor order of the network ---
nwload calls, xvars
gen long actor = real(subinstr(_nwnode, "n", "", 1))
gen long row = _n
merge m:1 actor using `actors', keep(master match) nogenerate
sort row
list _nwnode actor floor gradetype in 1/4
list _nwnode actor floor gradetype in 55/58
tabulate floor

* --- the baseline choice model, then homophily on the floor of the dorm ---
nwdynam calls, inertia recip indeg
estimates store base
nwdynam calls, inertia recip indeg same(floor)
estimates store samefloor
estimates table base samefloor, b(%9.3f) stats(ll N)
lrtest samefloor base

* --- closure effects ---
nwdynam calls, inertia recip indeg trans
nwdynam calls, inertia recip indeg nodetrans

* --- recency: should an old call still count? ---
nwdynam calls, inertiawindow(604800) recip indeg
nwdynam calls, weightedinertia recip indeg

* --- the rate model with a covariate ---
nwdynam calls, submodel(rate) indeg outdeg
estimates store rate0
nwdynam calls, submodel(rate) indeg outdeg ego(floor)
estimates store rate1
lrtest rate1 rate0
