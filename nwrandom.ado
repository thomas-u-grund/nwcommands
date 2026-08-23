/***
{smcl}
{* *! version 2.0.0, 1dec2016: Thomas Grund}{...}
{marker topic}
{helpb nw_topical##generator:[NW-2.3] Generators}

{title:Title}

{p2colset 9 18 22 2}{...}
{p2col :nwrandom {hline 2}}Generate a random network{p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 17 2}
{cmdab: nwrandom} 
{it:{help int:nodes}}
{cmd:,}
[{opth prob(float)}
{opth density(float)}
{opt census}({help nwdyads:{it:mutual asym} [{it:null}]})
{opt weights(p1, p2,...)}
{opt undirected}
{opth ntimes(int)}
{opt name}({it:{help newnetname}})
{opt labs}({it:lab1, lab2, ...})
{opt xvars}]

{synoptset 30 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{it:{help int:nodes}}}number of nodes{p_end}
{synopt:{opth prob(float)}}probability for a tie{p_end}
{synopt:{opth density(float)}}exact density of the new network{p_end}
{synopt:{opt census}({help nwdyads:{it:mutual} [{it:asym null}]})}dyad census of the new network{p_end}
{synopt:{opt weights(p1, p2,...)}}probabilities p_k for tie weights k{p_end}
{synopt:{opt undirected}}generate an undirected network; default = directed{p_end}
{synopt:{opth ntimes(int)}}number of random networks to be generated; default = 1{p_end}
{synopt:{opt name}({it:{help newnetname}})}name of the new random network; default = {it:random}{p_end}
{synopt:{opt labs}({it:lab1, lab2, ...})}overwrite node labels{p_end}
{synopt:{opt xvars}}generate Stata variables for the network{p_end}


{title:Description}

{pstd}
{cmd:nwrandom} generates a (un-)directed, (un-)weighted Erdos-Renyi network. Each
potential tie in the network has the same probability to exist, which is defined 
by {bf:prob()}. Option {bf:prob()} generates ties based on probabilities, which means that
the exact number of ties can vary. 

{pstd}
Alternatively, the overall density of the network can be specified with 
{bf:density()}. This option always generates the same number of ties
( = {it:density * nodes}), where each tie has the same probability to exist.

{pstd}
Lastly, one can also generate a random network that has a specific {help nwdyads:dyad census} using {opt census()} (see {help nwdyads}).  

{pstd}
Either {bf:prob()}, {bf:density()} or {bf:census()} needs to be specified.

{pstd}
With option {bf:weights(}{it:p1, p2,...}{bf:)} the command generates a weighted network. Here,
{it:p_k} stands for the probability to sample tie weight {it:k}. The probabilities {it:p1, p2..., pn}
do not necessarily have to sum up to one; they are standardized. For example, the following
produces a random network with 10 nodes, where each tie has the probability 0.5 to exist. Furthermore,
each one of these randomly sampled ties gets assigned a tie weight because of option {bf:weights()}. In this case,
{bf:weights(0.0, 0.3,0.7)} indicates that tie weight 1 should be sampled with probability 0.0, tie weight 2 with
probability 0.3 and tie weight 3 with probability 0.7. 

	{cmd}. nwrandom 10, prob(.5) weights(0.0, 0.3, 0.7)
{txt}
{pstd}
The command can also be used to generate many random networks at the same time. For example, the following command
produces 100 random networks, where ties have the probability 0.1 to exist.

{pmore}
{bf:. nwrandom 50, prob(.1) ntimes(100)}

{pstd}
By default, directed networks are generated, option {bf:undirected} generates undiretced networks instead. 

{pstd}
The command can also be used to generate both complete ({bf:prob(1)}) and empty networks ({bf:prob(0)}). 


{title:Examples}
	
	{cmd:. nwclear}
	{cmd:. nwrandom 50, prob(.1)}
	{cmd:. nwrandom 15, density(0.5)}
	{cmd:. nwrandom 20, prob(.3) ntimes(5)}
	{cmd:. nwrandom 10, prob(.2) undirected}
	{cmd:. nwrandom 200, census(100 2000)}
	{cmd:. nwrandom 10, density(.2) weights(0.1, 0.3, 0.6)}

{title:Stored results}

	{bf:nwrandom} stores the following in {bf:r()}:
		  
	Macros
	  {bf:r(netlist)}	list of new networks
	  
{title:See also}

	{help nwsmall}, {help nwpref}, {help nwpref}, {help nwlattice}, {help nwring}

***/

