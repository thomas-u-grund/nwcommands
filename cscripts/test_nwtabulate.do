cscript

do unw_core.do

nwclear
do cscripts/test_nwtab1.do
do cscripts/test_nwtab2.do
do cscripts/test_nwtab3.do

* --- failure path: more than 2 networks. nw_syntax's own max(2) check
* (the first thing nwtabulate calls) rejects this before ever reaching
* the dispatcher's own separate "Maximum two networks allowed" branch
* below it - confirmed directly (that later branch is unreachable in
* practice, not a bug: nw_syntax already errors first).
nwclear
nwrandom 5, prob(.5) name(tabA)
nwrandom 5, prob(.5) name(tabB)
nwrandom 5, prob(.5) name(tabC)
capture noisily nwtabulate tabA tabB tabC
assert _rc == 482




