/***
{smcl}
{* *! version 1.0.0  11nov2014}{...}
{marker topic}
{helpb nw_topical##generator:[NW-2.3] Generators}
{marker top2}
{helpb nw_topical##manipulation:[NW-2.5] Manipulation}

{title:Title}

{p2colset 9 20 22 2}{...}
{p2col :nwsubset {hline 2}}Subset the nodes of a network{p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 17 2}
{cmdab: nwsubset} 
[{it:{help netname}}]
[{it:{help if}}]
[,
{opt name}({it:{help newnetname}})
{opt replace}]


{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt name}({it:{help newnetname}})}name of the new network{p_end}
{synopt:{opt replace}}replace existing network{p_end}


{title:Description}

{pstd}
{cmd:nwsubset} simply subsets an existing network {it:netname}. By default, the subset network is called {it:netname_sub}. It
consists of all the nodes of the original network {it:netname} for which the {bf:if} condition
is true. When no {help if} condition is specified, the command simply generates a duplicate.

{pstd}
For example, this generates a new network from the {bf:flomarriage} network that consists of only
the nodes with {bf:wealth > 50}.

	{bf:. nwwebuse florentine, nwclear}
	{bf:. nwsubset flomarriage if wealth > 50}

{pstd}
By default, this generates a new network called {it:flomarriage_sub}. Notice that something similar could be achieved with {help nwgen}:

	{bf:. nwgen flo_sub = flomarriage if wealth > 50}	

{pstd}
However, the last command does not copy the node labels of network {it:flomarriage}. This is because the {help if} condition in {help nwgen} applies to a whole {help netexp:network expression}. Because
network expressions can be very complicated, no labels are copied. 



{title:Supported network types}

{pstd}
Binary: yes. Directed: yes. Weighted: yes, tie values are preserved in the extracted subset. Signed: yes, values including negative are preserved. Two-mode: not checked.

{title:See also}

	{help nwgenerate}, {help nwduplicate}

***/

capture program drop nwsubset
program nwsubset
	version 9
	
	unw_defs
	
	syntax [ anything(name=netname)] [if/] [, name(string) replace]
	
	nw_syntax `netname', max(1)
	local original `netname'

	// BUGFIX (moderate-severity pass, generators_derived group):
	// nwsubset's own DEFAULT name (`netname'_sub, when name() is not
	// given at all) used to hard-error on collision instead of
	// auto-incrementing the way every sibling in this group
	// (nwdyadprob/nwhomophily/nwexpand/nwdissimilar/nwsimilar) does for
	// their own default names - inconsistent within the same group.
	// Resolved the same way as those siblings: only when the caller did
	// NOT supply name(), pre-resolve the actual (possibly
	// auto-incremented) target name via nwvalidate up front; an
	// explicit, caller-chosen name() still requires `replace' on a
	// genuine collision, now enforced by nwduplicate itself (see its own
	// moderate-severity-pass fix) rather than by a second, redundant
	// check duplicated here.
	local name_was_given = ("`name'" != "")
	if "`name'" == "" {
		local name "`netname'_sub"
	}
	if !`name_was_given' {
		nwvalidate `name'
		local name = r(validname)
	}

	nwduplicate `netname', name(`name') `replace'
	// BUGFIX: was unconditional - when no `if' condition is given (the
	// documented "simply generates a duplicate" behavior), `if' is
	// empty, so this became the literal, invalid `nwdrop `name' if ( ==
	// 0)' and crashed (r198) on every no-if call. Only apply the filter
	// when an `if' condition was actually given.
	if "`if'" != "" {
		// BUGFIX: an `if' condition matching zero nodes (a perfectly
		// ordinary user mistake, or a legitimate "this subset is
		// empty" request) crashed with an uncontrolled, uninformative
		// Mata error deep inside the network-registration machinery
		// (r3300) rather than a clean message. Caught and converted;
		// the half-built `name' network nwduplicate already created is
		// dropped too, rather than left behind in a broken state.
		capture nwdrop `name' if (`if' == 0)
		if _rc != 0 {
			capture nwdrop `name'
			di "{err}The if condition selects no nodes; network {bf:`name'} would have zero nodes remaining."
			error 198
		}
	}

end

