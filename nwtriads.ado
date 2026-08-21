/***
{smcl}
{* *! version 2.0.0  8jul2016}{...}
{marker topic}
{helpb nw_topical##information:[NW-2.4] Information}

{title:Title}

{p2colset 5 18 22 2}{...}
{p2col :nwtriads  {hline 2}}Triad census of the network{p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 17 2}
{cmdab: nwtriads} 
[{help netname}]

{title:Description}

{pstd}
Returns the triad census of the network (or a list of networks). This is a way to characertize a network based on its triads.

{pstd}
Each unique triad (triple of nodes {it:i}, {it:j}, and {it:k})
in a directed network can be one of the following:

	003  = i,j,k, empty triad.
	012  = i->j, k, triad with a single directed edge.
	102  = i<->j, k, triad with a reciprocated connection between two vertices.
	021D = i<-j->k, triadic out-star.
	021U = i->j<-k triadic in-star.
	021C = i->j->k, directed line.
	111D = i<->j<-k
	111U = i<->j->k.
	030T = i->j<-k, i->k.
	030C = i<-j<-k, i->k.
	201  = i<->j<->k.
	120D = i<-j->k, i<->k.
	120U = i->j<-k, i<->k.
	120C = i->j->k, i<->k.
	210  = i->j<->k, i<->k.
	300  = i<->j<->k, i<->k,  complete triad.
 
 {pstd}
 This is the so called MAN notation. As in {help nwdyads} it characterized a triad
 by the number of 1) mutual dyads, 2) asymmetric dyads and 3) null dyads. For example,
 MAN = 102 means that there is one mutual dyad and two null dyads.


{title:Supported network types}

{pstd}
Binary: yes. Directed: yes - this is the command's native case; the full 16-type MAN
classification requires a genuine directed/asymmetric-dyad distinction. Undirected: the command
still runs, but 12 of the 16 categories (everything except {bf:_003}/{bf:_102}/{bf:_201}/{bf:_300})
are not meaningful for undirected data and reliably return 0, since an undirected network
has no asymmetric ties by construction - {cmd:nwtriads} prints a note to this effect when called on
an undirected network. Weighted: not applicable (a triad census is inherently a binary/dichotomous
count). Signed: not checked. Two-mode: not checked.


{title:Examples}
	
{com}. webnwuse glasgow, nwclear
{res}
{com}. nwtriads glasgow3
{res}
{txt}    Triad census: {res} glasgow3{txt}

{txt}{ralign 10:003}{col 12}{c |}{ralign 10:012}{col 24}{c |}{ralign 10:021D}{col 36}{c |}{ralign 10:021U}{col 48}{c |}
{hline 11}{c +}{hline 11}{c +}{hline 11}{c +}{hline 11}{c +}
{res}{ralign 10:16086}{col 12}{c |}{ralign 10:1401}{col 24}{c |}{ralign 10:4}{col 36}{c |}{ralign 10:8}{col 48}{c |}

{txt}{ralign 10:021C}{col 12}{c |}{ralign 10:030T}{col 24}{c |}{ralign 10:030C}{col 36}{c |}{ralign 10:102}{col 48}{c |}
{hline 11}{c +}{hline 11}{c +}{hline 11}{c +}{hline 11}{c +}
{res}{ralign 10:7}{col 12}{c |}{ralign 10:1}{col 24}{c |}{ralign 10:0}{col 36}{c |}{ralign 10:1969}{col 48}{c |}

{txt}{ralign 10:120D}{col 12}{c |}{ralign 10:120U}{col 24}{c |}{ralign 10:120C}{col 36}{c |}{ralign 10:111D}{col 48}{c |}
{hline 11}{c +}{hline 11}{c +}{hline 11}{c +}{hline 11}{c +}
{res}{ralign 10:3}{col 12}{c |}{ralign 10:28}{col 24}{c |}{ralign 10:33}{col 36}{c |}{ralign 10:4}{col 48}{c |}

{txt}{ralign 10:111U}{col 12}{c |}{ralign 10:201}{col 24}{c |}{ralign 10:210}{col 36}{c |}{ralign 10:300}{col 48}{c |}
{hline 11}{c +}{hline 11}{c +}{hline 11}{c +}{hline 11}{c +}
{res}{ralign 10:1}{col 12}{c |}{ralign 10:17}{col 24}{c |}{ralign 10:26}{col 36}{c |}{ralign 10:12}{col 48}{c |}

{txt}     Transitivity: {res}.4830508474576271

{pstd}
{txt}This example shows, e.g. that in the {it:glasgow3} network, there are 12 triads where all nodes {it:i}, {it:j} and {it:k} are directely connected with each other.


{title:Stores results}

	Scalars:
		{bf:r(_003)}	empty triad
		{bf:r(_012)}	triad with one asymmetric dyad and two null dyads.
		...
		{bf:r(_300)}	complete triad
		
	Macros:
		{bf:r(name)}	name of the network
		
		
{title:See also}

	{help nwdyads}



***/

