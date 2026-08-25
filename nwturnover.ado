/***
{smcl}
{* *! version 1.0.0  22aug2026 author: Thomas Grund}{...}
{marker topic}
{helpb nw_topical##analysis_other:[NW-2.6.7] Other Analysis Utilities}

{title:Title}

{p2colset 9 21 22 2}{...}
{p2col :nwturnover {hline 2}}Tie turnover/stability between two waves of the same network{p_end}
{p2colreset}{...}

{title:Syntax}

{p 8 17 2}
{cmdab: nwturnover}
{it:net1} {it:net2}
[{cmd:,}
{opth generate(newvarname)}
{opt replace}
{opt silent}]


{synoptset 25 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opth generate(newvarname)}}Name of the Stata variable that stores each node's own local stability; default = {it:_turnover}{p_end}
{synopt:{opt replace}}Replace existing variable{p_end}
{synopt:{opt silent}}Suppress display of results{p_end}

{p2colreset}{...}

{title:Description}

{pstd}
{cmd:nwturnover} compares two networks on the SAME node set representing two waves of
observation of the same relationship (e.g. a panel/longitudinal network study, {it:net1} at time
{it:t} and {it:net2} at time {it:t+1}) and reports how much the tie structure changed between
them: how many ties were {bf:stable} (present at both waves), {bf:formed} (absent at {it:net1},
present at {it:net2}), or {bf:dissolved} (present at {it:net1}, absent at {it:net2}). Only tie
presence/absence is compared (not tie weight) - {help nwcorrelate}, which correlates tie
{it:values} between two networks, answers a related but different question.

{pstd}
{bf:r(jaccard)} is the standard "Jaccard index of network change" used in longitudinal SNA (e.g.
Snijders et al.'s SIENA methodology) to gauge whether enough change occurred between waves to be
worth modeling at all: {bf:stable / (stable + formed + dissolved)} - 1 when the two networks are
identical, 0 when they share no tie in common whatsoever. {bf:r(persistence)} is a related but
distinct question - of the ties that existed at {it:net1}, what fraction survived to {it:net2}:
{bf:stable / (stable + dissolved)}, undefined (missing) if {it:net1} has no ties at all.

{pstd}
By default, {cmd:nwturnover} also generates a per-node variable ({it:_turnover}) giving each
node's OWN local Jaccard stability - computed the same way as {bf:r(jaccard)}, but restricted to
that one node's own ties across the two waves, rather than the whole network's.

{pstd}
{it:net1} and {it:net2} must have the same number of nodes and the same directedness (both
directed or both undirected) - comparing a directed network to an undirected one, or two networks
of different size, is rejected explicitly rather than silently doing something arithmetically
possible but conceptually meaningless.

{pstd}
For an {bf:undirected} pair of networks, {bf:r(stable)}, {bf:r(formed)}, and {bf:r(dissolved)}
each count both {it:(i,j)} and {it:(j,i)} for the same tie, so all three are exactly double the
number of actual undirected ties involved (the same convention {help nwmixing} uses for its own
mixing table). {bf:r(jaccard)} and {bf:r(persistence)} are unaffected, since the doubling cancels
in both ratios.

{title:Stored results}

	Scalars
	  {bf:r(stable)}		number of ties present in both networks
	  {bf:r(formed)}		number of ties present only in {it:net2}
	  {bf:r(dissolved)}		number of ties present only in {it:net1}
	  {bf:r(jaccard)}		stable / (stable + formed + dissolved)
	  {bf:r(persistence)}		stable / (stable + dissolved); missing if {it:net1} has no ties

{title:Examples}

	{cmd:. nwset, mat((0,1,1\1,0,0\1,0,0)) name(wave1)}
	{cmd:. nwset, mat((0,1,0\1,0,1\0,1,0)) name(wave2)}
	{cmd:. nwturnover wave1 wave2}

{title:References}

{pstd}
Snijders, T.A.B., van de Bunt, G.G., Steglich, C.E.G. (2010). Introduction to stochastic actor-based
models for network dynamics. {it:Social Networks} 32(1), 44-60. (the Jaccard index of network
change, used as a standard diagnostic for whether panel-wave data is suitable for dynamic modeling)

{title:Supported network types}

{pstd}
Binary: yes. Directed: yes (each ordered pair compared independently, both networks must share
the same directedness). Weighted: not used - only tie presence/absence is compared. Signed: not
checked. Two-mode: not checked - operates on each network's own square adjacency matrix.

{title:See also}

	{help nwcorrelate}, {help nwcomponents}, {help nwqap}

***/

