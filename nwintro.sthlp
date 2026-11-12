{smcl}
{* *! version 3.20.0  12nov2026}{...}

{phang}
{help nwcommands:NW-1 intro} {hline 2} Introduction and concepts

{title:Contents}

{col 14}Section{col 31}Description
{col 14}{hline 46}
{help nwintro##intro:{col 14}{bf:[NW-1.1]}{col 31}{bf:Introduction}}
{help nwintro##requirements:{col 14}{bf:[NW-1.2]}{col 31}{bf:Required software}}
{help nwintro##nwconcepts:{col 14}{bf:[NW-1.3]}{col 31}{bf:Network concepts similar to Stata}}
{help nwintro##nwprograms:{col 14}{bf:[NW-1.4]}{col 31}{bf:Network commands similar to Stata}}
{help nwintro##models:{col 14}{bf:[NW-1.5]}{col 31}{bf:Statistical network models}}
{help nwintro##help:{col 14}{bf:[NW-1.6]}{col 31}{bf:Questions, bugs and getting involved}}
{help nwintro##citation:{col 14}{bf:[NW-1.7]}{col 31}{bf:Citation}}
{help nwintro##limits:{col 14}{bf:[NW-1.8]}{col 31}{bf:Network size and speed}}


{marker intro}{...}
{title:Introduction}

{pstd}
nwcommands brings network analysis to Stata. Tutorials, data sets, manuals and news are at

{pmore}
{browse "https://nwcommands.org"}

{pstd}
Network analysis studies the relationships (ties) between units, such as friendship, advice or trust between people,
or alliances between organizations, and the structure that these relationships form together. It is not limited to
social units: any relational data, from genes to words, can be analyzed as a network. Unlike most statistical
approaches, network analysis treats the dependence between units as the object of study.

{pstd}
A network G = (V,E) is a set of nodes {it:V} and a set of ties {it:E} between pairs (dyads) of nodes {it:i} and
{it:j}. It can be stored as an adjacency matrix {it:M} with one row and one column per node: {it:M_ij} = 0 when there
is no tie from {it:i} to {it:j}, and {it:M_ij} = 1 (or, in a valued network, the value of the tie) when there is one.

{pstd}
The core package {help nwcommands} has 134 commands. They {help nwtopical##import:import, export, load and save},
{help nwtopical##generator:generate}, {help nwtopical##manipulation:manipulate}, {help nwtopical##information:describe},
{help nwtopical##analysis:analyze} and {help nwtopical##visualization:plot and animate} networks: centrality, cohesion and
subgroups, communities, positions and roles, paths and flows, homophily and mixing, and tests such as QAP and conditional
uniform graph tests. You can also write your own {help nwprogramming:network commands}.

{pstd}
A minimal example, which loads a real network and computes degree centrality:

	{cmd:. nwwebuse florentine, nwclear}
	{cmd:. nwdegree flomarriage, generate(deg)}
	{cmd:. list _nwnode deg in 1/5}

{pstd}
See {help nwstart} for a full, hands-on walkthrough.

{pstd}
Networks are held by nwcommands, not in the Stata dataset: Stata's {cmd:clear} does not remove them, {help nwclear} does.


{marker requirements}{...}
{title:Required software}

{pstd}
Stata 17 or later. The commands are tested with Stata 17, 18 and 19, on macOS and on Windows. The Mata library is
built with Stata 17, because a library built by a newer Stata is ignored by older versions; Stata 16 and older are not
supported.

{pstd}
The core commands need nothing beyond Stata and the files of this package: no package from SSC, no internet connection
after installation, and nothing is installed into your PLUS directory without your asking. The compiled plugins for
macOS, Windows and Linux are installed with the package.


{marker nwconcepts}{...}
{title:Network concepts similar to Stata}

{pstd}
nwcommands mirrors many concepts of Stata. The most important ones and their Stata counterparts are:

{center:{c TLC}{hline 14}{c TT}{hline 16}{c TT}{hline 31}{c TRC}}
{center:{c |}   Stata      {c |}  nwcommands    {c |}         Description           {c |}}
{center:{c LT}{hline 14}{c +}{hline 16}{c +}{hline 31}{c RT}}
{center:{c |} {help varname}      {c |} {help netname}        {c |} Name of existing network      {c |}}
{center:{c |} {help newvarname}   {c |} {help newnetname}     {c |} Name of new network           {c |}}
{center:{c |} {help varlist}      {c |} {help netlist}        {c |} List of networks              {c |}}
{center:{c |} {help exp}          {c |} {help netexp}         {c |} Network expression            {c |}}
{center:{c |} {help dta_examples} {c |} {help netexample}     {c |} Example network data          {c |}}
{center:{c BLC}{hline 14}{c BT}{hline 16}{c BT}{hline 31}{c BRC}}

{pstd}
For example, many commands accept a {help netname} as an argument or option, just as Stata commands accept a {help varname}.
Network lists can be abbreviated like {help varlist:variable lists}.


{marker nwprograms}{...}
{title:Network commands similar to Stata}

{pstd}
Many commands work like the Stata commands they are named after. The full list of commands is in
{help nwtopical:the topical list}.

{center:{c TLC}{hline 14}{c TT}{hline 16}{c TT}{hline 31}{c TRC}}
{center:{c |}   Stata      {c |}  nwcommands    {c |}         Description           {c |}}
{center:{c LT}{hline 14}{c +}{hline 16}{c +}{hline 31}{c RT}}
{center:{c |} {help clear}        {c |} {help nwclear}        {c |} Clear all network data        {c |}}
{center:{c |} {help drop}         {c |} {help nwdrop}         {c |} Drop networks from memory     {c |}}
{center:{c |} {help keep}         {c |} {help nwkeep}         {c |} Keep networks in memory       {c |}}
{center:{c |} {help use}          {c |} {help nwuse}          {c |} Use network data              {c |}}
{center:{c |} {help webuse}       {c |} {help nwwebuse}       {c |} Use network data from internet{c |}}
{center:{c |} {help save}         {c |} {help nwsave}         {c |} Save network data             {c |}}
{center:{c |} {help generate}     {c |} {help nwgenerate}     {c |} Generate networks             {c |}}
{center:{c |} {help egen}         {c |} {help nwgen}          {c |} Advanced network generation   {c |}}
{center:{c |} {help replace}      {c |} {help nwreplace}      {c |} Replace networks              {c |}}
{center:{c |} {help recode}       {c |} {help nwrecode}       {c |} Recode networks               {c |}}
{center:{c |} {help summarize}    {c |} {help nwsummarize}    {c |} Summarize networks            {c |}}
{center:{c |} {help unab}         {c |} {help nwunab}         {c |} Unabbreviate network lists    {c |}}
{center:{c |} {help ds}           {c |} {help nwds}           {c |} List networks                 {c |}}
{center:{c |} {help tabulate}     {c |} {help nwtabulate}     {c |} Tabulate networks             {c |}}
{center:{c |} {help correlate}    {c |} {help nwcorrelate}    {c |} Correlate networks            {c |}}
{center:{c |} {help expand}       {c |} {help nwexpand}       {c |} Expand variable to network    {c |}}
{center:{c |} {help syntax}       {c |} {help _nwsyntax}      {c |} Parse network syntax          {c |}}
{center:{c BLC}{hline 14}{c BT}{hline 16}{c BT}{hline 31}{c BRC}}


{marker models}{...}
{title:Statistical network models}

{pstd}
The statistical models for networks are separate packages that build on {cmd:nwcommands}: {cmd:nwsaom} (stochastic
actor-oriented models), {cmd:nwergm} (exponential random graph models), {cmd:nwdynam} (dynamic network actor models) and
{cmd:nwrem} (relational event models). Install them with {stata "nwinstall, models":nwinstall, models}; {help nwversion}
shows which are installed. Which package you need is explained at
{browse "https://nwcommands.org/which-package/"}.


{marker help}{...}
{title:Questions, bugs and getting involved}

{pstd}
Ask questions in the GitHub Discussions of the package, and report errors, wrong results and feature requests as GitHub
issues:

{pmore}
{browse "https://github.com/thomas-u-grund/nwcommands/discussions"}{break}
{browse "https://github.com/thomas-u-grund/nwcommands/issues"}

{pstd}
New releases and workshops are announced on the nwcommands mailing list,
{browse "https://groups.google.com/g/nwcommands"}. If you want to contribute to the software, start with the repository,
{browse "https://github.com/thomas-u-grund/nwcommands"}, or write to {browse "mailto:thomas.u.grund@gmail.com":thomas.u.grund@gmail.com}.


{marker citation}{...}
{title:Citation}

{pstd}
Please cite the package and the version you used ({help nwversion} prints it):

{pmore}
Grund, T. U. (2026). {it:nwcommands: Network Analysis in Stata} (version {it:x.y.z}) [Computer software].
{browse "https://github.com/thomas-u-grund/nwcommands"}

{pstd}
How to cite the model packages is explained at {browse "https://nwcommands.org/citing/"}.


{marker limits}{...}
{title:Network size and speed}

{pstd}
How large a network you can use depends on what you do with it. nwcommands stores a network in three ways, each with
its own limits. This section gives measured numbers, so that you know what to expect before you build a large network.

{pstd}
In total, the software supports up to 9999 networks in memory at once, regardless of their individual size.

{pstd}
The web page {browse "https://nwcommands.org/nwcommands/size-limits/":How large a network can I analyze?} lists, command by command, which commands are comfortable, workable or refused at 1,000 to 100,000 nodes.

{marker limits_sparse}{...}
{title:Structural analysis (components, degree, clustering, neighbors, unweighted distances)}

{pstd}
Most of the package's own graph-traversal commands - {help nwcomponents}, {help nwdegree}, {help nwclustering},
{help nwneighbor}, {help nwgeodesic}'s unweighted mode, {help nwevcent} (eigenvector centrality, by sparse power iteration),
{help nwpagerank} (also sparse power iteration), {help nwrandomwalk} (exact hitting time via a sparse linear
solve, not simulation), {help nwmaxflow} and {help nwmatching} (Edmonds-Karp max-flow on a sparse vertex-split
representation), {help nwlambda} (edge connectivity, the same sparse max-flow primitive), and anything built on
them - operate on a genuinely sparse internal representation. They do {bf:not} allocate memory proportional to
the square of the node count, only to the number of actual ties. Measured end to end in Stata/BE (not MP), on a
shared computer, for a random directed network with 10 ties per node: {help nwfromedge} builds 10,000 / 25,000 /
40,000 / 100,000 nodes in 0.3 / 0.8 / 1.2 / 3.7 seconds (with automatic directed/undirected detection, i.e. without
{opt directed}: 0.3 / 0.9 / 1.5 / 8.8 seconds; {opt forceundirected} at 100,000 nodes: 14 seconds). At 100,000 nodes /
1,000,000 ties, {help nwdegree} takes 0.5, {help nwcomponents} 0.5, {help nwneighbor} (one node) 0.4 and
{help nwclustering} 0.7 seconds (at 25,000 nodes: 0.13, 0.12 and 0.13 seconds for the first three). Building the network from an edge
list ({help nwfromedge}, {cmd:nwset, edgelist}, {help nwimport} type(edgelist)) never allocates the dense matrix.
With 5 ties drawn per node (a mean degree of 10 when undirected) and 100,000 nodes, in seconds: {help nwfromedge} 0.51 for a
directed network and 1.07 for an undirected one; {help nwdegree} 0.032 (undirected) and 0.19 (directed); {help nwconstraint}
2.2 (undirected) and 0.70 (directed); {help nwclique} with option {opt nomatrix} 0.26.
{help nwtoedge} with {opt compress}, {help nwsave}, {help nwuse} and {help nwappend} of a single network work at this
size too (100,000 nodes / 1,000,000 ties: {cmd:nwtoedge, compress} 15, {cmd:nwsave} 15 seconds and a 124 MB file,
{cmd:nwuse} 28, {cmd:nwappend} 36 seconds on a busy computer; 25,000 nodes: 2.0, 2.7, 4.4 and 4.0 seconds).
{help nwgeodesic} is {bf:not} in this group at the command level: it returns the full matrix of distances between
all pairs, which is dense (10,000 nodes: 19 seconds; refused above 20,000 nodes).
({help nwfactions} and {help nwmotifs} are combinatorial rather than sparse-traversal in nature - see their own
help files for their own, different scaling characteristics.)

{pstd}
Other general-purpose commands work on the ties as well
(Stata/BE, random directed network with 10 ties per node; 1,000 / 5,000 / 20,000 nodes): {help nwtoedge} with
{opt compress}, {help nwexport} (edge list, Pajek, UCINET, GML), {help nwrecode} and {help nwdichotomize} take
0.1-0.3 / 0.2-0.4 / 0.3-1.4 seconds; {help nwtabulate} of one network 0.01 / 0.01 / 0.03 seconds; {help nwkcomponents}
(undirected, about 20 ties per node) 0.05 / 2 / 31 seconds. Still quadratic by nature: {help nwtoedge} and {help nw2toedge}
without {opt compress} (one row per dyad: 5,000 nodes 20 / 24 seconds, refused above 50,000,000 rows), {help nwplotmatrix}
(one box per dyad: 1,000 nodes 5 seconds, refused above 2,500 nodes) and {cmd:nwplot, layout(kk)} (5,000 nodes 21 seconds
and 2.2 GB).

{marker limits_dense}{...}
{title:Commands that need the full adjacency matrix}

{pstd}
A number of commands, most weighted-distance calculations among them, need the network's complete N-by-N adjacency matrix in memory at once. This matrix
is guarded at 20,000 nodes: attempting to build it above that size raises a clear, immediate error rather than
silently exhausting memory (at 20,000 nodes the matrix alone is already several gigabytes of numbers). In
practice, comfortable, responsive use of these specific commands is closer to a few thousand nodes than to the
20,000-node hard ceiling - memory and running time both grow with the SQUARE of the node count for anything that
touches this matrix directly. Among the commands people reach for with big data, {help nwgeodesic}, {help nwsummarize},
the uncompressed {help nwtoedge} (it lists every dyad), {cmd:nwtoedge} and {cmd:nwsave} of several networks at once,
and {help nw2toedge} are in this group; so are two-mode networks in {cmd:nwtoedge, compress}. ({help nwspectral} needs the full eigenspectrum of the Laplacian, not just a dominant pair, so it has no sparse
equivalent as {help nwevcent} has.)

{pstd}
Measured at 5,000 nodes (Stata/BE, random network with 10 ties per node, one command each): {help nwspectral}, {help nwconcor}
and {help nwhierarchy} work on dense matrices with a running time that grows with the cube (or, for the clustering, about
the 2.4th power) of the number of nodes: 1,000 / 2,000 / 3,000 / 5,000 nodes take 1.5 / 14 / 50 / more than 180 seconds
({cmd:nwspectral}), 4 / 16 / 57 / more than 180 seconds ({cmd:nwconcor}) and 3 / 16 / 45 / 170 seconds ({cmd:nwhierarchy});
{help nwhomophily} 78 seconds and 5.3 GB, {help nwcollapse} 61 seconds, {help nwbalance}, {help nwmatching}, {help nwmixing}, {help nwevcent}, {help nwdissimilar},
{help nwsimilar}, {help nwsimindex} and {help nwlambda} take under 2 seconds at 5,000 nodes. {help nwtostata} needs one Stata
variable per node and is limited by the number of variables of your Stata flavour (2,048 in Stata/BE).

{pstd}
Measured at 10,000 nodes (Stata/BE, random network with 10 ties per node): the cubic commands {help nwspectral},
{help nwconcor} and {help nwhierarchy} (and {help nwdendrogram} of its result) need more than 5 minutes and stop with
r(484) above 6,000 nodes unless the option {opt force} is given; {help nwcorrelate} of the nodes of one network needs about
25 dense matrices and stops with r(484) above 7,000 nodes; {help nwqap} 40 seconds and 11.6 GB; {help nwhomophily},
{help nwcollapse} and the uncompressed {help nwtoedge} stop above 7,071 nodes; the generators draw the ties as a list ({help nwrandom} 0.1 seconds, {help nwcug} with 5 draws 1.5 seconds). Two-mode networks
cost the square of both modes together: 10,000 + 5,000 nodes need 7 GB. {help nwcommunity} 0.24 seconds,
{help nwrandomwalk} 0.15 seconds, {help nwcomponents} 0.04 seconds. Most other commands finish in under 30 seconds
(the slowest: {help nwplot} with the circle layout 39 seconds, {help nwutility} 26 seconds, {help nwkatz} 24 seconds).

{pstd}
Measured at 20,000 nodes (Stata/BE, random directed network with 10 ties per node, 200,000 ties; the sparse cutoff of the
dense matrix). Most commands work on the stored ties and finish in seconds: {help nwcomponents} 0.07, {help nwdegree} 0.08,
{help nwcommunity} 0.6, {help nwcoreperiphery} 0.6, {help nwclique} 1.0, {help nwcloseness} and {help nwkatz} 9.9 and 10 seconds
(one breadth-first search per node in the plugin),
{help nwbetween} 29, {help nwkcomponents} (k = 2) 1.0, {help nwcohesion} 27 seconds. {help nwtranspose}, {help nwpermute}, {help nwaddnodes},
{help nwdropnodes}, {help nwkeepnodes}, {help nwturnover}, {help nwshared}, {help nwsimmelian}, {help nwbridges}, {help nwpath},
{help nwdyads}, {help nwsummarize} and {help nwvalue} do not build an {it:n}-by-{it:n} matrix. The generators {help nwring}, {help nwrandom}, {help nwsmall} and {help nwpref} draw the ties as a list above
2,000 nodes (0.2 to 2.8 seconds at 20,000 nodes), so {help nwcug} with 5 draws takes 2 seconds. Networks whose result is a dense
{it:n}-by-{it:n} network take their memory, which is why the following stop at once with r(484) when it would not fit in 12 GB
({opt force} runs them): {help nwsimilar} (9 matrices, 28.8 GB), {help nwdissimilar}, {help nwsimindex}, {help nwcorrelate} of two
networks, {help nwqap} (48 GB), {help nwutility} and {help nwplot}; still working at 20,000 nodes: {help nwgeodesic} (10 seconds,
6.4 GB), {help nwreach} (11 seconds, 6.4 GB), {help nwlambda} (30 seconds, 6.5 GB), {help nwconstraint}, {help nwexpand}.
Two-mode networks are one matrix over both modes: 20,000 nodes in total (13,333 + 6,667) work in every two-mode command
(1.7 to 12 seconds, 3.4 GB), above 20,000 nodes {help nw2fromedge} refuses at once. Refused by design: {help nwtoedge} and
{help nw2toedge} without {opt compress} (one row per dyad, refused above 50,000,000 rows), {help nwhomophily} and {help nwcollapse}
(the same list of dyads, refused at once), {help nwspectral}, {help nwconcor}, {help nwhierarchy} and {help nwdendrogram} (cubic,
refused above 6,000 nodes), {help nwnclique}, {help nwkplex} and {help nwnclan} (more than 100,000 maximal subgroups),
{help nwplotmatrix} and {help nwtostata}.

{pstd}
Measured at 100,000 nodes (Stata/BE, random directed network with 10 ties per node, 1.0 million ties, 0.6 to 1.5 GB for most
commands). Seconds: {help nwfromedge} 3, {help nwset} 3, {help nwsave} 6, {help nwuse} 14, {help nwdegree} 0.3, {help nwdyads} 0.5,
{help nwsummarize} 0.06, {help nwcomponents} 0.3, {help nwkcore} 0.5, {help nwpagerank} 0.3, {help nwcommunity} 7 (label propagation 15),
{help nwevcent} 0.5, {help nwclustering} 0.7, {help nwshared} 10, {help nwtriads} 1.0, {help nwburt} 0.17,
{help nwsimmelian} 0.75, {help nwconstraint} 10 (undirected; the compiled search takes 0.9 seconds of that, the rest is storing the result as a network), {help nwclique} (the search takes 0.6 seconds; from about 40,000 nodes the time is Stata storing the clique matrix, which grows with the square of the number of columns), {help nwmaxflow} 1.7, {help nwrecode} and
{help nwdichotomize} 2, {help nwdropnodes}, {help nwkeepnodes} and {help nwsubset} 1 to 3, {help nwattime} 2, the generators
{help nwring}, {help nwrandom}, {help nwpref} 1 to 2 and {help nwsmall} 6 (but {help nwrandom} with {opt prob()} 64 seconds).
These commands stop at once with r(484), a message and an alternative ({opt force} runs them anyway): the commands with an
{it:n}-by-{it:n} result or matrix ({help nwgeodesic}, {help nwreach}, {help nwlambda}, {help nwexpand}, {help nwcontext},
{help nwreplace}, {help nwsimilar}, {help nwdissimilar}, {help nwsimindex}, {help nwcorrelate}, {help nwqap}, {help nwutility},
{help nwspectral}, {help nwconcor}, {help nwhierarchy}, {help nwplotmatrix}, {help nwtomata}, {help nwtostata}), and the ones that
would run for more than 2 minutes: {help nwbetween} (about 15 minutes), {help nwcloseness} and {help nwkatz} (5 minutes; measured
302 seconds), {help nwkcomponents} (refused without {opt force} above about 31,000 nodes, although k = 2 takes about a minute at 100,000 nodes) and {help nwcohesion} (about 13 minutes). Two-mode networks are one matrix over
both modes and are refused above 20,000 nodes in total ({help nw2fromedge}).

{marker limits_combinatorial}{...}
{title:Cohesion, factions, motifs, connectivity and exhaustive subgroup searches}

{pstd}
{help nwcohesion}, {help nwfactions}, {help nwlambda}, {help nwmotifs}, {help nwclustering} (on a two-mode network) and {help nwinduced}
with {opt measure(degree)} run in compiled code on the list of ties and do not build N-by-N matrices
(except that {help nwlambda}'s result is itself a dense N-by-N network). Measured in Stata/BE on a random network with
10 ties drawn per node, seconds at 300 / 1,000 / 5,000 nodes: {cmd:nwcohesion} 0.02 / 0.10 / 1.4, {cmd:nwfactions}
0.02 / 0.02 / 0.05, {cmd:nwlambda} 0.02 / 0.09 / 1.9 (1.4 GB at 5,000 nodes), {cmd:nwmotifs} 0.006 / 0.014 / 0.05,
{cmd:nwclustering} on a two-mode network (N and N/2 nodes) 0.09 / 0.24 / 1.4, {cmd:nwinduced, measure(degree)} 0.02 / 0.03 / 0.09.
{cmd:nwinduced} with betweenness,
closeness or eigenvector centrality still recomputes the measure for every node left out and takes minutes at a few
hundred nodes.

{pstd}
{help nwkplex}, {help nwnclique} and {help nwnclan} list {it:all} maximal subgroups, and the number of those, not
the number of nodes, decides what is feasible: a random network with 10 ties per node and 100 nodes already has
46,580,136 maximal 2-cliques of at least 3 nodes (100 nodes, 10,141 maximal 2-plexes; 1,000 nodes, 148,070; 300 nodes,
3,968,148 maximal 3-plexes). The search itself is fast (maximal 2-plexes of 5,000 nodes are counted in 2 seconds; the
n-clans of 5,000 nodes in 2.5 seconds), but the result is a sets-by-nodes matrix. These commands therefore stop with a
clear message (r(484)) when they find more than {opt maxplexes()} / {opt maxcliques()} sets (default 100,000), when
the matrix would be too large, or after {opt maxtime()} seconds (default 60); {opt countonly} counts the sets
without storing them and {opt nomatrix} keeps only the per-node variable and the counts. See the help file of each
command for its measured sizes.

{marker limits_stata}{...}
{title:Loading a network as Stata variables}

{pstd}
{help nwload} (and the {opt xvars} option many {help nwtopical##generator:network generators} accept) represents
a network as ordinary Stata variables, one per node, in a wide adjacency-matrix layout. This is bounded by
Stata's own variable-count ceiling ({bf:c(max_k_theory)} - varies by your Stata flavor: for example, a few
thousand in Small Stata, far more in Stata/IC, BE, or MP), not by anything this package imposes. {cmd:nwload}
itself will not materialize a network above 1000 nodes this way unless {opt force} is specified, since doing so
routinely for large networks is rarely what you want.

{pstd}
Crucially, loading a network as Stata variables is {bf:not} required to analyze it - every {help netname}-based
command works directly against the network's own internal representation, with or without any Stata variables
present. By default, network generators do {bf:not} load their result as Stata variables at all (only {opt xvars}
does this on request) - so building and analyzing a 50,000-node network's own structure never has to touch
Stata's variable budget in the first place, as long as you never ask a command to also load it. {help nwload} is
still there for the cases that genuinely call for it - inspecting individual tie values directly, or feeding a
network's data into ordinary Stata commands.

{pstd}
None of the figures on this page are promises for every possible network shape or every command - a command's
own help file is the authority on anything specific to it. When in doubt for a genuinely large network, try the
structural commands first (they are the ones proven at real scale), and treat the figures for the dense-matrix commands as realistic planning numbers rather than hard guarantees.

{hline}
{pstd}{it:nwcommands version 3.20.0, 12 November 2026} ({help nwversion:check your installed version}){p_end}{* nwversion}
