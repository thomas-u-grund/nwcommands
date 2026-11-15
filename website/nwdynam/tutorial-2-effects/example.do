* nwdynam tutorial 2: effects, covariates and comparing models
* Requires the core nwcommands and the package nwdynam.
* The data (manufacturing company emails and the reporting hierarchy) are loaded from the web.

* --- the actor attributes: level in the hierarchy and division (one row per employee) ---
nwwebuse manufacturing_nodes, nwclear
encode division, generate(div)
tempfile actors
save `actors'
quietly levelsof label, local(everyone) clean

* --- declare the events (see tutorial 1) ---
nwwebuse manufacturing, nwclear
keep if t < 5
quietly levelsof sender, local(a) clean
quietly levelsof receiver, local(b) clean
local seen : list a | b
local without : list everyone - seen
local miss
foreach e of local without {
    local miss `miss',`e'
}
local miss = substr("`miss'", 2, .)
nwset sender receiver, directed eventtime(t) name(mail)
nwaddnodes mail, nodenames(`miss')

* --- put the actor attributes into the data, in the actor order of the network ---
nwload mail, xvars
gen long row = _n
rename _nwnode label
merge m:1 label using `actors', keep(master match) nogenerate
sort row
list label level div in 1/4
list label level div in 130/133
tabulate level

* --- the baseline choice model, then homophily on the division ---
nwdynam mail, inertia recip indeg
estimates store base
nwdynam mail, inertia recip indeg same(div)
estimates store samediv
estimates table base samediv, b(%9.3f) stats(ll N)
lrtest samediv base

* --- closure effects ---
nwdynam mail, inertia recip indeg trans
display "log likelihood: " %9.2f e(ll)
nwdynam mail, inertia recip indeg nodetrans
display "log likelihood: " %9.2f e(ll)

* --- recency: should an old email still count? ---
nwdynam mail, inertiawindow(0.5) recip indeg
display "log likelihood: " %9.2f e(ll)
nwdynam mail, weightedinertia recip indeg
display "log likelihood: " %9.2f e(ll)

* --- the rate model with a covariate ---
nwdynam mail, submodel(rate) indeg outdeg
estimates store rate0
nwdynam mail, submodel(rate) indeg outdeg ego(level)
estimates store rate1
lrtest rate1 rate0