capture program drop nwturnover
program nwturnover, rclass
	version 12
	syntax anything(name=netnames) [, GENerate(string) REPlace silent]
	set more off

	nw_syntax `netnames', max(2) min(2)
	local netname1 : word 1 of `netname'
	local netname2 : word 2 of `netname'

	nw_syntax `netname1'
	local nodes1 `nodes'
	local directed1 `directed'
	local netobj1 `netobj'

	nw_syntax `netname2'
	local nodes2 `nodes'
	local directed2 `directed'
	local netobj2 `netobj'

	if `nodes1' != `nodes2' {
		di "{err}Networks of different size."
		error 6056
	}
	if "`directed1'" != "`directed2'" {
		di "{err}{bf:`netname1'} and {bf:`netname2'} must both be directed or both be undirected."
		error 198
	}
	local isdirected = ("`directed1'" == "true")

	local netgenerate "`generate'"
	if "`netgenerate'" == "" {
		local netgenerate = "_turnover"
	}
	capture confirm variable `netgenerate', exact
	if _rc == 0 & "`replace'" == "" {
		noi di "{err}Variable {bf:`netgenerate'} already exists; specify {bf:replace}"
		err 99
	}

	mata: st_rclear()
	qui if _N < `nodes1' {
		set obs `nodes1'
	}
	nw_syntax `netname1'
	local netobj1 `netobj'
	nw_syntax `netname2'
	local netobj2 `netobj'

	tempname __nw_A1 __nw_A2 __nw_pernode __nw_turnrate
	mata: `__nw_A1' = (*`netobj1'->get_matrix_mod(0,`isdirected')) :!= 0
	mata: `__nw_A2' = (*`netobj2'->get_matrix_mod(0,`isdirected')) :!= 0
	mata: _diag(`__nw_A1', 0)
	mata: _diag(`__nw_A2', 0)

	mata: `__nw_pernode' = J(`nodes1', 3, 0)
	mata: `__nw_pernode'[.,1] = rowsum(`__nw_A1' :& `__nw_A2')
	mata: `__nw_pernode'[.,2] = rowsum(`__nw_A2' :& !`__nw_A1')
	mata: `__nw_pernode'[.,3] = rowsum(`__nw_A1' :& !`__nw_A2')

	local divisor = cond(`isdirected', 1, 2)
	mata: st_numscalar("nw_stable", sum(`__nw_pernode'[.,1]) / `divisor')
	mata: st_numscalar("nw_formed", sum(`__nw_pernode'[.,2]) / `divisor')
	mata: st_numscalar("nw_dissolved", sum(`__nw_pernode'[.,3]) / `divisor')

	mata: `__nw_turnrate' = J(`nodes1', 1, .)
	mata: nw_denom_total = rowsum(`__nw_pernode')
	mata: `__nw_turnrate'[selectindex(nw_denom_total :> 0)] = `__nw_pernode'[selectindex(nw_denom_total :> 0),1] :/ nw_denom_total[selectindex(nw_denom_total :> 0)]
	mata: mata drop nw_denom_total

	capture drop `netgenerate'
	qui gen `netgenerate' = .
	mata: st_store((1::`nodes1'), "`netgenerate'", `__nw_turnrate')
	mata: mata drop `__nw_A1' `__nw_A2' `__nw_pernode' `__nw_turnrate'

	local total = nw_stable + nw_formed + nw_dissolved
	local jaccard = cond(`total' > 0, nw_stable / `total', .)
	local persistdenom = nw_stable + nw_dissolved
	local persistence = cond(`persistdenom' > 0, nw_stable / `persistdenom', .)

	return scalar stable = nw_stable
	return scalar formed = nw_formed
	return scalar dissolved = nw_dissolved
	return scalar jaccard = `jaccard'
	return scalar persistence = `persistence'

	// see nwbrokerage.ado's own header comment: the "already exists"
	// probe above leaves _rc stale even after a fully successful run -
	// reset explicitly and silently.
	capture confirm variable `netgenerate', exact

	if "`silent'" == "" {
		noi di "{hline 40}"
		noi di "{txt}  Networks: {res}`netname1'{txt} -> {res}`netname2'"
		noi di "{txt}  Stable: {res}`=nw_stable'{txt}  Formed: {res}`=nw_formed'{txt}  Dissolved: {res}`=nw_dissolved'"
		noi di "{txt}  Jaccard index: {res}`=round(`jaccard',0.0001)'"
		if `persistdenom' > 0 {
			noi di "{txt}  Persistence: {res}`=round(`persistence',0.0001)'"
		}
		noi di " "
	}
end
