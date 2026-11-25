{smcl}
{* *! version 1.0.0  19nov2026 author: Thomas Grund}{...}
{marker topic}
{helpb nwtopical##manipulation:[NW-2.5] Manipulation}

{title:Title}

{p2colset 9 22 24 2}{...}
{p2col :nwbackbone {hline 2}}Backbone extraction for valued networks and two-mode projections{p_end}
{p2colreset}{...}

{title:Syntax}

{p 8 17 2}
{cmd:nwbackbone} [{it:{help netname}}] {cmd:,} {opt m:ethod(method)} [{it:options}]

{synoptset 28 tabbed}{...}
{synopthdr}
{synoptline}
{p2coldent:* {opt m:ethod(method)}}{cmd:global}, {cmd:disparity}, {cmd:lans}, {cmd:mlf} (valued one-mode network) or {cmd:sdsm}, {cmd:fdsm}, {cmd:fixedrow}, {cmd:fixedcol}, {cmd:fixedfill} (two-mode network){p_end}
{synopt:{opt al:pha(#)}}significance level; default {cmd:0.05}{p_end}
{synopt:{opt mtc(adjustment)}}multiple-testing correction: {cmd:none} (default), {cmd:bonferroni}, {cmd:holm}, {cmd:hochberg}, {cmd:hommel}, {cmd:BH} (= {cmd:fdr}), {cmd:BY}{p_end}
{synopt:{opt thr:eshold(# [#])}}for {cmd:method(global)}: keep ties with a value above #{p_end}
{synopt:{opt sign:ed}}keep significantly weak ties as well, with the value -1{p_end}
{synopt:{opt keep:values}}give the kept ties their tie values (the counts of the projection) instead of 1{p_end}
{synopt:{opt miss:ingaszero}}also test the dyads without a tie{p_end}
{synopt:{opt p:roject(1|2)}}two-mode network: the mode whose projection is filtered; default {cmd:1}{p_end}
{synopt:{opt tri:als(#)}}{cmd:method(fdsm)}: number of random networks{p_end}
{synopt:{opt seed(#)}}random-number seed ({cmd:method(fdsm)}){p_end}
{synopt:{opt gen:erate(newname)}}name of the backbone network; default {cmd:backbone}{p_end}
{synopt:{opt replace}}overwrite an existing network of that name{p_end}
{synopt:{opt silent}}do not show the summary{p_end}
{synoptline}
{p 4 6 2}* {opt method()} is required.{p_end}

{title:Description}

{pstd}
{cmd:nwbackbone} reduces a dense, valued network to its backbone: the ties that are significantly strong
(or, with {opt signed}, significantly weak) against a stated null model. The result is a new network that is
binary (1 for a kept tie) or, with {opt keepvalues}, keeps the values of the kept ties. The methods and
their names follow the R package {it:backbone} (Neal; version 3.0.4), against which {cmd:nwbackbone} was
checked.

{pstd}
Two kinds of input are handled.

{phang2}{bf:A valued one-mode network} (tie values other than 0 and 1; directed or undirected). The methods
{cmd:disparity}, {cmd:lans} and {cmd:mlf} test every tie against a null model of the ties of the same nodes;
{cmd:global} keeps ties above a value.{p_end}
{phang2}{bf:A binary two-mode network}, say persons by events. The weighted projection onto one mode counts the
shared affiliations of every pair of nodes; the methods {cmd:sdsm}, {cmd:fdsm}, {cmd:fixedrow},
{cmd:fixedcol} and {cmd:fixedfill} test each count against a null model of random two-mode networks.
The backbone is a one-mode network of the nodes of the mode chosen with {opt project()}.{p_end}

{title:Methods}

{synoptset 12}{...}
{synopt:{cmd:global}}Keeps every tie whose value is greater than {opt threshold()}. With two numbers, ties above the larger one are
kept as +1 and ties below the smaller one as -1. No test is made, so {opt alpha()}, {opt mtc()} and {opt signed} do not apply.{p_end}
{synopt:{cmd:disparity}}Disparity filter (Serrano, Boguna and Vespignani 2009). The null model spreads the strength of a node
uniformly at random over its ties; a tie is tested from the point of view of both end nodes (for a directed network, the
sender and the receiver) and the smaller p-value counts.{p_end}
{synopt:{cmd:lans}}Locally adaptive network sparsification (Foti, Hughes and Rockmore 2011): a tie is kept if it ranks high among the
ties of its node (nonparametric; ranks of the shares of the node's strength).{p_end}
{synopt:{cmd:mlf}}Marginal likelihood filter (Dianati 2016): tie values are counts whose total is distributed over the dyads in proportion to the
strengths of the nodes; each tie is tested with a binomial distribution. Needs integer tie values.{p_end}
{synopt:{cmd:sdsm}}Stochastic degree sequence model (Neal 2014; compared with the other models by Neal, Domagalski and Sagan 2021): the probability of a tie of the two-mode network is modelled from the degrees of
both nodes (the bipartite configuration model, maximum likelihood); the number of shared affiliations of two nodes is then a
Poisson-binomial variable. Its tail is computed with the refined normal approximation of the R package, not exactly.{p_end}
{synopt:{cmd:fdsm}}Fixed degree sequence model (Zweig and Kaufmann 2011; Neal, Domagalski and Sagan 2021): the p-value is the share of random two-mode networks with the
same degrees (Monte Carlo with curveball trades, Strona et al. 2014; the number of networks is {opt trials()}) in which the pair shares at least as many affiliations. Slow for large networks.{p_end}
{synopt:{cmd:fixedrow}}Fixed row model (Neal, Domagalski and Sagan 2021): the row degrees are fixed; the shared affiliations follow a hypergeometric distribution.{p_end}
{synopt:{cmd:fixedcol}}Fixed column model: the column degrees are fixed; refined normal approximation.{p_end}
{synopt:{cmd:fixedfill}}Fixed fill model: only the total number of ties is fixed; exact distribution.{p_end}

{title:Options}

{phang}
{opt alpha(#)}: a tie is kept if its p-value is smaller than {it:#} (after the correction of {opt mtc()}). With {opt signed} a tie is kept as strong, or as weak (-1),
if the p-value of that tail is smaller than {it:#}/2.

{phang}
{opt mtc(adjustment)} corrects the p-values for the number of tests made, with the formulas of R's {cmd:p.adjust}. For an
undirected network (and always for a projection) each pair is counted once. Without the option every tie is tested at {opt alpha()}, which
over-states the evidence when thousands of ties are tested.

{phang}
{opt threshold(# [#])} is required for {cmd:method(global)}.

{phang}
{opt signed} also records the ties that are significantly weaker than the null model expects: the backbone then has the values +1
and -1. For {cmd:method(global)} give two thresholds instead.

{phang}
{opt keepvalues} gives each kept tie its original value (for a projection: the number of shared affiliations); the
{opt signed} sign is then lost. Without the option kept ties have the value 1 (-1).

{phang}
{opt missingaszero} also tests dyads that have no tie (value 0 or, for a projection, no shared affiliation). Dyads without a tie are
otherwise never in the backbone. The number of tests for {opt mtc()} grows accordingly. With {cmd:signed} this
is how significantly weak, absent ties are found.

{phang}
{opt project(1|2)} (two-mode networks) chooses the mode whose nodes become the nodes of the backbone; mode 1 is the first level shown by {help nwsummarize}.
The result is a one-mode network with the node names of that mode.

{phang}
{opt trials(#)} sets the number of random networks of {cmd:fdsm}. By default it is chosen as in the R package from {opt alpha()} so that
the test can tell a p-value just below {opt alpha()} from one just above it, which needs about 80,000 networks at {cmd:alpha(0.05)}; with a
multiple-testing correction the default is much larger. For exploratory work set {opt trials()} to a few thousand
(the p-values then have a standard error of up to {cmd:0.5/sqrt(}trials{cmd:)}). {cmd:set seed} or {opt seed()} makes the result reproducible.

{phang}
{opt generate(newname)} and {opt replace}: name of the network created; an existing network is only overwritten with {opt replace}.

{title:Remarks}

{pstd}
{bf:What a backbone is.} The ties of a valued network are not all equally informative: a weight can be large only because
both nodes are active. Each method asks, for every tie, whether its weight is larger than a particular random model of the same
network would produce, and keeps the ties for which the answer is yes. The methods differ in the null model (and so in what
counts as a surprise), not in the final step. A tie that is kept is a statement about that null model, not a statement that
other ties do not matter.

{pstd}
{bf:Checked against R.} For one-mode networks and for {cmd:sdsm}, {cmd:fixedrow}, {cmd:fixedcol} and {cmd:fixedfill} the p-values equal those of
the R package {it:backbone} 3.0.4 (to better than 1e-8 absolute, 1e-6 relative) and the kept ties are identical, with and without the
corrections and with {opt signed}, on the networks of the test suite. A p-value that is exactly equal to {opt alpha()} in exact arithmetic
can fall on either side of it through rounding, in R as well as here. {cmd:fdsm} cannot reproduce R's random numbers; its p-values agree with a 40,000-draw
reference within the Monte Carlo error. Not implemented: the SDSM variant with edge constraints, the extraction from unweighted networks
(sparsification: {cmd:backbone_from_unweighted} in R), and bipartite networks with tie values.

{pstd}
{bf:Limits.} The p-values are computed for all pairs of nodes at once and held in memory as {it:n} x {it:n} matrices. Beyond a few thousand nodes of the projected mode
memory runs out first. {cmd:fdsm} needs one projection per random network and
becomes slow beyond a few hundred nodes at the default number of networks.

{pstd}
{bf:Direction.} A directed network is filtered as directed; an undirected network as undirected (a pair is tested once). The disparity filter of a directed network uses the out-strength of the sender and the in-strength of the receiver and
keeps the smaller p-value, as in R.

{pstd}
{bf:Input.} {cmd:disparity}, {cmd:lans} and {cmd:mlf} need a valued network with non-negative values; a network with only the values 0 and 1 is refused, as in R. For a
binary one-mode network see {help nwdichotomize} for the opposite direction (valued to binary at a fixed cutoff).

{title:Stored results}

{pstd}
{cmd:nwbackbone} stores the following in {cmd:r()}:

{synoptset 18 tabbed}{...}
{p2col 5 18 22 2: Scalars}{p_end}
{synopt:{cmd:r(nodes)}}number of nodes of the backbone network{p_end}
{synopt:{cmd:r(ties_in)}}number of ties tested (pairs for an undirected network){p_end}
{synopt:{cmd:r(ties)}}number of ties in the backbone{p_end}
{synopt:{cmd:r(removed)}}percentage of the ties removed{p_end}
{synopt:{cmd:r(alpha)}}the level{p_end}
{synopt:{cmd:r(trials)}}number of random networks ({cmd:fdsm}){p_end}
{p2col 5 18 22 2: Macros}{p_end}
{synopt:{cmd:r(network)}}name of the input network{p_end}
{synopt:{cmd:r(backbone)}}name of the backbone network{p_end}
{synopt:{cmd:r(method)}, {cmd:r(mtc)}}options as used{p_end}

{title:Examples}

{pstd}Disparity filter of a valued network, with a Holm correction{p_end}
{phang2}{cmd:. nwset, mat((0,9,1,1\9,0,1,2\1,1,0,8\1,2,8,0)) name(w) undirected}{p_end}
{phang2}{cmd:. nwbackbone w, method(disparity) alpha(0.2) mtc(holm) generate(wb)}{p_end}

{pstd}Keep the ties of a valued network with a value above 3, with their values{p_end}
{phang2}{cmd:. nwbackbone w, method(global) threshold(3) keepvalues generate(wg)}{p_end}

{pstd}Load a two-mode network (women by social events){p_end}
{phang2}{cmd:. nwwebuse davis, nwclear}{p_end}

{pstd}Backbone of the projection of a two-mode network (persons by events) onto the persons{p_end}
{phang2}{cmd:. nwbackbone davis, method(sdsm) alpha(0.05) mtc(BH) project(1) generate(persons)}{p_end}

{pstd}Fixed degree sequence model with 2,000 random networks{p_end}
{phang2}{cmd:. nwbackbone davis, method(fdsm) trials(2000) seed(1) generate(persons_fdsm)}{p_end}

{title:References}

{phang}
Dianati, N. 2016. Unwinding the hairball graph: pruning algorithms for weighted complex networks. {it:Physical Review E} 93: 012304.

{phang}
Foti, N. J., J. M. Hughes and D. N. Rockmore. 2011. Nonparametric sparsification of complex multiscale networks. {it:PLOS ONE} 6: e16431.

{phang}
Neal, Z. P. 2014. The backbone of bipartite projections: inferring relationships from co-authorship, co-sponsorship, co-attendance and other co-behaviors. {it:Social Networks} 39: 84-97.

{phang}
Neal, Z. P., R. Domagalski and B. Sagan. 2021. Comparing alternatives to the fixed degree sequence model for extracting the backbone of bipartite projections. {it:Scientific Reports} 11: 23929.

{phang}
Neal, Z. P. 2026. backbone: an R package to extract network backbones. {it:PLOS ONE} 21: e0349258.

{phang}
Serrano, M. A., M. Boguna and A. Vespignani. 2009. Extracting the multiscale backbone of complex weighted networks. {it:Proceedings of the National Academy of Sciences} 106: 6483-6488.

{phang}
Strona, G., D. Nappo, F. Boccacci, S. Fattorini and J. San-Miguel-Ayanz. 2014. A fast and unbiased procedure to randomize ecological binary matrices with fixed row and column totals. {it:Nature Communications} 5: 4114.

{phang}
Zweig, K. A. and M. Kaufmann. 2011. A systematic approach to the one-mode projection of bipartite graphs. {it:Social Network Analysis and Mining} 1: 187-218.

{title:Also see}

{psee}
{help nwdichotomize}, {help nwproject}, {help nwrecode}, {help nwkeep}
{p_end}

{hline}
{pstd}{it:nwcommands version 3.37.1, 25 November 2026} ({help nwversion:check your installed version}){p_end}{* nwversion}
