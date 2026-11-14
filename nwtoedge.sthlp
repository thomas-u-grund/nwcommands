{smcl}
{* *! 12jul2016 author: Thomas Grund}{...}
{marker topic}
{helpb nwtopical##import:[NW-2.2] Import/Export}

{title:Title}

{p2colset 9 18 22 2}{...}
{p2col :nwtoedge {hline 2}}Convert a network to an edge list{p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 17 2}
{cmdab: nwtoedge} 
[{it:{help netlist}}]
[{cmd:,}
{opth egovars(varlist)}
{opth altervars(varlist)}
{opth ego(newvarname)}
{opth alter(newvarname)}
{opth comparevars(varlist)}
{opt comparemode}({it:{help nwexpand##expand_mode:mode}})
{opt compress}
{opt full}
{opt upper}
{opt numeric}
{opt ignore2mode}
{opt all:pairs}
{opt time}
{opt agg:regate}]

{synoptset 22 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opth egovars(varlist)}}Keep attributes of sending nodes{p_end}
{synopt:{opth altervars(varlist)}}Keep attributes of receiving nodes {p_end}
{synopt:{opth ego(newvarname)}}Sender of ties; default = {it:_ego}{p_end}
{synopt:{opth alter(newvarname)}}Receiver of ties; default = {it:_alter}{p_end}
{synopt:{opth comparevars(varlist)}}Add an ego/alter comparison column for each variable (e.g. {it:same}, {it:dist}){p_end}
{synopt:{opt comparemode}({it:{help nwexpand##expand_mode:mode}})}Comparison used for {opt comparevars()}; default = {it:same}{p_end}
{synopt:{opt compress}}Compress edgelist{p_end}
{synopt:{opt full}}List both {it:(i,j)} and {it:(j,i)} for an undirected network's dyads, rather than only one entry per dyad; forced automatically whenever any network in a {help netlist} is
directed{p_end}
{synopt:{opt upper}}List only one entry per undirected dyad (the default; see {opt full} above) - has no effect and is suppressed with a warning on a directed network{p_end}
{synopt:{opt numeric}}Programming option: replace the node names in {it:ego} and {it:alter} with the node numbers of a full node x node grid
(for the list of all dyads); only allowed with a single network{p_end}
{synopt:{opt ignore2mode}}Treat a two-mode network like a one-mode one - suppress the mode indicator that would otherwise be added to {opt egovars()}/{opt altervars()} automatically{p_end}
{synopt:{opt isolates0}}reserved; not currently implemented{p_end}
{synopt:{opt all:pairs}}Two-mode network: also write the pairs of nodes of different modes without a tie (by default a two-mode network is written as its ties, as with {opt compress}){p_end}
{synopt:{opt time}}Temporal network: list one row per event, per observation of a tie or per interval, with the time(s) (see {help nwtoedge##temporal:Temporal networks}){p_end}
{synopt:{opt agg:regate}}Temporal network: list each tie once, aggregated over all times, without the note{p_end}

{p2colreset}{...}


{title:Description}

{pstd}
{cmd:nwtoedge} makes an edgelist from a network or a list of networks. 

{pstd}
An edgelist of a single network {help netname} produced by {cmd:nwtoedge} is a set of three variables representing
the relations in the network. The first variable ({it:_ego}) gives the {help nodeid}
of the sending node {it:i} of a relationship; the second variable ({it:_alter}) gives the {help nodeid} of the 
receiving node {it:j}. Lastly, the variable {it:netname} saves information about the 
dyad pair ({it:i},{it:j}) in the network {it:netname}. 

{pstd}
When a network is undirected only one entry for the dyad pair ({it:i},{it:j})
is generated, unless option {opt full} is specified. For an undirected valued network the listed pairs are those with {it:_ego} > {it:_alter}, so each tie appears once, in the row of the higher node
id. 

{pstd}
When the command is used with a {help netlist}, it generates one new variable for each network {it:netname} in the list. If only one
of the networks in {help netlist} is directed, the option {opt full} is enforced.

{pstd}
One can also include node attributes (saved as normal Stata variables) in the edgelist. Option {opt egovars()} 
generates new variables that match the attributes of the sender of a tie (ego); option {opt altervars()} 
generates new variables that match the attributes of the receiver of a tie (alter).

{pstd}
For example, 

	{cmd:. nwwebuse glasgow1}
	{com}. nwtoedge glasgow1, egovars(sport1)
	{com}. list
{txt}
      {c TLC}{hline 9}{c -}{hline 7}{c -}{hline 10}{c -}{hline 13}{c TRC}
      {c |} {res}_ego    _alter    glasgow1   from_sport1 {txt}{c |}
      {c LT}{hline 9}{c -}{hline 7}{c -}{hline 10}{c -}{hline 13}{c RT}
   1. {c |} {res}      1       1          0       regular {txt}{c |}
   2. {c |} {res}      1       2          0       regular {txt}{c |}
   3. {c |} {res}      1       3          0       regular {txt}{c |}
   4. {c |} {res}      1       4          0       regular {txt}{c |}
   5. {c |} {res}      1       5          0       regular {txt}{c |}
      {c LT}{hline 9}{c -}{hline 7}{c -}{hline 10}{c -}{hline 13}{c RT}
   6. {c |} {res}      1       6          0       regular {txt}{c |}
		.....
      {c LT}{hline 9}{c -}{hline 7}{c -}{hline 10}{c -}{hline 13}{c RT}
  11. {c |} {res}      1      11          1       regular {txt}{c |}
  12. {c |} {res}      1      12          0       regular {txt}{c |}
  13. {c |} {res}      1      13          0       regular {txt}{c |}
  14. {c |} {res}      1      14          1       regular {txt}{c |}
  15. {c |} {res}      1      15          0       regular {txt}{c |}
      {c LT}{hline 9}{c -}{hline 7}{c -}{hline 10}{c -}{hline 13}{c RT}
		.....	  
	  
{pstd}
loads the {help netexample:Glasgow data} and transforms the network {it:glasgow1} in an edgelist. For example, {it:glasgow1[11] = 1} means,
that there is a network tie from node 1 to node 11. It also generates a new variable {it:from_sport1},
which holds in this case information about the attribute of the sender of a tie on the original variable {it:sport1}.				 

{pstd}
For two-mode networks see {help nw2set:introduction to two-mode networks}) and {help nw2toedge}.

{marker temporal}{...}
{pstd}
{bf:Temporal networks.} A network declared with {cmd:time()}, {cmd:interval()} or {cmd:eventtime()} in {help nwset} holds times that the list of ties above
does not have: that list holds each tie once, aggregated over all times (for an event network every pair with at least one event), and the command says so
in a note. {opt aggregate} states the aggregation and leaves the note out. With {opt time} the data in memory are replaced by one row for every event of an event network (in
the order given), every observation of a tie of a snapshot network, or every interval of an interval network, for a single one-mode network: the variables {it:_ego}
and {it:_alter} (or the names in {opt ego()} and {opt alter()}), {it:_time} (event and snapshot networks) or {it:_start} and {it:_end} (interval networks), and {it:_value} for a valued event network. An undirected snapshot or
interval network lists each tie once. {help nwset} with {cmd:eventtime()}, {cmd:time()} or {cmd:interval()} turns the rows into the network again. {opt time}
cannot be combined with {opt aggregate} or with the options of the list of ties above (except {opt ego()} and {opt alter()}); error 198.{p_end}

	{cmd:. nwtoedge calls, time}
	{cmd:. nwset _ego _alter, eventtime(_time) name(calls2) directed}

{pstd}
The command can also transform two (or more) networks in edgelists at the same time. 

	{cmd:. nwtoedge glasgow1 glasgow2}
	
{pstd}
This generates a dataset with one variable for each network, {it:glasgow1} and {it:glasgow2}:

	{com}. list
{txt}
      {c TLC}{hline 9}{c -}{hline 7}{c -}{hline 10}{c -}{hline 10}{c TRC}
      {c |} {res}_ego    _alter    glasgow1   glasgow2 {txt}{c |}
      {c LT}{hline 9}{c -}{hline 7}{c -}{hline 10}{c -}{hline 10}{c RT}
   1. {c |} {res}      1       1          0          0 {txt}{c |}
   2. {c |} {res}      1       2          0          0 {txt}{c |}
   3. {c |} {res}      1       3          0          0 {txt}{c |}
   4. {c |} {res}      1       4          0          0 {txt}{c |}
   5. {c |} {res}      1       5          0          0 {txt}{c |}
      {c LT}{hline 9}{c -}{hline 7}{c -}{hline 10}{c -}{hline 10}{c RT}
   6. {c |} {res}      1       6          0          0 {txt}{c |}
   7. {c |} {res}      1       7          0          0 {txt}{c |}
   8. {c |} {res}      1       8          0          0 {txt}{c |}
   9. {c |} {res}      1       9          0          0 {txt}{c |}
  10. {c |} {res}      1      10          0          1 {txt}{c |}
      {c LT}{hline 9}{c -}{hline 7}{c -}{hline 10}{c -}{hline 10}{c RT}
  11. {c |} {res}      1      11          1          0 {txt}{c |}
  12. {c |} {res}      1      12          0          0 {txt}{c |}
  13. {c |} {res}      1      13          0          0 {txt}{c |}
  14. {c |} {res}      1      14          1          1 {txt}{c |}
  15. {c |} {res}      1      15          0          0 {txt}{c |}
 		.....

{pstd}
{opth comparevars(varlist)} adds an ego/alter {it:comparison} column for each listed variable,
alongside (not instead of) whatever {opt egovars()}/{opt altervars()} already add - e.g. "do ego
and alter share the same value" or "how far apart are their values", rather than just the two raw
values side by side. {opt comparemode()} picks which comparison (any {help nwexpand##expand_mode:nwexpand mode} - {bf:same} (the default), {bf:dist}, {bf:absdist}, {bf:distinv}, {bf:absdistinv},
{bf:sender}, {bf:receiver}) applies to every variable in {opt comparevars()}; each variable is
internally expanded via {help nwexpand} itself (so the exact same, already-certified comparison
logic is used, not a reimplementation) and the resulting column is named {it:mode_varname} -
matching {help nwexpand}'s own default naming - e.g. {opt comparevars(sport1)} with the default
{bf:comparemode(same)} adds a column named {it:same_sport1}. {bf:dist}/{bf:distinv}/{bf:sender}/
{bf:receiver} comparisons are directional (ego's value relative to alter's, not the reverse), so
adding one automatically triggers the same "any directed network in the list forces {opt full}"
rule already used for a mixed directed/undirected {help netlist} - every dyad appears in both
directions, so the signed comparison is preserved correctly for both.

	{cmd:. nwwebuse glasgow, nwclear}
	{cmd:. nwtoedge glasgow1, comparevars(sport1) comparemode(same)}
	{cmd:. nwtoedge glasgow1, comparevars(sport1) comparemode(dist)}


{title:Network types}

{pstd}
{bf:Directed:} yes. {bf:Valued:} tie values are written to the edge list. {bf:Two-mode:} yes - one row per tie between
the modes ({opt allpairs}: every pair) with the modes of both nodes. {bf:Signed:} not checked. The node list is stored
with the data, so {help nwfromedge} restores isolates. See {help nwnetworktypes}.{p_end}

{title:Limits}

{pstd}
The list of {it:all} dyads (without {opt compress}) has one row for every pair of nodes, so its size grows with the
square of the number of nodes. Measured in Stata/BE, random directed network with 10 ties per node: 1,000 nodes
(1,000,000 rows) 0.5 seconds, 5,000 nodes (25,000,000 rows) 20 seconds and 3.2 GB; above 50,000,000 rows (7,072
nodes, 10,000 for an undirected network) the command stops with an error that recommends {opt compress}. With
{opt compress} only the ties are listed: 1,000 / 5,000 / 20,000 nodes in 0.08 / 0.24 / 0.9 seconds.
For a two-mode network {opt compress} lists only the ties between the two modes (as {help nw2toedge} does), never the pairs of nodes inside one mode.{p_end}
{pstd}
For all commands at network sizes of 1,000 to 100,000 nodes see the web page {browse "https://nwcommands.org/nwcommands/size-limits/":How large a network can I analyze?}

{title:See also}
	
	{help nwfromedge}, {help nw2toedge}, {help nwsave}, {help nwexpand}

{hline}
{pstd}{it:nwcommands version 3.24.0, 13 November 2026} ({help nwversion:check your installed version}){p_end}{* nwversion}
