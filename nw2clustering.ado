/***
{smcl}
{* *! version 1.0.0  24aug2026 author: Thomas Grund}{...}
{marker topic}
{helpb nw_topical##analysis_positions:[NW-2.6.4] Positions, Roles & Equivalence}

{title:Title}

{p2colset 9 21 22 2}{...}
{p2col :nw2clustering {hline 2}}Clustering coefficient (transitivity) of a two-mode network{p_end}
{p2colreset}{...}

{title:Syntax}

{p 8 17 2}
{cmdab: nw2clustering}
[{it:{help netname}}]
[{cmd:,}
{opt measure(string)}
{opth level(int)}
{opth generate(newvarname)}
{opt replace}]

{synoptset 25 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt measure(binary|arithmetic|geometric|maximum|minimum)}}How to combine a 4-path's own
four tie values; {it:binary} dichotomizes every tie to presence/absence first;
{it:arithmetic}/{it:geometric}/{it:maximum}/{it:minimum} combine the four raw tie values via that
function; default = {it:arithmetic} for a valued network, {it:binary} otherwise{p_end}
{synopt:{opth level(int)}}Which mode (1 or 2) to compute clustering scores for; default = 1{p_end}
{synopt:{opth generate(newvarname)}}Name of the Stata variable that stores each {opt level()}-mode
node's own clustering coefficient; default = {it:_clustering2_lev}{it:level}{p_end}
{synopt:{opt replace}}Overwrite an existing {opth generate(newvarname)} variable; required if it already exists{p_end}

{p2colreset}{...}

{title:Description}

{pstd}
{cmd:nw2clustering} calculates the two-mode (bipartite) analogue of the ordinary clustering
coefficient (see {help nwclustering}) using the 4-path / 6-cycle definition of Opsahl (2013) and
Robins & Alexander (2004): an ordinary triangle cannot exist in a two-mode network (a tie only ever
connects the two different modes), so "closure" is instead measured on paths of length 4 - two
{opt level()}-mode nodes connected via two distinct intermediate opposite-mode alters - and a path is
{it:closed} when its two ends are ALSO both tied to some further common alter, forming a 6-cycle.
This deliberately excludes shorter 4-cycles (reusing one of the same two alters) as a form of closure,
matching the cited reference's own distinction between mere shared-affiliation redundancy and genuine
triadic-style closure.

{pstd}
Only nodes of the requested {opt level()} receive a value; nodes of the other mode are left missing.
A node with too few alters, or whose own connected component has fewer than 3 same-mode nodes, has no
possible 4-path and its own coefficient is reported missing (not spuriously 0).

{pstd}
{help nwclustering} automatically switches to this command whenever it is called on a two-mode network,
forwarding {opt measure()} and {opt generate()} (always at the default {opt level(1)} in that case) -
call {cmd:nw2clustering} directly to choose {opt level(2)} or a non-default {opt measure()}.

{title:Supported network types}

{pstd}
Binary: yes (the default {opt measure(binary)} case). Directed: not checked - a two-mode network's
ties are treated as undirected. Weighted: yes, via {opt measure(arithmetic|geometric|maximum|
minimum)}, each combining the 4-path's own four tie values before testing closure. Signed: not
checked; negative tie values are not validated or rejected. Two-mode: {bf:T3} - this command's entire
purpose is two-mode clustering; calling it on a one-mode network raises a clear error.

{title:Stored results}

	Scalars
	  {bf:r(C_avg)}		mean of the per-node clustering coefficients (the requested {opt level()} only)
	  {bf:r(C_global)}	network-level global clustering coefficient (ratio of total closed to total
	                        potential 4-paths)

	Macros
	  {bf:r(measure)}		the {opt measure()} actually used

{title:Examples}

	{cmd:. nwset ego alter, twomode name(bip)}
	{cmd:. nw2clustering bip}
	{cmd:. sum _clustering2_lev1}

{title:References}

{pstd}
Opsahl, T. (2013). Triadic closure in two-mode networks: Redefining the global and local clustering
coefficients. {it:Social Networks} 35(2), 159-167.

{pstd}
Robins, G., Alexander, M. (2004). Small worlds among interlocking directors: Network structure and
distance in bipartite graphs. {it:Computational & Mathematical Organization Theory} 10(1), 69-94.

{title:See also}

	{help nwclustering}, {help nw2project}, {help nw2degree}

***/
capture program drop nw2clustering
program nw2clustering
	syntax [anything(name=netname)][, measure(string) level(int 1) GENerate(string) replace]

	unw_defs

	if "`generate'" == "" {
		local generate = "_clustering2_lev`level'"
	}

	// BUGFIX (moderate-severity pass, positions_equivalence group): no
	// collision guard existed at all - worse than a silent overwrite,
	// confirmed directly: when `generate' already existed, the command
	// still returned rc==0 (claiming success) but left the pre-existing
	// variable's values completely UNCHANGED, computing nothing. Root
	// cause is downstream (`merge m:m ..., nogenerate' silently keeps
	// the master's own version and discards the using dataset's
	// same-named column whenever both share a variable name, with no
	// error), but the fix belongs here: check up front, before any of
	// the expensive computation below ever runs, matching the
	// `replace'-required convention every sibling command with a
	// generate() option (nwclustering/nwconcor/nwcoreperiphery/nwburt/
	// nwbrokerage) already uses.
	capture confirm variable `generate', exact
	if _rc == 0 & "`replace'" == "" {
		di "{err}Variable {bf:`generate'} already exists; specify {bf:replace}"
		err 99
	}
	tempfile temp clustering edge_list ego_list alter_list
	nw_syntax `netname'
	nw_datasync `netname'

	// BUGFIX: level() accepted any integer with no validation at all -
	// an out-of-range value (anything but 1 or 2) crashed several steps
	// later with a cryptic raw Stata error ("variable n not found /
	// Data are already wide") instead of a clear message, since the
	// initial `_nwmode_ego == "level"' filter simply matched nothing.
	if !inlist(`level', 1, 2) {
		di "{err}level() must be 1 or 2"
		error 198
	}

	// BUGFIX: calling nw2clustering directly on a one-mode network
	// crashed with a cryptic internal error ("_nwmode_ego not found")
	// rather than a clear message - nwclustering.ado's own auto-switch
	// protects the common path (two-mode detected -> automatically
	// calls nw2clustering), but nothing stopped a direct call on the
	// wrong kind of network.
	if "`is2mode'" != "true" {
		di "{err}nw2clustering requires a two-mode network; see {help nwclustering} for one-mode networks."
		error 198
	}

	// Auto-detect from the network's own stored valued/unvalued state
	// rather than always defaulting to "binary" regardless - matching
	// the netmeasure auto-detection convention already established in
	// nwcommunity.ado/nwconcor.ado/nwcoreperiphery.ado/nwmodularity.ado/
	// nwspectral.ado (and nwclustering.ado's own identical fix). Moved
	// below nw_syntax so `valued' is actually populated before this
	// check runs - it wasn't, previously.
	if "`measure'" == "" {
		if "`valued'" == "true" {
			local measure "arithmetic"
		}
		else {
			local measure "binary"
		}
	}
	_opts_oneof "binary arithmetic geometric maximum minimum" "measure" "`measure'" 6556

	qui {
	
	preserve

	nwtoedge `netname'
	// BUGFIX: `nwtoedge' only ever emits ONE row per pair (the classic
	// "avoid double-listing an undirected tie" lower-triangle
	// convention: for a pair (i,j), only the row with the higher raw
	// node index as `ego' is emitted). For a two-mode network this
	// means EVERY genuine cross-mode tie's `ego' side is whichever mode
	// happens to occupy the higher index range - an accident of node
	// creation order, not something tied to mode at all - so the
	// `_nwmode_ego == "level"' filter below only ever finds real edges
	// for ONE of the two levels; the other level's own filtered edge
	// list is entirely empty (or, before the missing-value fix just
	// below, entirely populated by meaningless same-mode "structural
	// non-edge" rows that happen to share one mode value and so don't
	// immediately crash the reshape steps downstream - which is exactly
	// why this went undetected: it silently produced a plausible-
	// looking but meaningless result for whichever level was NOT the
	// lucky one, rather than erroring). Confirmed directly via a hand
	// trace: on a 4+4-node bipartite network created mode-1-then-mode-2,
	// `_nwmode_ego=="1"' matches zero real edges at all. Fixed by
	// explicitly building BOTH directions of every real cross-mode tie
	// (append a swapped-ego/alter mirror copy) before the level filter,
	// so `_nwmode_ego == "level"' finds real edges for either level
	// regardless of which mode nwtoedge happened to assign as `ego'.
	keep if `netname' != 0 & `netname' != .
	tempfile fwd
	save `fwd'
	rename `nw_ego' _nw2c_swap
	rename `nw_alter' `nw_ego'
	rename _nw2c_swap `nw_alter'
	rename _nwmode_ego _nw2c_swap
	rename _nwmode_alter _nwmode_ego
	rename _nw2c_swap _nwmode_alter
	append using `fwd'

	keep if _nwmode_ego == "`level'"
	drop _nwmode_ego _nwmode_alter
	if "`measure'" == "binary" {
		replace `netname' = (`netname' != 0)
		local measure = "arithmetic"
	}
	rename `nw_ego' ego
	rename `nw_alter' alter
	rename `netname' value
    save `edge_list'

	order alter ego
	rename ego ego_
	rename value value_
	bys alter: gen n = _n
	reshape wide ego_ value_, i(alter) j(n)
	save `alter_list'

	use `edge_list', clear
	order ego alter
	rename alter alter_
	rename value value_
	bys ego: gen n = _n
	reshape wide alter_ value_, i(ego) j(n)
	save `ego_list'

	use `edge_list', clear
	rename value value0
	rename ego ego0
	merge m:m alter using `alter_list', nogenerate
	// PERFORMANCE/CORRECTNESS FIX: this command has always crashed on
	// any bipartite network with a reshape error ("variable ... does
	// not uniquely identify the observations", r(9)), confirmed
	// reproducible even on a tiny 4-node network - not an edge case.
	// Root cause: an m:m merge against a per-key-unique `using' table
	// (alter_list/ego_list are each keyed uniquely by construction, via
	// their own earlier `reshape wide ... i(alter)/i(ego)') broadcasts
	// the SAME using-side row to every master-side row sharing that
	// key - so if the master side already has more than one row for a
	// given key (a real possibility this far into a multi-hop path
	// enumeration), those rows come out of the merge bit-for-bit
	// identical, not just sharing the same key. Confirmed directly
	// (`duplicates report' vs `duplicates report' restricted to the
	// reshape's own i()-varlist gave identical counts) - these are
	// pure redundant broadcast copies, not rows differing in some
	// other column, so dropping the surplus is lossless. The identical
	// pattern recurs at every merge+reshape step below (this function
	// walks a growing ego0-alter0-ego1-alter1-ego2-alter2-ego3 4-path,
	// one hop merged in at a time) - fixed at all of them, not just the
	// one specific network structure that happened to crash first.
	// BUGFIX: `duplicates drop' (like `collapse' below) errors
	// outright ("no observations", r(2000)) on a genuinely empty
	// (0-row) dataset - a legitimate outcome at this point in the
	// pipeline (e.g. a level whose own component of the network has
	// fewer than 3 distinct same-mode nodes, so no 4-path/6-cycle can
	// possibly exist), not an error condition. Guarded the same way
	// throughout this file.
	qui count
	if r(N) > 0 {
		duplicates drop
	}
	rename alter alter0
	reshape long ego_ value_, i(ego0 alter0) j(id)
	drop id
	drop if ego_ == "" | ego_ == ego0
	rename ego_ ego1
	rename value_ value1
	order ego0 value0 alter0 value1 ego1 

	rename ego1 ego
	merge m:m ego using `ego_list', nogenerate
	// same redundant-broadcast-duplicate fix as the first merge above.
	qui count
	if r(N) > 0 {
		duplicates drop
	}
	reshape long alter_ value_, i(ego0 alter0 ego) j(id)
	drop id
	drop if alter_ == "" | alter_ == alter0

	rename ego ego1
	rename alter_ alter1
	rename value_ value2
	order ego0 value0 alter0 value1 ego1 value2 alter1

	rename alter1 alter
	merge m:m alter using `alter_list', nogenerate
	// same redundant-broadcast-duplicate fix as the first merge above.
	qui count
	if r(N) > 0 {
		duplicates drop
	}
	reshape long ego_ value_, i(ego0 alter0 ego1 alter) j(id)
	drop id 
	drop if ego_ == "" | ego_ == ego1 | ego_ == ego0
	rename ego_ ego2
	rename value_ value3
	rename alter alter1
	order ego0 value0 alter0 value1 ego1 value2 alter1 value3 ego2

	gen potential_4path = 1
	gen arithmetic = (value0 + value1 + value2 + value3) / 4
	gen geometric = (value0 * value1 * value2 * value3)^(1/4)
	gen maximum = max(value0, value1, value2, value3)
	gen minimum = min(value0, value1, value2, value3)
	sum `measure'
	local potential_4paths = r(sum)
	save `temp', replace

	//// Check which ones are closed
	rename ego2 ego
	merge m:m ego using `ego_list', nogenerate
	drop if potential_4path == .
	// same redundant-broadcast-duplicate fix as the first merge above.
	qui count
	if r(N) > 0 {
		duplicates drop
	}
	reshape long alter_ ,i(ego0 alter0 ego1 alter1 ego) j(alter)
	drop if alter_ == alter0 | alter_ == alter1
	rename ego ego2
	rename alter_ alter2
	drop alter

	order ego0 alter0 ego1 alter1 ego2 alter2
	rename alter2 alter
	merge m:m alter using `alter_list', nogenerate
	drop if potential_4path == .
	// same redundant-broadcast-duplicate fix as the first merge above.
	qui count
	if r(N) > 0 {
		duplicates drop
	}
	reshape long ego_, i(ego0 alter0 ego1 alter1 ego2 alter) j(ego)
	drop if ego_ == ""
	drop ego
	rename ego_ ego3
	rename alter alter2
	order ego0 alter0 ego1 alter1 ego2 alter2 ego3
	gen closed = (ego0 == ego3) 
	keep ego0 value0 alter0 value1 ego1 value2 alter1 value3 ego2 arithmetic geometric maximum minimum closed
	// BUGFIX: `collapse' (like `duplicates drop' above) errors outright
	// ("no observations", r(2000)) on a genuinely empty (0-row) dataset -
	// a legitimate outcome here (no closed 4-paths found for this
	// level), not an error condition. Skipping it when already empty is
	// exactly equivalent to what it would have produced anyway (0 rows,
	// same by()/closed columns, already ensured by the `keep' just
	// above).
	qui count
	if r(N) > 0 {
		collapse (max) closed, by(ego0 value0 alter0 value1 ego1 value2 alter1 value3 ego2 arithmetic geometric maximum minimum)
	}

	merge m:m  ego0 value0 alter0 value1 ego1 value2 alter1 value3 ego2 arithmetic geometric maximum minimum using `temp', nogenerate

	gen closed_value = closed * `measure'
	sum closed_value
	local closed_4paths = r(sum)

	// BUGFIX: `egen ..., total()' (via its own internal `by ego1:'
	// group loop) errors ("variable ... not found", r(111)) on a
	// genuinely empty (0-row) dataset - the `by' loop body never runs
	// for zero groups, so egen's own internal working variable is never
	// created, and its final `rename' step fails outright. A completely
	// empty result here is legitimate whenever this level has fewer
	// than 3 distinct same-mode nodes anywhere in a single connected
	// component of the network (the minimum needed for any 4-path to
	// exist at all) - confirmed directly on a network built from two
	// disjoint 4-cycles, each with only 2 same-mode nodes. `gen'
	// (unlike `egen'/`bys') tolerates 0 rows fine, so build the
	// (correctly empty) `pot'/`clo' columns directly rather than via
	// `egen' when there is nothing to group.
	qui count
	if r(N) > 0 {
		bys ego1: egen pot = total(`measure')
		bys ego1: egen clo = total(closed_value)
		bys ego1: keep if _n == 1
	}
	else {
		gen pot = .
		gen clo = .
	}
	gen `generate' = clo / pot
	keep ego1 `generate'
	rename ego1 _nwnode
	save `clustering'

	sum `generate'
	local C_avg = r(mean)
	
	restore
	// `merge' silently keeps the master's own version and discards the
	// using dataset's values whenever both share a non-key variable name
	// (see the guard above) - so an explicit `replace' call still needs
	// the stale variable dropped here first, or the freshly-computed
	// `clustering' results would be discarded exactly the same way.
	capture drop `generate'
	merge m:m `nw_nodename' using `clustering', nogenerate
	}
	
	mata: st_rclear()
	mata: st_numscalar("r(C_global)", `=`closed_4paths' / `potential_4paths'')
	mata: st_global("r(measure)", "`measure'")
	mata: st_numscalar("r(C_avg)", `C_avg')
	// Two separate `capture'd probes earlier in this program (the
	// collision-guard `confirm variable' at the top, and the pre-merge
	// `drop' further up) each leave their own stale, harmless nonzero
	// _rc on the ordinary case where there is nothing to find/drop -
	// and nothing in between them touches _rc again (`mata:'/`local'/
	// `sum' do not), so whichever ran last would otherwise leak out as
	// this command's own final, misleading return code. Reset
	// explicitly as the last step, matching this package's own
	// established idiom for exactly this situation (see nwaltergen.ado's/
	// nwbrokerage.ado's own header comments) - placed here, after every
	// other `capture' in this program, rather than right after either
	// individual probe, so it cannot itself be re-dirtied by a later one.
	capture confirm number 1
end











