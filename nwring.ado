/***
{smcl}
{* *! version 1.0.0  11nov2014}{...}
{marker topic}
{helpb nw_topical##generator:[NW-2.3] Generators}

{title:Title}

{p2colset 9 16 22 2}{...}
{p2col :nwring {hline 2}}Generate a ring-lattice network{p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 17 2}
{cmdab: nwring} 
{it:{help int:nodes}}
{cmd:,}
{opth k(int)} 
[{opt weights(p1, p2,...)}
{opt undirected}
{opth name(newnetname)}
{opt labs}({it:lab1 lab2 ...})
{opt xvars}
{opth ntimes(int)}]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{it:{help in:nodes}}}number of nodes{p_end}
{synopt:{opth k(int)}}number of neighhbors on ring-lattice on each side{p_end}
{synopt:{opt weights(p1, p2,...)}}probabilities p_k for tie weights k{p_end}
{synopt:{opt undirected}}generate an undirected network; default = directed{p_end}
{synopt:{opth name(newnetname)}}name of the new network{p_end}
{synopt:{opt labs}({it:lab1 lab2 ...})}overwrite node labels{p_end}
{synopt:{opt xvars}}generate Stata variables for the network{p_end}
{synopt:{opth ntimes(int)}}number of networks to be generated; default = 1{p_end}
{synopt:{opt noreplace}}reserved; currently a no-op - the create/replace collision guard on {opt name()} already applies regardless{p_end}

{title:Description}

{pstd}
{cmd:nwring} generates a (un-)directed, (un-)weighted ring-lattice network. Each node is connected to {it:k} 
nodes on each side. Basically, each node has 2 * {it:k} neighbors in a ring structure.

{pstd}
With option {bf:weights(}{it:p1, p2,...}{bf:)} the command generates a weighted network. Here,
{it:p_k} stands for the probability to sample tie weight {it:k}. The probabilities {it:p1, p2..., pn}
do not necessarily have to sum up to one; they are standardized. For example, the following
produces a ring-lattice network with 20 nodes, where each node is connected to two neighbors on each side. Furthermore,
each one of these sampled ties gets assigned a tie weight because of option {bf:weights()}. In this case,
{bf:weights(0.0, 0.3,0.7)} indicates that tie weight 1 should be sampled with probability 0.0, tie weight 2 with
probability 0.3 and tie weight 3 with probability 0.7. 

	{cmd:. nwring 20, k(2) weights(0.0,0.3,0.7)}
	

{title:Supported network types}

{pstd}
Binary: yes (only structural tie placement - see Weighted). Directed: yes, via {opt undirected} (default is directed). Weighted: yes, via {opt weights()}, independent of the ring/shortcut placement mechanism itself. Signed: not checked. Two-mode: not applicable - this generator always produces a one-mode network.

{title:Examples}
	
	{cmd:. nwclear}
	{cmd:. nwring 20, k(2) undirected}

{title:Stored results}

	{bf:nwring} stores the following in {bf:r()}:

	Macros
	  {bf:r(netlist)}	list of new networks

{title:See also}

	{help nwpref}, {help nwrandom}, {help nwlattice}, {help nwsmall}

***/

capture program drop nwring
program nwring
	// `prob(real 0)' removed - it was accepted by syntax but never
	// referenced anywhere in this file's body (confirmed: density on a
	// prob()-specified call was identical to the same call with no
	// prob() at all), so it had zero effect regardless of value. Unlike
	// nwsmall's own prob() (a substantially different rewiring
	// algorithm, `smallworldprob()' in unw_core.do), wiring up a real
	// rewiring feature here would be new functionality, not a bug fix -
	// out of scope for this pass; see nwsmall for the small-world
	// variant if that behavior is wanted.
	syntax anything(name=nodes), k(integer) [ weights(string) ntimes(integer 1) labs(string) name(string) undirected noreplace xvars]

	// BUGFIX: an unspecified name() has always been documented/expected
	// to auto-rename on collision ("ring", "ring_1", ...) rather than
	// require replace() - see nwrandom.ado's/nwpref.ado's own identical
	// fix (harmonisation unit 126/129) for the full root cause. Resolved
	// the same way: only when the caller did NOT supply name(),
	// pre-resolve the actual (possibly auto-incremented) target name via
	// nwvalidate before nwset ever sees it.
	local name_was_given = ("`name'" != "")
	if "`name'" == "" {
		local name "ring"
	}
	if !`name_was_given' {
		nwvalidate `name'
		local name = r(validname)
	}

	if `ntimes' != 1 {
		di in smcl as txt "{p}"
		qui nwset
		local oldnetlist `r(nets)'
		forvalues i = 1/`ntimes'{
			if mod(`i', 25) == 0 {
				di in smcl as txt "...`i'"
			}
			// BUGFIX: was `stub(`stub')' - nwring's own syntax line
			// never declares a `stub' option at all (unlike sibling
			// nwlattice/nwpref, which do), so this stray token made
			// EVERY ntimes()>1 call crash with r(198) "option stub()
			// not allowed" - the documented multi-network-generation
			// feature was completely broken. Also forwards `weights'
			// now, which this recursive call never did (a separate,
			// silent bug: ntimes()>1 always came back unweighted
			// regardless of weights() - see nwrandom.ado's/nwpref.ado's
			// own identical fix).
			nwring `nodes', k(`k') name(`name'_`i') weights(`weights') `xvars' `undirected'
		}
		// Feature parity (moderate-severity pass, generators_structural
		// group): only nwrandom exposed r(netlist) for its own ntimes()>1
		// case; nwpref/nwlattice/nwring/nwsmall all share the identical
		// convention but never returned it.
		qui nwset
		local newnetlist `r(nets)'
		local netlist : list newnetlist - oldnetlist
		mata: st_rclear()
		mata: st_global("r(netlist)", "`netlist'")
		exit
	}
	
	tempname __nwnew
	mata: `__nwnew' = ringlattice(`nodes', `k')
	if "`weights'" != "" {
		tempname w
		capture mata: `w' = rdiscrete(`nodes', `nodes',(`weights')) 
		if _rc != 0 {
			di "{err}Could not sample tie weights, check option {bf:weights()}.{txt}"
		}
		capture mata: `w' = `w' :/ sum((`weights'))
		if "`undirected'" != "" {
			mata: `w' = lowertriangle(`w',0)
			mata: `w' = `w' + `w''
		}
		capture mata: `__nwnew' = `__nwnew' :* `w'
	}
	mata: st_rclear()
	nwset, mat(`__nwnew') labs(`labs') name(`name') `undirected'
	if "`xvars'" == "" {
		nwload, xvars
	}
	else {
		nwload
	}
	mata: st_global("r(netlist)", "`name'")

end

capture mata: mata drop ringlattice()

mata: 
real matrix ringlattice(nodes, k){
	real matrix net, y, rows
	real scalar i, j
	// generate ring lattice
	net = J(nodes, nodes, 0)
	rows = (1::nodes)
	for (i = 1; i<=k; i++) {
		y = (editvalue(mod((rows' :+ i), (nodes)),0,nodes))'
		for (j = 1; j<= rows(y); j++){
			net[j, y[j,1]] = 1
		}
		y = (editvalue(mod((rows' :- i), (nodes)),0,nodes))'
		for (j = 1; j<= rows(y); j++){
			net[j, y[j,1]] = 1
		}
	}
	return(net)
}
end
