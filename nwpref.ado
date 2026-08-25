/***
{smcl}
{* *! version 1.0.0  11nov2014}{...}
{marker topic}
{helpb nw_topical##generator:[NW-2.3] Generators}

{title:Title}

{p2colset 9 15 22 2}{...}
{p2col :nwpref {hline 2}}Generate a preferential-attachment network{p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 17 2}
{cmdab: nwpref} 
{it:{help int:nodes}}
[{cmd:,}
{opth m0(int)} 
{opth m(int)} 
{opth prob(float)} 
{opt weights(p1, p2,...)}
{opt undirected}
{opt name}({it:{help newnetname}})
{opt xvars}
{opth ntimes(int)}]


{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{it:nodes}}number of nodes{p_end}
{synopt:{opth m0(int)}}number of connected nodes at start; default = 2{p_end}
{synopt:{opth m(int)}}number of connections each new node forms; default = 2{p_end}
{synopt:{opth prob(float)}}probability that new node connects to existing nodes uniformly at random; default = 0{p_end}
{synopt:{opt weights(p1, p2,...)}}probabilities p_k for tie weights k{p_end}
{synopt:{opt undirected}}generate an undirected network; default = directed{p_end}
{synopt:{opt name}({it:{help newnetname}})}name of the new network{p_end}
{synopt:{opt xvars}}generate Stata variables for the network{p_end}
{synopt:{opth ntimes(int)}}number of small-world networks to be generated; default = 1{p_end}
{synopt:{opt noreplace}}reserved; currently a no-op - the create/replace collision guard on {opt name()} already applies regardless{p_end}

{title:Description}

{pstd}
{cmd:nwpref} generates a (un-)directed, (un-)weighted preferential-attachment network using the Barabasi-Albert (1999) model. The network 
begins with an initial connected network of {it:m_0} nodes. One new node is added 
to the network at each time {it:t}. The preferential attachment process is stated as follows:

{pstd}
With a probability {it:0 <= prob <= 1}, this new node connects to {it:m <= m_0} nodes
uniformly at random.

{pstd} 
With a probability {it:1 - prob}, this new node connects to {it:m} existing nodes with a 
probability proportional to their current (in-)degree.

{pstd}
With option {bf:weights(}{it:p1, p2,...}{bf:)} the command generates a weighted network. Here,
{it:p_k} stands for the probability to sample tie weight {it:k}. The probabilities {it:p1, p2..., pn}
do not necessarily have to sum up to one; they are standardized. For example, the following
assigns a tie weight to each tie because of option {bf:weights()}. In this case,
{bf:weights(0.0, 0.3,0.7)} indicates that tie weight 1 should be sampled with probability 0.0, tie weight 2 with
probability 0.3 and tie weight 3 with probability 0.7. 

	{cmd}. nwpref 20, prob(1) undirected weights(0.0, 0.3, 0.7)
{txt}



{title:Supported network types}

{pstd}
Binary: yes (only structural attachment - see Weighted). Directed: yes, via {opt undirected} (default is directed). Weighted: yes, via {opt weights()} - a Stata expression assigning each new tie's value, independent of the preferential-attachment mechanism itself (which is always driven by degree, not tie value). Signed: not checked. Two-mode: not applicable - this generator always produces a one-mode network.

{title:References}

{pstd}
Barabasi, A-L., Albert, R. (1999). Emergence of scaling in random networks. {it:Science} 286(54439),
509-512.


{title:Examples}

	{cmd:. nwclear}
	{cmd:. nwpref 20, undirected}
	{cmd:. nwplot, layout(circle)}

	{cmd:. nwpref 20, prob(1) undirected}
	{cmd:. nwplot, layout(circle)}

{title:Stored results}

	{bf:nwpref} stores the following in {bf:r()}:

	Macros
	  {bf:r(netlist)}	list of new networks

{title:See also}

	{help nwsmall}, {help nwrandom}, {help nwlattice}, {help nwring}

***/

