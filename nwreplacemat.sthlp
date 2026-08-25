{smcl}
{* *! version 1.0.0  3sept2014}{...}
{marker topic}
{helpb nw_topical##manipulation:[NW-2.5] Manipulation}

{title:Title}

{p2colset 9 22 22 2}{...}
{p2col :nwreplacemat {hline 2}}Replace network with Stata or Mata matrix{p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 17 2}
{cmdab: nwreplacemat} 
[{it:{help netname}}]
{cmd:,}
{opt newmat}({it:matname})
[{opt nosync}
{opt netonly}
{opt xvars}
{opt vars}({it:{help newvarlist}})
{opt labs}({it:lab1 lab2 ...})]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt newmat}({it:matname})}name of a Stata or Mata matrix{p_end}
{synopt:{opt nosync}}do not sync Stata variables; by default Stata variables are synced (see {help nwsync}){p_end}
{synopt:{opt netonly}}only update the network, do not touch the Stata dataset at all{p_end}
{synopt:{opt xvars}}also load the updated network as Stata variables (see {help nwload}){p_end}
{synopt:{opt vars}({it:{help newvarlist}})}Stata variable names to use when {it:matname} requires resizing the network; default = auto-generated{p_end}
{synopt:{opt labs}({it:lab1 lab2 ...})}new node labels to use when {it:matname} requires resizing the network; default = {bf:1}, {bf:2}, ... {p_end}

{title:Description}

{pstd}
{cmd:nwreplacemat} changes a network by replacing the adjacency matrix of the network with an existing Mata matrix. 

{pstd}
The command checks if the Stata/Mata matrix {it:matname} has the correct dimensions.

{pstd}
By default, the command also checks if the new adjacency matrix is symmetric and if yes, it alters the 
meta-information of the network (directed => undirected). In case, one still wants to assign 
a perfectly symmetric matrix to a directed network, one can use:

{pmore}
{cmd:nwname} [{it:{help netname}}]{cmd:, directed(true)}

{pstd}
 to overwrite the automatic setting afterwards. 


{title:Supported network types}

{pstd}
Binary: yes. Directed: yes - this command's entire purpose is writing an arbitrary matrix in as the network's own adjacency matrix, whatever directed/symmetric shape it has. Weighted: yes, natively. Signed: yes, any value including negative can be written in. Two-mode: not checked.

{title:Examples}

{pstd}
This example generates a ring lattice first ({it:mynet}), but then replaces the adjacency matrix of this
network with a new Mata matrix {bf:J(5,5,99)}.

	{com}. nwring 5, k(1), name(mynet)
	{com}. mata: net = J(5,5,99)
	{com}. nwreplacemat mynet, newmat(net) 
	{com}. nwsummarize mynet, matonly

	     1   2   3   4   5
	  {c TLC}{hline 25}{c TRC}
	1 {c |}  {res}0                    {txt}  {c |}
	2 {c |}  {res}99   0               {txt}  {c |}
	3 {c |}  {res}99   99   0          {txt}  {c |}
	4 {c |}  {res}99   99   99   0     {txt}  {c |}
	5 {c |}  {res}99   99   99   99   0{txt}  {c |}
	  {c BLC}{hline 25}{c BRC}

	
{title:See also}

	{help nwreplace}
