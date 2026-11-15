* nwdynam tutorial 1: a first DyNAM on an email event log
* Requires the core nwcommands and the package nwdynam.
* The data (manufacturing company emails) are loaded from the web; no files are needed.

nwdynam version

* --- the event data: one row per email, with the time it was sent (in days) ---
nwwebuse manufacturing, nwclear
keep if t < 5
list in 1/5
count
display "span in days: " %5.2f t[_N] - t[1]
duplicates report sender receiver

* --- declare the events as an event network ---
* The log mentions some of the 154 employees of the company; the others neither send nor receive
* an email in these five days. They still belong to the risk set, so we add them as isolates.
quietly levelsof sender, local(a) clean
quietly levelsof receiver, local(b) clean
local seen : list a | b
display "employees in the log: " `: word count `seen''
tempfile mail
save `mail'
nwwebuse manufacturing_nodes, nwclear
quietly levelsof label, local(everyone) clean
display "employees in the company file: " `: word count `everyone''
local without : list everyone - seen
display "employees without an email: " `: word count `without''
local miss
foreach e of local without {
    local miss `miss',`e'
}
local miss = substr("`miss'", 2, .)
use `mail', clear
nwset sender receiver, directed eventtime(t) name(mail)
nwaddnodes mail, nodenames(`miss')
nwset

* --- the choice sub-model (the default) ---
nwdynam mail
display "log likelihood: " %9.2f e(ll)

* --- the rate sub-model ---
nwdynam mail, submodel(rate)

* --- stored results ---
display "sub-model: " e(submodel) ", effects: " e(effects)
display "events: " e(N) ", actors: " e(nodes) ", log likelihood: " %9.2f e(ll)
