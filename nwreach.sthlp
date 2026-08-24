{smcl}
{* *! 15jul2016 Thomas Grund}{...}
{marker topic}
{helpb nw_topical##generator:[NW-2.3] Generators}
{marker top2}
{helpb nw_topical##analysis_paths:[NW-2.6.5] Paths, Reachability & Ego Networks}

{title:Title}

{p2colset 9 17 22 2}{...}
{p2col :nwreach {hline 2}}Calculate reachability network{p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 17 2}
{cmdab: nwreach} 
[{it:{help netname}}]
[{cmd:,}
{opt sym}
{opth name(string)}
{opt xvars}
{opt nwreplace}]


{synoptset 25 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt sym}}Symmetrize network before calculation of reachability{p_end}
{synopt:{opth name(newnetname)}}Name of the new network; default = {it:reach}{p_end}
{synopt:{opt xvars}}Generate Stata variables for the network{p_end}
{synopt:{opt nwreplace}}if a network named {it:newnetname} already exists, drop it and use this name anyway - required, not silent (see {help nwgeodesic} for the same convention){p_end}


{title:Description}

{pstd}
{cmd:nwreach} calculates the reachability network. The dyads {it:x_ij} in the reachibility network take
value 1 when there is at least one path between {it:nodes i} and {it:j} in the original network {help netname}, and
0 if there is no such path. 



{title:Supported network types}

{pstd}
Binary: yes (only) - reachability is a structural yes/no property; {help nwgeodesic}'s own weighted distance semantics do not carry through here. Directed: yes - symmetrized by default (same convention as {help nwgeodesic}), {opt sym} available. Weighted: not applicable. Signed: not applicable. Two-mode: not checked.

{title:Examples}
	
	{com}. nwclear
	. nwrandom 10, prob(.1)
	{com}. nwreach random, sym
	{com}. nwsummarize _reach, matonly

	1    2    3    4    5    6    7    8    9   10
     {c TLC}{hline 51}{c TRC}
   1 {c |}  {res} 0                                             {txt}  {c |}
   2 {c |}  {res} 1    0                                        {txt}  {c |}
   3 {c |}  {res} 1    1    0                                   {txt}  {c |}
   4 {c |}  {res} 1    1    1    0                              {txt}  {c |}
   5 {c |}  {res} 1    1    1    1    0                         {txt}  {c |}
   6 {c |}  {res} 1    1    1    1    1    0                    {txt}  {c |}
   7 {c |}  {res} 1    1    1    1    1    1    0               {txt}  {c |}
   8 {c |}  {res} 0    0    0    0    0    0    0    0          {txt}  {c |}
   9 {c |}  {res} 1    1    1    1    1    1    1    0    0     {txt}  {c |}
  10 {c |}  {res} 1    1    1    1    1    1    1    0    1    0{txt}  {c |}
     {c BLC}{hline 51}{c BRC}{txt}
	 
{pstd}
In this example, there is basically one isolate node (node 8) who is unconnected from everybody else.
	
	
{title:See also}

	{help nwgeodesic}, {help nwpath}

last certified : 24 Aug 2026