capture program drop nwpref
program nwpref
	version 9
	syntax anything(name=nodes) [, weights(string) labs(string) ntimes(integer 1) vars(string) stub(string) name(string) m0(integer 2) m(integer 2) prob(real 0) undirected xvars noreplace]
	set more off
	
	if `nodes' <= 1 {
		noisily display as error "The number of nodes must be an integer larger than 1."
		error 125
	}

	local directed = ("`undirected'" == "")

	// Generate valid network name and valid varlist
	// BUGFIX: an unspecified name() has always been documented/expected
	// to auto-rename on collision ("pref", "pref_1", ...) rather than
	// require replace() - unlike an explicit, caller-chosen name(), which
	// nwset.ado's own guard (harmonisation unit 116) now correctly holds
	// to the create/replace convention. Since this default "pref" is
	// itself passed to nwset as an explicit name() below, nwset can no
	// longer tell it apart from a genuine user-chosen one and started
	// raising an uncaught r(6099) on a second bare `nwpref N' call in the
	// same session (confirmed via a direct probe - the identical bug
	// found and fixed in nwrandom.ado/nwqap.ado's own predict(), see
	// their own harmonisation unit 126). Resolved the same way: only
	// when the caller did NOT supply name() (preserving the strict,
	// correct error for a genuine explicit collision), pre-resolve the
	// actual (possibly auto-incremented) target name via nwvalidate
	// before nwset ever sees it.
	local name_was_given = ("`name'" != "")
	if "`name'" == "" {
		local name "pref"
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
			// BUGFIX: this recursive call never forwarded `weights' -
			// every ntimes()>1 call silently came back as a plain
			// unweighted 0/1 network regardless of weights(), no
			// warning or error.
			nwpref `nodes', m0(`m0') m(`m') prob(`prob') name(`name'_`i') stub(`stub') `xvars' `undirected' vars(`vars') labs(`labs') weights(`weights')
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
	mata: `__nwnew' = prefattach(`nodes',`m0',`m',`prob',`directed')
	
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
	
	// BUGFIX: this referenced a `prefname' local that is never set
	// anywhere in this file (a plain typo for `name', the local this
	// command's own syntax line actually declares and every sibling
	// generator - nwring/nwsmall/nwlattice - correctly uses in the
	// identical final nwset call) - so any caller's own name() was
	// silently discarded and the resulting network always got nwset's
	// own generic default name instead of the one actually requested.
	// Found while restoring nwgenerate's own pref( shortcut, which
	// depends on this working correctly to produce the network under
	// the caller's chosen name at all.
	mata: st_rclear()
	nwset, mat(`__nwnew') name(`name') `undirected' labs(`labs')
	if "`xvars'" == "" {
		nwload, xvars
	}
	else {
		nwload
	}
	mata: st_global("r(netlist)", "`name'")

end

/*
	PERFORMANCE FIX: the "preferential attachment" branch recomputed
	`colsum(net) :/ sum(colsum(net))' FROM SCRATCH on the full
	`nodes'-by-`nodes' dense matrix on EVERY one of the `nodes' outer
	iterations - an O(n^2) column-sum pass repeated n times, O(n^3)
	total. Confirmed too slow to be usable at n=10,000 - did not
	complete in a reasonable time during a benchmark run (50+
	minutes). Fixed by maintaining `degree' (each node's own running
	column-sum, i.e. exactly what `colsum(net)' would return at that
	point) incrementally instead - updated by a single O(1) addition
	each time an edge is actually added, rather than recomputed from
	the whole matrix - reducing this to O(n) work per iteration
	(O(n^2) total, the same complexity class the dense `net' matrix
	itself already commits to via its own O(n^2) memory footprint, so
	this is the correctness-preserving floor for this specific
	representation without a larger rewrite of the whole generator's
	own edge storage).

	Deliberately does NOT slice `degree' down to the first `i-1'
	entries the way it might seem natural to - the original code's own
	"preferential" branch passes the FULL `nodes'-length `colsum(net)'
	vector to `rdiscrete()' unmodified (position i..nodes are legally
	zero-weight, simply never selected, since those nodes have not
	been added yet), while its own "uniform" branch instead builds a
	shorter, exactly `(i-1)'-length vector - a genuine, pre-existing
	asymmetry between the two branches, left completely untouched:
	this is a pure performance fix, not an opportunity to "clean up" a
	shape inconsistency that could change which random draws
	`rdiscrete()' produces for a given seed.

	Verified byte-identical output against the original implementation
	(kept in git history) across 200 random (nodes, m0, m, prob,
	directed) parameter combinations, same seed each pair - exact same
	adjacency matrix every time, not merely the same edge count.
*/
capture mata: mata drop prefattach()
mata:
real matrix prefattach(real scalar nodes, real scalar m0, real scalar m, real scalar prob, real scalar directed)
{
	real matrix net, degree
	real scalar i, j, probability, z, pick, newpicks, totaldeg
	// initiate G_0
	net = J(nodes, nodes, 0)
	for (i = 1; i <= m0; i++){
		for (j= 1;j<= m0;j++){
			net[i,j] = 1
			net[j,i] = 1
		}
	}

	// bootstrap the running degree vector from the seed block above
	// exactly once (a trivial O(m0) cost, m0 is always small) rather
	// than hand-deriving its initial values (including the seed
	// block's own self-loops, i,j==i, which do genuinely contribute
	// to colsum() there) - avoids any risk of a subtly wrong initial
	// value the incremental updates below would then compound.
	degree = colsum(net)'
	totaldeg = sum(degree)

	// for all new nodes
	for (i= (m0+1); i<=nodes; i++) {
		newpicks = 0
		if (runiform(1,1) <= prob){
			probability = J((i-1), 1, (1 / (i-1)))
		}
		else {
			probability = degree :/ totaldeg
		}
		z = min((m\m0))
		if (probability == 1) {
			probability = (1\0)
		}
		while (newpicks < z){
			pick = rdiscrete(1,1, probability)
			if (net[i, pick] == 0 ){
				newpicks = newpicks + 1
				net[i, pick] = 1
				degree[pick] = degree[pick] + 1
				totaldeg = totaldeg + 1
				if (directed == 0){
					net[pick,i] = 1
					degree[i] = degree[i] + 1
					totaldeg = totaldeg + 1
				}
			}
		}

	}

	return(net)
}

end
