{smcl}
{* *! 12jul2016 author: Thomas Grund}{...}
{marker topic}
{helpb nw_topical##import:[NW-2.2] Import/Export}

{title:Title}

{p2colset 9 18 22 2}{...}
{p2col :nwtoedge {hline 2} Convert network to edgelist}
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
{opt comparemode}({it:{help nwexpand##expand_mode:mode}})]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opth egovars(varlist)}}Keep attributes of sending nodes{p_end}
{synopt:{opth altervars(varlist)}}Keep attributes of receiving nodes {p_end}
{synopt:{opth ego(newvarname)}}Sender of ties; default = {it:_ego}{p_end}
{synopt:{opth alter(newvarname)}}Receiver of ties; default = {it:_alter}{p_end}
{synopt:{opth comparevars(varlist)}}Add an ego/alter comparison column for each variable (e.g. {it:same}, {it:dist}){p_end}
{synopt:{opt comparemode}({it:{help nwexpand##expand_mode:mode}})}Comparison used for {opt comparevars()}; default = {it:same}{p_end}
{synopt:{opt compress}}Compress edgelist{p_end}

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
is generated, unless option {opt full} is specified. 

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
values side by side. {opt comparemode()} picks which comparison (any {help nwexpand##expand_mode:
nwexpand mode} - {bf:same} (the default), {bf:dist}, {bf:absdist}, {bf:distinv}, {bf:absdistinv},
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

{title:See also}
	
	{help nwfromedge}, {help nw2toedge}, {help nwsave}, {help nwexpand}

last certified : 22 Aug 2026
