* nwdynam tutorial 3: what a small event log can and cannot tell you
* Requires the core nwcommands and the package nwdynam.
* The data (manufacturing company emails) are loaded from the web.

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

* --- the real log: the first 60 events, then more, up to all 631 of the first five days ---
* (the same 154 employees in the risk set every time)
nwwebuse manufacturing_nodes, nwclear
quietly levelsof label, local(everyone) clean
nwwebuse manufacturing, nwclear
keep if t < 5
tempfile all
save `all'
foreach n in 60 150 300 631 {
    use `all', clear
    keep in 1/`n'
    quietly levelsof sender, local(a) clean
    quietly levelsof receiver, local(b) clean
    local seen : list a | b
    local without : list everyone - seen
    local miss
    foreach e of local without {
        local miss `miss',`e'
    }
    local miss = substr("`miss'", 2, .)
    nwset sender receiver, directed eventtime(t) name(first`n')
    nwaddnodes first`n', nodenames(`miss')
}
nwdynam first60, inertia recip
nwdynam first631, inertia recip

* --- how the precision of 'recip' grows with the number of events ---
foreach n in 60 150 300 631 {
    quietly nwdynam first`n', inertia recip
    matrix b = e(b)
    matrix V = e(V)
    display "events " %4.0f e(N) ":  recip = " %6.3f b[1,2] "   s.e. = " %6.3f sqrt(V[2,2])
}

* --- more effects on the short log ---
nwdynam first60, inertia recip indeg trans

* --- effects that do not belong to a sub-model are refused ---
capture noisily nwdynam first631, submodel(rate) recip
display "return code: " _rc