capture program drop nwrandom
program nwrandom
	syntax anything(name=nodes), [weights(string) selfloop ntimes(integer 1) Census(numlist integer min=1 max=3) Density(string) Prob(string) labs(string) name(string) undirected xvars noreplace * ]
	unw_defs
	
	// Generate valid network name and valid varlist
	if "`name'" == "" {
		local name "random"
	}

	if `ntimes' != 1 {
		di in smcl as txt "{p}"
		qui nwset
		local oldnetlist `r(nets)'
		forvalues i = 1/`ntimes'{
			if mod(`i', 25) == 0 {
				di in smcl as txt "...`i'"
			}
			nwrandom `nodes', census(`census') name(`name'_`i') density(`density') prob(`prob') `selfloop' `xvars' `undirected' labs(`labs')
		}
		qui nwset
		local newnetlist `r(nets)'
		local netlist : list newnetlist - oldnetlist
		mata: st_rclear()
		mata: st_global("r(netlist)", "`netlist'")
		exit
	}
	
	tempname __nwnew
	
	if ("`prob'" != "") {
		mata: `__nwnew' = get_random_prob(`nodes', `prob', ("`undirected'" != ""), "`selfloop'" != "")
	}
	if ("`density'" != "") {
		mata: `__nwnew' = get_random_density(`nodes', `density', ("`undirected'" != ""), "`selfloop'" != "")
	}
	if "`census'" != "" {
		local mutual : word 1 of `census'
		local asym : word 2 of `census'
		if "`asym'" == "" {
			local asym = 0	
		}
		local total = `mutual' + `asym'	
		if `total' > `=((`nodes' * (`nodes'-1)) / 2)' {
			di "{err}Too manny dyads requested,"
			exit
		}
		mata: `__nwnew' = dyadcensusGenerator(`nodes', `mutual', `asym')
	}
	
	if "`weights'" != "" {
		tempname w
		capture mata: `w' = (`weights') :/ sum((`weights')) 
		capture mata: `w' = rdiscrete(`nodes', `nodes',(`w')) 
		if _rc != 0 {
			di "{err}Could not sample tie weights, check option {bf:weights()}.{txt}"
		}

		if "`undirected'" != "" {
			mata: `w' = lowertriangle(`w',0)
			mata: `w' = `w' + `w''
		}
		capture mata: `__nwnew' = `__nwnew' :* `w'
	}
	
	if ("`prob'"=="" & "`density'"=="" & "`census'" == ""){
		di "{err}either {it:prob}(), {it:density}() or {it:census()} missing"
		exit
	}

	mata: st_rclear()
	nwset, mat(`__nwnew') name(`name') labs(`labs') `undirected' `selfloop'
	if "`xvars'" == "" {
		nwload, xvars
	}
	else {
		nwload
	}

	capture mata: mata drop `__nwnew'

	// r(netlist) is documented (Stored results, above) as always being
	// set to "list of new networks" - true for the ntimes()>1 branch's
	// own early exit above, but this single-network base case never set
	// it at all (found while dealing with xvars consistently project-
	// wide, which happened to route more calls through this exact final
	// stretch of the program).
	mata: st_global("r(netlist)", "`name'")
end


capture mata: mata drop tiesGenerator()
capture mata: mata drop correctDiagonal()
capture mata: mata drop dyadcensusGenerator()
capture mata: mata drop get_random_prob()
capture mata: mata drop get_random_density()

mata:
real matrix get_random_prob(real scalar nodes, real scalar prob, real scalar undirected, real scalar selfloop){
	real matrix adj 
	
	adj = floor(uniform(nodes,nodes) :+ prob)
	if (undirected == 1) {
		_makesymmetric(adj)
	}
	if (selfloop == 0){
		_diag(adj,0)
	}
	return(adj)
}

real matrix get_random_density(real scalar nodes, real scalar density, real scalar undirected, real scalar selfloop){
	real scalar ties, n2, tiesdiag
	real matrix adj
	
	ties = floor((nodes * (nodes -(1 - selfloop)) * density))
	n2 = nodes * nodes
		
	if (undirected == 0){
		adj=(1::n2)
		_jumble(adj)
		adj=colshape(adj, nodes)
		adj = (adj:<=ties)
		tiesdiag = sum(diagonal(adj))
		if (selfloop == 0){
			adj = correctDiagonal(adj,0, tiesdiag)
		}
	}
	else {
		adj = tiesGenerator(nodes, ties)
		tiesdiag = sum(diagonal(adj))
		if (selfloop == 0){
			adj = correctDiagonal(adj,1, tiesdiag)
		}
	}
	return(adj)
}

real matrix function tiesGenerator(real scalar nodes, real scalar ties)
{
	real matrix X
	real scalar temp
	
	ties = ties / 2
	temp = ((nodes * (nodes-1) / 2) + nodes)
	X = invvech(jumble((1::temp)))
	X = (X:<=ties)
	return(X)
}

real matrix function dyadcensusGenerator( scalar nodes, scalar mutual, scalar asym)
{
	real matrix X
	real scalar temp, ties, M, A, tiesdiag, T, R, Rlower, Rupper, Rboth
	
	ties = ties / 2
	temp = ((nodes * (nodes-1) / 2) + nodes)
	X = invvech(jumble((1::temp)))
	M = (X:<=mutual)
	A = (X:> mutual):*(X:<= (asym + mutual))
	
	tiesdiag = sum(diagonal(M))
	M = correctDiagonal(M,1, tiesdiag )
	_diag(M,0)
	
	T = M :+ A
	T = T :/ T
	_editmissing(T,0)
	_diag(T, 0)

	tiesdiag = (2 * (mutual + asym) - sum(T)) / 2	
	T = correctDiagonal(T,1, tiesdiag)
	T = T :/ T
	_editmissing(T,0)
	_diag(T, 0)

	A = T :- M
	R = round(runiform(nodes, nodes))
	
	Rlower = lowertriangle(R, 0)
	Rupper = uppertriangle(J(nodes, nodes, 1) - Rlower',0)
	Rboth = Rlower + Rupper
	A = A:* Rboth
	return(M :+ A)
}

real matrix function correctDiagonal(real matrix net, scalar undirected, scalar tiesdiag){
	real scalar nodes, i, found, ran, rrow, rcol
	
	nodes = rows(net)
	for (i = 1 ; i <= tiesdiag; i++ ) {
		found = 0
		while (found == 0) {
			ran = (ceil(runiform(1,2):* nodes))
			rrow = ran[1,1]
			rcol = ran[1,2]
			if ((net[rrow, rcol] == 0) & (rrow != rcol))  {
				found = 1
				net[rrow, rcol] = 1
				if (undirected == 1){
					net[rcol, rrow] = 1
				}
			}
		}
	}
	_diag(net, 0)
	return(net)
}
end

