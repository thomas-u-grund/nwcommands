/***
{smcl}
{* *! 11jul2016 author: Thomas Grund}{...}
{marker topic}
{helpb nw_topical##manipulation:[NW-2.5] Manipulation}

{title:Title}

{p2colset 9 15 22 2}{...}
{p2col :nwdrop {hline 2}}Drop networks or network nodes{p_end}
{p2colreset}{...}

{title:Syntax}

{p 8 17 2}
{cmdab: nwdrop} 
[{it:{help netlist}}]

{p 8 17 2}
{cmdab: nwdrop} 
[{it:{help netname}}]
{ifin}
[{cmd:,}
{opt clean}]


{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt clean}}Drop node observations{p_end}

{synoptline}
{p2colreset}{...}

	
{title:Description}

{pstd}
Drops a network or a list of networks. The command is the network version of {help drop} and mirrors {help nwkeep}.

{pstd}
It can also be used with {help if} or {help in}. Then it only drops certain nodes from a network. This updates the
Stata variable {bf:_nwinclude}, which indicates if a node is included in a network.

{title:Examples}

{pstd}
The following command loads data from the internet and drops one network.

	{cmd}. nwwebuse florentine
	{com}. nwds
	{res}{txt}{col 1}flobusiness   {col 20}flomarriage

	{com}. nwdrop flobusiness
	{com}. nwds
	{res}{txt}{col 1}flomarriage

{pstd}
The next command drops the first three nodes of network {it:flomarriage}.
	
	{cmd:. nwdrop flomarriage if _n <= 3}

{pstd}
This drops every node from the network {it:flomarriage} where the variable {it:seat} != 1.

	{cmd:. nwdrop flomarriage if seat != 1}
	
	{pstd}
This drops the node with the name "medici" from the {it:flomarriage} network.

	{cmd:. nwdrop flomarriage if _nwnode == "medici"}

{pstd}
Whenever a command allows a {help netlist}, networks can be abbreviated. For example,

	{cmd:. nwdrop fl*}
	{cmd:. nwdrop _all}
		

{title:Remarks}

{pstd}
By default, all dropped nodes remain in the dataset, i.e. they are only excluded from the network. With option
{bf:clean}, dropped nodes are removed from the Stata dataset as well. Notice that for example the node
"medici" in the Florentine dataset is a node in both the marriage and the business network. Hence, the option {bf:clean}
would remove this node and all node attributes. In the example above, the node "medici" would be removed from the {bf:flomarriage}
network, but not from the {bf:flobusiness} network. But with the option {bf:clean} all node attributes would be deleted as well (although the node "medici" remains in the {bf:flobusiness}
network). 

{title:Also see}
   
   {help nwdropnodes}, {help nwclear}, {help nwkeep}, {help nwkeepnodes}

***/

capture program drop nwdrop
program nwdrop
	version 9
	syntax [anything(name=netname)] [if] [in], [clean]
	unw_defs
	nw_syntax `netname', max(9999)

	if `"`if'"' == "" & `"`in'"' == "" {
		foreach netname_temp in `netname' {
			mata: `nws'.drop("`netname_temp'")
		}
		qui nwset
		if r(networks) == 0 {
			capture mata: mata drop `nw'
		}
	}
	else {
		nw_syntax `netname', max(1)
		local n `nodes'
		nw_datasync `netname'
		
		tempvar ifcond temp
		tempname drop
		qui gen `ifcond' = 1 `if' `in'
		qui gen `temp' = `ifcond' * `nw_included'
		mata: `drop' = (st_data((1::`nodes'),"`ifcond'"))'
		mata: _editmissing(`drop', 0)
		mata: `netobj'->drop_nodes(`drop')
		mata: mata drop `drop'
		if "`clean'" != "" {
			capture drop if `temp' == 1
		}
		nw_datasync `netname'
	}
	mata: st_rclear()
end


