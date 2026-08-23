/***
{smcl}
{* *! version 2.0 Thomas Grund}{...}
{marker topic}
{helpb nw_topical##manipulation:[NW-2.5] Manipulation}

{title:Title}

{p2colset 9 18 22 2}{...}
{p2col :nwrename {hline 2}}Rename a network{p_end}
{p2colreset}{...}


{title:Syntax}

{pstd}
Rename single network

{p 8 16 2}
{opt nwrename} {it:old_netname} {it:new_netname}


{pstd}
Rename multiple networks

{p 8 16 2}
{opt nwrename} ({it:old1 old2 ...}) ({it:new1 new2 ...})


{marker description}{...}
{title:Description}

{pstd}
{cmd:nwrename} changes the name of an existing network {it:old_netname} to
{it:new_netname}; the content of the network remains unchanged.


{marker examples}{...}
{title:Examples}

	{com}. nwwebuse florentine, nwclear

	{res}{txt}(2 networks)
	{hline 20}
		{res}flobusiness
		{res}flomarriage
	
	{com}. nwds
	{res}{txt}{col 1}flobusiness{col 24}flomarriage

	{com}. nwrename flobusiness business
	{com}. nwrename flomarriage marriage{txt}

	{com}. nwds
	{res}{txt}{col 1}business{col 21}marriage


{title:See also}

	{help nwname}, {help rename}

***/

capture program drop nwrename
program nwrename
	
	local renameCmd `0'
	
	preserve
	drop _all
	nw_syntax _all, max(9999)
	foreach onenet in `netname' {
		gen `onenet' = .
	}
	rename `renameCmd', r
	local oldnames "`r(oldnames)'"
	local newnames "`r(newnames)'"
	restore
	local i = 1
	foreach onenet in `oldnames' {
		local newname : word `i' of `newnames'
		nw_name `onenet', newname(`newname')
		local i = `i' + 1
	}
end

