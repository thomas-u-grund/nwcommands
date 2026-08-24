/***
{smcl}
{* *! version 2.0.0  1dec2016: Thomas Grund}{...}
{marker topic}
{helpb nw_topical##generator:[NW-2.3] Generators}

{title:Title}

{p2colset 9 20 22 2}{...}
{p2col :nwdyadprob {hline 2}}Generate a network based on tie probabilities{p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 17 2}
{cmdab: nwdyadprob} 
[{it:{help netname}}]
[{cmd:,}
{opt mat(matamatrix)}
{opth density(float)}
{opt weights(p1, p2,...)}
{opth name(netname)}
{opt xvars}
{opt undirected}
{opt labs}({it:lab1 lab2 ...})]


{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt mat}({it:matrix})}Stata or Mata matrix with tie probabilities{p_end}
{synopt:{opth density(float)}}density of the new network{p_end}
{synopt:{opt weights(p1, p2,...)}}probabilities p_k for tie weights k{p_end}
{synopt:{opth name(netname)}}name of the new random network{p_end}
{synopt:{opt xvars}}generate Stata variables for the network{p_end}
{synopt:{opt undirected}}generate undirected network{p_end}
{synopt:{opt labs}({it:lab1 lab2 ...})}overwrite node labels{p_end}


{title:Description}

{pstd}
{cmd:nwdyadprob} generates a (un-)directed random network where each tie {it:x_ij} has the 
probability {it:p_ij} to exist. The values for {it:p_ij} are derived either 1) from the edge values
in network {help netname} and the {it:density} (if given) or 2) from a Stata/Mata matrix specified in {bf:mat()}. The command can be used to create
all sorts of networks.

{pstd}
Let {it:e_ij} be the edge values of network {help netname}. 

{pstd}
Then, the probability for a tie {it:x_ij} to exist in the newly created network is {it:p_ij}:

{pmore}
{it:p_ij = ((e_ij) / sum(e_kl)) * density * 100}

{pstd}
When no {bf:density()} is given, the probability is simply:

{pmore}
{it:p_ij = e_ij}

{pstd}
With option {bf:weights(}{it:p1, p2,...}{bf:)} the command generates a weighted network. Here,
{it:p_k} stands for the probability to sample tie weight {it:k}. The probabilities {it:p1, p2..., pn}
do not necessarily have to sum up to one; they are standardized.


{title:Supported network types}

{pstd}
Binary: yes (only structural tie placement - see Weighted). Directed: yes, via {opt undirected} (default is directed). Weighted: yes, via {opt weights()} (a per-dyad tie-value expression, independent of {opt density()}'s own probability-of-placement role) - though {opt weights()} is currently only implemented for the {opt mat()}-based path, not the {opt density()}-based path (an explicit, honest error is raised if both are combined; see the command's own Description). Signed: not checked. Two-mode: not applicable - this generator always produces a one-mode network.

{title:Example}

{pstd} 
The following example generates a network where ties are more likely to exist between nodes 
with similar {it:gender} and different {it:race}.

{pstd}
First, we generate two variables {it:gender} and {it:race}. 
	
	{cmd:. nwclear}
	{cmd:. set obs 10}
	{cmd:. gen gender = (_n > 5) + 2}
	{cmd:. gen race = int(0.5 + uniform())}

{pstd}
Next, we generate two expanded networks for each of the two variables (see {help nwexpand}). Basically, 
we generate for each variable a matrix {it:M} where {it:M_ij} = 1 when nodes {it:i} and {it:j} have the same
score on an attribute. And these matrices {it:M} are used to generate new networks.

	{cmd:. nwexpand gender}
	{cmd:. nwexpand race}
	
{pstd}
This creates the following networks.

	{com}. nwset
	{res}{txt}(2 networks)
	{hline 20}
		{res}same_gender
		{res}same_race{txt}

{pstd}
Having a closer look at the new network {it:same_gender}, shows the network that {help nwexpand} created.		
	
	{com}. nwsummarize same_gender, matonly

	       1    2    3    4    5    6    7    8    9   10
	   {c TLC}{hline 51}{c TRC}
	 1 {c |}  {res} 0                                             {txt}  {c |}
	 2 {c |}  {res} 1    0                                        {txt}  {c |}
	 3 {c |}  {res} 1    1    0                                   {txt}  {c |}
	 4 {c |}  {res} 1    1    1    0                              {txt}  {c |}
	 5 {c |}  {res} 1    1    1    1    0                         {txt}  {c |}
	 6 {c |}  {res} 0    0    0    0    0    0                    {txt}  {c |}
	 7 {c |}  {res} 0    0    0    0    0    1    0               {txt}  {c |}
	 8 {c |}  {res} 0    0    0    0    0    1    1    0          {txt}  {c |}
	 9 {c |}  {res} 0    0    0    0    0    1    1    1    0     {txt}  {c |}
	10 {c |}  {res} 0    0    0    0    0    1    1    1    1    0{txt}  {c |}
	   {c BLC}{hline 51}{c BRC}
	 
{pstd}
In the next step, we generate a network {it:dyadweight} on the basis of {it:same_gender} and
{it:same_race}.

{pstd}
As an example, we want that in the final network 1) ties between nodes with the same gender 
are overrepresented and 2) ties between nodes with the same race are underrepresented. This generates
tie probabilitities according to this request.  
	
	{cmd:. nwgen dyadweight = exp(5 * same_gender) * exp((-5) * same_race)}

{pstd}
Check out the tie values created in this way:

	{cmd:. nwsummarize dyadweight, matonly}
	
{pstd}
Finally, we create a new network based on tie probabilities defined in network {it:dyadweight}.

	{cmd:. nwdyadprob dyadweight, density(0.1)}
	
{pstd}
The result can be nicely plotted in the following way:

	{cmd:. nwplot, color(gender) layout(circle) title("gender, homophily = exp(5)")}
	{cmd:. graph save g4, replace}
	{cmd:. nwplot, color(race) layout(circle) title("race, homophily = exp(-5)")}
	{cmd:. graph save g5, replace}
	{cmd:. graph combine g4.gph g5.gph }


{title:Remarks}

{pstd}
The program requires some additional programs ({bf:gsample, moremata}) that it automatically installs from the internet. 


{title:See also}

	{help nwhomophily}, {help nwgen}, {help nwexpand}

***/
capture program drop nwdyadprob
program nwdyadprob
	syntax [anything(name=weightnet)],  [ weights(string) density(string) mat(string) name(string) labs(passthru) xvars undirected]
	
	unw_defs
	
	// BUGFIX: an unspecified name() has always been documented/expected
	// to auto-rename on collision ("dyadprob", "dyadprob_1", ...) rather
	// than require replace() - see nwrandom.ado's/nwpref.ado's own
	// identical fix (harmonisation unit 126/129/130) for the full root
	// cause. Resolved the same way: only when the caller did NOT supply
	// name(), pre-resolve the actual (possibly auto-incremented) target
	// name via nwvalidate before nwset ever sees it.
	local name_was_given = ("`name'" != "")
	if "`name'" == "" {
		local name "dyadprob"
	}
	if !`name_was_given' {
		nwvalidate `name'
		local name = r(validname)
	}
	
	tempname m
	if "`mat'" == "" {
		local mat = "`m'"
	}
	else {
		// BUGFIX: a caller-supplied mat() used to be referenced directly
		// by its raw text everywhere below, including two in-place
		// mutation attempts (`mat' = lowertriangle(`mat')' further down,
		// and `mat' = transformIntoProbs(...)' above when combined with
		// weightnet). That only works when mat() is an actual, existing
		// Mata variable NAME - it crashes ("invalid lval", r3000) the
		// moment mat() is instead a literal expression (e.g.
		// mat(J(5,5,.5)), exactly as shown working in this command's own
		// .sthlp examples) combined with `undirected'. Copying into a
		// private tempname up front - the same pattern already used just
		// above for the "mat() unspecified" case - makes every later
		// reference (read or write) operate on a real, assignable
		// variable regardless of what kind of Mata argument the caller
		// passed.
		tempname __matcopy
		mata: `__matcopy' = (`mat')
		local mat = "`__matcopy'"
	}


	// Install gsample if needed
	capture which gsample
	if _rc != 0 {
		ssc install gsample
	}
	capture mata: mata which mm_sample()
	if _rc != 0 {
		ssc install moremata
	}

	if "`weightnet'" != "" {
		nw_syntax `weightnet', other(_wn)
		mata: `mat' = transformIntoProbs((*`_wnnetobj'->get_matrix()))
	}
	
	tempname __nwnew
	mata: `__nwnew' = getNetFromProbs(`mat')
	mata: st_numscalar("r(nodes)", rows(`__nwnew' ))
	local nodes = `r(nodes)'
	
	if  "`density'" == ""{
		capture mata: `mat'
		if _rc != 0 {
			di "{err}Mata matrix `mat' not found.{txt}"
			error _rc
		}
		else {
			mata: st_numscalar("r(matrows)", rows(`mat'))
			mata: st_numscalar("r(matcols)", cols(`mat'))
			if (`r(matrows)' != `r(matcols)') {
				// Error-code coherence pass: a malformed input matrix
				// shape, not a "network already exists" collision (the
				// `6099' this line had drifted onto by coincidence) -
				// `errMatrixShape' (6082, unw_defs.ado) already names
				// this exact situation for nwreplacemat.ado's own
				// identical check.
				di "{err}Mata matrix `mat' not square.{txt}"
				error `errMatrixShape'
			}
			if "`undirected'" != "" {
				mata: `mat' = lowertriangle(`mat')
			}
			// BUGFIX: `weights()' is documented ("the command generates
			// a weighted network") but was accepted by `syntax' and
			// then never referenced anywhere else in this program - a
			// complete no-op; the network always came back plain
			// binary 0/1 regardless of what weights() requested.
			// Implemented using the exact same sampling pattern this
			// package's own generator siblings (nwrandom.ado/
			// nwpref.ado) already use and have had cross-validated:
			// rdiscrete() over the (standardized) requested weight
			// probabilities, one draw per potential dyad, applied as
			// an elementwise multiplier onto the realized 0/1 tie
			// matrix (so a non-tie, 0, stays 0 regardless of the
			// sampled weight).
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
				capture mata: mata drop `w'
			}
			nwset, mat(`__nwnew') name(`name') `labs' `xvars'

			if "`undirected'" != "" {
				nwsym `dyadname'
			}
		}

	}
	if "`density'" != "" & "`weights'" != "" {
		// BUGFIX: `weights()' was silently ignored here too when
		// density() is also given (a separate code path - see the
		// `density'=="" branch above for the case that's now properly
		// implemented) - implementing weighted sampling for the
		// gsample()-based path is a larger, separate undertaking (it
		// depends on an external SSC package installed at runtime, and
		// needs its own dedicated validation) not attempted in this
		// pass. An honest, clear error is a real improvement over
		// silently producing an unweighted network while claiming
		// weights() was honored.
		di "{err}Option {bf:weights()} combined with {bf:density()} is not yet supported; specify {bf:mat()} instead of {bf:density()} to use weights().{txt}"
		error 198
	}
	if "`density'" != "" {
		// Generate network from weight network
		preserve
		nwset, mat(`mat') name(_tempdyad)
		nwreplace _tempdyad = _tempdyad * 10
		nwtoedge _tempdyad, full

		if "`undirected'" != "" {
			replace _tempdyad = 0 if `nw_alter' <= `nw_ego'
		}

		local ties = `nodes' * (`nodes' -1) * `density'
		if "`undirected'" != "" {
			local ties = `ties' / 2
		}
		qui gen _nonzero = (_tempdyad > 0)
		qui sum _nonzero
		if `r(sum)' < `ties' {
			noi di "{err}Not enough non-zero weights to generate `ties' ties"
			nwdrop _tempdyad
			exit
		}
		qui drop if `nw_ego' == `nw_alter'
		gsample `ties' [aweight=_tempdyad], generate(link) wor
		qui nwfromedge `nw_ego' `nw_alter' link, name(`name') `labs' `xvars'
		nwdrop _tempdyad
		restore
	}
	
	if "`undirected'" != "" {
		nwsym 
	}
	if "`xvars'" == "" {
		nwload, xvars
	}
	else {
		nwload
	}

end

capture mata: mata drop getNetFromProbs()
capture mata: mata drop transformIntoProbs()

mata:
real matrix getNetFromProbs(real matrix probs) {
	real matrix net
	real scalar nodes
	
	net = J(rows(probs), rows(probs), 0)
	if (rows(probs) == cols(probs)) {
		nodes = rows(probs)
		net = (runiform(rows(probs), cols(probs)):<= probs)	
		_diag(net, 0)
	}
	return(net)
}

real matrix transformIntoProbs(real matrix net) {
	if (max(net) > 1 | min(net) < 0) {
		net = invlogit(net)
		_diag(net,0)
	}
	return(net)
}
end

