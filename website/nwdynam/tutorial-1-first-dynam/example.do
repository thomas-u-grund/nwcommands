* nwdynam tutorial 1: a first DyNAM on a phone-call event log
* Requires the core nwcommands and the package nwdynam.
* Run from this folder; the data are in ../data (events and actor attributes).

nwdynam version

* --- the event data: one row per call, with the time it happened ---
import delimited "../data/calls_events.csv", clear
list in 1/5
count
display "span in days: " (eventtime[_N] - eventtime[1]) / 86400
duplicates report sender receiver

* --- declare the events as an event network ---
* The log mentions 54 of the 84 students; the other 30 never call or are called.
* They still belong to the risk set, so we add them as isolates.
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
nwset

* --- the choice sub-model (the default) ---
nwdynam calls

* --- the rate sub-model ---
nwdynam calls, submodel(rate)

* --- stored results ---
display "sub-model: " e(submodel) ", effects: " e(effects)
display "events: " e(N) ", actors: " e(nodes) ", log likelihood: " %9.2f e(ll)
display "odds ratio of reciprocity in the choice model: " %6.2f exp(1.389441)
