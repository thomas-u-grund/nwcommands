{smcl}
{* *!  13jul2016 author: Thomas Grund}{...}
{marker topic}
{helpb nw_topical##utilities:[NW-2.7] Utilities}

{title:Title}

{p2colset 9 18 22 2}{...}
{p2col :nw_tomata {hline 2} Return adjacency matrix of network}
{p2colreset}{...}


{title:Syntax}

{p 8 17 2}
{cmdab: nw_tomata}
[{it:{help netname}}] 
{cmd:, }
[{opt mat(matamatrix)}]
{p_end}

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt mat(matamatrix)}}name of the new Mata matrix{p_end}
{synoptline}
{p2colreset}{...}


{title:Description}

{pstd}
This command allows interaction with the underlying adjacency matrix in Mata  of a network. You
do not need to know Mata to use any of the nwcommands, but sometimes you might want to obtain the 
adjacency matrix, for example, when programming your own network commands. 

{pstd}
{cmd:nw_tomata} returns a link to the {help nw_programming##modernprogramming:Mata network object} and saves it in {bf:r(netobj)}. Furthermore,
it returns a direct link to the underlying Mata adjacency matrix of the network object and saves it in
{bf:r(adj)}.

{pstd}
Keep in mind that when you make alterations to {bf:r(adj)} in Mata you change a network. This
should only be done by advanced programmers.

{pstd}
When the option {opt mat()} is specified, the command obtains a copy of the adjacency matrix and
saves it as a new Mata matrix {it:matamatrix}. When you make alterations to this {it:matamtrix} you do
not change the network.


{title:Example}

	{com}. nwclear
	{com}. nwrandom 5, prob(1) name(mynet)
	{com}. nw_tomata, mat(myadj)
	{res}
	{com}. return list

     {txt}macros:
                r(adj_copy) : "{res}myadj{txt}"
                     r(adj) : "{res}(*nw.nws.pdefs[1]->get_matrix()){txt}"
                  r(netobj) : "{res}nw.nws.pdefs[1]{txt}"
                 r(netname) : "{res}mynet{txt}"

{pstd}
The previous commands generated a new Mata matrix called {it:myadj}. The next command
displays this copy of the adjacency matrix.
	
	{com}. mata: `r(adj_copy)'
     {res}{txt}[symmetric]
            1   2   3   4   5
         {c TLC}{hline 21}{c TRC}
       1 {c |}  {res}.                {txt}  {c |}
       2 {c |}  {res}1   .            {txt}  {c |}
       3 {c |}  {res}1   1   .        {txt}  {c |}
       4 {c |}  {res}1   1   1   .    {txt}  {c |}
       5 {c |}  {res}1   1   1   1   .{txt}  {c |}
         {c BLC}{hline 21}{c BRC}

{pstd}
One can also directly interact with the underlying adjacency matrix of a network. But be careful
when doing so because you might corrupt your network data. This displays the actual adjacency matrix.

	{com}. mata: `r(adj)'
     {res}{txt}[symmetric]
            1   2   3   4   5
         {c TLC}{hline 21}{c TRC}
       1 {c |}  {res}.                {txt}  {c |}
       2 {c |}  {res}1   .            {txt}  {c |}
       3 {c |}  {res}1   1   .        {txt}  {c |}
       4 {c |}  {res}1   1   1   .    {txt}  {c |}
       5 {c |}  {res}1   1   1   1   .{txt}  {c |}
         {c BLC}{hline 21}{c BRC}

	  
{title:See also}

	{help nw_programming:Programming own network commands}
	
last certified : 21 Aug 2026
