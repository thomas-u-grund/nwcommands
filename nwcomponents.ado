/***
{smcl}
{* *! version 2.0.0  18aug2016 author: Thomas Grund}{...}
{marker topic}
{helpb nw_topical##analysis_cohesion:[NW-2.6.2] Cohesion, Components & Subgroups}

{title:Title}

{p2colset 9 21 22 2}{...}
{p2col :nwcomponents {hline 2}}Calculate network components / largest component{p_end}
{p2colreset}{...}

{title:Syntax}

{p 8 17 2}
{cmdab: nwcomponents} 
[{it:{help netlist}}]
[, {opt lgc}
{opth generate(newvarname)
{opt replace}]


{synoptset 25 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opth generate(newvarname)}}Name of the Stata variable that stores information about components; default = {it:_component} or {it:_lgc}{p_end}
{synopt:{opt replace}}Replace existing variable{p_end}
{synopt:{opt lgc}}Calculate membership to largest component{p_end}

{p2colreset}{...}
	
{title:Description}

{pstd}
Calculate the components of a network or a list of networks. A component is a set of nodes that are
only connected among each other. All calculations are performed on the undirected network. Nodes can only belong to one component. 

{pstd}
By default, {cmd:nwcomponents} generates 
a new variable {it:_components} which stores the component membership. When
option {bf:lgc} is specified, the command generates a new variable 
{it:_lgc} which stores information about membership to the largest component.


{title:Stored results}

	Scalars
	  {bf:r(components)}		number of components
	  
	Matrices
	  {bf:r(comp_sizeid)}		distribution over components
	  

{title:Examples}

	{cmd:. nwwebuse florentine, nwclear}
	{cmd:. nwcomponents flomarriage}

	{res}{hline 40}
	{txt}  Network name: {res}flomarriage
	{txt}  Components: {res}2

	 {txt}_component {c |}      Freq.     Percent        Cum.
	{hline 12}{c +}{hline 35}
	{txt}          1 {c |}{res}         15       93.75       93.75
	{txt}          2 {c |}{res}          1        6.25      100.00
	{txt}{hline 12}{c +}{hline 35}
	      Total {c |}{res}         16      100.00{txt}
  
 {pstd}
 This shows that there are two components in the Florentine marriage network. All except one node belong to the first
 component. Some alternative ways how the commands can be used.
 
	{cmd:. nwwebuse glasgow}
	{cmd:. nwcomponents glasgow1, generate(mycomponent)} 
	{cmd:. nwcomponents _all, lgc} 
	{cmd:. nwcomponents _all, lgc generate(mylgc)} 
  

 {title:See also}
 
	{help nwgen}, {help nwkcomponents}

***/

capture program drop nwcomponents
program nwcomponents, rclass
	version 9
	syntax [anything(name=netname)][, lgc GENerate(string) replace ]
	set more off

	nw_syntax `netname', max(9999)
	
	if `networks' > 1 {
		local k = 1
	}
	
	qui foreach netname_temp in `netname' {
		nwname `netname_temp'
		local nodes = r(nodes)

		if "`generate'" == "" {
			if "`lgc'" == "" {
				local generate = "_component"
			}
			else {
				local generate = "_lgc"
			}
		}
		
		// Checks the exact suffixed name this iteration is about to
		// create, not the bare stem - Stata's own variable-name
		// abbreviation would otherwise let `confirm variable
		// _component' match an already-existing `_component1' on a
		// later netlist iteration, falsely blocking that iteration
		// even though its own target name is still free. Found while
		// building nwconcor.ado's netlist support (same underlying
		// bug in the same copy-pasted pattern - see its own certified
		// row).
		capture confirm variable `generate'`k', exact
		if _rc == 0 & "`replace'" == "" {
			noi di "{err}Variable {bf:`generate'`k'} already exists; specify {bf:replace}"
			err 99
		}
		
		capture drop `generate'`k'
		gen `generate'`k' = .
		mata: st_rclear()
		qui if _N < `nodes' {
			set obs `nodes'
		}
		nw_syntax `netname_temp'
		mata: st_store((1::`nodes'),"`generate'`k'", `netobj'->calculate_components())

		qui tab `generate'`k', matrow(comp_id) matcell(comp_size)
		
		mata: comp_id = st_matrix("comp_id")
		mata: comp_number = rows(comp_id)
		mata: comp_size = st_matrix("comp_size")
		mata: comp_share = comp_size :/ (sum(comp_size))
		mata: comp_sizeid = J(comp_number, 3, 0)
		mata: comp_sizeid[.,1] = comp_size
		mata: comp_sizeid[.,2] = comp_id
		mata: comp_sizeid[.,3] = comp_share
		mata: comp_sizeid = sort(comp_sizeid, -1)
		mata: st_numscalar("components", comp_number)
		mata: st_matrix("comp_sizeid", comp_sizeid)
			
		matrix colnames comp_sizeid = size compid share
	
		local rowlabs ""
			
		return scalar components = components
		local lcomp = components
		
		forvalues i = 1/`=components'{
			local rowlabs "`rowlabs' comp`i'"
		}
		matrix rownames comp_sizeid = `rowlabs'
		return matrix comp_sizeid = comp_sizeid
		mata: mata drop comp_number comp_share comp_id comp_size comp_sizeid

		noi di "{hline 40}"
		noi di "{txt}  Network name: {res}`netname_temp'"
		noi di "{txt}  Components: {res}`lcomp'"

		
		qui if "`lgc'" != "" {
			tab `generate'`k', matcell(freqs) matrow(comps)
			local freqs_max = 1
			local freqs_all = rowsof(freqs)
			forvalues i = 1/`freqs_all' {
				if freqs[`freqs_max',1] < freqs[`i',1] {
					local freqs_max = `i'
				}
			}
			local comps_lgc = comps[`freqs_max',1]
			replace `generate'`k' = 0 if `generate'`k' != `comps_lgc' & `generate'`k' != .
			replace `generate'`k' = 1 if `generate'`k' == `comps_lgc' & `generate'`k' != .	
		}
		noi tab `generate'`k'
		noi di " "
		noi di " "
		local k = `=`k' + 1'
		
	}
end
