* nwrem tutorial 1: a first relational event model on a phone-call log
* Requires the core nwcommands and the package nwrem.
* Run from this folder; the data are in ../data (events and actor attributes).

nwrem version

* --- the event data: one row per call, with the time it happened ---
import delimited "../data/calls_events.csv", clear
list in 1/5
count
display "span in days: " (eventtime[_N] - eventtime[1]) / 86400

* --- declare the events as an event network ---
* The log mentions 54 of the 84 students; the other 30 never call or are called.
* They still are possible senders and receivers, so we add them as isolates.
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

* --- a model of activity: do busy senders and popular receivers keep their roles? ---
nwrem calls, nodsnd nidrec

* --- a model of history: do people call those they called, or who called them? ---
nwrem calls, frpsndsnd frrecsnd
display "events: " e(N) ", actors: " e(nodes) ", log likelihood: " %9.2f e(ll)
display "effect of inertia on the odds: x" %6.1f exp(_b[frpsndsnd] * 0.1) " per 10 percentage points"

* --- both together ---
nwrem calls, nodsnd nidrec frpsndsnd frrecsnd
