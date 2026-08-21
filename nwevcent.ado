/***
{smcl}
{* *! version 1.0.0  3sept2014}{...}
{marker topic}
{helpb nw_topical##analysis:[NW-2.6] Analysis}

{title:Title}

{p2colset 9 17 22 2}{...}
{p2col :nwevcent {hline 2} Calculate eigenvector centrality}
{p2colreset}{...}


{title:Syntax}

{p 8 17 2}
{cmdab: nwevcent}
[{it:{help netname}}]
[{cmd:,}
{opt generate}({it:{help varname}})
{opt nosym}
{opt weighted}
{opt replace}]

{synoptset 25 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt generate}({it:{help varname}})}variable name for eigenvector centrality scores; default:
{it:varname = _evcent}{p_end}
{synopt:{opt nosym}}do not symmetrize network before calculation{p_end}
{synopt:{opt weighted}}calculate on tie values instead of dichotomizing a valued network{p_end}
{synopt:{opt replace}}replace existing {it:generate()} variable{p_end}


{title:Description}

{pstd}
Calculates eigenvector centrality for each node {it:i} in a netwwork and
saves the result as a Stata variable. It assigns relative scores to all nodes in the network
based on the concept that connections to high-scoring nodes contribute more to the score of
the node in question than equal connections to low-scoring nodes.

{pstd}
By default, a valued network is dichotomized before calculation (any nonzero, non-missing tie value
counts as a tie, regardless of magnitude) - the historical, still-default behavior of this command.
Option {bf:weighted} instead calculates on the tie values themselves, so that stronger ties
contribute proportionally more, matching the standard weighted generalization of eigenvector
centrality (Newman 2004, Bonacich power centrality). {bf:weighted} has no effect on an unvalued
network (there is nothing to weight by).

{pstd}
Eigenvector centrality is only defined for connected networks.


{title:Scope}

{pstd}
Directed and undirected, valued and unvalued, one-mode only


{title:Examples}

	{cmd:. nwwebuse gang, nwclear}
	{cmd:. nwevcent gang, generate(_evcent)}
	{cmd:. sum _evcent}
	{cmd:. nwevcent gang, generate(_evcent_w) weighted}


{title:References}

{pstd}
Newman, M.E.J. (2004). Analysis of weighted networks. {it:Physical Review E} 70, 056131.

{pstd}
Bonacich, P. (1972). Factoring and weighting approaches to status scores and clique identification.
{it:Journal of Mathematical Sociology} 2(1), 113-120.


{title:See also}

	{help nwcloseness}, {help nwbetween}, {help nwdegree}, {help nwcloseness}

***/
capture program drop nwevcent
program nwevcent
	version 9
	syntax [anything(name=netname)] , [nosym weighted GENerate(string) replace]
	nw_syntax `netname'
	nw_datasync `netname'

	if "`generate'" == "" {
		local generate "_evcent"
	}
	if "`sym'" == "" {
		local nosym 0
	}
	else {
		local nosym 1
	}

	local getvalued = 0
	if "`weighted'" != "" & "`valued'" == "true" {
		local getvalued = 1
	}

	capture confirm variable `generate'
	if _rc == 0 & "`replace'" == "" {
		di "{err}Variable {it:`generate'} already exists. Use option {bf:replace}.{txt}"
		exit
	}
	else {
		capture generate `generate' = .
	}

	mata: st_store((1::`nodes'),"`generate'", nw_evcentrality(`netobj',`nosym',`getvalued'))

	di "{hline 40}"
	di "{txt}  Network name: {res}`netname'"
	di "{hline 40}"
	di "{txt}    Eigenvector centrality"
	if `nosym' == 0 {
		di "{txt}.   (calculated on symmetrized network)"
	}
	if `getvalued' == 1 {
		di "{txt}.   (calculated on tie values, not dichotomized)"
	}
	mata: st_rclear()
	sum `generate'

end

capture mata: mata drop nw_evcentrality()
mata:
real matrix function nw_evcentrality(pointer (class nw_def scalar) scalar thisnw, real scalar nosym, real scalar getvalued)
{
	real matrix EC, EV, net
	real scalar maxEV,index,i,n

	net = (*thisnw->get_matrix_mod(getvalued,nosym))
	_diag(net,0)

	symeigensystem(net, EC=.,EV=.)
	maxEV = (max(EV))
	if (maxEV == 0) {
		return(J(thisnw->get_nodes(), 1, .))
	}

	// get_nodes() returns a scalar, not a matrix - rows() of it is always
	// 1, so this search previously only ever checked i=1 (never actually
	// searching). Silently correct in practice only because Mata's
	// symeigensystem() returns eigenvalues already sorted descending (so
	// index 1 already held the max) - fixed to genuinely search rather
	// than rely on that ordering holding for every possible input.
	n = thisnw->get_nodes()
	for(i=1;i<=n;i++){
		if ((EV[1,i]) ==(maxEV) & maxEV != .){
			index = i
			break
		}
	}
	if (EC[1,index] < 0) {
		return(EC[.,index]*-1)
	}
	else {
		return(EC[.,index])
	}
}
end

