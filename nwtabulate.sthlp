{smcl}
{* *! 12jul2016: Thomas Grund}{...}
{marker topic}
{helpb nw_topical##information:[NW-2.4] Information}

{title:Tables of networks}

    See

{p 8 32 2}
{helpb nwtab1:nwtabulate oneway}{space 7}for one-way table of network ties

{p 8 32 2}
{helpb nwtab2:nwtabulate twoway}{space 7}for two-way table of networks 

{p 8 32 2}
{helpb nwtab3:nwtabulate twoway}{space 7}for two-way table of network and node attribute

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

{smcl}
{* *! 12jul2016: Thomas Grund}{...}

{title:Title}

{p2colset 9 20 23 2}{...}
{p2col :nwtabulate {hline 2} Two-way table of two networks}
{p2colreset}{...}


{title:Syntax}

{p 8 17 2}
{cmdab: nwtab:ulate} 
{it:{help netname:netname1}}
{it:{help netname:netname2}}
[{cmd:,}
{opth permutations(integer)}
{opt plot}
{opt plotoptions}({it:{help tabplot:tabplot_options}})
{opt eiplot}
{opt eiplotoptions}({it:{help kdensity:kdensity_options}})
{it:{help tabulate twoway:tabulate2_options}}]


{synoptset 25 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt plot}}Make a tabplot{p_end}
{synopt:{opt eiplot}}Make a plot for significance of E-I-index{p_end}
{synopt:{opth permutations(integer)}}QAP permutations for significance of E-I-index{p_end}

{title:Description}

{pstd}
Teh command produces the network version of {help tabulate twoway} for two networks. It
shows the overlap of ties for two networks that share the same nodes (see {help nodeid}) on the dyadic level. The
command essentially transforms {it:netname1} and {it:netname2} in edgelist format (see {help nwtoedge})
and runs a normal {help tabulate twoway}, hence,
all {help tabulate twoway:tabulate2_options} can be used as well.  

{pstd}
When at least one of the networks {it:netname1} or {it:netname2} is directed, the command produces a full edgelist for the networks with
two entries for the node pair (i,j). 

{pstd}
The command also calculates the E-I-index (Krackhardt and Stern 1988). The Krackhardt E/I Ratio
is a social network measure of the relative density of internal connections within a social group 
compared to the number of connections that group has to the external world. Applied to two networks the number of internal
connections refers to the number of times that the tie value for the pair (i,j) is the same in {it:netname1} and {it:netname2}.

	{it:E-I-index = (E - I) / (E + I)}

{pstd}
where I (internal) is the number of ties within a social group G and E is 
the number of ties to the external world (outside of group G). The E-I-index ranges 
between -1 (only within-group ties exist) and 1 (only between-group ties exist). 

{pstd}
More intuitively, the E-I-index simply calculates the number of 
ties off the diagonal (in the table produced by the command)
by the total number of ties. By default, the command runs 100 QAP
permutations of the network (see {help nwqap}) to obtain a p-value
for the E-I-index. Basically, the network is randomly permuted and the
E-I-index is calculated again to obtain a distribution for the E-I-index
under the condition that the network and the attribute are unrelated.


{title:Example}

{pstd}
This loads the Florentine {help netexample:data} and shows the overlap between
the networks {it:flomarriage} and {it:flobusiness}. Both have the same nodes, i.e. 16 Florentine families. 

     {com}. nwwebuse florentine, nwclear
     {com}. nwtabulate flomarriage flobusiness
{res}
     {txt}   Network1:  {res}flomarriage{txt}{col 36}Directed : {res}false{txt}
     {txt}                           {txt}{col 36}Selfloops: {res}false{txt}
     {res}{txt}   Network2:  {res}flobusiness{txt}{col 36}Directed : {res}false{txt}
     {txt}                           {txt}{col 36}Selfloops: {res}false{txt}

     flomarriag {c |}      flobusiness
              e {c |}         0          1 {c |}     Total
     {hline 11}{c +}{hline 22}{c +}{hline 10}
              0 {c |}{res}        93          7 {txt}{c |}{res}       100 
     {txt}         1 {c |}{res}        12          8 {txt}{c |}{res}        20 
     {txt}{hline 11}{c +}{hline 22}{c +}{hline 10}
          Total {c |}{res}       105         15 {txt}{c |}{res}       120 

     {txt}   E-I Index: {res}-.683{txt} p-value: {res}0{txt}

	
{pstd}
There are 120 possible (undirected) ties between Florentine families that can overlap in the two networks. There are 8 undirected ties
where families have both a marriage and a business relationship. In contrast, there are 7 undirected pairs of families with a business, but not with a marriage
relationship.


