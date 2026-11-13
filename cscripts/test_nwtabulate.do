cscript

do unw_core.do

nwclear
do cscripts/test_nwtab1.do
do cscripts/test_nwtab2.do
do cscripts/test_nwtab3.do

* --- failure path: more than 2 networks: "Maximum two networks allowed", error 198.
nwclear
nwrandom 5, prob(.5) name(tabA)
nwrandom 5, prob(.5) name(tabB)
nwrandom 5, prob(.5) name(tabC)
capture noisily nwtabulate tabA tabB tabC
assert _rc == 198




