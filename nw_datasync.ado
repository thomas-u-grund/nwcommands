/***
{smcl}
{* *! version 2.0.0  4jul2016 author: Thomas Grund}{...}
{marker topic}
{helpb nw_topical##analysis:[NW-2.7] Utilities}
version 2.0.0

{title:Title}

{p2colset 9 17 22 2}{...}
{p2col :nw_datasync {hline 2} Utility to sync current network with dataset}
{p2colreset}{...}


{title:Syntax}

{p 8 17 2}
{cmdab: nw_datasync} 
[{it:{help netname}}]
[{cmd:,}
{opt generate}({it:{help varname}})
{opt off}
{opt on}
{opt overwrite}

{synoptset 25 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt generate}({it:{help varname}})}Generate variable that indicates which observations are nodes in current network{p_end}
{synopt:{opt off}}Switch datasync off{p_end}
{synopt:{opt on}}Switch datasync on; default{p_end}
{synopt:{opt overwrite}}Only used for advanced programming {p_end}
{synoptline}
{p2colreset}{...}


{title:Description}

{pstd}
Node attributes are saved in the normal Stata dataset. The observations in the dataset correspond to the nodes in a network. Beginning with version 2.0.0 both are automatically matched by the 
name of the nodes. In the dataset this match is performed on the variable {bf:_nwnode}. In case this variable does not exist, it is automatically created. 

{pstd}
Normally, there is no need to explicitly call {bf:nw_datasync}. All other nwcommands that make use of variables in the Stata dataset (e.g. node attributes) sync automatically.

{pstd}
Syncing is relatively fast, hence, there should be no need to switch it off. Furthermore, a sync is only performed when it is actually needed and the
sorting of the observations on the variable {bf:_nwnode} does not correspond to the sorting of the nodes in the network. For larger networks it can make sense
to switch syncing off. But keep in mind that then it is up to you to make sure that observations correspond to nodes in the network. In this case, the first observation in the
dataset is matched with the first node in the network and so on.
***/


capture program drop nw_datasync
program nw_datasync
	syntax [anything(name=netname)] [, force overwrite generate(string) on off]
	unw_defs
	if "`on'" != "" {
		di "{txt}Switching datasync on."
		mata: `nws'.set_datasync(1)
	}
	if "`off'" != "" {
		di "{txt}Switching datasync off."
		mata: `nws'.set_datasync(0)
	}
	nw_syntax `netname'
		
	capture confirm variable `nw_nodename'
	
	// Maybe datasync is not needed
	if (_rc == 0 & _N >= `nodes' & "`force'" == ""){
		qui putmata `nw_nodename' if _n <= `nodes' , replace
		mata: check_signatures(`nodes', `netobj'->get_nodenames(), "`nw_nodename'", `netobj'->is_2mode())
		mata: mata drop `nw_nodename'
	}
	
	if `datasync' == 0 {
		di "{txt}Warning! Datasync switched off. Variables might be corrupted."
		exit
	}
	
	set more off
	tempfile f
	tempname nodename
	tempname nodeindex

	mata: `nodename' = (`netobj'->get_nodenames())'
	mata: st_numscalar("r(nodes)", `netobj'->get_nodes())
	
	if "`overwrite'" != "" {
		capture drop `nw_nodename'
		qui getmata `nw_nodename' = `nodename', force replace
		capture mata: mata drop `nodename'
		capture mata: mata drop `nodeindex'
		exit
	}
	
	preserve
	drop _all

	unw_defs
	tempname mode

	//if `r(nodes)' > `=_N' {
		//set obs `r(nodes)'
	//}

	qui getmata `nw_nodename' = `nodename', force replace
	
	nw_syntax `netname'
	
	if ("`is2mode'" == "true") {
		mata: `mode' = (`netobj'->get_modes())'
		qui getmata `nw_mode' =  `mode'
	}
	qui gen `nodeindex' = _n
	qui save `f', replace
	restore
	
	capture confirm variable `nw_nodename'
	qui if (_rc != 0) {
		gen str40 `nw_nodename' = ""
	}

	tempvar current
	qui capture drop `generate'
	qui merge n:1 (`nw_nodename') using `f', generate(`current')

	qui replace `current' = (`current' != 1)
	gsort -`current' +`nodeindex'
	qui if "`generate'" != "" {
		capture drop `generate'
		gen `generate' = (`current'==1)
	}
	else {
		capture drop `nw_included'
		gen `nw_included' = (`current'==1)
	}
	
	
	capture mata: mata drop `mode'
	capture mata: mata drop `nodename'
	capture mata: mata drop `nodeindex'

end

capture mata: mata drop check_signatures()
mata:
void check_signatures(real scalar nodes, string matrix nodenames, string scalar nwnode, string scalar is2mode) {
	if ((nodenames') == st_sdata((1,nodes), nwnode)) {
		if (is2mode != "") {
		   // ----- TODO ----- implement 
		}
		else {
			stata("exit")
		}
	}
}
end


