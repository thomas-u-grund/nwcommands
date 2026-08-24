cscript

do unw_core.do

* nwunab had no dedicated test coverage at all - which is exactly how
* its own r(networks) always-1 bug (a typo referencing the undeclared
* local `unablist' instead of `unabnets', the local `unab' actually
* populates) went uncaught: `word count "`unablist'"' always expanded
* to the two-character literal string `""' regardless of how many
* networks actually matched, and `word count' counts that as one word.

nwclear
nwrandom 5, prob(1) name(neta)
nwrandom 5, prob(1) name(netb)
nwrandom 5, prob(1) name(cneta)

nwunab mynets : net*
assert _rc == 0
assert `r(networks)' == 2
assert `"`r(netlist)'"' == `"neta netb"'
assert `"`mynets'"' == `"neta netb"'

* a single match must still report exactly 1, not undercounting either.
nwunab onenet : cneta*
assert `r(networks)' == 1
assert `"`r(netlist)'"' == `"cneta"'

* all three networks together.
nwunab allnets : *neta netb
assert `r(networks)' == 3

di "=== nwunab r(networks) REGRESSION VERIFIED ==="