capture program drop nwtriads
program nwtriads
	version 9
	syntax [anything(name=netname)]
	
	nw_syntax `netname', max(1)
	local onedirected = "`directed'"

	// The 16-type MAN census is a genuinely directed-network concept:
	// calculate_triadcensus() computes it from the network's mutual (M)
	// and asymmetric (C = net - M) dyad components, and for an
	// undirected network every tie is symmetric by construction, so C
	// is mathematically zero and every category that depends only on C
	// is trivially 0 regardless of the network's actual structure -
	// confirmed by direct computation on several undirected test
	// networks. _210 was previously found NOT to reliably return 0 for
	// undirected input, suspected at the time to be a Mata
	// [symmetric]-matrix-type edge case inside calculate_triadcensus()
	// itself - that suspicion was wrong: the actual root cause (found by
	// directly comparing calculate_triadcensus()'s own return-vector
	// order against this file's r()-extraction below) was a simple
	// swapped pair of indices right here in nwtriads.ado, reading
	// r(_201) from x_210's position and r(_210) from x_201's position -
	// now fixed. calculate_triadcensus() itself was correct the whole
	// time; only the extraction was wrong.
	if "`directed'" == "false" {
		di "{txt}Note: {bf:`netname'} is undirected - most MAN triad categories"
		di "{txt}are not meaningful for undirected data (there are no"
		di "{txt}asymmetric dyads to distinguish); only"
		di "{txt}{bf:_003}/{bf:_102}/{bf:_201}/{bf:_300} (0/1/2/3-edge triads)"
		di "{txt}reliably reflect the network's actual structure."
		di "{txt}See {help nwclustering} for undirected transitivity."
	}

	tempname triadcensus
	mata: `triadcensus' = `netobj'->calculate_triadcensus()

	mata: st_numscalar("r(_003)", `triadcensus'[1])
	mata: st_numscalar("r(_012)", `triadcensus'[2])
	mata: st_numscalar("r(_021D)", `triadcensus'[3])
	mata: st_numscalar("r(_021U)", `triadcensus'[4])
	mata: st_numscalar("r(_021C)", `triadcensus'[5])
	mata: st_numscalar("r(_030T)", `triadcensus'[6])
	mata: st_numscalar("r(_030C)", `triadcensus'[7])
	mata: st_numscalar("r(_102)", `triadcensus'[8])
	mata: st_numscalar("r(_111D)", `triadcensus'[9])
	mata: st_numscalar("r(_111U)", `triadcensus'[10])
	mata: st_numscalar("r(_120D)", `triadcensus'[11])
	mata: st_numscalar("r(_120U)", `triadcensus'[12])
	mata: st_numscalar("r(_120C)", `triadcensus'[13])
	// was st_numscalar("r(_201)", ...[14]) / st_numscalar("r(_210)",
	// ...[15]) - swapped. calculate_triadcensus()'s own return statement
	// (unw_core.do) orders its vector "..., x_120C, x_210, x_201, x_300"
	// - index 14 is x_210, index 15 is x_201 - so this file had them
	// backwards. Confirmed via 3 hand-computable undirected networks
	// (see cscripts/test_nwtriads.do): a 5-node cycle (no triangles,
	// 5 open 2-edge triads) reported _210=5/_201=0 before this fix -
	// exactly the swap, since _210 should be 0 for any undirected
	// network (no asymmetric dyads to form a 2-1-mutual/1-asym triad
	// from) while _201 (2-edge open triads) should be 5. This also
	// resolves the previously-suspected "Mata [symmetric]-matrix-type
	// edge case" (see docs/CERTIFICATION.md's now-superseded Pending
	// row) - direct probing found no such Mata quirk at all once this
	// far simpler root cause was found; calculate_triadcensus() itself
	// was correct the whole time.
	mata: st_numscalar("r(_201)", `triadcensus'[15])
	mata: st_numscalar("r(_210)", `triadcensus'[14])
	mata: st_numscalar("r(_300)", `triadcensus'[16])

	tempname r
	
	_return hold `r'
	preserve
	nwclustering `netname'
	local transitivity `r(cluster_global)'
	restore
	_return restore `r'
	
	mata: st_global("r(name)", "`netname'")
	mata: st_numscalar("r(transitivity)", `transitivity')

	
	di
	di "{txt}    Triad census: {res} `netname'{txt}"
	di 
	di "{txt}{ralign 10:003}{col 12}{c |}{ralign 10:012}{col 24}{c |}{ralign 10:021D}{col 36}{c |}{ralign 10:021U}{col 48}{c |}"
	di "{hline 11}{c +}{hline 11}{c +}{hline 11}{c +}{hline 11}{c +}"
	di "{res}{ralign 10:`r(_003)'}{col 12}{c |}{ralign 10:`r(_012)'}{col 24}{c |}{ralign 10:`r(_021D)'}{col 36}{c |}{ralign 10:`r(_021U)'}{col 48}{c |}"
	di
	di "{txt}{ralign 10:021C}{col 12}{c |}{ralign 10:030T}{col 24}{c |}{ralign 10:030C}{col 36}{c |}{ralign 10:102}{col 48}{c |}"
	di "{hline 11}{c +}{hline 11}{c +}{hline 11}{c +}{hline 11}{c +}"
	di "{res}{ralign 10:`r(_021C)'}{col 12}{c |}{ralign 10:`r(_030T)'}{col 24}{c |}{ralign 10:`r(_030C)'}{col 36}{c |}{ralign 10:`r(_102)'}{col 48}{c |}"
	di
	di "{txt}{ralign 10:120D}{col 12}{c |}{ralign 10:120U}{col 24}{c |}{ralign 10:120C}{col 36}{c |}{ralign 10:111D}{col 48}{c |}"
	di "{hline 11}{c +}{hline 11}{c +}{hline 11}{c +}{hline 11}{c +}"
	di "{res}{ralign 10:`r(_120D)'}{col 12}{c |}{ralign 10:`r(_120U)'}{col 24}{c |}{ralign 10:`r(_120C)'}{col 36}{c |}{ralign 10:`r(_111D)'}{col 48}{c |}"
	di
	di "{txt}{ralign 10:111U}{col 12}{c |}{ralign 10:201}{col 24}{c |}{ralign 10:210}{col 36}{c |}{ralign 10:300}{col 48}{c |}"
	di "{hline 11}{c +}{hline 11}{c +}{hline 11}{c +}{hline 11}{c +}"
	di "{res}{ralign 10:`r(_111U)'}{col 12}{c |}{ralign 10:`r(_201)'}{col 24}{c |}{ralign 10:`r(_210)'}{col 36}{c |}{ralign 10:`r(_300)'}{col 48}{c |}"
	di 
	di "{txt}     Transitivity: {res}`r(transitivity)'"
end
	

