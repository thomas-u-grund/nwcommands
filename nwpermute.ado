/***
{smcl}
{* *! 15jul2016 Thomas Grund}{...}
{marker topic}
{helpb nw_topical##generator:[NW-2.3] Generators}

{title:Title}

{p2colset 9 18 22 2}{...}
{p2col :nwpermute {hline 2}}Generate permutation of a network{p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 17 2}
{cmdab: nwpermute} 
[{it:{help netname}}]
[{cmd:,}
{opth generate(newnetname)}
{opt replace}
{opt xvars}]

{synoptset 25 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opth generate(newnetname)}}Save permutation as new network{p_end}
{synopt:{opt replace}}Replace existing network with permutation{p_end}
{synopt:{opt xvars}}Do not generate Stata variables{p_end}


{title:Description}

{pstd}
Produces a random permutation of the network {help netname}. In such a permutation, the nodes are randomly
reshuffled, while the overall structure of the network remains the same. Either option {bf:replace} or {bf:generate} needs to 
be specfied. 

{pstd}
A simple example illustrates what the command does. First, we generate a regular lattice network. 
 
	{com}. nwclear
	. nwlattice 3 3
	{com}. nwsummarize lattice, matonly

	     1   2   3   4   5   6   7   8   9
	  {c TLC}{hline 37}{c TRC}
	1 {c |}  {res}0                                {txt}  {c |}
	2 {c |}  {res}1   0                            {txt}  {c |}
	3 {c |}  {res}0   1   0                        {txt}  {c |}
	4 {c |}  {res}1   0   0   0                    {txt}  {c |}
	5 {c |}  {res}0   1   0   1   0                {txt}  {c |}
	6 {c |}  {res}0   0   1   0   1   0            {txt}  {c |}
	7 {c |}  {res}0   0   0   1   0   0   0        {txt}  {c |}
	8 {c |}  {res}0   0   0   0   1   0   1   0    {txt}  {c |}
	9 {c |}  {res}0   0   0   0   0   1   0   1   0{txt}  {c |}
	  {c BLC}{hline 37}{c BRC}

{pstd}
Now, let us permute the network {it:lattice}.
		
	{com}. nwpermute lattice, replace
	{com}. nwsummarize lattice, matonly

	     1   2   3   4   5   6   7   8   9
	  {c TLC}{hline 37}{c TRC}
	1 {c |}  {res}0                                {txt}  {c |}
	2 {c |}  {res}1   0                            {txt}  {c |}
	3 {c |}  {res}0   0   0                        {txt}  {c |}
	4 {c |}  {res}0   0   1   0                    {txt}  {c |}
	5 {c |}  {res}1   0   0   0   0                {txt}  {c |}
	6 {c |}  {res}0   1   0   1   0   0            {txt}  {c |}
	7 {c |}  {res}0   0   0   0   1   0   0        {txt}  {c |}
	8 {c |}  {res}0   0   1   0   0   0   1   0    {txt}  {c |}
	9 {c |}  {res}0   1   0   1   1   0   0   1   0{txt}  {c |}
	  {c BLC}{hline 37}{c BRC}

{pstd}
The structure of the network remains exactly the same, however, the nodes have a different order. Often,
such a permutation is desired to recalculate network statistics (and derive standard errors and confidence intervals for 
these statistics) while keeping the overall structure of the network constant (see more {help nwqap}, {help nwcorrelate}).	
	
	
{title:Example}

{pstd}
	
	{cmd:. nwclear}
	{cmd:. nwrandom 10, prob(.1) name(mynet)}
	{cmd:. nwplot mynet, lab layout(circle)}
	{cmd:. nwpermute mynet, replace}
	{cmd:. nwplot mynet, lab layout(circle)}

{title:See also}

	{help nwqap}, {help nwcorrelate}

***/
capture program drop nwpermute	
program nwpermute
	version 9.0
	syntax [anything(name=netname)], [ xvars replace generate(string)]
	if "`replace'" == "" & "`generate'" == "" {
		di "{err}Either option {bf:replace} or {bf:generate} required."
		error 999
	}
	nw_syntax `netname', max(1)
	if "`generate'" == "" & "`replace'" != "" {
		mata: `netobj'->permute()
	}
	if "`generate'" != "" {
		capture nwdrop `generate'
		nwduplicate `netname', name(`generate')
		nw_syntax `generate'
		mata: `netobj'->permute()
	}
	if "`xvars'" == "" {
		nwload `netname'
	}
end
