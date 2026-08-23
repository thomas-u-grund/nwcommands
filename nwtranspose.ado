/***
{smcl}
{* *! version 2.0 author: Thomas Grund}{...}
{marker topic}
{helpb nw_topical##generator:[NW-2.3] Generators}
{marker top2}
{helpb nw_topical##manipulation:[NW-2.5] Manipulation}


{title:Title}

{p2colset 9 20 22 2}{...}
{p2col :nwtranspose {hline 2}}Transpose a network{p_end}
{p2colreset}{...}

{title:Syntax}

{p 8 17 2}
{cmdab: nwtranspose} 
[{it:{help netname}}]
[{cmd:,}
{cmd:generate}({it:{help newnetname}})
{opt xvars}]

{synoptset 25 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt generate}({it:{help newnetname}})}Save transpose as new network{p_end}
{synopt:{opt xvars}}Do not produce Stata variables{p_end}

{synoptline}
{p2colreset}{...}
	
{title:Description}

{pstd}
Simply transposes a network, i.e. a directed tie from node {it:i} to node {it:j} is transformed in a 
directed tie from node {it:j} to node {it:i}. By default, {cmd:nwtranspose} replaces a network, but you 
can specify that it should create a new network instead with {bf:generate()}. 


{title:Examples}

	{com}. nwclear
	. nwrandom 5, prob(.3) name(net)
	{com}. nwsummarize net, matonly
	
	{res}     {txt}1   2   3   4   5
          {c TLC}{hline 21}{c TRC}
	1 {c |}  {res}0   0   1   0   0{txt}  {c |}
	2 {c |}  {res}1   0   0   0   0{txt}  {c |}
	3 {c |}  {res}0   0   0   1   0{txt}  {c |}
	4 {c |}  {res}1   1   0   0   1{txt}  {c |}
	5 {c |}  {res}0   0   1   0   0{txt}  {c |}
          {c BLC}{hline 21}{c BRC}

	{com}. nwtranspose net, generate(net_transp)
	{com}. nwsummarize net_transp, matonly
	
	{res}     {txt}1   2   3   4   5
          {c TLC}{hline 21}{c TRC}
	1 {c |}  {res}0   1   0   1   0{txt}  {c |}
	2 {c |}  {res}0   0   0   1   0{txt}  {c |}
	3 {c |}  {res}1   0   0   0   1{txt}  {c |}
	4 {c |}  {res}0   0   1   0   0{txt}  {c |}
	5 {c |}  {res}0   0   0   1   0{txt}  {c |}
          {c BLC}{hline 21}{c BRC}

***/

capture program drop nwtranspose
program nwtranspose 
	version 9
	syntax [anything(name=netname)], [ xvars generate(string)]
	
	nw_syntax `netname', max(1)
	local netobj1 `netobj'
	
	if ("`generate'" != ""){
		nwduplicate `netname', name(`generate') `xvars'
		local netname `generate'
	}
	nw_syntax `netname', max(1)
	local netobj2 `netobj'
	
	mata: `netobj2'->set_edge((*`netobj1'->get_matrix())')
	
end
