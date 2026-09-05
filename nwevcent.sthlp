{smcl}
{* *! version 1.0.0  3sept2014}{...}
{marker topic}
{helpb nwtopical##analysis_centrality:[NW-2.6.1] Centrality}

{title:Title}

{p2colset 9 17 22 2}{...}
{p2col :nwevcent {hline 2}}Calculate eigenvector centrality{p_end}
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


{title:Supported network types}

{pstd}
Binary: yes. Directed: yes - symmetrized by default (same "no-prefix trap" {opt nosym} convention as {help nwcloseness}/{help nwkatz}), {opt nosym} available. Weighted: not by default - {opt weighted} switches to the tie-value-weighted generalization (Newman 2004, Bonacich power centrality); has no effect on an unvalued network. Signed: not checked. Two-mode: not applicable (one-mode only).

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

last certified : 24 Aug 2026
