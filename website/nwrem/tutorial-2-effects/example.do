* nwrem tutorial 2: covariates, pair covariates and recency
* Requires the core nwcommands and the package nwrem.
* The data (Michalski 2020, CC0) are loaded from the nwcommands website.

* --- the employees: supervisor, level and division ---
nwwebuse manufacturing_nodes, nwclear
tempfile staff
save `staff'

* --- the event data: one row per email, with the time it was sent (days since 1 January 2010) ---
nwwebuse manufacturing, nwclear
list in 1/5
count

* --- a short window: the emails of the first five days of the data ---
* All 144 employees could have sent or received an email, but fewer appear in the window.
* The others are still possible senders and receivers, so we add them as isolates.
levelsof sender, local(a) clean
levelsof receiver, local(b) clean
local all : list a | b
keep if t < 5
count
display "span in days: " %5.2f (t[_N] - t[1])

* --- declare the events as an event network ---
levelsof sender, local(a) clean
levelsof receiver, local(b) clean
local present : list a | b
local miss : list all - present
display "employees in the window: " `: word count `present'' ", added as isolates: " `: word count `miss''
nwset sender receiver, directed eventtime(t) name(mail)
local miss : subinstr local miss " " ",", all
nwaddnodes mail, nodenames(`miss')
nwset

* --- actor attributes, one row per actor in the actor order of the network ---
nwload mail, xvars
gen str4 label = _nwnode
gen long row = _n
merge m:1 label using `staff', keep(master match) nogenerate
sort row
list _nwnode level supervisor division in 1/4
tabulate level

* --- pair covariate: 1 if two employees have the same direct supervisor ---
mata:
V = st_sdata(., "supervisor")
n = rows(V)
S = J(n, n, 0)
for (i = 1; i <= n; i++) {
    for (j = 1; j <= n; j++) S[i, j] = (i != j) & (V[i] != "") & (V[i] == V[j])
}
end
nwset, mat(S) name(samesup) directed
nwset

* --- history of the pair (the model of tutorial 1) and actor covariates ---
nwrem mail, frpsndsnd frrecsnd
estimates store hist
nwrem mail, frpsndsnd frrecsnd covsnd(level) covrec(level)
estimates store levels
nwrem mail, frpsndsnd frrecsnd covevent(samesup)
estimates store samesuper

* --- recent instead of frequent ---
nwrem mail, rsndsnd rrecsnd
estimates store recent
nwrem mail, frpsndsnd frrecsnd rsndsnd rrecsnd
estimates store both

estimates table hist levels samesuper recent both, b(%9.3f) stats(ll N)
lrtest levels hist
lrtest both hist
