/***
{smcl}
{* *! version 1.0.6  23aug2014 author: Thomas Grund}{...}
{marker topic}
{helpb nw_topical##generator:[NW-2.3] Generators}
{marker top2}
{helpb nw_topical##analysis:[NW-2.6] Analysis}

{title:Title}

{p2colset 9 15 22 2}{...}
{p2col :nwgen {hline 2} Network extensions to generate}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}


{p 8 17 2}
{cmd:nwgen} {it:{help newnetname}} {cmd:=} {it:netfcn}({it:arguments}) [{cmd:,} {it:options}]

{p 8 17 2}
{cmd:nwgen} {it:{help newnetname}} {cmd:=} {it:{help netexp}} [{help if}] [{cmd:,} {it:options}]
		


{title:Description}

{pstd}
The command generates a network. It can be used either with a) some function {bf:{it:netfnc}} or b) with a network expression {bf:{it:netexp}}. 


{pstd}
{it:netfcn} is one of:

{phang2}{opth duplicate(netname)} [, {opt xvars}]
{p_end}
{pmore2}Duplicate a network (see {help nwduplicate}).
 
{phang2}{opth dyadprob(netname)} , {opth density(float)} [{opt undirected} {opt xvars}]
{p_end}
{pmore2}Generate a network based on tie probabilities (see {help nwdyadprob}).

{phang2}{opth geodesic(netname)} [{cmd:,}
{opth unconnected(integer)}
{opt nosym}
{opt xvars}]
{p_end}
{pmore2}Generate a network of shortest paths between nodes (see {help nwgeodesic}).

{phang2}{opth homophily(varname)}, {opth homophily(float)} {opth density(float)} [...]
{p_end}
{pmore2}Generate a homophily network (see {help nwhomophily}).

{phang2}{opt lattice}({it:{help int:rows cols}}) [, {opt undirected} {opt xwrap} {opt ywrap} {opt xvars}] 
{p_end}
{pmore2}Generate a lattice network (see {help nwlattice}).

{phang2}{opth large(netname)}
{p_end}
{pmore2}Extract the largest component as a network.

{phang2}{opth path(netname)}, {opth ego(nodeid)} {opth alter(nodeid)} [{opth length(int)} {opt sym} {opt xvars}] 
{p_end}
{pmore2}Generate a network of paths between nodes (see {help nwpath}).

{phang2}{opth permute(netname)} [, {opt xvars}] 
{p_end}
{pmore2}Random permutation of a network (see {help nwpermute}).

{phang2}{opt pref}({help int:nodes}) [, {opth m0(int)} {opth m(int)} {opth prob(float)} {opt undirected} {opt xvars}] 
{p_end}
{pmore2}Generate a preferential attachment a network (see {help nwpref}).

{phang2}{opt random}({help int:nodes}) [, {opth prob(float)} {opth density(float)} {opt undirected} {opt xvars}] 
{p_end}
{pmore2}Generate a random network (see {help nwrandom}).

{phang2}{opth reach(netname)} [, {opt nosym} {opt xvars}] 
{p_end}
{pmore2}Generate a reachability network (see {help nwreach}).

{phang2}{opt ring}({help int:nodes}) , {opth k(int)} [{opt undirected} {opt xvars}] 
{p_end}
{pmore2}Generate a ring lattice (see {help nwring}).

{phang2}{opt small}({help int:nodes}) , {opth k(int)} [{opth prob(float)} {opth shortcuts(int)} {opt undirected} {opt xvars}] 
{p_end}
{pmore2}Generate a small-world network (see {help nwsmall}).

{phang2}{opth transpose(netname)} [, {opt xvars}] 
{p_end}
{pmore2}Transpose a network (see {help nwtranspose}).
***/

