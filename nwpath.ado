/***
{smcl}
{* *! version 2.0.1  29may2019 author: Thomas Grund}{...}
{marker topic}
{helpb nw_topical##generator:[NW-2.3] Generators}
{marker top2}
{helpb nw_topical##analysis_paths:[NW-2.6.5] Paths, Reachability & Ego Networks}

{title:Title}

{p2colset 9 15 22 2}{...}
{p2col :nwpath {hline 2}}Calculate paths between nodes{p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 17 2}
{cmdab: nwpath} 
[{it:{help netname}}],
[{opth ego(nodename)}
{opth alter(nodename)} | 
{opth egoid(nodeid)}
{opth alterid(nodeid)}]
{opth generate(newnetnamestub)}
{opt sym}
{opt nwreplace}]


{synoptset 23 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Main}
{synopt:{opth ego(nodename)}}Name of start node{p_end}
{synopt:{opth alter(nodename)}}Name of destination node{p_end}
{synopt:{opth egoid(nodeid)}}Nodeid of start node{p_end}
{synopt:{opth alterid(nodeid)}}Nodeid of destination node{p_end}
{synopt:{opth generate(newnetnamestub)}}Save paths as networks beginning with {it:newnetnamestub}{p_end}
{synopt:{opt sym}}Symmetrize network for calculation{p_end}
{synopt:{opt nwreplace}}Overwrite networks with {it:newnetnamestub}{p_end}
{synoptline}
{p2colreset}{...}

		
{title:Description}

{pstd}
{cmd: nwpath} calculates the shortest paths between node {it:ego} and node {it:alter}, i.e. ways how the nodes
are connected with each other.

{pstd}
With option {opth generate(newnetname)} the command produces one new network for each valid path that is found.
For example, if three paths are found between nodes {it:ego} and {it:alter}, the networks {it:newnetnamestub_1, newnetnamestub_2, newnetnamestub_3}
are produced.


{title:Supported network types}

{pstd}
Binary: yes. Directed: yes ({opt sym} to symmetrize first). Weighted: not applicable - any nonzero
tie is treated as traversable regardless of its value; there is currently no shortest-{it:weighted}
-path variant (see {help nwgeodesic} for weighted distances). Signed: not checked. Two-mode: not
checked.


{title:Options}

{p2col 5 30 30 30:{opth ego(nodename)}}Must be specified and indicates the startpoint of a path.

{p2col 5 30 30 30:{opth alter(nodename)}}Must be specified and indicates the endpoint of a path.

{p2col 5 30 30 30:{opt sym}}Calculates everything on the symmetrized network.{p_end}

{p2col 5 30 30 30:{opth generate(newnetnamestub)}}Save the paths as networks. This can be used to display 
paths using nwplot, see example.{p_end}


{title:Remarks}

{pstd}
It can be a good idea to save the paths between two nodes by specifying {opth generate(newnetname)} for plotting.
For example, 

	{cmd:. nwwebuse florentine, nwclear}
	{cmd:. nwpath flobusiness, ego(medici) alter(peruzzi) generate(medici_peruzzi)}

{pstd}
There is exactly one shortest path between {it:medici} and {it:peruzzi}, so a single network,
{it:medici_peruzzi_1}, is generated ({opt generate()} is a stub - one network per shortest path found,
numbered {it:_1}, {it:_2}, ... - so a pair of nodes with multiple shortest paths would instead
produce {it:medici_peruzzi_1}, {it:medici_peruzzi_2}, and so on).
One can now use this new network to represent the edgecolor when plotting the original network.

	{cmd:. nwplot flobusiness, edgecolor(medici_peruzzi_1) scheme(s2network)}


{title:Examples}


     {cmd:. nwwebuse florentine}
     {cmd:. nwpath flobusiness, ego(medici) alter(peruzzi)}
     {res}
     {hline 40}
     {txt}  Network: {res}flobusiness
     {hline 40}
     {txt}    Ego                  : {res}medici
     {txt}    Alter                : {res}peruzzi
     {txt}    Shortest path length : {res}3
     {hline 40}

     {txt}  Path 1:  {res}medici{txt} => {res}barbadori{txt} => {res}castellani{txt} => {res}peruzzi
     {txt}  Path 2:  {res}medici{txt} => {res}ridolfi{txt} => {res}strozzi{txt} => {res}peruzzi{txt}
	

{title:Stores results}

	Scalars:
	  {bf:r(paths)}		 number of shortest paths found (0 if {it:ego} and {it:alter} are not connected)
	  {bf:r(path_length)}	 length of the shortest path (-1 if not connected)
	  {bf:r(path_shortest)}	 same as {bf:r(path_length)}; this command currently only ever finds
	                    shortest paths, there is no {bf:length()} option to select a longer one
	  {bf:r(ego)}		 nodeid of ego
	  {bf:r(alter)}		 nodeid of alter

	Matrices:
	  {bf:r(paths_matrix)}	one row per path found, node ids along the path; only set when
	                    {bf:r(paths)} > 0


{title:Also see}

   {help nwgeodesic}

***/
capture program drop nwpath
program nwpath
	version 9
	// `name(string)' removed - it was accepted by syntax but never
	// referenced anywhere in this file's body (a fully dead,
	// undocumented no-op; confirmed via grep). The real option for
	// naming this command's output network(s) is `generate()' - a stub
	// prefix, since one call can produce multiple path networks, so
	// `name()' could not simply have aliased it (a single fixed name
	// doesn't fit a multi-network stub the way it does for other
	// commands in this group).
	syntax [anything(name=netname)],  [nwreplace ego(string) alter(string) egoid(integer 0) alterid(integer 0) sym generate(string) ]
	
	if "`sym'" != "" & "`generate'" != "" {
		di "{err}Options {bf:sym} and {bf:generate()} cannot be combined."
		err 99
	}
	if "`ego'" == "" & "`egoid'" == "" {
		di "{err}Either options {bf:ego()} or {bf:egoid} needs to be specified"
		err 99
	}
	if "`alter'" == "" & "`alterid'" == "" {
		di "{err}Either options {bf:ego()} or {bf:egoid} needs to be specified"
		err 99
	}
	nw_syntax `netname', max(1)
	
	if `egoid' != 0 {
		qui capture nwnode `netname', egoid(`egoid')
		if _rc != 0 {
			noi di "{err}Egoid {bf:`egoid'} out of bounds"
			err 99
		}
		local ego "`r(nodename)'"
	}
	if `alterid' != 0 {
		qui capture nwnode `netname', egoid(`alterid') 
		if _rc != 0 {
			noi di "{err}Alterid {bf:`alterid'} out of bounds"
			err 99
		}
		local alter "`r(nodename)'"
	}
	
	if "`directed'" == "false" {
		local undirected_sign "<"
	}
	
	set more off
	if "`length'" == "" {
		local length 0
	}
	
	// check if ego or alter does not exit
	capture qui nwvalue `netname', ego("`ego'") alter("`alter'")
	if _rc != 0 {
		di "{err}Node {bf:`ego'} or {bf:`alter'} does not exist in network {it:`netname'}; check spelling"
		error 99
	}
	local egoid `r(ego_id)'
	local alterid `r(alter_id)'
	local netname_orig `netname'
	
	tempname _path _sym
	if "`sym'" != "" {
		nwduplicate `netname', name(`_sym')
		nwsym `_sym'
		nw_syntax `_sym'
		local symtext " (symmetrized)"
		local undirected_sign "<"
	}
	mata: `_path' = `netobj'->get_path(`egoid', `alterid', `length')
	mata: st_numscalar("r(paths)", rows(`_path'))
	mata: st_numscalar("r(path_length)", cols(`_path') - 1)
	mata: st_numscalar("r(ego)", `egoid')
	mata: st_numscalar("r(alter)", `alterid')
	// r(path_shortest): this command only ever finds shortest paths -
	// length() is documented (and was previously documented as though
	// implemented) but was never actually a real syntax option, so
	// there is currently no way to request a longer, non-shortest path.
	// r(path_shortest) is therefore always identical to r(path_length)
	// today; kept as its own explicit return (rather than removed from
	// the documented interface) so it is already in place, unchanged,
	// on the day a real length()-selection option is eventually added.
	mata: st_numscalar("r(path_shortest)", cols(`_path') - 1)
	if `r(paths)' > 0 {
		mata: st_matrix("r(paths_matrix)", `_path')
	}


	di ""
	di "{hline 40}"
	di "{txt}  Network: {res}`netname_orig'`symtext'"
	di "{hline 40}"
	di "{txt}    Ego                  : {res}`ego'"
	di "{txt}    Alter                : {res}`alter'"
	if `r(path_length)'>=0 {
		di "{txt}    Shortest path length : {res}`r(path_length)'"
	}
	else {
		di "{txt}    Shortest path length : {res}not connected"
	}
	di "{hline 40}"
	
	forvalues i = 1/`r(paths)' {
		local p "{txt}	Path `i': {res}`ego'"
		forvalues j = 2/`=`r(path_length)'+1' {
			mata: st_local("next", `netobj'->get_nodenames()[`_path'[`i',`j']])
			local p "`p' `undirected_sign'=> `next'"
		}
		di "`p'"
	}

	
	if "`generate'" != "" {
		forvalues i = 1/`r(paths)' {
			capture nw_syntax `generate'_`i', other("other")
			if _rc == 0 & "`nwreplace'" == "" {
				capture nwdrop `_sym'
				di "{pstd} {err}Network {bf:`generate'_`i'} already exists; use {bf:nwreplace} or specify another stub {bf:generate()}{p_end}"
				error 99
			}
			capture nwdrop `generate'_`i'
			nwduplicate `netname', name(`generate'_`i')
			nw_syntax 
			mata: `netobj'-> set_edge(makenet(`_path', `i', `nodes'))
		}
	}
	
	tempname rstore
	_return hold `rstore'
	capture nwdrop `_sym'
	_return restore `rstore'
	capture mata: mata drop `_path'
end

capture mata: mata drop makenet()

mata:
real matrix makenet(real matrix path, real scalar id, real scalar nodes){
	real matrix net
	real scalar i, ego, alter
	net = J(nodes, nodes, 0)
	for (i = 1; i < cols(path); i++){
		ego = path[id, i]
		alter = path[id, (i + 1)]
		net[ego, alter] = 1
	}
	return(net)
}
end
