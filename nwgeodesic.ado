/***
{smcl}
{* *! 14jul2016: Thomas Grund}{...}
{marker topic}
{helpb nw_topical##generator:[NW-2.3] Generators}
{marker top2}
{helpb nw_topical##analysis_paths:[NW-2.6.5] Paths, Reachability & Ego Networks}

{title:Title}

{p2colset 9 10 10 2}{...}
{p2col:nwgeodesic {hline 2} Calculate shortest paths between nodes}
{p2colreset}{...}


{title:Syntax}

{p 8 17 2}
{cmd:nwgeodesic} 
[{it:{help netname}}]
[{cmd:,}
{opth unconnected(int)}
{opt nosym}
{opt sympopt(options)}
{opth name(string)}
{opt nwreplace}
{opth generate(newvarname)}
{opt xvars}]


{synoptset 30 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opth unconnected(int)}}Define the length of the path between two unconnected nodes{p_end}
{synopt:{opth alpha(real)}}Deal with valued networks{p_end}
{synopt:{opt sym}}Calculate distances from symmetrized network{p_end}
{synopt:{opt name}({it:{help newnetname}})}Name of the new distance network; default = {it:_geodesic}{p_end}
{synopt:{opt nwreplace}}Overwrite existing network {it:newnetname}{p_end}
{synopt:{opth generate(newvarname)}}Name of the Stata variable that stores each node's eccentricity; default = {it:_eccentricity}{p_end}
{synopt:{opt xvars}}Do not generate Stata variables{p_end}


{title:Description}

{pstd}
{cmd:nwgeodesic} calculates the shortest paths (also known as geodesic distances) between all nodes {it:i} and {it:j}, the average shortest path length
and the diameter of the (un-)weighted network {help netname} according to Opsahl et al. (2010). The matrix of distances
is saved as a new network called {help newnetname} (default: {it:geodesic}). 

{pstd}
With option {opt sym} the distances are calculated from the symmetrized network. Option {opt symopt()}
allows control over the symmetrization (see options in {help nwsym}).

{pstd}
{cmd:nwgeodesic} also generates a new variable (default: {it:_eccentricity}) that stores each node's
{it:eccentricity} - the length of the longest shortest path from that node to any other node - and
returns the network's {it:radius} (the smallest eccentricity across all nodes) as {bf:r(radius)}.
Like the diameter, both are undefined (missing for a node's eccentricity; {bf:r(radius) = -1}) when
the network has unconnected pairs and {bf:unconnected()} was not specified. An existing {it:generate()}
variable is overwritten when {bf:nwreplace} is specified (there is no separate {bf:replace} option for
just the variable).

{pstd}
By default, the distance between two unconnected nodes {it:i} and {it:j}, i.e. there is no path that connects node {it:i} with node {it:j}, is set to missing. Non-existent paths are excluded from 
the calculation of the average shortest path length (unless option {bf:unconnected()} is specified). 

{pstd}
The option {bf:unconnected(max)} sets the distance of non-connected nodes to the maximum distance 
observed in the network plus 1.

{pstd}
Following Opsahl et al. (2010) the shortest path between node {it:i} and node {it:j}
for a given {it:alpha} is defined as:

{pmore}
{it:d_w_alpha(i,j) = min (1 / w_ih^alpha + ... + 1 / w_hj^alpha )}

{pstd}
where {it:w_ih} is the weight (value) of the tie between node {it:i} and node {it:h}. When {bf:{it:alpha} = 1}
this formula reduces to: 

{pmore}
{it:d_w_alpha(i,j) = min (1 / w_ih + ... + 1 / w_hj)}

{pstd}
which is essentially what Newman (2001) and Brandes (2001) suggested. This simply equates the distance between two
nodes with the inverse of the weight of the tie that connects them. Such a solution for dealing with 
valued networks, however, does not explicitly account for the number of steps that need to be taken to connect to nodes.
In contrast, Opsahl et al. (2010) allows giving different weight to longer and shorter paths. When {bf:{it:alpha} = 0}
the formula above ignores tie weights.


{title:References}

{pstd}
Brandes, U. (2001). A faster algorithm for betweenness centrality. {it:Journal of Mathematical Sociology} 25, 163–177.

{pstd}
Opsahl, T., Agneessens, F. and Skvoretz, J. (2010). Node centrality in weighted networks: Generalizing degree and shortest paths. {it:Social Networks} 32 (3), 245-251.

{pstd}
Newman, M. E.J. (2001). Scientific collaboration networks. II. Shortest paths, weighted
networks, and centrality. {it:Physical Review E} 64, 016132.


{title:Example}
	
    {com}. nwwebuse florentine, nwclear
    {com}. nwgeodesic flomarriage

    {res}{hline 40}
    {txt}  Network name: {res}flomarriage
    {txt}  Network of shortest paths: {res}_geodesic
    {hline 40}
    {txt}    Nodes: {res}16
    {txt}    Symmetrized : {res}(already undirected)
        {hline 36}
    {txt}    Paths: {res}120
    {txt}    Unconnected paths: {res} 15
    {txt}    Average shortest path length: {res} (not defined)
    {txt}    Diameter: {res} (not defined)
    {txt}    Radius: {res} (not defined){txt}

{pstd}
In this first example, the average shortest path length is not defined because there
are 15 non-existent paths. There is one isolate node who cannot connect to any of the
other 15 nodes. The next example, makes use of the option {bf:unconnected()} to assign
these non-existent paths a certain length. Here, the option {bf:unconnected(max)} assigns
them the length 6.

    {com}. nwgeodesic flomarriage, unconnected(max)

    {res}{hline 40}
    {txt}  Network name: {res}flomarriage
    {txt}  Network of shortest paths: {res}_geodesic
    {hline 40}
    {txt}    Nodes: {res}16
    {txt}    Symmetrized : {res}(already undirected)
        {hline 36}
    {txt}    Paths: {res}120
    {txt}    Unconnected paths: {res} 15
    {txt}    Unconnected paths replaced with: {res} 6
    {txt}    Average shortest path length: {res} 2.925
    {txt}    Diameter: {res} 6{txt}

{pstd}
({cmd:nwgeodesic} also reports the network {it:radius} - the minimum node eccentricity - as an
additional line here, and, unless {bf:xvars} is specified, generates a per-node {it:_eccentricity}
variable; not reproduced above since it depends on live data.)

	
{title:Stored results}	

	Scalars
	  {bf:r(nodes)}		number of nodes
	  {bf:r(numpaths)}	number of shortest paths
	  {bf:r(diameter)}	network diameter
	  {bf:r(radius)}	network radius (minimum node eccentricity)
	  {bf:r(avgpath)}	average shortest path length
		  
	Macros
	  {bf:r(symmetrized)}	calculated on symmetrized network
	  {bf:r(netname)}	name of the original network
	  {bf:r(netname)}	name of the new distance network	  
		  
		  
{title:See also}

	{help nwcloseness}, {help nwreach}, {help nwpath}, {help nwcomponents}

***/
capture program drop nwgeodesic
program nwgeodesic
	version 9
	syntax [anything(name=netname)], [ nwreplace force noreplace name(string) alpha(real 0) xvars unconnected(string) sym symopt(string) generate(string)]

	capture
	unw_defs
	nw_syntax `netname'
	local origname "`netname'"
	
	if "`name'" == "" {
		local name "`nwgen_geodesic'"
	}
	
	tempname symnet
	local symmetrized "false"

	nw_syntax `netname', max(1)

	local eccvar "`generate'"
	if "`eccvar'" == "" {
		local eccvar "_eccentricity"
	}
	// Deliberately reuses nwreplace (not a separate replace option): this
	// syntax line already declares a dead, unused `noreplace' option, and
	// Stata's syntax parser silently fails to populate a `replace' local
	// when both `replace' and `noreplace' are declared together - verified
	// directly rather than assumed. Piggybacking on the existing, already-
	// working nwreplace avoids the collision entirely.
	capture confirm variable `eccvar'
	if _rc == 0 & "`nwreplace'" == "" {
		di "{err}Variable {bf:`eccvar'} already exists; specify {bf:nwreplace}"
		err 99
	}

	if "`sym'" != "" {
		di "{txt}Geodesics calculated on the symmetrized network."
		nwsym `netname', generate(`symnet') `symopt' noreplace
		nw_syntax `symnet', max(1)
		local symmetrized "true"
	}
	capture nw_syntax `name', other(_check)
	if _rc == 0 & "`nwreplace'" == "" {
		di "{pstd} {err}Network {bf:`name'} already exists; use {bf:nwreplace} or specify another {it:newnetname} with {bf:name()}{p_end}"
		error 99
	}
	capture nwdrop `name'
	nwduplicate `netname', name(`name')
	nw_syntax `name'
	
	if ("`valued'" == "false" & `alpha' != 1 ){
		di "{txt}Network is unvalued; {bf:alpha = `alpha'} is ignored."
		local alpha = 1
	}
	
	if (`alpha' == 0) {
		mata: `netobj'->set_edge(`netobj'->calculate_distances(`alpha', "brute"))
	}
	else if (`nodes' > 100 & "`force'" == ""){
		di "{txt}Calculated on unvalued network because network size exceeds 100."
		di "Use option {bf:force} to calculate distance on valued network nevertheless." 
		mata: `netobj'->set_edge(`netobj'->calculate_distances(`alpha', "brute"))	
	}
	else {
		mata: `netobj'->set_edge(`netobj'->calculate_distances(`alpha', "dijkstra"))	
	}
	
	// Get number of unconnected links
	mata: st_numscalar("r(unconnected)", sum((*`netobj'->get_matrix()):==.) - sum(diagonal(*`netobj'->get_matrix()):==.))
	
	// Deal with non-existing paths
	if "`unconnected'" != "" {
		mata: d = diagonal(*`netobj'->get_matrix())
		if "`unconnected'" == "max" {
			mata: st_local("unconnected", strofreal(max(*`netobj'->get_matrix())+1))
			mata: _editvalue((*`netobj'->get_matrix()),., `unconnected')
		}
		capture confirm number `unconnected'
		if _rc == 0 {
			mata: _editvalue((*`netobj'->get_matrix()),.,`unconnected')
		}
		mata: _diag((*`netobj'->get_matrix()), d)
		mata: mata drop d
	}

	mata: st_numscalar("r(nodes)", `nodes')
	mata: st_numscalar("r(numpaths)", `nodes' * (`nodes' - 1))

	// Get number of paths in distance network
	if "`directed'" == "false" {
		mata: st_numscalar("r(numpaths)", (`r(numpaths)' / 2))
	}
	
	// Get average shortest path length
	tempname s
	mata: _sum = sum(*`netobj'->get_matrix())

	mata: st_numscalar("r(avgpath)", (_sum / (`r(numpaths)')))
	if ("`directed'" == "false"){
		mata: st_numscalar("r(avgpath)", (_sum / (`r(numpaths)' * 2)))
		mata: st_numscalar("r(unconnected)",(`r(unconnected)' / 2))
	}		
	mata: mata drop _sum
	
	// Get rest
	mata: st_global("r(netname)","`origname'")
	mata: st_global("r(geodesic)","`name'")
	mata: st_global("r(symmetrized)", "`symmetrized'")
	mata: st_numscalar("r(diameter)", max(*`netobj'->get_matrix()))
	mata: st_numscalar("r(alpha)", `alpha')

	// Per-node eccentricity (max distance from a node to any other node) and
	// network radius (min eccentricity). Missing propagates through max()
	// exactly like it already does for r(diameter) above: a node that
	// cannot reach every other node has undefined (missing) eccentricity
	// unless unconnected() was specified.
	tempname __nw_ecc
	mata: `__nw_ecc' = rowmax(*`netobj'->get_matrix())
	mata: st_numscalar("r(radius)", min(`__nw_ecc'))
	if "`xvars'" == "" {
		qui capture drop `eccvar'
		qui gen `eccvar' = .
		mata: st_store((1::`nodes'), "`eccvar'", `__nw_ecc')
	}
	mata: mata drop `__nw_ecc'

	// Adjust for unconnected networks
	if `r(unconnected)' != 0 & "`unconnected'" == "" {
		mata: st_numscalar("r(avgpath)", -1)
		mata: st_numscalar("r(diameter)",-1)
		mata: st_numscalar("r(radius)",-1)
	}

	di "{hline 40}"
	di "{txt}  Network name: {res}`r(netname)'"
	di "{txt}  Network of shortest paths: {res}`r(geodesic)'"
	di "{hline 40}"
	di "{txt}    Nodes: {res}`r(nodes)'"
	
	if "`directed'" == "true" {
		di "{txt}    Symmetrized : {res}`r(symmetrized)'"
	}
	else {
		di "{txt}    Symmetrized : {res}(already undirected)"
	}
	if "`valued'" == "true" {
		di "{txt}    ALpha : {res}`r(alpha)'"
	}
	di "    {hline 36}"
	di "{txt}    Paths: {res}`r(numpaths)'"
	di "{txt}    Unconnected paths: {res} `r(unconnected)'"
	
	if "`unconnected'" != "" {
		di "{txt}    Unconnected paths replaced with: {res} `unconnected'"
	}
	
	if `r(unconnected)' == 0 | "`unconnected'" != "" {
		di "{txt}    Average shortest path length: {res} `r(avgpath)'"
		di "{txt}    Diameter: {res} `r(diameter)'"
		di "{txt}    Radius: {res} `r(radius)'"
	}
	else {
		di "{txt}    Average shortest path length: {res} (not defined)"
		di "{txt}    Diameter: {res} (not defined)"
		di "{txt}    Radius: {res} (not defined)"
	}

	capture _return drop _geo
	_return hold _geo
	capture nwdrop `symnet'
	
	if "`xvars'" == "" {
		nwload `name'
	}
	_return restore _geo
end

/*
capture mata mata drop getgeodesic()


mata:
void getgeodesic(pointer (class nw_def scalar) scalar nw)
{
	if (min(*nw->get_distance()) >= 0 ) { 
		st_numscalar("r(L)", sum(nw->get_distance())/(rows(*nw->get_distance())*rows(*nw->get_distance()) - rows(*nw->get_distance()))) 
	}
	else {
		st_numscalar("r(L)", -1) 
	}
}
end*/
