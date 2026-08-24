/***
{smcl}
{* *! version 03jun2019 author: Thomas Grund}{...}
{marker topic}
{helpb nw_topical##analysis_other:[NW-2.6.7] Other Analysis Utilities}

{title:Title}

{p2colset 9 18 22 2}{...}
{p2col :nwvalue {hline 2}}Checks if node exists in a network{p_end}
{p2colreset}{...}

{title:Syntax}

{p 8 17 2}
{cmdab: nwnode} 
[{it:{help netname}}],
[{opt ego}({it:nodename}) |
{opt egoid}({it:nodeid})]


{title:Description}

{pstd}
The command checks if node {it:nodename} exists in network {it:netname} and returns its {it:nodeid}. In
case it does not exist, it returns -1.

 

{title:Supported network types}

{pstd}
Binary: yes. Directed: yes. Weighted: yes. Signed: yes. Two-mode: yes - a pure node-existence/lookup check; does not read tie values or depend on directed/valued/two-mode status.

{title:Examples}

	{cmd:. nwwebuse florentine}
	{cmd:. nwnode flobusiness, ego(medici)}


{title:Stored values}

	{cmd:r(nodeid)}
	{cmd:r(nodename)}
	
{title:See also}
   
   {help nwvalue}
***/

capture program drop nwnode
program nwnode
	version 9
	syntax [anything(name=netname)], [ego(string) egoid(string)]
	nw_syntax `netname'
	
	if "`ego'" == ""  & "`egoid'" == "" {
		di "{err}Either option {bf:ego()} or {bf:egoid()} needs to be specified."
		err 99
	}
	
	mata: st_numscalar("r(nodeid)", -1)
	
	if "`egoid'" != "" {
		confirm number `egoid'
		if `egoid' <=0 | `egoid' > `nodes'{
			di "{err}Egoid `egoid' out of range"
			err 99
		}
		mata: st_global("r(nodename)", `netobj'->get_nodenames()[`egoid'])
		mata: st_numscalar("r(nodeid)", `egoid')
	}
	else if "`ego'" != "" {
		mata: st_numscalar("r(nodeid)", `netobj'->get_nodeid_from_nodename("`ego'"))
		mata: st_global("r(nodename)", "`ego'")
	}
	else {
		di "{err}Either option {bf:ego()} or {bf:egoid()} needs to be specified."
	}
	
	di ""
	di "{txt}Network: {res}`netname'"
	di "{txt}Search node: {res}`ego'"
	if `r(nodeid)' == -1 {
		di "	Not found"
	}
	else {
		di "{txt}Ego id: {res}`r(nodeid)'"
	}
end