{title:See also}

	{help nwtab1:one-way nwtabulate}, {help nwtab3:two-way nwtabulate attribute}, {help nwcorrelate}, {help nwqap}, {help tabulate}

{smcl}
{* *! 12jul2016: Thomas Grund}{...}

{title:Title}

{p2colset 9 20 23 2}{...}
{p2col :nwtabulate {hline 2} Two-way table of network and node attribute}
{p2colreset}{...}


{title:Syntax}

{p 8 17 2}
{cmdab: nwtab:ulate} 
{it:{help netname:netname}}
{cmd:,}
{opth attribute(varname)}
[{opth permutations(integer)}
{opt plot}
{opt plotoptions}({it:{help tabplot:tabplot_options}})
{opt eiplot}
{opt eiplotoptions}({it:{help kdensity:kdensity_options}})
{it:{help tabulate twoway:tabulate2_options}}]


{synoptset 25 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opth attribute(varname)}}Node-level attribute{p_end}
{synopt:{opt plot}}Make a tabplot{p_end}
{synopt:{opt eiplot}}Make a plot for significance of E-I-index{p_end}
{synopt:{opth permutations(integer)}}QAP permutations for significance of E-I-index{p_end}

{title:Description}

{pstd}
When one network and one attribute is given in option {opt attribute()}, the command
produces a two-way table that indicates the number of ties between
network nodes with certain attributes (tie values are not considered). This can be used to 
detect homophily in a network (the tendency for ties to exist between similar 
nodes). 

{pstd}
The command also calculates the E-I-index (Krackhardt and Stern 1988). The Krackhardt E/I Ratio
is a social network measure of the relative density of internal connections within a social group 
compared to the number of connections that group has to the external world.

	{it:E-I-index = (E - I) / (E + I)}

{pstd}
where I (internal) is the number of ties within a social group G and E is 
the number of ties to the external world (outside of group G). The E-I-index ranges 
between -1 (only within-group ties exist) and 1 (only between-group ties exist). 

{pstd}
More intuitively, the E-I-index simply calculates the number of 
ties off the diagonal (in the table produced by the command)
by the total number of ties. By default, the command runs 100 QAP
permutations of the network (see {help nwqap}) to obtain a p-value
for the E-I-index. Basically, the network is randomly permuted and the
E-I-index is calculated again to obtain a distribution for the E-I-index
under the condition that the network and the attribute are unrelated.


{title:Example}

{pstd}
This loads the Florentine {help netexample:data} and shows the attributes of the sending and receiving nodes for those pairs (i,j) who are connected
with each other. In this case, it shows the marriage connections between Florentine families who both have a seat in the civic council and so on. For example,
there are 12 undirected marriage ties between two Florentine families where both have a seat in the civic council. There are 4 marriage ties where one family
has a seat in the civic council and the other one does not. 


     {com}. nwwebuse florentine, nwclear
     {com}. nwtabulate flomarriage, attribute(seat)
     {res}
     {txt}   Network:  {res}flomarriage{txt}{col 36}Directed : {res}false{txt}
     {txt}                           {txt}{col 36}Selfloops: {res}false{txt}
     {txt}   Attribute:  {res}seat{txt}
     {res}
                {txt}{c |}      seat_alter
       seat_ego {c |}         0          1 {c |}     Total
     {hline 11}{c +}{hline 22}{c +}{hline 10}
              0 {c |}{res}         0          4 {txt}{c |}{res}         4 
     {txt}         1 {c |}{res}         4         12 {txt}{c |}{res}        16 
     {txt}{hline 11}{c +}{hline 22}{c +}{hline 10}
          Total {c |}{res}         4         16 {txt}{c |}{res}        20 

     {txt}   E-I Index: {res}-.2{txt}   p-value: {res}.84

	

{title:See also}
{pstd}
	{help nwtab1:one-way nwtabulate}, {help nwtab2:two-way nwtabulate network}, {help nwcorrelate}, {help nwqap}, {help tabulate}

last certified : 21 Aug 2026
