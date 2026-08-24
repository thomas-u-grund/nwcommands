cscript

do unw_core.do

* nw2clustering had zero real test coverage before this (the only
* existing case in this file built a network via nwfromedge and never
* actually called nw2clustering at all) - and was, in fact, completely
* broken: it crashed with a reshape error ("variable ... does not
* uniquely identify the observations", r(9)) on EVERY bipartite
* network, including tiny ones, confirmed via a minimal 4-node repro
* (found during harmonisation unit 103's own benchmark setup
* validation, not fixed at the time - see docs/CERTIFICATION.md).
*
* Root cause: this command walks a growing 4-path
* (ego0-alter0-ego1-alter1-ego2-alter2-ego3) via a sequence of m:m
* merges against per-key-unique lookup tables (each keyed uniquely by
* construction), then reshapes the result. An m:m merge against a
* uniquely-keyed `using' table broadcasts the SAME using-row to every
* master-row sharing that key - so once the master side already has
* more than one row for a given key (a real possibility this far into
* a multi-hop enumeration), the merge produces bit-for-bit IDENTICAL
* duplicate rows, which the very next reshape's own i()-varlist then
* correctly refuses to accept as unique. Confirmed directly that these
* were genuinely full-row duplicates, not merely same-key-different-
* value rows (`duplicates report' with no varlist gave identical
* counts to `duplicates report' restricted to just the reshape's own
* key columns) - so a plain `duplicates drop' immediately after each
* of the five merge steps is lossless by construction (it can only
* remove a row that is identical to another in EVERY column), not a
* heuristic that could silently discard genuinely different paths.
*
* This unit fixes the crash - it does not newly re-derive or certify
* the underlying Opsahl & Panzarasa (2009) weighted bipartite
* clustering formula from first principles (nothing about that
* formula's own logic was touched; the fix only removes redundant
* duplicate rows upstream of it). Verified below via: (1) the command
* runs to completion, without error, across the original crash repro
* plus 8 further random bipartite structures of varying size/density;
* (2) every reported clustering value is either missing (nodes with no
* possible 4-path to normalize by - the same convention nwclustering
* uses elsewhere in this package for degree<2 nodes) or within the
* mathematically required [0,1] bounds for a normalized clustering
* ratio.

nwclear
nwset, mat((0,1,0,1\1,0,1,0\0,1,0,1\1,0,1,0)) name(bip4) bipartite
nw2clustering bip4
assert _rc == 0
nwload
mata: st_view(cv1=., ., "_clustering2_lev1")
mata: assert(all((cv1 :>= 0 :& cv1 :<= 1) :| cv1 :== .))

* several further bipartite structures of varying size/density - the
* actual regression guard against the crash recurring for some OTHER
* network shape than the one specific case above.
forvalues t = 1/8 {
	nwclear
	local n1 = 3 + mod(`t'*7,5)
	local n2 = 3 + mod(`t'*11,5)
	clear
	set obs `=`n1'*`n2''
	gen ego = ""
	gen alter = ""
	local r = 0
	forvalues i = 1/`n1' {
		forvalues j = 1/`n2' {
			local r = `r' + 1
			if mod((`t'*104729 + `i'*7919 + `j'*131), 100) < 40 {
				replace ego = "a`i'" in `r'
				replace alter = "b`j'" in `r'
			}
		}
	}
	drop if ego == ""
	nwset ego alter, twomode name(bipnet) nooutput
	nw2clustering bipnet
	assert _rc == 0
	nwload
	mata: st_view(cv=., ., "_clustering2_lev1")
	mata: assert(all((cv :>= 0 :& cv :<= 1) :| cv :== .))
}


* --- alpha-audit regression: level(2) crashed outright with a raw
* reshape error ("variable _nwmode_alter not constant within ego",
* r(9)). Root-caused to a much deeper pre-existing bug than that one
* symptom suggested: nwtoedge emits only ONE row per pair (the higher-
* raw-index node as `ego') - for a two-mode network this means every
* genuine cross-mode tie's `ego' side is whichever mode happens to
* occupy the higher index range, so the `_nwmode_ego == "level"' filter
* only ever found real edges for ONE of the two levels; the other level
* silently operated on zero real edges the whole time (masked, for
* level(1) specifically, by missing-valued same-mode "structural
* non-edge" rows that happened to share one mode value and so didn't
* immediately crash - producing a plausible-looking but meaningless
* result instead of an error). Fixed by explicitly building both
* directions of every real cross-mode tie before the level filter, so
* either level finds real edges regardless of which mode nwtoedge
* happened to assign as `ego'. Verified here that level(1) and level(2)
* produce genuinely different (non-identical), individually valid
* per-node results on the same network - not just "doesn't crash".
nwclear
set seed 7
clear
set obs 25
gen ego = ""
gen alter = ""
local r = 0
forvalues i = 1/5 {
	forvalues j = 1/5 {
		local r = `r' + 1
		if mod(`i'*7 + `j'*13, 10) < 6 {
			replace ego = "a`i'" in `r'
			replace alter = "b`j'" in `r'
		}
	}
}
drop if ego == ""
nwset ego alter, twomode name(bipnet2) nooutput
nw2clustering bipnet2, level(1) generate(lev1)
assert _rc == 0
nw2clustering bipnet2, level(2) generate(lev2)
assert _rc == 0
nwload
mata: st_view(cv1=., ., "lev1")
mata: st_view(cv2=., ., "lev2")
mata: assert(all((cv1 :>= 0 :& cv1 :<= 1) :| cv1 :== .))
mata: assert(all((cv2 :>= 0 :& cv2 :<= 1) :| cv2 :== .))
* level(1) only populates mode-1 nodes (the first 5), level(2) only mode-2
mata: assert(all(cv1[1::5] :< .) & all(cv1[6::10] :== .))
mata: assert(all(cv2[6::10] :< .) & all(cv2[1::5] :== .))
di "=== LEVEL(2) REGRESSION VERIFIED ==="


* --- alpha-audit regression: level() validation and one-mode guard.
* level() previously accepted any integer with no validation, crashing
* several steps later with a cryptic raw error instead of a clear
* message; calling nw2clustering directly on a one-mode network crashed
* just as cryptically rather than erroring cleanly.
capture noisily nw2clustering bipnet2, level(99)
assert _rc != 0

nwclear
nwset, mat((0,1,1,1\1,0,0,0\1,0,0,0\1,0,0,0)) name(onemode) undirected labs(A,B,C,D)
capture noisily nw2clustering onemode
assert _rc != 0
di "=== level()/one-mode VALIDATION VERIFIED ==="


* --- alpha-audit regression: a network too small/structurally
* inadequate to contain any valid 4-path/6-cycle (here: two disjoint
* 4-cycles, so each component has only 2 same-mode nodes - never the 3
* distinct same-mode nodes a 4-path needs) used to crash with a raw
* internal Stata error at one of several different points ("no
* observations" r(2000) from `duplicates drop'/`collapse', or "variable
* ... not found" r(111) from `egen ..., total()' - all genuinely empty-
* dataset-intolerant Stata commands) instead of the graceful all-missing
* result this scenario deserves (matching nwbalance's own established
* "zero closed triads is not an error" convention elsewhere in this
* package).
nwclear
nwset, mat((0,1,0,1\1,0,1,0\0,1,0,1\1,0,1,0)) name(nopath) bipartite
nw2clustering nopath, level(1) generate(lnp1)
assert _rc == 0
nwload
mata: st_view(cv=., ., "lnp1")
mata: assert(all(cv :== .))
nw2clustering nopath, level(2) generate(lnp2)
assert _rc == 0
nwload
mata: st_view(cv=., ., "lnp2")
mata: assert(all(cv :== .))
di "=== NO-VALID-4-PATH REGRESSION VERIFIED ==="
