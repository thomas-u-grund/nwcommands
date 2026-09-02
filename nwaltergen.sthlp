{smcl}
{* *! version 1.0.0  21aug2026 author: Thomas Grund}{...}
{marker topic}
{helpb nw_topical##analysis_paths:[NW-2.6.5] Paths, Reachability & Ego Networks}

{title:Title}

{p2colset 9 21 22 2}{...}
{p2col :nwaltergen {hline 2}}Generate a variable from alter/neighbor attributes{p_end}
{p2colreset}{...}

{title:Syntax}

{p 8 17 2}
{cmd:nwaltergen} {it:newvar} {cmd:=} {it:stat}{cmd:(alter.}{it:srcvar}{cmd:)}
[{cmd:,}
{opth net(netname)}
{opt replace}
{opth hop(int)}]

{p 8 17 2}
{cmd:nwaltergen} {it:newvar} {cmd:= proportion(alter.}{it:srcvar}{cmd:}{it:{help nwaltergen##propop:op}}{it:value}{cmd:)}
[{cmd:,}
{opth net(netname)}
{opt replace}
{opth hop(int)}]

{p 8 17 2}
{it:stat} is one of {bf:mean}, {bf:wmean}, {bf:sum}, {bf:min}, {bf:max}, {bf:sd}, {bf:count},
{bf:diversity}.

{marker propop}{...}
{p 8 17 2}
{it:op} is {bf:==} or {bf:!=}; {it:value} must be numeric.

{synoptset 25 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opth net(netname)}}Network to use; default = the current network{p_end}
{synopt:{opt replace}}Replace existing variable{p_end}
{synopt:{opth hop(int)}}Aggregate over nodes exactly this many (unweighted) steps away, instead of direct neighbors; default = 1{p_end}

{p2colreset}{...}

{title:Description}

{pstd}
{cmd:nwaltergen} generates a new Stata variable that summarizes, for each node ({it:ego}), a
Stata variable's values among its network neighbors ({it:alters}) - e.g. "the average smoking
status among a person's contacts" ({cmd:mean(alter.smoking)}) or "the number of contacts who
already adopted" ({cmd:count(alter.adopted)}). This is the standard "network exposure" /
alter-aggregation primitive used throughout social influence, diffusion, and peer-effects
research (see e.g. Valente 2005 on exposure models).

{pstd}
{it:srcvar} must already exist in the dataset and be indexed the same way as every other
per-node result in {cmd:nwcommands}: observation {it:i} holds the value for node {it:i}.

{pstd}
For directed networks, {it:alter} means {it:out}-neighbors only - the nodes ego has a tie {it:to}
- since exposure/influence is inherently about tie direction, not just structural adjacency (contrast
this with, e.g., {help nwkcore}, where an undirected structural question uses the union of
in- and out-neighbors instead). For undirected networks the distinction does not arise.

{pstd}
Missing values of {it:srcvar} among a node's alters are dropped before the statistic is computed
(so a node with 3 alters, one of whom has a missing {it:srcvar}, is summarized over the 2
non-missing values) - never silently propagated into the result. A node with zero alters (after
dropping missing values, if applicable) returns missing for {bf:mean}/{bf:min}/{bf:max}/{bf:sd}/
{bf:diversity}, and 0 for {bf:sum}/{bf:count}. {bf:sd} additionally requires at least 2 non-missing
alter values (it is undefined for a single value) and returns missing otherwise.

{pstd}
{bf:proportion(alter.}{it:srcvar}{bf:==}{it:value}{bf:)} (or {bf:!=}) gives the proportion of
ego's alters whose {it:srcvar} equals (or does not equal) a specific numeric category - e.g. "the
proportion of a person's contacts who work in sector 3" ({cmd:proportion(alter.sector==3)}). For an
already-binary (0/1) {it:srcvar}, {cmd:mean(alter.}{it:srcvar}{cmd:)} already gives exactly "the
proportion with {it:srcvar}==1", so a bare {cmd:proportion(alter.}{it:srcvar}{cmd:)} with no
comparison is not offered as a separate synonym for it - {bf:proportion()}'s own value is for
picking out one category of a variable with more than two categories, without first having to
{cmd:generate} a 0/1 indicator by hand. Missing {it:srcvar} values are still dropped before the
proportion is computed, exactly as for every other {it:stat} - a missing value is never silently
read as "not in this category".

{pstd}
{bf:diversity(alter.}{it:srcvar}{bf:)} gives Blau's (1977) index of heterogeneity among ego's
alters' {it:srcvar} values - {bf:1 - sum(p_k^2)}, where {it:p_k} is the proportion of alters
falling in category {it:k} of {it:srcvar} (treated as a categorical/discrete-coded variable, e.g.
sector or ethnicity) - the standard "ego-network composition" measure: 0 when every alter shares
the same category (no diversity), approaching 1 as alters spread evenly across many categories.
This is the composition/diversity capability {help nwego}'s own "Supported network types" note
originally left open - unlike ego-network size/density, it needs per-alter attribute {it:values},
not just structural connectivity, so it belongs here alongside {help nwaltergen}'s other alter-
attribute aggregations rather than in {help nwego} itself. Missing {it:srcvar} values are dropped
before computing the index, exactly as for every other {it:stat}; an ego with zero alters (after
dropping missing values) returns missing, not spuriously 0 (mirroring {bf:mean}/{bf:min}/{bf:max}/
{bf:sd}'s own convention, not {bf:sum}/{bf:count}'s - diversity, like a mean, is undefined with no
data to summarize, not naturally zero).

{pstd}
{bf:wmean(alter.}{it:srcvar}{bf:)} is a tie-strength-{it:weighted} exposure mean - {bf:sum(w*x) /
sum(w)} over ego's alters, where {it:w} is the tie weight to each alter and {it:x} is that alter's
{it:srcvar} value - instead of {bf:mean()}'s own plain, equally-weighted average. This is the
standard weighted-exposure/peer-effect formulation used when tie strength itself should matter -
e.g. a strong tie's contact matters more to exposure than a weak one (see e.g. Marsden and Friedkin
1993 on weighted social influence). On a binary (unweighted) network every present tie has weight 1,
so {bf:wmean()} gives exactly the same result as {bf:mean()} - not an approximation, since a tie's
weight is exactly 1 whenever the network itself carries no distinct tie values. An alter with a
missing {it:srcvar} is dropped from both the numerator {it:and} the weight-sum denominator together
(so it does not silently bias the result toward zero), matching every other {it:stat}'s own
missing-value convention. {bf:wmean()} is only supported at the default {opth hop(int):hop(1)}
(direct alters) - which single tie weight should represent a multi-hop path has no single
well-defined answer, so combining it with {opth hop(int)} > 1 is rejected with a clear error rather
than guessed at.

{pstd}
{opth hop(int)} aggregates over nodes exactly that many (unweighted) steps away instead of direct
(one-hop) neighbors - e.g. {cmd:mean(alter.smoking), hop(2)} is "the average smoking status among
the contacts of a person's contacts" (excluding the person's own direct contacts, unless a network
happens to reach them again by a different, exactly-2-step path). This is the standard multi-hop /
lagged exposure question in diffusion research: does influence propagate beyond a node's immediate
neighborhood? A node with no alters at exactly the requested hop distance (including one smaller
than the network's diameter from it, or simply unreachable) is treated the same as a node with no
direct alters: missing for {bf:mean}/{bf:min}/{bf:max}/{bf:sd}, 0 for {bf:sum}/{bf:count}. For a
directed network, distance follows tie direction (out-going steps), matching {it:alter}'s own
one-hop convention above; {opth hop(int)} works with {bf:proportion()} too.

{pstd}
{cmd:nwgen} recognizes the same {cmd:mean(alter.}{it:x}{cmd:)}-style syntax (including
{cmd:proportion(alter.}{it:x}{cmd:==}{it:value}{cmd:)} and {opth hop(int)}) as a shortcut and
dispatches to {cmd:nwaltergen} automatically - {cmd:nwgen exposure = mean(alter.smoking)} and
{cmd:nwaltergen exposure = mean(alter.smoking)} are equivalent.

{title:Supported network types}

{pstd}
Binary: yes. Directed: yes - {it:alter} means out-neighbors only, since exposure/influence follows
tie direction (see above). Weighted: {bf:W2} - {bf:mean}/{bf:sum}/{bf:min}/{bf:max}/{bf:sd}/
{bf:count}/{bf:diversity} use only structural adjacency (tie strength does not enter); {bf:wmean}
(added 2026-09-02, closing a self-flagged gap) uses tie strength directly as the aggregation weight,
an explicit opt-in via a separate {it:stat} name rather than an automatic switch. Signed: not
checked - {bf:wmean()} would divide by a possibly near-zero or sign-cancelling weight sum for a
node with negative-weighted ties, not handled distinctly. Two-mode: no - {it:srcvar} is read per
node under the one-mode {it:_nwnode} indexing convention, with no mode-specific handling.

{title:Examples}

	{cmd:. nwwebuse florentine, nwclear}
	{cmd:. nwaltergen richavg = mean(alter.wealth)}
	{cmd:. nwgen richavg2 = mean(alter.wealth), replace}
	{cmd:. nwaltergen richwexp = wmean(alter.wealth)}
	{cmd:. nwaltergen priorseat = proportion(alter.seat==1)}
	{cmd:. nwaltergen richavg2hop = mean(alter.wealth), hop(2)}
	{cmd:. nwaltergen seatdiv = diversity(alter.seat)}


{title:References}

{pstd}
Valente, T.W. (2005). Network models and methods for studying the diffusion of innovations. In
{it:Models and Methods in Social Network Analysis}, Cambridge University Press.

{pstd}
Marsden, P.V., Friedkin, N.E. (1993). Network studies of social influence. {it:Sociological Methods
& Research} 22(1), 127-151. ({bf:wmean()}'s own tie-strength-weighted exposure formulation)

{pstd}
Blau, P.M. (1977). {it:Inequality and Heterogeneity: A Primitive Theory of Social Structure}. Free
Press. ({bf:diversity()}'s own index of heterogeneity)

{title:See also}

	{help nwgen}, {help nwneighbor}, {help nwdegree}

last certified : 02 Sep 2026
