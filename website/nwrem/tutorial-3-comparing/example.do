* nwrem tutorial 3: comparing specifications and limits
* Requires the core nwcommands and the package nwrem.
* Run from this folder; the data are in ../data.

* --- declare the events (see tutorial 1) ---
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

* --- five specifications ---
quietly nwrem calls, nodsnd nidrec
estimates store m1
quietly nwrem calls, frpsndsnd frrecsnd
estimates store m2
quietly nwrem calls, nodsnd nidrec frpsndsnd frrecsnd
estimates store m3
quietly nwrem calls, rsndsnd rrecsnd
estimates store m4
quietly nwrem calls, nodsnd nidrec rsndsnd rrecsnd
estimates store m5

* --- compare: log likelihood, number of parameters, AIC and BIC ---
estimates stats m1 m2 m3 m4 m5
lrtest m3 m1
lrtest m3 m2

* --- do the estimates depend on the optimiser's starting point? ---
nwrem calls, nodsnd nidrec frpsndsnd frrecsnd seed(1)
nwrem calls, nodsnd nidrec frpsndsnd frrecsnd seed(2)

* --- what is refused ---
capture noisily nwrem calls
display "return code: " _rc
capture noisily nwrem calls, frpsndsnd covsnd(nosuchvar)
display "return code: " _rc

* --- a network that is not an event network ---
nwrandom 8, prob(.3) name(ordinary)
capture noisily nwrem ordinary, nodsnd
display "return code: " _rc
