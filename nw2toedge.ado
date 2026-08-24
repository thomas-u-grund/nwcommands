/***
{smcl}
{* *! 12jul2016 author: Thomas Grund}{...}
{marker topic}
{helpb nw_topical##import:[NW-2.2] Import/Export}

{title:Title}

{p2colset 9 18 22 2}{...}
{p2col :nwtoedge {hline 2}}Convert two-mode network to edgelist{p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 17 2}
{cmdab: nw2toedge} 
[{it:{help netlist}}]
[{cmd:,}
{opth egovars(varlist)}
{opth altervars(varlist)}
{opth ego(newvarname)}
{opth alter(newvarname)}]
		
{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opth egovars(varlist)}}Keep attributes of sending nodes{p_end}
{synopt:{opth altervars(varlist)}}Keep attributes of receiving nodes {p_end}
{synopt:{opth ego(newvarname)}}Sender of ties; default = {it:_ego}{p_end}
{synopt:{opth alter(newvarname)}}Receiver of ties; default = {it:_alter}{p_end}

{p2colreset}{...}


{title:Description}

{pstd}
{cmd:nwtoedge} makes an edgelist from a two-mode network or a list of networks. 

{pstd}
An edgelist of a single network {help netname} produced by {cmd:nwtoedge} is a set of three variables representing
the relations in the network. The first variable ({it:_ego}) gives the {help nodeid}
of the sending node {it:i} of a relationship; the second variable ({it:_alter}) gives the {help nodeid} of the 
receiving node {it:j}. Lastly, the variable {it:netname} saves information about the 
dyad pair ({it:i},{it:j}) in the network {it:netname}. 

{pstd}
When a network is undirected only one entry for the dyad pair ({it:i},{it:j})
is generated, unless option {opt full} is specified. 

{pstd}
When the command is used with a {help netlist}, it generates one new variable for each network {it:netname} in the list. If only one
of the networks in {help netlist} is directed, the option {opt full} is enforced.

{pstd}
One can also include node attributes (saved as normal Stata variables) in the edgelist. Option {opt egovars()} 
generates new variables that match the attributes of the sender of a tie (ego); option {opt altervars()} 
generates new variables that match the attributes of the receiver of a tie (alter).

{pstd}
For two-mode networks (see {help nw2set:introduction to two-mode networks}) the command automatically
generates the two variables {it:_nwmode_ego} and {it:_nwmode_alter}. They indicate in the edgelist format
the mode to which a node belongs.
  
{title:See also}
	
	{help nw2fromedge}, {help nwtoedge}, {help nwsave}

***/
capture program drop nw2toedge
program nw2toedge
	version 9
	syntax [anything(name=netname)][, isolates0 compress upper egovars(varlist) altervars(varlist)  ///
	ego(name) alter(name) full ignore2mode] 

	unw_defs
	nw_syntax `netname', max(9999)
	local nets `netname'

	
	if "`ego'" == "" {
		local ego = "`nw_ego'"
	}
	if "`alter'" == "" {
		local alter = "`nw_alter'"
	}	

	foreach net in `nets' {
		nw_datasync `net'
	}
	
	// Deal with two-mode networks
	if "`is2mode'" == "true"  & "`ignore2mode'" == ""{
		local egovars "`nw_mode' `egovars'"
		local altervars "`nw_mode' `altervars'"
	}

	// Handle attributes of nodes
	qui if "`egovars'" != "" {
		preserve
		tempfile fromfile
		keep `nw_nodename' `egovars' 
		foreach var of varlist `egovars' {
			rename `var' `var'`ego'
		}
		save `fromfile'
		restore
	}
	
	qui if "`altervars'" != "" {
		preserve
		tempfile tofile
		keep `nw_nodename' `altervars'
		foreach var of varlist `altervars' {
			rename `var' `var'`alter'
		}
		save `tofile'
		restore
	}
	
	
	// Check if there is at least one directed network in the list
	qui foreach net in `nets' {
		nw_syntax `net'
		if "`directed'" == "true" {
			local full = "full"
		}
	}

	local i = 0
	qui foreach net in `nets' {
		nw_syntax `net'
		tempfile __nwedgelist`i'
		
		if "`upper'" != "" & "`directed'" == "true" {
			noi di "{txt}Warning! Network {res}`net'{txt} is directed. Option {res}upper{txt} surpressed." 
		}
		mata: __nwedgelist`i' = (`netobj'->get_edgelist((("`upper'" != "" | "`directed'" == "false") & "`full'" == "")))[,(1::5)]
		preserve
		drop _all
		tempvar include
		tempvar transp
		getmata (`ego' `alter' `net' `include' `transp') = __nwedgelist`i', force
		destring `include', replace force
		capture drop if `include' != 1
		capture drop `include'
		destring `net', replace force
		mata: mata drop __nwedgelist`i'
		save `__nwedgelist`i''
		restore
		local i = `i' + 1
	}
	
	qui drop _all
	qui use `__nwedgelist0'

	qui forvalues j = 1/`=`i'-1' {
		merge m:n (`ego' `alter') using `__nwedgelist`j'', nogenerate
	}
	
	qui if trim("`egovars'") != "" {
		capture drop `nw_nodename'
		gen `nw_nodename' = `ego'
		merge m:n (`nw_nodename') using `fromfile', nogenerate 
	}
	qui if trim("`altervars'") != "" {
		capture drop `nw_nodename'
		gen `nw_nodename' = `alter'
		merge m:n (`nw_nodename') using `tofile', nogenerate 
	}
	capture drop `nw_nodename'
	sort `ego' `alter'
	qui if "`compress'" != "" {
		tempvar t
		gen `t' = 0
		foreach net in `nets' {
			replace `t' = `t' + abs(`net')
		}
		drop if `t' == 0
	}
	
	foreach net in `nets' {
		capture drop if `net' == `missing2'
	}
	// BUGFIX: this used to run unconditionally, but the `nw_mode'`ego'/
	// `nw_mode'`alter' variables it references only exist when the
	// two-mode block above (line ~94) actually ran - which it
	// deliberately skips when `ignore2mode' is given, since the whole
	// point of that option is to bypass 2-mode-specific handling. Any
	// two-mode network combined with `ignore2mode' crashed ("variable
	// not found") as a result - a completely ordinary, easily-triggered
	// combination. Guarded with the same condition as the block that
	// actually creates those variables.
	if "`is2mode'" == "true" & "`ignore2mode'" == "" {
		qui keep if `nw_mode'`ego' != `nw_mode'`alter'
	}

end
