{smcl}
{* *! 12jul2016: Thomas Grund}{...}

{title:Title}

{p2colset 9 20 23 2}{...}
{p2col :nwtabulate {hline 2} One-way table of dyads}
{p2colreset}{...}


{title:Syntax}

{p 8 17 2}
{cmdab: nwtab:ulate} 
[{it:{help netname}}]
[{cmd:,}
{it:{help tabulate_oneway##tabulate1_options:tabulate1_options}}]

{title:Description}

{pstd}
The one-way nwtabulate simply tabulates all ties in the network and shows the distribution of tie
values. It works just as {help tabulate}, but on the level of network ties. The command recognizes when a network is undirected or selflooped.

{pstd}
For example, for a directed network with 5 nodes, the commands displays the distribution of a total of 5 * 4 = 20 tie values. For an undirected network
with 5 nodes, the commands displays the distribution of a total of (5 * 4)/2 = 10 tie values. 

{pstd}
The command makes use of the normal {help tabulate} command, hence, all 
{it:{help tabulate_oneway##tabulate1_options:tabulate1_options}} can be applied. This can be useful to extract the distribution of tie values for further calculation.

{title:Example}
	
   {cmd:. nwwebuse gang}
   {cmd:. nwtabulate gang}
{res}
{txt}   Network:  {res}gang{txt}{col 24}Directed: {res}false{txt}

       gang {c |}      Freq.     Percent        Cum.
{hline 12}{c +}{hline 35}
          0 {c |}{res}      1,116       77.99       77.99
{txt}          1 {c |}{res}        182       12.72       90.71
{txt}          2 {c |}{res}         92        6.43       97.13
{txt}          3 {c |}{res}         25        1.75       98.88
{txt}          4 {c |}{res}         16        1.12      100.00
{txt}{hline 12}{c +}{hline 35}
      Total {c |}{res}      1,431      100.00

	  {pstd}{txt}
In the {it:gang} network, 1116 potential (undirected) co-offending ties are not realized, 182 ties have the value 1,
92 ties have the value 2 and so on.


{title:See also}

    {help nwtab2:two-way nwtabulate}, {help tabulate}



version: 2.0.0
certified: 12 Jul 2016, 18:18:50
