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
{opt name}({it:{help newnetname}})]


{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt name}({it:{help newnetname}})}name of the new network{p_end}


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
	
	
{title:See also}

	{help nwgenerate}, {help nwsubset}

***/

capture program drop nwduplicate
program nwduplicate
	syntax [anything(name=netname)], [name(string) ]
	unw_defs	
	nw_syntax `netname', max(1)
	
	if "`name'" == "" {
		local name "`netname'_copy"
	}
	nwvalidate `name'
	mata: `nws'.duplicate("`netname'", "`r(validname)'")
end

