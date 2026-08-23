/***
{smcl}
{* *! version 2.0.0  19aug2016}{...}
{marker topic}
{helpb nw_topical##manipulation:[NW-2.5] Manipulation}

{title:Title}

{p2colset 9 20 22 2}{...}
{p2col :nwcollapse {hline 2}}Collapse a network{p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 17 2}
{cmdab: nwcollapse} 
[{opt (stat)}]
[{it:{help netname}}]
[{cmd:,}
{opth by(varname)} 
{opth generate(newnetname)} 
{it:{help collapse##table_options:options}}]


{title:Description}

{pstd}
This command collapses a network, i.e. it merges network nodes. It works very similar as {help collapse}. With option {opth by(varname)} one specifies which nodes should
be merged. The rule for collapsing two nodes are specified with {it:stat}, by default {it:stat} = {bf:max} ({help collapse:see here for possible values}). For example, when nodes
A and B are collapsed to node Z, Z inherits all the ties from node A and B. The nodes in the new network are named after the values in {it:varname}.  

{pstd}
By default, an existing network is replaced, unless option {opt generate(newnetname)} is specified. 


{marker examples}{...}
{title:Examples}

{pstd}
This collapses the first and the second node of a random network. The collapsed node will have all ties that the original nodes had. 

	{cmd:. nwrandom 20, prob(.1) name(mynet)}
	{cmd:. gen att = _n}
	{cmd:. replace att = 1 in 2}
	{cmd:. nwcollapse mynet, by(att)}

	
{title:See also}

	{help collapse}
***/

capture program drop nwcollapse
program nwcollapse
	syntax [anything] [, generate(string) by(varname) *]
	
	preserve
	gettoken stat netname : anything, parse(")")
	if "`netname'" == "" {
		local netname "`stat'"
		local stat = "" 
	}
	else {
		local netname = substr("`netname'", 3,.)
		local stat = substr("`stat'",2,.)
	}

	if "`stat'" == "" {
		local stat = "max"
	}
	nw_syntax `netname'
	local original `netname'
	
	if "`name'" == "" {
		local name "`netname'_collapsed"
	}
	
	nwduplicate `original', name(_temp_`original')
	nw_datasync _temp_`original'
	nw_syntax _temp_`original'
	tempvar by_group by_dummy
	gen `by_dummy' = 1
	replace `by_dummy' = . if _n > `nodes'
	tempvar running
	gen `running' = _n
	bys `by': egen `by_group' = total(`by_dummy')
	sort `running'
	replace _nwnode = "new_" + _nwnode if `by_group' > 1
	nwname _temp_`original', newlabsfromvar(_nwnode)
	
	nwtoedge _temp_`original', egovars(`by') altervars(`by') ego(_fromid) alter(_toid)
	
	tempvar _newfrom _newto

	keep _fromid _toid _temp_`original' `by'_fromid `by'_toid
	collapse (`stat') _temp_`original' (firstnm) _fromid _toid , by(`by'_fromid `by'_toid) `options'
	
	if "`generate'" != "" {
		qui nwfromedge _fromid _toid _temp_`original', name(`generate')
	}
	else {
		nwdrop `original'
		qui nwfromedge _fromid _toid _temp_`original', name(`original')
	}
	restore
end

