cscript

* Two mistakes that used to pass silently (book appendix "When things go wrong"):
* (1) nwset with repeated node labels, (2) nwload over variables of another network or of the user.
do unw_core.do

* (1) repeated labels are refused, with the repeated label named
nwclear
capture noisily nwset, mat((0,1,1\1,0,1\1,1,0)) undirected labs(A,A,B)
assert _rc == 198
nwset, mat((0,1,1\1,0,1\1,1,0)) undirected labs(A,B,C)
nwsummarize
assert r(nodes) == 3
capture noisily nwset, mat((0,1\1,0)) undirected labs(x,x) name(dup2)
assert _rc == 198
capture nwname dup2
assert _rc != 0

* (2a) loading a second network replaces the first one's variables, with a note
nwuse data/florentine, nwclear
drop _all
nwload flomarriage
confirm variable medici
nwload flobusiness
confirm variable medici
* the columns are now flobusiness: medici-Barbadori is a business tie but not a marriage tie
nwsummarize flobusiness
quietly count if medici == 1
local nbus = r(N)
* Medici: 5 business ties, 6 marriage ties
assert `nbus' == 5

* (2b) a user variable with a node's name is not overwritten without overwrite
nwuse data/florentine, nwclear
drop _all
set obs 16
generate medici = 99 in 1
capture noisily nwload flomarriage
assert _rc == 110
assert medici[1] == 99
nwload flomarriage, overwrite
assert medici[1] != 99

* (2c) reloading the same network is silent and works
nwuse data/florentine, nwclear
drop _all
nwload flomarriage
nwload flomarriage
confirm variable medici

* (2d) a renamed node variable does not block the next nwload (book chapter 10)
nwuse data/florentine, nwclear
drop _all
nwload flomarriage
rename bischeri my_bischeri
nwload flobusiness
confirm variable bischeri
confirm variable my_bischeri

* (2e) a network declared from the user's own variables can be loaded again
clear
set obs 3
generate a = (_n != 1)
generate b = (_n != 2)
generate c = (_n != 3)
nwset a b c, name(own) undirected
nwload own
confirm variable a

di "PASS test_silent_mistakes"
