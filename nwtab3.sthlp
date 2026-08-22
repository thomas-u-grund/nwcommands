{smcl}
{* *! 12jul2016: Thomas Grund}{...}

{title:Title}

{p2colset 9 20 23 2}{...}
{p2col :nwtabulate {hline 2} Two-way table of network and node-attribute}
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

	{help nwtab1:one-way nwtabulate}, {help nwtab2:two-way nwtabulate network}, {help nwcorrelate}, {help nwqap}, {help tabulate}



version: 2.0.0
certified: 12 Jul 2016, 18:18:52
