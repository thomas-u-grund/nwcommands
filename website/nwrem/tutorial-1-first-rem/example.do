* nwrem tutorial 1: a first relational event model on an email log
* Requires the core nwcommands and the package nwrem.
* The data (Michalski 2020, CC0) are loaded from the nwcommands website.

nwrem version

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

* --- a model of activity: do busy senders and popular receivers keep their roles? ---
nwrem mail, nodsnd nidrec

* --- a model of history: do people write to those they wrote to, or who wrote to them? ---
nwrem mail, frpsndsnd frrecsnd
display "events: " e(N) ", actors: " e(nodes) ", log likelihood: " %9.2f e(ll)
display "effect of inertia on the odds: x" %6.1f exp(_b[frpsndsnd] * 0.1) " per 10 percentage points"

* --- both together ---
nwrem mail, nodsnd nidrec frpsndsnd frrecsnd
