/***
{smcl}
{* *! version 1.0.0  11nov2014}{...}
{marker topic}
{helpb nw_topical##generator:[NW-2.3] Generators}

{title:Title}

{p2colset 9 15 22 2}{...}
{p2col :nwpref {hline 2} Generate a preferential-attachment network}
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
{synopt:{opt xvars}}do not generate Stata variables{p_end}
{synopt:{opth ntimes(int)}}number of small-world networks to be generated; default = 1{p_end}

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


{title:References}

{pstd}
Barabasi, A-L.; Albert, R. (1999) "Emergence of scaling in random networks". Science 286 (54439): 509-512. 


{title:Examples}
	
	{cmd:. nwclear}
	{cmd:. nwpref 20, undirected}
	{cmd:. nwplot, layout(circle)}
	
	{cmd:. nwpref 20, prob(1) undirected}
	{cmd:. nwplot, layout(circle)}

	
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
	if "`name'" == "" {
		local name "pref"
	}

	if `ntimes' != 1 {
		di in smcl as txt "{p}"
		forvalues i = 1/`ntimes'{
			if mod(`i', 25) == 0 {
				di in smcl as txt "...`i'"
			}
			nwpref `nodes', m0(`m0') m(`m') prob(`prob') name(`name'_`i') stub(`stub') `xvars' `undirected' vars(`vars') labs(`labs')
		}
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
	nwset, mat(`__nwnew') name(`name') `undirected' labs(`labs')
	nwload, `xvars' 
	
	
end

capture mata: mata drop prefattach()

mata:
real matrix prefattach(real scalar nodes, real scalar m0, real scalar m, real scalar prob, real scalar directed)
{
	real matrix net
	real scalar i, j, probability, z, pick, newpicks
	// initiate G_0
	net = J(nodes, nodes, 0)
	for (i = 1; i <= m0; i++){
		for (j= 1;j<= m0;j++){
			net[i,j] = 1
			net[j,i] = 1
		}
	}
	
	// for all new nodes
	for (i= (m0+1); i<=nodes; i++) {  
		newpicks = 0
		if (runiform(1,1) <= prob){
			probability = J((i-1), 1, (1 / (i-1)))	
		}
		else { 
			probability = colsum(net) :/ sum(colsum(net))
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
				if (directed == 0){
					net[pick,i] = 1
				}
			}
		}
		
	}
	
	return(net)
}

end
