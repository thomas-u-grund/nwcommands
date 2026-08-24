/***
{smcl}
{* *! version 2.0.0, 1dec2016: Thomas Grund}{...}
{marker topic}
{helpb nw_topical##generator:[NW-2.3] Generators}

{title:Title}

{p2colset 9 16 22 2}{...}
{p2col :nwsmall {hline 2}}Generate a small-world network{p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 17 2}
{cmdab: nwsmall} 
{it:{help int:nodes}}
{cmd:,}
{opth k(int)} 
{opth prob(float)} 
[{opt weights(p1, p2,...)}
{opt undirected}
{opth ntimes(int)}
{opt name}({it:{help newnetname}})
{opt labs}({it:lab1 lab2 ...})
{opt xvars}]

{p 8 17 2}
{cmdab: nwsmall} 
{it:{help int:nodes}}
{cmd:,}
{opth k(int)} 
{opt shortcuts(integer)} 
[{opt weights(p1, p2,...)}
{opt undirected}
{opth ntimes(int)}
{opt name}({it:{help newnetname}})
{opt labs}({it:lab1 lab2 ...})
{opt xvars}]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{it:{help int:nodes}}}number of nodes{p_end}
{synopt:{opth k(int)}}number of neighhbors on ring-lattice on each side{p_end}
{synopt:{opth prob(float)}}probability for a tie to rewire{p_end}
{synopt:{opth shortcuts(int)}}exact number of ties to rewire{p_end}
{synopt:{opt weights(p1, p2,...)}}probabilities p_k for tie weights k{p_end}
{synopt:{opt undirected}}generate an undirected network; default = directed{p_end}
{synopt:{opth ntimes(int)}}number of small-world networks to be generated; default = 1{p_end}
{synopt:{opt name}({it:{help newnetname}})}name of the new network{p_end}
{synopt:{opt labs}({it:lab1 lab2 ...})}overwrite node labels{p_end}
{synopt:{opt xvars}}generate Stata variables for the network{p_end}


{title:Description}

{pstd}
{cmd:nwsmall} generates a (un-)directed, (un-)weighted small-world network using the original Watts-Strogatz model (see Watts and Strogatz 1998). The algorithm starts
with a ring-lattice where each node has {it:k} neighbors on each side. Next, the ties of the ring-lattice 
are rewired in one of two ways:

{pstd}
1) When option {bf:prob()} is specified, each tie of the ring-lattice has a certain probability to get rewired. All non-existent ties
are valid as rewirings (including the ones produced through previous rewirings).

{pstd}
2) When option {bf:shortcuts()} is specified, an exact number of ties of the ring-lattice gets rewired. In this algorithm, only ties 
that had not been in the original ring-lattice are valid rewirings. 

{pstd}
Either option {bf:prob()} or {bf:shortcuts()} needs to be specified.

{pstd}
With option {bf:weights(}{it:p1, p2,...}{bf:)} the command generates a weighted network. Here,
{it:p_k} stands for the probability to sample tie weight {it:k}. The probabilities {it:p1, p2..., pn}
do not necessarily have to sum up to one; they are standardized. For example, the following
produces a small-world network with 20 nodes. Furthermore,
each one of these sampled ties gets assigned a tie weight because of option {bf:weights()}. In this case,
{bf:weights(0.0, 0.3,0.7)} indicates that tie weight 1 should be sampled with probability 0.0, tie weight 2 with
probability 0.3 and tie weight 3 with probability 0.7. 

	{cmd}. nwsmall 20, k(2) prob(.2) weights(0.0, 0.3, 0.7)
{txt}

{title:References}

{pstd}
Watts, D. J.; Strogatz, S. H. (1998). "Collective dynamics of 'small-world' networks". Nature 393 (6684): 440–442


{title:Examples}
	
{pstd}
In the first example, each tie on the ring-lattice has a probability to get rewired.

	{cmd:. nwclear}
	{cmd:. nwsmall 20, k(2) prob(.2)}
	{cmd:. nwplot, layout(circle)}

{pstd}
In the second example, there are exactly three shortcuts.

	{cmd:. nwsmall 30, k(2) shortcuts(3) undirected}
	{cmd:. nwplot, layout(circle)}

	
{title:See also}

	{help nwpref}, {help nwrandom}, {help nwlattice}, {help nwring}

***/
capture program drop nwsmall
program nwsmall
	// BUGFIX: `name(string)' was missing from this syntax line entirely
	// - the body below already references `` `name' `` (defaulting to
	// the hardcoded "small" when empty), but with no way to declare it
	// on the command line at all, that local could never actually be
	// set by a caller: every single nwsmall call silently ignored any
	// name() a caller tried to pass and produced a network hardcoded to
	// "small" every time (a second call without a different name(),
	// wanted or not, would collide). Found while restoring nwgenerate's
	// own small( shortcut, which failed outright with "option name()
	// not allowed" the moment it tried to pass one - not a new bug,
	// this file's own body already assumed the option existed. Added
	// here to match its own sibling nwring.ado, which already declares
	// name(string) correctly.
	syntax anything(name=nodes), k(integer) [ weights(string) ntimes(integer 1) labs(string) name(string) prob(string) shortcuts(string) undirected noreplace xvars]
	
	if "`prob'" != "" {
		if (`prob' > 1) | (`prob' < 0){
			di "{err}Probability needs to be between 0 and 1.{txt}"
		}
	}
	if "`density'" != "" {
		if (`density' > 1 | `density' < 0){
			di "{err}Density needs to be between 0 and 1.{txt}"
		}
	}
	local directed = ("`undirected'" == "")

	// BUGFIX: an unspecified name() has always been documented/expected
	// to auto-rename on collision ("small", "small_1", ...) rather than
	// require replace() - see nwrandom.ado's/nwpref.ado's own identical
	// fix (harmonisation unit 126/129) for the full root cause. Resolved
	// the same way: only when the caller did NOT supply name(),
	// pre-resolve the actual (possibly auto-incremented) target name via
	// nwvalidate before nwset ever sees it.
	local name_was_given = ("`name'" != "")
	if "`name'" == "" {
		local name "small"
	}
	if !`name_was_given' {
		nwvalidate `name'
		local name = r(validname)
	}
	
	if `ntimes' != 1 {
		di in smcl as txt "{p}"
		forvalues i = 1/`ntimes'{
			if mod(`i', 25) == 0 {
				di in smcl as txt "...`i'"
			}
			// BUGFIX: was `stub(`stub')' - nwsmall's own syntax line
			// never declares a `stub' option at all, so this stray
			// token made EVERY ntimes()>1 call crash with r(198)
			// "option stub() not allowed" - identical root cause to
			// nwring.ado's own bug. Also forwards `weights' now, which
			// this recursive call never did (ntimes()>1 always came
			// back unweighted regardless of weights() - see
			// nwrandom.ado's/nwpref.ado's own identical fix).
			nwsmall `nodes', k(`k') name(`name'_`i') shortcuts(`shortcuts') prob(`prob') weights(`weights') `xvars' `undirected'
		}
		exit
	}
	
	
	if ("`prob'"=="" & "`shortcuts'"==""){
		di "{err}either {it:prob}() or {it:shortcuts}() missing"
		exit
	}
	
	tempname __nwnew
	if "`prob'" != "" {
		mata: `__nwnew' = smallworldprob(`nodes', `k', `prob', `directed')
	}
	if "`shortcuts'" != "" {
		mata: `__nwnew' = smallworldsk(`nodes', `k', `shortcuts', `directed')
	}
	
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
	
	nwset, mat(`__nwnew') labs(`labs') name(`name') `undirected' 
	if "`xvars'" == "" {
		nwload, xvars
	}
	else {
		nwload
	}
	mata: st_rclear()
