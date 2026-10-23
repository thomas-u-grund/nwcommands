{smcl}
{* *! version 1.0.0  author: Thomas Grund}{...}
{title:Title}

{p2colset 9 32 33 2}{...}
{p2col :nwergm covariate terms {hline 2}}Node and dyadic covariate terms of {helpb nwergm}, with R ergm's argument conventions{p_end}
{p2colreset}{...}

{title:Syntax}

{p 8 17 2}
{cmd:nwergm} [{it:netname}]{cmd:,} {opt edges} {it:term}{cmd:(}{it:varlist} [{cmd:,} {it:suboptions}]{cmd:)} ...

{pstd}
Every attribute term below takes one or more numeric node variables (the variable is read by node position) or a Stata expression such as {cmd:nodecov(ln(x))}, followed by an optional comma and the suboptions of that term.
The suboptions apply to every variable listed in the same option.
Attribute variables must not contain missing values, as in R ergm ({it:In term nodecov: attribute has missing data, which is not currently supported}).
String variables must be encoded first.

{title:Level selection (R's levels=, base=)}

{pstd}
{opt levels(numlist)} selects levels by position in the sorted list of distinct values, exactly like a numeric {cmd:levels=} argument in R: positive numbers keep those positions, negative numbers drop them ({cmd:levels(-1)} drops the first level).
{opt levelvalues(numlist)} gives the level values themselves, in the order wanted (R's {cmd:levels=I(c(...))}).
{opt base(numlist)} is R's deprecated {cmd:base=}: positions to drop when {opt levels()} is not given.
For {opt nodefactor()}, {opt nodeofactor()} and {opt nodeifactor()} the default is {cmd:base(1)} (the first level is dropped); {cmd:base(0)} keeps all levels.

{synoptset 34 tabbed}{...}
{synopthdr:term}
{synoptline}
{synopt:{opt nodefactor(vars [, levels() levelvalues() base()])}}counts of edge endpoints per level{p_end}
{synopt:{opt nodeofactor()}, {opt nodeifactor()}}directed versions (out-ties, in-ties){p_end}
{synopt:{opt nodematch(vars [, diff keep() levels() levelvalues()])}}homophily; {opt diff} gives one coefficient per level, {opt keep()} selects level positions; levels outside the selection never match{p_end}
{synopt:{opt nodematchdiff(vars)}}same as {cmd:nodematch(vars, diff)}{p_end}
{synopt:{opt nodemix(vars [, levels() levelvalues() levels2() base()])}}mixing matrix cells.
Directed networks: all ordered (tail level, head level) cells; undirected: cells with row level before column level.
By default the first cell is dropped ({cmd:levels2(-1)}); {opt levels2()} selects cells by position (column by column) and {opt base()} is the deprecated alternative{p_end}
{synopt:{opt mm(vars [, levels() levels2()])}}mixing matrix with a single attribute (the same cells as {opt nodemix()}){p_end}
{synopt:{opt absdist(vars [, pow(#)])}}sum over ties of |x_i - x_j|^pow (R's {cmd:absdiff}){p_end}
{synopt:{opt absdiffcat(vars [, levels() levelvalues() base()])}}one count per distinct nonzero absolute difference{p_end}
{synopt:{opt diff(vars [, pow() dir() signaction()])}}sum of (x_tail - x_head)^pow; {opt dir()} is t-h (default), h-t, tail-head, head-tail, b1-b2, b2-b1; {opt signaction()} is identity, abs, posonly or negonly{p_end}
{synopt:{opt smalldiff(vars, cutoff(#))}}ties with |x_i - x_j| <= cutoff{p_end}
{synopt:{opt nodecov()}, {opt nodeicov()}, {opt nodeocov()}}node covariate main effects; expressions allowed{p_end}
{synopt:{opt nodecovrange()}, {opt nodeocovrange()}, {opt nodeicovrange()}}sum over nodes of the range of the covariate among neighbours (out-/in-neighbours); dyad-dependent{p_end}
{synopt:{opt nodefactordistinct(vars [, levels() levelvalues()])}}sum over nodes of the number of distinct neighbour levels; {opt nodeofactordistinct()} and {opt nodeifactordistinct()} for directed networks; dyad-dependent{p_end}
{synopt:{opt sociality(vars [, nodes() levels()])}}degree of each node (undirected). Use {cmd:sociality(.)} for no attribute; with an attribute only ties between nodes with equal attribute value count.
{opt nodes(numlist)} selects node positions, default {cmd:nodes(-1)} (first node dropped){p_end}
{synopt:{opt attrcov(vars, mat(matname))}}edge covariate x(i,j) = mat(level of i, level of j) with a Stata matrix with one row and column per distinct level{p_end}
{synopt:{opt edgecov(netname|matname)}}edge covariate from a network or an n x n Stata matrix (undirected: upper triangle){p_end}
{synopt:{opt dyadcov(netname|matname)}}directed networks: three coefficients (mutual, utri, ltri); undirected: same as {opt edgecov()}.
An asymmetric directed covariate uses its upper triangle, as in R{p_end}
{synoptline}

{title:Other options}

{phang}
{opt coeflabel(old new [old new ...])} renames coefficients (R's {cmd:Label()} operator).

{title:Differences from R}

{pstd}
Character-valued {cmd:levels2} (grouping of cells), the {cmd:form=} argument for valued networks, and the formula-valued {cmd:levels} arguments are not available.
{cmd:mm()} supports one attribute only (no margins).
The curved (free-decay) pseudolikelihood fit follows R's trust-region algorithm, so on weakly identified data it ends at the same boundary solution as R; a decay value given in {opt gwespfree()} etc. is only the starting value for MCMLE.

{title:Also see}

{psee}
{helpb nwergm}, {helpb nwergm_estat}
