{smcl}
{* *! version 3.37.1  25nov2026}{...}

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
The core package {help nwcommands} has 138 commands. They {help nwtopical##import:import, export, load and save},
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
Stata 17 or later. The commands are tested on macOS with Stata 17, 18 and 19 and on Windows with Stata 19. The Mata library is
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
{center:{c |} {help syntax}       {c |} {help nwprogramming##syntax:_nwsyntax}      {c |} Parse network syntax          {c |}}
{center:{c BLC}{hline 14}{c BT}{hline 16}{c BT}{hline 31}{c BRC}}


{marker models}{...}
{title:Statistical network models}

{pstd}
The statistical models for networks are separate packages that build on {cmd:nwcommands}: {cmd:nwsaom} (stochastic
actor-oriented models), {cmd:nwergm} (exponential random graph models), {cmd:nwdynam} (dynamic network actor models),
{cmd:nwrem} (relational event models), {cmd:nwalaam} (autologistic actor attribute models), {cmd:nwlsm} (latent space models) and {cmd:nwsbm} (stochastic block models). Install them with {stata "nwinstall, models":nwinstall, models}; {help nwversion}
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
How large a network you can use depends on what you do with it. Commands that work on the stored ties need memory in
proportion to the number of ties; commands whose work or result is an {it:n}-by-{it:n} matrix need memory in proportion
to the square of the number of nodes. Up to 9999 networks can be in memory at once.

{pstd}
The web page {browse "https://nwcommands.org/nwcommands/size-limits/":How large a network can I analyze?} lists, command by
command, which commands are comfortable, workable or refused at 1,000 to 100,000 nodes. The help file of each command
states its own limits.

{marker limits_sparse}{...}
{title:Commands that work on the ties}

{pstd}
Among others, {help nwfromedge}, {cmd:nwset, edgelist}, {help nwimport} type(edgelist), {help nwdegree},
{help nwcomponents}, {help nwclustering}, {help nwneighbor}, {help nwevcent}, {help nwpagerank}, {help nwrandomwalk},
{help nwmaxflow}, {help nwmatching}, {help nwtriads}, {help nwburt}, {help nwsimmelian}, and {help nwtoedge} with
{opt compress} do not build an {it:n}-by-{it:n} matrix.

{marker limits_dense}{...}
{title:Commands that need the full adjacency matrix}

{pstd}
The matrix is not built above 20,000 nodes; in practice these commands are comfortable at a few thousand nodes. At
100,000 nodes, commands with an {it:n}-by-{it:n} result or matrix ({help nwgeodesic}, {help nwreach}, {help nwlambda},
{help nwexpand}, {help nwcontext}, {help nwsimilar}, {help nwdissimilar}, {help nwsimindex}, {help nwcorrelate},
{help nwqap}, {help nwutility}, {help nwspectral}, {help nwconcor}, {help nwhierarchy}, {help nwplotmatrix},
{help nwtomata}, {help nwtostata}) stop with r(484), a message and an alternative.

{pstd}
Further limits:

{p 8 12 2}o {help nwspectral}, {help nwconcor}, {help nwhierarchy} and {help nwdendrogram}: running time grows steeply
with the number of nodes; refused above 6,000 nodes unless {opt force} is given.{p_end}
{p 8 12 2}o {help nwcorrelate} of the nodes of one network: refused above 7,000 nodes.{p_end}
{p 8 12 2}o {help nwhomophily}, {help nwcollapse}, and {help nwtoedge} and {help nw2toedge} without {opt compress} (one
row per dyad): refused above 50,000,000 dyads (7,071 nodes for a directed network).{p_end}
{p 8 12 2}o {help nwplotmatrix}: refused above 2,500 nodes.{p_end}
{p 8 12 2}o {help nwbetween}, {help nwcloseness}, {help nwkatz}, {help nwkcomponents} and {help nwcohesion} stop with
r(484) on very large networks when the run would be long; their help files give the rules.{p_end}
{p 8 12 2}o Commands that would need more than 12 GB for a dense result stop with r(484).{p_end}
{p 8 12 2}o Two-mode networks are one matrix over both modes and are refused above 20,000 nodes in total.{p_end}

{pstd}
Where a command offers the option {opt force}, it runs in spite of such a guard. {help nwtostata} needs one Stata
variable per node and is limited by the number of variables of your Stata flavor.

{marker limits_combinatorial}{...}
{title:Cohesion, factions, motifs, connectivity and exhaustive subgroup searches}

{pstd}
{help nwcohesion}, {help nwfactions}, {help nwlambda}, {help nwmotifs}, {help nwclustering} (on a two-mode network) and
{help nwinduced} with {opt measure(degree)} run in compiled code on the list of ties (the result of {help nwlambda} is
itself a dense {it:n}-by-{it:n} network). {cmd:nwinduced} with betweenness, closeness or eigenvector centrality
recomputes the measure for every node left out and is slow already at a few hundred nodes.

{pstd}
{help nwkplex}, {help nwnclique} and {help nwnclan} list {it:all} maximal subgroups, and the number of those, not the
number of nodes, decides what is feasible: it can reach millions in a network of 100 nodes. These commands stop with a
message (r(484)) when they find more than {opt maxplexes()} / {opt maxcliques()} sets (default 100,000), when the matrix
would be too large, or after {opt maxtime()} seconds (default 60); {opt countonly} counts the sets without storing them
and {opt nomatrix} keeps only the per-node variable and the counts.

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
These limits do not cover every shape of network; the help file of a command is the authority on it.

{hline}
{pstd}{it:nwcommands version 3.37.1, 25 November 2026} ({help nwversion:check your installed version}){p_end}{* nwversion}