end

capture mata: mata drop smallworldsk()
capture mata: mata drop smallworldprob()
capture mata: mata drop insideBand()

mata: 
real matrix smallworldsk(nodes, k, shortcuts, directed){
	real matrix net, rewires, blub, blub2
	real scalar rows, i, j, y, alreadyRewired, rx_old, ry_old, wrongPick, ry,sign
	
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
	
	// initial list of ties to rewire
	rewires = runiform(shortcuts, 2)
	rewires[,1] = ceil(rewires[,1]:* nodes)
	
	if (directed == 0) {
		blub = ceil(rewires[,2]:*k)
		blub2 = editvalue(mod((rewires[,1] :+ blub), nodes), 0, nodes)
		rewires[,2] = blub2[,1]
	}
	if (directed == 1) {
		sign = round(runiform(shortcuts,1))
		sign = J(shortcuts,1,1) :- (sign :* 2) 
		rewires[,2] = editvalue(mod((rewires[,1] :+ (ceil(rewires[,2]:*k):*sign)), nodes),0,nodes)
	}
	
	alreadyRewired = 0
	for (i = 1; i<= shortcuts; i++) {		
		//make sure that tie to rewire is valid
		alreadyRewired = 1
		while (alreadyRewired == 1){
			alreadyRewired = 0
			if (net[rewires[i,1],rewires[i,2]] == 0){
				alreadyRewired = 1
			
				rewires[i,1] = ceil(runiform(1,1) * nodes)
				if (directed == 0) {
					rewires[i,2] = runiform(1,1)
					rewires[i,2] = editvalue(mod(rewires[i,1] :+ ceil(rewires[i,2]:*k), nodes), 0, nodes)
				}
				if (directed == 1) {
					sign = round(runiform(1,1))
					sign = 1 :- (sign :* 2) 
					rewires[i,2] = editvalue(mod(rewires[i,1] :+ (ceil(rewires[i,2]:*k):*sign), nodes),0,nodes)
				}
			}
		}	
		
		rx_old = rewires[i,1]
		ry_old = rewires[i,2]
		
		//require new tie
		wrongPick = 1
		while(wrongPick == 1){
			wrongPick = 0
			ry = ceil(runiform(1,1) :* nodes)
			wrongPick = (((insideBand(nodes, k, rx_old, ry)) == 1) | (net[rx_old, ry] != 0)) 
		}
		net[rx_old,ry] = 1
		if (directed == 0) {
			net[ry,rx_old] = 1
		}
		
		// delete old tie
		net[rx_old,ry_old ] = 0
		if (directed == 0) {
			net[ry_old ,rx_old ] = 0
		}		
	}
	
	return(net)
}

