/***
{smcl}
{* *! version 2.1  13may2019 author: Thomas Grund}{...}
{marker topic}
{helpb nw_topical##import:[NW-2.2] Import/Export}

{title:Title}

{p2colset 9 14 22 2}{...}
{p2col :nwsave  {hline 2} Save network data in file}
{p2colreset}{...}

{title:Syntax}

{p 8 17 2}
{cmdab: nwsave} 
{it:{help filename}}
[{cmd:,}
{cmd:replace}]


{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{cmd: replace}}overwrite existing dataset{p_end}


{title:Description}

{pstd}
{bf:nwsave} saves all networks (and Stata variables) currently in memory on disk. Since version 2.1 the
command saves data in its own file format {bf:.nwdta}. Network data saved in this way
can be loaded with {help nwuse}. Notice that the command {help save} does not save
network data.

{title:Examples}
        
{pstd}
This example creates 5 new random networks and {help nwsave:saves} them as {it:mynets}. A new dataset called {it:mynets.nwdta} is created in the working directory.

        {cmd:. nwclear}
        {cmd:. nwrandom 20, ntimes(5) prob(.2)}
        {cmd:. nwsave mynets}

{pstd}
After this, one can easily load these 5 networks in a new Stata session just as if one would load a normal Stata dataset. 

        {cmd:. nwuse mynets}
        

{title:See also}

        {help nwuse}, {help nwwebwuse}, {help save}
***/
capture program drop nwsave_new
program nwsave_new
	syntax anything [, old replace * format(string)]
	local webname = subinstr("`anything'", ".dta","",.)
	unw_defs
	
	nw_syntax _all, max(99999)
	local nets r(networks)

	local format = "edgelist"
	
	
	// save attributes first
	foreach onenet in `netname' {
		nwload `onenet', labelonly
	}
	capture drop _nwinclude
	tempfile attributes
	gen _nw_running = _n
	save`old' `attributes', replace
	
	// obtain edgelists for each network together with entries to which network entry belongs
	nw_syntax _all, max(99999)
	qui foreach onenet in `netname' {
		nwload `onenet', labelonly
		gen _nw_match_`onenet' = 1 if _nwinclude == 1
	}
	
	qui nwtoedge _all, egovars(_nw_match_*) ego(_nw_ego) alter(_nw_alter)
	qui gen _nw_running = _n
	tempfile edgelist
	save`old' `edgelist', replace

	clear
	qui nwset
    set obs `r(networks)'
	qui {
	 gen _nw_format = "" 
	 gen _nw_nets = . 
	 gen _nw_netname = ""
	 gen _nw_size = .
	 gen _nw_directed = ""
	 gen _nw_twomode = .
	 gen _nw_selfloop = .
	 gen _nw_title = ""
    }
	local i = 1
	
	qui foreach onenet in `netname' {
		nwname `onenet'
		replace _nw_netname = "`onenet'" in `i'
		local nodes = `r(nodes)'
		replace _nw_size = `nodes' in `i'
		replace _nw_directed = "`r(directed)'" in `i'
		replace _nw_format = "edgelist" in `i'
		replace _nw_title = "r(title)" in `i'
		replace _nw_selfloop = "r(selfloop)" in `i' 
		replace _nw_twomode = "r(mode2)" in `i' 
		local i = `i' + 1
	}
	qui replace _nw_nets = `=`i'-1' in 1
	qui gen _nw_running = _n
	tempfile metadata
	qui save`old' `metadata', replace
	
	qui merge 1:1 _nw_running using `attributes', nogenerate
	qui merge 1:1 _nw_running using `edgelist', nogenerate
	
	qui save`old' `webname'.nwdta, replace `options'
end

