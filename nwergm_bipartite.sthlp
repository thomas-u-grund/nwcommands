{smcl}
{* *! nwergm_bipartite.sthlp  two-mode terms of nwergm}{...}
{vieweralsosee "nwergm" "help nwergm"}{...}
{viewerjumpto "Syntax" "nwergm_bipartite##syntax"}{...}
{viewerjumpto "Terms" "nwergm_bipartite##terms"}{...}
{viewerjumpto "Behaviour" "nwergm_bipartite##behaviour"}{...}
{title:Title}

{p2colset 5 27 29 2}{...}
{p2col:{bf:nwergm (two-mode)} {hline 2}}Two-mode (bipartite) terms of {help nwergm}{p_end}
{p2colreset}{...}

{marker syntax}{...}
{title:Syntax}

{p 8 16 2}
{cmd:nwergm} {it:netname} {cmd:,} {opt edges} {it:bipartite_term}{cmd:(}{it:main} [{cmd:,} {it:suboptions}]{cmd:)} ... [{opt method(mple|mcmle)}]

{pstd}
The terms of R's {cmd:ergm} that carry a mode in their name keep their R meaning; the mode digit moves to the end of the Stata option name
(Stata does not allow a digit followed by a letter in an option name): {cmd:b1degree} is {cmd:bdegree1()}, {cmd:b2degree} is {cmd:bdegree2()}, and so on.
Arguments of R's terms become the first argument of the option, and R's named arguments become suboptions after a comma.
Level selections ({opt levels()}, {opt base()}) count positions in the sorted distinct values, as in R.
Node attributes are numeric variables in the observation order of the nodes (mode-1 nodes first).

{marker terms}{...}
{title:Terms}

{synoptset 34 tabbed}{...}
{synopthdr:option}
{synoptline}
{synopt:{opt bconcurrent1(all)} | {opt bconcurrent2(all)}}Nodes of the mode with degree 2 or more. {cmd:bconcurrent1(by(}{it:var}{cmd:)} [{cmd:levels(}{it:numlist}{cmd:)}]{cmd:)} gives one statistic per level of the attribute (R: {cmd:b1concurrent(by=)}){p_end}
{synopt:{opt bmindegree1(numlist)} | {opt bmindegree2(numlist)}}Nodes with degree of at least d (R: {cmd:b1mindegree}){p_end}
{synopt:{opt bdegrange1(numlist, to(numlist) by() levels() homophily)}}Nodes with degree in [from,to) ({cmd:.} in {opt to()} is infinity; R: {cmd:b1degrange}); {opt bdegrange2()} for mode 2{p_end}
{synopt:{opt bdegree1(numlist, by() levels() homophily)}}{cmd:b1degree} with {cmd:by=}/{cmd:homophily=}; {opt bdegree2()} for mode 2{p_end}
{synopt:{opt bstar1(numlist, attr() levels())}}k-stars whose centre and leaves share the attribute value ({cmd:b1star(k, attr=)}); {opt bstar2()} for mode 2{p_end}
{synopt:{opt bcovrange1(varname)} | {opt bcovrange2(varname)}}Sum over nodes of the range of the neighbours' attribute ({cmd:b1covrange}, {cmd:b2covrange}){p_end}
{synopt:{opt bfactordistinct1(var, levels())} | {opt bfactordistinct2()}}Sum over nodes of the number of distinct attribute values among the neighbours{p_end}
{synopt:{opt bsociality1(numlist)} | {opt bsociality2(numlist)}}Degree of single nodes; the numbers are positions within the mode and negative numbers exclude, so {cmd:bsociality1(-1)} (R's default) leaves out the first node{p_end}
{synopt:{opt bstarmix1(k, attr(var) nodiff base())} | {opt bstarmix2()}}Mixing matrix of k-stars ({cmd:b1starmix}, {cmd:b2starmix}){p_end}
{synopt:{opt btwostar1(var, attr2(var) levels1() levels2() levels3() base())} | {opt btwostar2()}}Two-star census by the attributes of centre and leaves ({cmd:b1twostar}, {cmd:b2twostar}){p_end}
{synopt:{opt coincidence(all)} | {opt coincidence(active(#))}}Number of common mode-1 neighbours for each pair of mode-2 nodes; {opt active()} keeps the pairs observed more than # times{p_end}
{synopt:{opt bdsp1(numlist)} | {opt bdsp2(numlist)}}Pairs of nodes of the mode with exactly d shared partners ({cmd:b1dsp}, {cmd:b2dsp}){p_end}
{synopt:{opt bgwdsp1(decay)} | {opt bgwdsp2(decay)}}Geometrically weighted dyadwise shared partners, fixed decay ({cmd:gwb1dsp(fixed=TRUE)}){p_end}
{synopt:{opt bgwdegreefree1(decay)} | {opt bgwdegreefree2()} | {opt bgwdspfree1()} | {opt bgwdspfree2()}}The curved versions (R's default {cmd:fixed=FALSE}); the number is the starting value of the decay{p_end}
{synopt:{opt bgwdegree1(decay, attr(var) levels())}}{cmd:gwb1degree(decay, fixed=TRUE, attr=)}; plain {cmd:bgwdegree1(decay)} is unchanged{p_end}
{synopt:{opt bnodematch1(var, diff alpha(#) beta(#) byattr(var) keep() levels())}}Full {cmd:b1nodematch}: {opt byattr()} is R's {cmd:byb2attr}; {opt bnodematch2()} takes the mode-1 attribute as {opt byattr()}{p_end}
{synopt:{opt nodemix(var)}}On a two-mode network, edges between each level of the mode-1 and each level of the mode-2 attribute (the first cell is omitted, as R){p_end}
{synoptline}

{marker behaviour}{...}
{title:Behaviour as in R}

{pstd}
The undirected one-mode terms that R accepts on a two-mode network ({opt nodecov()}, {opt nodefactor()}, {opt nodematch()}, {opt absdist()}, {opt edgecov()}, {opt hamming()}, {opt degree()}, {opt kstar()}, {opt concurrent}, {opt degrange()}, {opt esp()}, {opt dsp()}, {opt gwesp()}, {opt gwdsp()}, {opt gwnsp()}, {opt triangle})
are computed over the whole node set and give the same numbers as R. The directed-only terms ({opt mutual}, {opt nodeicov()}, {opt nodeocov()}, {opt odegree()}, ...)
stop with R's message {it:Term may not be used with networks with directed==FALSE}, and {opt gwdegree()}, {opt gwodegree()}, {opt gwidegree()} with {it:bipartite > 0}.
The two-mode terms on a one-mode network stop with {it:Term may not be used with networks with bipartite==FALSE}.

{pstd}
{cmd:nwergm simulate} accepts the same options together with {opt bipartite(#)}, the number of mode-1 nodes.
{cmd:estat gof} after a two-mode model compares the degree distributions of both modes, the dyadwise shared partners and the geodesic distances
with simulated networks (observed, minimum, mean, maximum and Monte Carlo p-value), as R's {cmd:gof()}.
Constraints ({opt blockdiag()}, {opt freedyads()}) and {opt edgecov()} with a two-mode covariate network work on two-mode models.

{pstd}
The pseudolikelihood fit solves the logistic regression to a tighter tolerance than Stata's default so that the coefficients agree with R to about 1e-6 when the fit is well identified.
{p_end}