capture program drop nwgenerate
program nwgenerate
	local arg `0'
	gettoken arg options: arg, parse(",") bind
	if "`options'" != "" {
		local options: subinstr local options "," " " 
	}
	
	gettoken newnetname netexp: arg, parse("=")
	local netexp: subinstr local netexp "_if" "$$ff"
	local netexp: subinstr local netexp "if" "#"
	
	gettoken dump opts: arg, parse(",") bind
	if "`opts'" != "" {
		local 0 `opts'
		syntax [, xvars vars(string) replace *]
	}
	local fcn_opt = "`options'"
	local newnetname = trim("`newnetname'")
	
	unw_defs
		
	capture nw_syntax `newnetname'

	if _rc == 0 & (strpos("`options'", "replace")==0){
		di "{err}Network {bf:`newnetname'} already exists. Change {it:netname} or specify option {bf:replace}.{txt}"
		error 6099
	}
	else {
		capture nwdrop `newnetname'
	}
	
	// if condition
	local netexp: subinstr local netexp "_if" "$"	
	gettoken netexp ifcond: netexp, parse("#")
	local ifcond: subinstr local ifcond "#" "if"
	local ifcond: subinstr local ifcond "$$ff" "_if"
	local netexp: subinstr local netexp "$$ff" "_if"

	
	// check if network or variable should be created
	local netexp : subinstr local netexp "("  "( "	
	local selectjob : word 2 of `netexp'
	local nwgenopt "large( addnodes( collapse( duplicate( dyadprob( geodesic( subset( homophily( lattice( path( permute( pref( random( reach( ring( small( sym( transpose( evcent( context( degree( outdegree( indegree( isolates( components( lgc( clustering( closeness( farness( nearness( between("
	local whichjob : list  nwgenopt & selectjob
	local netfcn : word count `whichjob'
	
	// no varfcn or netfcn
	if `netfcn' == 0 {
		local netexp : subinstr local netexp "=" " "
		capture nw_name `newnetname'
		if _rc == 0 & (strpos("`options'", "replace")==0){
			di "{err}network {it:`netname'} already defined"
			error 6004
		}
	
		// replace the network if it exists already
		if (strpos("`options'", "replace")!=0){
			capture nwdrop `netname'
			local options ""
		}

		// evaluate network expression
		nw_expnetexp `netexp'
		nwset, mat(`netexp') name(`newnetname') `undirected' `options' xvars nodenames(`last_netobj'->get_nodenames())
		qui nwsym `newnetname', check
		
		if `r(is_symmetric)' == 1 {
			nw_name `newnetname', newdirected(false)
		}
		
		if "`ifcond'" != "" {
			qui nwkeep `newnetname' `ifcond'
		}
	}
	
	// generate network based on function
	else  {
		
		// get whatever is inside parenthesis
		local start = strpos("`netexp'", "(")
		local length2 = length("`netexp'")
		local length = `length2' - `start' - 1
		//local length = (strpos("`netexp'",")")) - `start' 
		local subopt = substr("`netexp'", `=`start' + 1', `length')
		
		local optionsold `options'
		
		local 0 `subopt'
		syntax [anything(name=sub1)] [, *]
		local sub2 `options'
		
		/* DEBUG
		di "newnetname: `newnetname'"
		di "netexp: `netexp'"
		di "subopt: `subopt'"
		di "sub1: `sub1'"
		di "sub2: `sub2'"
		di "options: `options'"
		*/
		
		qui if "`whichjob'" == "large(" {	
			tempvar _lgc
			nwcomponents `sub1', lgc generate(`_lgc')
			nwduplicate `sub1',  name(`newnetname')
			nwkeep `netname' if `_lgc' == 1
		}	
		
		// nwduplicate shortcut
		qui if "`whichjob'" == "duplicate(" {
			noi nw_syntax `sub1', max(1) 
			nwduplicate `sub1', `sub2' name(`newnetname') `fcn_opt'
		}	

		// nwdyadprob shortcut - NOT YET RESTORED, see note below
		qui if "`whichjob'" == "dyadprob(" {
			noi di "{err}nwgen's dyadprob() shortcut is not currently implemented; use {help nwdyadprob} directly."
			error 199
		}

		// nwgeodesic shortcut
		qui if "`whichjob'" == "geodesic(" {
			noi nw_syntax `sub1', max(1)
			nwgeodesic `sub1', `sub2' name(`newnetname') `fcn_opt'
		}
		// nwhomophily shortcut - NOT YET RESTORED, see note below
		qui if "`whichjob'" == "homophily(" {
			noi di "{err}nwgen's homophily() shortcut is not currently implemented; use {help nwhomophily} directly."
			error 199
		}
		// nwlattice shortcut - NOT YET RESTORED, see note below
		qui if "`whichjob'" == "lattice(" {
			noi di "{err}nwgen's lattice() shortcut is not currently implemented; use {help nwlattice} directly."
			error 199
		}
		// nwpath shortcut - NOT YET RESTORED, see note below
		qui if "`whichjob'" == "path(" {
			noi di "{err}nwgen's path() shortcut is not currently implemented; use {help nwpath} directly."
			error 199
		}
		// nwpermute shortcut
		qui if "`whichjob'" == "permute(" {
			noi nw_syntax `sub1', max(1)
			nwpermute `sub1', `sub2' name(`newnetname') `fcn_opt'
		}
		// nwpref shortcut - NOT YET RESTORED, see note below
		qui if "`whichjob'" == "pref(" {
			noi di "{err}nwgen's pref() shortcut is not currently implemented; use {help nwpref} directly."
			error 199
		}
		// nwrandom shortcut
		qui if "`whichjob'" == "random(" {
			nwrandom `sub1', `sub2' name(`newnetname') `fcn_opt'
		}
		// nwreach shortcut
		qui if "`whichjob'" == "reach(" {
			noi nw_syntax `sub1', max(1)
			nwreach `sub1', `sub2' name(`newnetname') `fcn_opt'
		}
		// nwring shortcut - NOT YET RESTORED, see note below
		if "`whichjob'" == "ring(" {
			noi di "{err}nwgen's ring() shortcut is not currently implemented; use {help nwring} directly."
			error 199
		}
		// nwsmall shortcut - NOT YET RESTORED, see note below
		qui if "`whichjob'" == "small(" {
			noi di "{err}nwgen's small() shortcut is not currently implemented; use {help nwsmall} directly."
			error 199
		}
		// nwtranspose shortcut - NOT YET RESTORED, see note below
		qui if "`whichjob'" == "transpose(" {
			noi di "{err}nwgen's transpose() shortcut is not currently implemented; use {help nwtranspose} directly."
			error 199
		}

	}
	/*
		The 8 shortcuts above (dyadprob/homophily/lattice/path/pref/ring/
		small/transpose) previously had their bodies commented out - a
		user calling e.g. -nwgen X = ring(5)- would silently do nothing
		instead of generating a network or erroring, a real (if quiet)
		bug found during this session's feature audit. Turned into a
		clear, immediate error rather than silently restoring the
		commented-out bodies unverified: each of the 8 target commands'
		current option syntax needs to be individually re-checked against
		what these dispatch lines originally assumed (written years ago)
		before re-enabling - see docs/ROADMAP.md, Stage 1.
	*/

end