real scalar insideBand(nodes, k, ego, alter) {
	real scalar inside
	
	inside = 0
	
	if (((ego - alter) <= k) & (ego >= alter)) {
		inside = 1
	}
	
	if (((ego - alter) > k ) & (((alter + nodes) - ego) <= k)) {
		inside = 1
	}

	if (((alter - ego) <= k) & (alter >= ego)) {
		inside = 1
	}
	
	if (((alter - ego) > k) & (((ego + nodes) - alter) <= k)) {
		inside = 1
	}
	if (ego == alter){
		inside = 1
	}
	return(inside)
} 

real matrix smallworldprob(nodes, k, prob, directed) {
	real matrix net
	real scalar rows, i, y, j, ego, alter, wrongPick, alter_new
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
	// undirected network
	if (directed == 0) {
		// loop through all nodes
		for (ego = 1; ego<= rows(y); ego++){
			// loop through all undirected ties for each node
			for (i = 1; i <= k; i++) {
				alter = mod((ego + i), nodes)
				if (alter == 0) {
					alter = nodes
				}
				
				// undirected tie to potentially rewire between ego and alter
				if (runiform(1,1) <= prob){
				
					// find new tie
					wrongPick = 1
					while(wrongPick == 1){
						wrongPick = 0
						alter_new = ceil(runiform(1,1) :* nodes)
						wrongPick = (((insideBand(nodes, k, ego, alter_new)) == 1) | (net[ego, alter_new] != 0)) 
					}
					
					
					//rewire undirected tie from ego to alter
					net[ego, alter] = 0
					net[alter, ego] = 0
					net[ego, alter_new] = 1
					net[alter_new, ego] = 1	
				}
			}
		}
	}
	
	// directed network
	if (directed == 1) {
		// loop through all nodes
		for (ego = 1; ego<= rows(y); ego++){
			// loop through all directed ties for each node
			for (i = (-k); i <= k; i++) {
				// exclude self-loops
				if (i != 0) {
					
					alter = mod((ego + i), nodes)
					if (alter == 0) {
						alter = nodes
					}
					// directed tie to potentially rewire between ego and alter
					if (runiform(1,1) <= prob){
					
						// find new tie
						wrongPick = 1
						while(wrongPick == 1){
							wrongPick = 0
							alter_new = ceil(runiform(1,1) :* nodes)
							wrongPick = (((insideBand(nodes, k, ego, alter_new)) == 1) | (net[ego, alter_new] != 0)) 
						}
					
						//rewire directed tie from ego to alter
						net[ego, alter] = 0
						net[ego, alter_new] = 1
					}
				}
			}
		}
	}
	
	return(net)
}
end

