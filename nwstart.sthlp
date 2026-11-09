{smcl}
{* *! version 3.17.6  09nov2026}{...}

{phang}
{help nwcommands:NW-4 start} {hline 2} Getting started

{title:Contents}

{col 14}Section{col 31}Description
{col 14}{hline 46}
{help nwstart##first:{col 14}{bf:[NW-4.1]}{col 31}{bf:A first session}}
{help nwstart##ideas:{col 14}{bf:[NW-4.2]}{col 31}{bf:Three ideas to know}}
{help nwstart##data:{col 14}{bf:[NW-4.3]}{col 31}{bf:Getting your own data in}}
{help nwstart##tutorials:{col 14}{bf:[NW-4.4]}{col 31}{bf:Tutorials}}
{help nwstart##more:{col 14}{bf:[NW-4.5]}{col 31}{bf:Where to look next}}


{marker first}{...}
{title:A first session}

{pstd}
Load the marriage and business ties between 16 Florentine families, look at what is in memory, and describe,
plot and analyze the marriage network. Click a command to run it.

{p 8 8 2}{stata "nwwebuse florentine, nwclear":. nwwebuse florentine, nwclear}{p_end}
{p 8 8 2}{stata "nwds":. nwds}{p_end}
{p 8 8 2}{stata "nwsummarize flomarriage":. nwsummarize flomarriage}{p_end}
{p 8 8 2}{stata "nwplot flomarriage, lab":. nwplot flomarriage, lab}{p_end}
{p 8 8 2}{stata "nwdegree flomarriage, generate(deg)":. nwdegree flomarriage, generate(deg)}{p_end}
{p 8 8 2}{stata "nwbetween flomarriage, generate(btw)":. nwbetween flomarriage, generate(btw)}{p_end}
{p 8 8 2}{stata "list _nwnode deg btw in 1/5":. list _nwnode deg btw in 1/5}{p_end}

{pstd}
{cmd:nwwebuse} loads two networks, {it:flomarriage} and {it:flobusiness}. {cmd:nwdegree} and {cmd:nwbetween} store one
value per node in ordinary Stata variables, which you can list, summarize or use in a regression.


{marker ideas}{...}
{title:Three ideas to know}

{phang}
1. {bf:Networks have names.} You refer to a network by its {help netname}, just as you refer to a variable by its
{help varname}. Network lists can be abbreviated like variable lists: {cmd:nwsummarize flo*}.

{phang}
2. {bf:Networks are not variables.} nwcommands keeps networks next to the dataset. Stata's {cmd:clear} does not remove
them; {help nwclear} does. Results for nodes ({cmd:generate()}) are ordinary variables, one observation per node.

{phang}
3. {bf:There is a current network.} A command without a network name uses the current network, normally the one
loaded or created last; {help nwcurrent} shows and changes it.

{pstd}
More of these parallels with Stata are in {help nwintro##nwconcepts:[NW-1.3]} and {help nwintro##nwprograms:[NW-1.4]}.


{marker data}{...}
{title:Getting your own data in}

{p2colset 8 26 28 2}{...}
{p2col:{help nwfromedge}}from an edge list (one row per tie) in the dataset{p_end}
{p2col:{help nwset}}from an adjacency matrix stored as variables, or from an edge list{p_end}
{p2col:{help nwimport}}from a Pajek, UCINET, GML or edge list file{p_end}
{p2col:{help nwuse}}from a network file saved with {help nwsave}{p_end}
{p2col:{help nwwebuse}}the example data sets ({help netexample}){p_end}
{p2colreset}{...}

{pstd}
Node attributes are ordinary variables in the same dataset, one observation per node. The tutorial
{browse "https://nwcommands.org/tutorials/04-reproducible-workflow/":A reproducible workflow} shows a complete do-file,
from CSV files of ties and people to saved results.


{marker tutorials}{...}
{title:Tutorials}

{pstd}
Nineteen worked tutorials, each with real Stata output, are at {browse "https://nwcommands.org/tutorials/"}. They build
on each other, but each one also stands alone.

{p2colset 8 12 14 2}{...}
{p2col:{bf:Getting started}}{p_end}
{p2col: 1}{browse "https://nwcommands.org/tutorials/01-installation-setup/":Installation and setup}{p_end}
{p2col: 2}{browse "https://nwcommands.org/tutorials/02-core-concepts/":Core concepts}{p_end}
{p2col: 3}{browse "https://nwcommands.org/tutorials/03-importing-exporting/":Importing and exporting}{p_end}
{p2col: 4}{browse "https://nwcommands.org/tutorials/04-reproducible-workflow/":A reproducible workflow}{p_end}
{p2col:{bf:Working with networks}}{p_end}
{p2col: 5}{browse "https://nwcommands.org/tutorials/05-visualization/":Visualization}{p_end}
{p2col: 6}{browse "https://nwcommands.org/tutorials/06-generating-networks/":Generating networks}{p_end}
{p2col: 7}{browse "https://nwcommands.org/tutorials/07-manipulating-networks/":Manipulating networks}{p_end}
{p2col:{bf:Describing networks}}{p_end}
{p2col: 8}{browse "https://nwcommands.org/tutorials/08-centrality/":Centrality}{p_end}
{p2col: 9}{browse "https://nwcommands.org/tutorials/09-paths-ego-networks/":Paths and ego networks}{p_end}
{p2col:10}{browse "https://nwcommands.org/tutorials/10-cohesion-subgroups/":Cohesion and subgroups}{p_end}
{p2col:11}{browse "https://nwcommands.org/tutorials/11-brokerage/":Brokerage and structural holes}{p_end}
{p2col:12}{browse "https://nwcommands.org/tutorials/12-triads-motifs/":Triads, dyads and motifs}{p_end}
{p2col:13}{browse "https://nwcommands.org/tutorials/13-positions-equivalence/":Positions and equivalence}{p_end}
{p2col:14}{browse "https://nwcommands.org/tutorials/14-homophily-mixing/":Homophily, assortativity and mixing}{p_end}
{p2col:{bf:Other kinds of networks}}{p_end}
{p2col:15}{browse "https://nwcommands.org/tutorials/15-two-mode-networks/":Two-mode networks}{p_end}
{p2col:16}{browse "https://nwcommands.org/tutorials/16-valued-networks/":Valued networks}{p_end}
{p2col:17}{browse "https://nwcommands.org/tutorials/17-networks-over-time/":Networks over time}{p_end}
{p2col:{bf:Testing and models}}{p_end}
{p2col:18}{browse "https://nwcommands.org/tutorials/18-testing/":Testing hypotheses about networks}{p_end}
{p2col:19}{browse "https://nwcommands.org/tutorials/19-intro-longitudinal-models/":Longitudinal models: an overview}{p_end}
{p2colreset}{...}

{pstd}
The statistical model packages have their own tutorials: {browse "https://nwcommands.org/nwsaom/":nwsaom},
{browse "https://nwcommands.org/nwergm/":nwergm}, {browse "https://nwcommands.org/nwdynam/":nwdynam} and
{browse "https://nwcommands.org/nwrem/":nwrem}.


{marker more}{...}
{title:Where to look next}

{p2colset 8 30 32 2}{...}
{p2col:{help nwtopical}}all commands, by topic{p_end}
{p2col:{help nwalphabetical}}all commands, alphabetically{p_end}
{p2col:{help nwintro}}introduction, requirements, network size and speed{p_end}
{p2col:{help nwnetworktypes}}what each command does with directed, valued, signed and two-mode networks{p_end}
{p2col:{help nwprogramming}}writing your own network commands{p_end}
{p2col:{browse "https://nwcommands.org/help/":Getting help}}questions, bug reports and the mailing list{p_end}
{p2colreset}{...}

{pstd}
Most commands also have a dialog box: after {cmd:nwinstall, all}, the {bf:Network Analysis} menu appears under
{bf:User}.

{hline}
{pstd}{it:nwcommands version 3.17.6, 9 November 2026} ({help nwversion:check your installed version}){p_end}{* nwversion}
