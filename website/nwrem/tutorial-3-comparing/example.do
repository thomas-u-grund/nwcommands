* nwrem tutorial 3: comparing specifications and limits
* Requires the core nwcommands and the package nwrem.
* The data (Michalski 2020, CC0) are loaded from the nwcommands website.

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

* --- five specifications ---
quietly nwrem mail, nodsnd nidrec
estimates store m1
quietly nwrem mail, frpsndsnd frrecsnd
estimates store m2
quietly nwrem mail, nodsnd nidrec frpsndsnd frrecsnd
estimates store m3
quietly nwrem mail, rsndsnd rrecsnd
estimates store m4
quietly nwrem mail, nodsnd nidrec rsndsnd rrecsnd
estimates store m5

* --- compare: log likelihood, number of parameters, AIC and BIC ---
estimates stats m1 m2 m3 m4 m5
lrtest m3 m1
lrtest m3 m2

* --- do the estimates depend on the optimiser's starting point? ---
nwrem mail, nodsnd nidrec frpsndsnd frrecsnd seed(1)
nwrem mail, nodsnd nidrec frpsndsnd frrecsnd seed(2)

* --- what is refused ---
capture noisily nwrem mail
display "return code: " _rc
capture noisily nwrem mail, frpsndsnd covsnd(nosuchvar)
display "return code: " _rc

* --- a network that is not an event network ---
nwrandom 8, prob(.3) name(ordinary)
capture noisily nwrem ordinary, nodsnd
display "return code: " _rc
