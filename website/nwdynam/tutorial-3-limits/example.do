* nwdynam tutorial 3: what a small event log can and cannot tell you
* Requires the core nwcommands and the package nwdynam.
* Run from this folder; the data are in ../data.

* --- a ten-event toy log (the example of the help file) ---
clear
input sender receiver t
1 2 1
1 3 2
2 1 3
1 2 4
3 2 5
2 3 6
1 3 7
3 1 8
2 1 9
1 3 10
end
nwset sender receiver, directed eventtime(t) name(chat)
nwdynam chat

* --- the real log: the first 60 events, then all 439 ---
* (the same 84 students in the risk set both times)
import delimited "../data/calls_events.csv", clear
tempfile all
save `all'
foreach n in 60 120 240 439 {
    use `all', clear
    keep in 1/`n'
    levelsof sender, local(a) clean
    levelsof receiver, local(b) clean
    local seen : list a | b
    local miss
    forvalues i = 1/84 {
        if !`: list i in seen' local miss `miss',`i'
    }
    local miss = substr("`miss'", 2, .)
    nwset sender receiver, directed eventtime(eventtime) name(first`n')
    nwaddnodes first`n', nodenames(`miss')
}
nwdynam first60, inertia recip
nwdynam first439, inertia recip

* --- how the precision of 'recip' grows with the number of events ---
foreach n in 60 120 240 439 {
    quietly nwdynam first`n', inertia recip
    matrix b = e(b)
    matrix V = e(V)
    display "events " %3.0f e(N) ":  recip = " %6.3f b[1,2] "   s.e. = " %6.3f sqrt(V[2,2])
}

* --- more effects on the short log ---
nwdynam first60, inertia recip indeg trans

* --- effects that do not belong to a sub-model are refused ---
capture noisily nwdynam first439, submodel(rate) recip
display "return code: " _rc
