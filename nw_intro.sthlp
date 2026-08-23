{smcl}
{* *! version  30nov2014}{...}
{phang}
{help nwcommands:NW-1 intro}
{hline 2} Introduction and concepts

{title:Contents}	
			
{col 14}Section{col 31}Description
{col 14}{hline 46}
{help nw_intro##intro:{col 14}{bf:[NW-1.1]}{...}{col 31}{bf:Introduction}}

{help nw_intro##limits:{col 14}{bf:[NW-1.2]}{...}{col 31}{bf:Limitations}}

{help nw_intro##nwconcepts:{col 14}{bf:[NW-1.3]}{...}{col 31}{bf:Network concepts similar to Stata}}

{help nw_intro##nwprograms:{col 14}{bf:[NW-1.4]}{...}{col 31}{bf:Network programs similar to Stata}}

{help nw_intro##general:{col 14}{bf:[NW-1.5]}{...}{col 31}{bf:General information}}

{help nw_intro##feedback:{col 14}{bf:[NW-1.6]}{...}{col 31}{bf:Feedback}}

{help nw_intro##email:{col 14}{bf:[NW-1.7]}{...}{col 31}{bf:Email list}}

{help nw_intro##debelopment:{col 14}{bf:[NW-1.8]}{...}{col 31}{bf:Getting involved}}

{help nw_intro##citation:{col 14}{bf:[NW-1.9]}{...}{col 31}{bf:Citation}}


{marker intro}{...}
{title:Introduction}

{pstd}
This software introduces network analysis to Stata. Updates, tutorials and further information about e.g. workshops can be found at:

{pmore}
{browse "http://nwcommands.org"}

{pstd}
Network analyses investigate the relationships (arcs/edges) between e.g. individuals or organizations, such
as friendship, advice, or trust. It is not limited to social units, but can also be applied to all sorts of 
relational data (e.g. genomes, semantic networks, and so on). 

{pstd}
In contrast to many other statistical approaches, in network analysis one models the interdependencies 
between entities explicitly. Such a perspective allows the visualization and study of structural features
of network structures such as e.g. {help nw_topical##analysis:centrality of network nodes}. 

{pstd}
A network G = (V,E) is a set of nodes {it:V} and relationships {it:E}. Relationships between nodes
are pairs (or dyads) of nodes {it:i} and {it:j}.

{pstd}
A simple way to think (and store) a network is the adjacency matrix. The adjaceny matrix {it:M} of a network has the dimensions {it:nodes x nodes}. The 
matrix cell {it:M_ij} = 0 when there is no tie between nodes {it:i} and {it:j}. In binary networks, {it:M_ij} = 1 when there is
a network relationship between nodes {it:i} and {it:j}. However, networks can also be valued, i.e. {it:M_ij} > 1.  

{pstd}
The {help nwcommands} introduce a software suite of over 50 Stata commands for network analyses in Stata. The
software includes programs for {help nw_topical##import:importing and exporting, loading and saving}, {help nw_topical##manipulation:handling, manipulating and replacing},
{help nw_topical##generator:generating}, {help nw_topical##information:describing}, {help nw_topical##analysis:analyzing} and
{help nw_topical##visualization:visualizing and animating networks}. This includes, for example, commands for measuring the importance of network
nodes, the detection of network patterns and features, the similarity of multiple networks, node attributes,
and the advanced statistical analysis of networks.

{pstd}
Furthermore, one can easily extend the network capabilities of Stata and write
own {help nw_programming:network programs}.


{marker limits}{...}
{title:Limitations and feasible network sizes}

{pstd}
"How large a network can I actually use?" depends on WHAT you are doing with it, not on the network alone - this
package stores a network three different ways internally, each with its own real, tested ceiling. This section
gives concrete numbers so you know what to expect before you build a large network, not after it stalls.

{pstd}
In total, the software supports up to 9999 networks in memory at once, regardless of their individual size.

{marker limits_sparse}{...}
{title:Structural analysis (components, degree, clustering, neighbors, unweighted distances)}

{pstd}
Most of the package's own graph-traversal commands - {help nwcomponents}, {help nwdegree}, {help nwclustering},
{help nwneighbor}, {help nwgeodesic}'s unweighted mode, and anything built on them - operate on a genuinely
sparse internal representation. They do {bf:not} allocate memory proportional to the square of the node count,
only to the number of actual ties, and have been benchmarked directly at 100,000 nodes / 1,000,000 ties (full
connected-components analysis in well under 10 seconds; degree/neighbor lookups near-instant). Networks at this
scale, or considerably beyond it, are practical for these commands specifically. See
{browse "docs/SPARSE_BACKEND.md"} in the package's own repository for the full technical account and benchmark
numbers.

{marker limits_dense}{...}
{title:Commands that need the full adjacency matrix (older algorithms, weighted distances, eigenvector-based centrality)}

{pstd}
A number of commands - most weighted-distance calculations, eigenvector-based centrality
({help nwevcent}), and several older algorithms not yet migrated to the sparse representation - still need the
network's complete N-by-N adjacency matrix in memory at once. This matrix is guarded at 20,000 nodes: attempting
to build it above that size raises a clear, immediate error rather than silently exhausting memory (at 20,000
nodes the matrix alone is already several gigabytes of numbers). In practice, comfortable, responsive use of
these specific commands is closer to a few thousand nodes than to the 20,000-node hard ceiling - memory and
running time both grow with the SQUARE of the node count for anything that touches this matrix directly.

{marker limits_stata}{...}
{title:Loading a network as Stata variables}

{pstd}
{help nwload} (and the {opt xvars} option many {help nw_topical##generator:network generators} accept) represents
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
network's data into ordinary Stata commands - just no longer something every generator does for you
automatically.

{marker limits_ergm}{...}
{title:Statistical network models ({help nwergm})}

{pstd}
{cmd:nwergm}'s own native (C) MCMC backend (see its own "Performance" help section) has been benchmarked directly
against R's {cmd:ergm} package at up to 2,000 nodes, reaching near performance parity (roughly 1.5-1.8x R's own
running time on models mixing several term families) - a large improvement over the pure-Mata fallback, which
remains available for any term the native backend does not yet implement. It has not been benchmarked beyond
2,000 nodes in this project. Its own per-proposal cost scales with each node's degree, not with the total node
count, so sparser networks and dyad-independent/degree-based terms should continue to scale well well beyond
that; models using the geometrically-weighted shared-partner (GWESP) term family carry a proportionally higher
constant cost per proposal and are the main remaining gap versus R on larger, denser networks.

{pstd}
None of the figures on this page are promises for every possible network shape or every command - a command's
own help file is the authority on anything specific to it. When in doubt for a genuinely large network, try the
structural commands first (they are the ones proven at real scale), and treat the dense-matrix-dependent and
{cmd:nwergm} figures above as realistic planning numbers rather than hard guarantees.


{marker nwconcepts}{...}
{title:Network concepts similar to Stata}

{pstd}
The software is written in such a way that it mirrors many concepts form traditional Stata. The most import concepts and its Stata counterparts are:

{center:{c TLC}{hline 14}{c TT}{hline 16}{c TT}{hline 31}{c TRC}}
{center:{c |}   Stata      {c |}  nwcommand     {c |}         Description           {c |}}
{center:{c LT}{hline 14}{c +}{hline 16}{c +}{hline 31}{c RT}}
{center:{c |} {help varname}      {c |} {help netname}        {c |} Name of existing network      {c |}}
{center:{c |} {help newvarname}   {c |} {help newnetname}     {c |} Name of new network           {c |}}
{center:{c |} {help varlist}      {c |} {help netlist}        {c |} List of networks              {c |}}
{center:{c |} {help exp}          {c |} {help netexp}         {c |} Network expression            {c |}}
{center:{c |} {help dta_examples} {c |} {help netexample}     {c |} Example network data          {c |}}
{center:{c BLC}{hline 14}{c BT}{hline 16}{c BT}{hline 31}{c BRC}}

{pstd}
For example, many nwcommands accept some {help netname} as an argument or option. This is very much the same as normal Stata programs
accepting a {help varname} in a similar fashion. One can even abbreviate {help netlist:network lists}, just as when one abbreviates 
{help varlist:variable lists}.  


{marker nwprograms}{...}
{title:Network programs similar to Stata}

{pstd}
Furthermore, there are many nwcommands that are very similar to traditional Stata commands. 
The intution and usage of these network extensions is very similar to what one is used to from Stata. A full list of programs can be found 
{help nw_topical:here}. These are programs with a lot of similarities to Stata commands.

{center:{c TLC}{hline 14}{c TT}{hline 16}{c TT}{hline 31}{c TRC}}
{center:{c |}   Stata      {c |}  nwcommand     {c |}         Description           {c |}}
{center:{c LT}{hline 14}{c +}{hline 16}{c +}{hline 31}{c RT}}
{center:{c |} {help clear}        {c |} {help nwclear}        {c |} Clear all network data        {c |}}
{center:{c |} {help drop}         {c |} {help nwdrop}         {c |} Drop networks from memory     {c |}}
{center:{c |} {help keep}         {c |} {help nwkeep}         {c |} Keep networks in memory       {c |}}
{center:{c |} {help use}          {c |} {help nwuse}          {c |} Use network data              {c |}}
{center:{c |} {help webuse}       {c |} {help nwwebuse}       {c |} Use network data from internet{c |}}
{center:{c |} {help save}         {c |} {help nwsave}         {c |} Save network data             {c |}}
{center:{c |} {help generate}     {c |} {help nwgenerate}     {c |} Generate networs              {c |}}
{center:{c |} {help egen}         {c |} {help nwgen}          {c |} Advanced network generation   {c |}}
{center:{c |} {help replace}      {c |} {help nwreplace}      {c |} Replace networks              {c |}}
{center:{c |} {help recode}       {c |} {help nwrecode}       {c |} Recode networs                {c |}}
{center:{c |} {help summarize}    {c |} {help nwsummarize}    {c |} Summarize networks            {c |}}
{center:{c |} {help unab}         {c |} {help nwunab}         {c |} Unabreviate network lists     {c |}}
{center:{c |} {help ds}           {c |} {help nwds}           {c |} Describe networks             {c |}}
{center:{c |} {help tabulate}     {c |} {help nwtabulate}     {c |} Tabulate networks             {c |}}
{center:{c |} {help correlate}    {c |} {help nwcorrelate}    {c |} Correlate networks            {c |}}
{center:{c |} {help expand}       {c |} {help nwexpand}       {c |} Exand variable to network     {c |}}
{center:{c |} {help syntax}       {c |} {help nw_syntax}      {c |} Parse network syntax          {c |}}
{center:{c BLC}{hline 14}{c BT}{hline 16}{c BT}{hline 31}{c BRC}}


{marker feedback}{...}
{title:Feedback}

{pstd}
If you find any bugs in the software, please contact the developers by sending an
email to {browse "mailto:thomas.grund@gmail.com"}


{marker email}{...}
{title:Email list}

{pstd}
You can also subscribe to the nwcommands-email list under:

{pmore}
{browse "http://groups.google.com/forum/#!forum/nwcommands/join"}

{pstd}
Once you are signed up you will receive information about updates, new releases and so on. You can also ask question over this email list. 


{marker development}{...}
{title:Getting involved}

{pstd}
If you want to get involved in the development of this software visit: 

{pmore}
{browse "http://github.com/ThomasGrund/nwcommands"}

{pstd}
You can also send an email directly to {browse "mailto:thomas.u.grund@gmail.com"}


{marker citation}{...}
{title:Citation}

{pstd}
Please cite the software as: 

{pmore}
{bf:Thomas U. Grund (2014). nwcommands: Software Tools for the Statistical Modeling of Network Data in Stata. URL http://nwcommands.org}
