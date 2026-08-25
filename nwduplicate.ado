/***
{smcl}
{* *! 8jul2016 author: Thomas Grund}{...}
{marker topic}
{helpb nw_topical##generator:[NW-2.3] Generators}

{title:Title}

{p2colset 9 20 22 2}{...}
{p2col :nwduplicate {hline 2}}Duplicate a network{p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 17 2}
{cmdab: nwduplicate}
[{it:{help netname}}]
[,
{opt name}({it:{help newnetname}})
{opt replace}]


{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt name}({it:{help newnetname}})}name of the new network{p_end}
{synopt:{opt replace}}if a network named {it:newnetname} already exists, drop it and use this name anyway (see {help nwset} for the same convention){p_end}


{title:Description}

{pstd}
{cmd:nwduplicate} simply duplicates an existing network {it:netname}. By default, the duplicated network is called {it:netname_copy}. It also 
duplicates the node labels of the original network.

{pstd}
For example:

	{bf:. nwwebuse florentine, nwclear}
	{bf:. nwduplicate flomarriage}
	{bf:. nwname flomarriage_copy}
	{bf:. return list}
	
	

{title:Supported network types}

{pstd}
Binary: yes. Directed: yes. Weighted: yes. Signed: yes - a full, generic copy of the network object (adjacency matrix, node labels, directed/valued/two-mode status, and mode assignments), independent of any of these properties.

{title:See also}

	{help nwgenerate}, {help nwsubset}

***/

capture program drop nwduplicate
program nwduplicate
	syntax [anything(name=netname)], [name(string) replace]
	unw_defs
	nw_syntax `netname', max(1)

	local name_given = ("`name'" != "")
	if "`name'" == "" {
		local name "`netname'_copy"
	}

	// BUGFIX (moderate-severity pass, generators_structural group): used
	// to call `nwvalidate' unconditionally, silently auto-incrementing
	// ("fixedcopy" -> "fixedcopy_1") on an explicit name() collision -
	// unlike every sibling generator in this group (nwrandom/nwpref/
	// nwlattice/nwring/nwsmall), which correctly require `replace' for
	// that case. The underlying `.duplicate()' Mata method has no
	// collision guard of its own either (unlike `nwset', which the
	// siblings ultimately call) - it would silently append a second,
	// same-named registry entry rather than erroring, so the check needs
	// to happen here explicitly. Auto-increment only when name() was
	// omitted (matching the siblings' own "unspecified name() still
	// auto-renames" convention); an explicit, colliding name() now
	// requires `replace' instead, same as every sibling.
	nwvalidate `name'
	if "`r(exists)'" == "true" & `name_given' {
		if "`replace'" != "" {
			nwdrop `name'
			local validname "`name'"
		}
		else {
			di "{err}Network `name' already exists. Specify option {bf:replace} to overwrite it."
			error 483
		}
	}
	else {
		local validname "`r(validname)'"
	}
	mata: `nws'.duplicate("`netname'", "`validname'")
end

