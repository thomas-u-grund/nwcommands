/***
{smcl}
{* *! version 1.0.0  21aug2026 author: Thomas Grund}{...}
{marker topic}
{helpb nw_topical##analysis:[NW-2.6] Analysis}

{title:Title}

{p2colset 9 19 22 2}{...}
{p2col :nwbalance {hline 2} Structural balance of a signed network}
{p2colreset}{...}

{title:Syntax}

{p 8 17 2}
{cmdab: nwbalance}
[{it:{help netname}}]
[{cmd:,}
{opt generate(namelist)}]

{synoptset 25 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt generate(namelist)}}Up to 3 names, for the per-node balance ratio, count of balanced
triads, and count of closed triads a node belongs to; default =
{it:_balance _baltriad _clotriad}{p_end}

{title:Description}

{pstd}
{cmd:nwbalance} evaluates a {help netname:network}'s ties as signed (positive/negative) and tests
every closed triad against Cartwright and Harary's (1956) strong structural balance criterion: a
closed triad is {it:balanced} when the product of its three tie values is positive - equivalently,
when it contains an even number (0 or 2) of negative ties ("the friend of my friend is my friend";
"the enemy of my enemy is my friend"). A triad with an odd number (1 or 3) of negative ties is
{it:unbalanced}.

{pstd}
Ties do not need to be declared {help nwvalue:signed} in any special way - any tie with a negative
value is treated as negative, any positive value as positive.

{pstd}
For each node, {cmd:nwbalance} generates the number of closed triads it belongs to, the number of
those that are balanced, and the ratio of the two. Network-level counts and the overall balance
ratio are returned in {help return:r()}.

{title:Stored results}

	Scalars
	  {bf:r(closed_triad)}		number of closed triads
	  {bf:r(balanced_triad)}	number of balanced closed triads
	  {bf:r(unbalanced_triad)}	number of unbalanced closed triads
	  {bf:r(balance)}		{it:balanced_triad} / {it:closed_triad}


{title:Examples}

	{cmd:. nwset, mat((0,1,1,-1\1,0,1,-1\1,1,0,1\-1,-1,1,0)) undirected labs(A,B,C,D)}
	{cmd:. nwbalance}

	{res}{hline 40}
	{txt}  Network name: {res}network
	{txt}{hline 40}
	{txt}    Closed triad: {res}4
	{txt}    Balanced triad: {res}2
	{txt}    Unbalanced triad: {res}2

{pstd}
Of the 4 triads in this network, {it:A-B-C} (all positive) and {it:A-B-D} (two negative ties) are
balanced; {it:A-C-D} and {it:B-C-D} (one negative tie each) are not.


{title:References}

{pstd}
Cartwright, D., Harary, F. (1956). Structural balance: a generalization of Heider's theory.
{it:Psychological Review} 63(5), 277-293.

{title:See also}

	{help nwtriads}, {help nwvalue}

***/

capture program drop nwbalance
program nwbalance
	version 9
	syntax [anything(name=netname)] [, generate(string)]
	set more off
	
	local closed : word 2 of `generate'
	local balance : word 3 of `generate'
	local B : word 1 of `generate'
	if "`closed'" == "" {
		local closed "_clotriad"
	}
	if "`balance'" == "" {
		local balance = "_baltriad"
	}
	if "`B'" == "" {
		local B = "_balance"
	}
	
	
	unw_defs
	nw_syntax `netname', max(1)
	nw_datasync `netname'
	local original "`netname'"
	local directed "`directed'"
	
	tempfile temp clustering edge_list adj_list
	nw_syntax `netname'
	tempvar included
	nw_datasync `netname', generate(`included')
	// captured before preserve, for the zero-closed-triads guard
	// below (a triangle-free network's node list can't be recovered
	// from the empty reshape output that would otherwise feed the
	// per-node collapse)
	qui levelsof `nw_nodename' if `included', local(allnodes)

	preserve
	
	qui {
	nw_syntax `netname'
	unw_defs
	nwtoedge `netname', full
	rename `nw_ego' ego
	rename `nw_alter' alter
	rename `netname' value
	drop if value == 0 | value == .
	drop if alter == ego
    save `edge_list', replace

	use `edge_list', clear
	order ego alter
	rename alter alter_
	rename value value_
	bys ego: gen n = _n
	reshape wide alter_ value_, i(ego) j(n)
	save `adj_list', replace

	use `edge_list', clear
	rename value value0
	rename ego ego0
	rename alter ego
	merge m:m ego using `adj_list', nogenerate
	rename ego alter0
	reshape long alter_ value_, i(ego0 alter0) j(id)
	drop id
	drop if alter_ == "" | alter_ == ego0
	rename alter_ ego1
	rename value_ value1
	order ego0 value0 alter0 value1 ego1 

	rename ego0 ego
	merge m:m ego using `adj_list', nogenerate
	rename ego ego0
	reshape long alter_ value_, i(ego0 alter0 ego1) j(id)
	drop id
	drop if alter_ == ""
	rename value_ value2
	rename ego1 ego2
	rename alter0 ego1
	keep if (alter_ == ego2)

	gen `balance' = ((value0 * value1 * value2) > 0)
	gen `closed' = 1
	gen `nw_nodename' = ego2

	qui count
	if r(N) == 0 {
		// no closed triads anywhere in the network - collapse errors
		// r(2000) "no observations" on a completely empty dataset,
		// even though every node genuinely has 0 closed triads here
		// (not an undefined/missing count). Build that all-zero
		// per-node result directly instead of collapsing, using the
		// node list captured before preserve.
		// "clear" (bare) behaves like "clear all" in Stata - it would
		// wipe Mata memory too, including this package's own
		// singleton network-state object, corrupting every command
		// called afterward for the rest of the session. "drop _all"
		// clears the dataset only, leaving Mata state untouched.
		drop _all
		local nnodes : word count `allnodes'
		qui set obs `nnodes'
		gen `nw_nodename' = ""
		local i = 0
		foreach onenode of local allnodes {
			local i = `i' + 1
			qui replace `nw_nodename' = "`onenode'" in `i'
		}
		gen `balance' = 0
		gen `closed' = 0
	}
	else {
		collapse (sum) `balance' `closed', by(`nw_nodename')
	}

	tempfile bal

	
	if "`directed'" == "false" {
		replace `balance' = `balance' / 2
		replace `closed' = `closed' / 2
	}
	gen `B' = `balance' / `closed'
	sum `closed' if `closed' != .
	local r1 `=`r(sum)' / 3'
	sum `balance' if `balance' != .
	local r2 `=`r(sum)'/3'
	mata: st_rclear()
	mata: st_numscalar("r(closed_triad)", `r1')
	mata: st_numscalar("r(balanced_triad)", `r2')
	mata: st_numscalar("r(unbalanced_triad)",`=`r(closed_triad)' - `r(balanced_triad)'')
	mata: st_numscalar("r(balance)", `=`r(balanced_triad)' / `r(closed_triad)'')
	_return hold balanceresult
	save `bal'
	restore 
	capture drop `balance'
	capture drop `closed'
	capture drop `B' 
	merge m:n `nw_nodename' using `bal', nogenerate
	}
	_return restore balanceresult
	
	noi di "{hline 40}"
	noi di "{txt}  Network name: {res}`netname'"
	noi di "{hline 40}"
	noi di "{txt}    Closed triad: {res}`r(closed_triad)'"
	noi di "{txt}    Balanced triad: {res}`r(balanced_triad)'"
	noi di "{txt}    Unbalanced triad: {res}`r(unbalanced_triad)'"

end
