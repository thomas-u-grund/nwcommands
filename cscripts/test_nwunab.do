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

* --- BUGFIX (ported from the archived nw_unab.ado, 2026-09-05): a
* literal `max(.)' (a numeric-missing max, e.g. forwarded from some
* caller's own integer option that defaults to missing rather than a
* real bound) must be treated as "no max given", not forwarded to
* `unab' as-is - `unab' would otherwise misread `.' as a real max()
* value and wrongly reject a match count it would otherwise accept. No
* current caller actually triggers this (_nwsyntax.ado, the only real
* caller passing max(), always supplies a concrete integer default),
* but the defense is real and worth keeping/testing regardless.
* Placed before the failure-path tests below deliberately: a `unab'
* call that errors leaves nwunab's own `preserve' unresolved (control
* never reaches its `restore'), corrupting later working-dataset state
* for whatever runs next in this same do-file - confirmed directly
* when this test was first written immediately after the min() failure
* case instead.
nwunab maxdot : net*, max(.)
assert _rc == 0
assert `r(networks)' == 2

* --- failure path: min() is passed straight through to Stata's own
* `unab', which enforces it - a pattern matching zero networks with
* min(1) required is rejected, not silently returned as an empty list.
capture noisily nwunab nomatch : bogus_pattern_xyz*, min(1)
assert _rc != 0

* an explicit, real max() must still be enforced normally. Also a
* failure-path case (see the placement note above) - kept last.
capture noisily nwunab toomany : *neta netb, max(1)
assert _rc != 0
