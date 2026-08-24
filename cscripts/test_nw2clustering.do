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
