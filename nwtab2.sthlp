{smcl}
{* *! 12jul2016: Thomas Grund}{...}

{title:Title}

{p2colset 9 20 23 2}{...}
{p2col :nwtabulate {hline 2}}Two-way table of two networks{p_end}
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



version: 2.0.0
certified: 12 Jul 2016, 18:18:51
