{smcl}
{marker topic}
{helpb nwtopical##programming:[NW-2.9] Programming}

{title:Title}

{p2colset 9 18 22 2}{...}
{p2col :nwtomatafast {hline 2}}Return a link to the adjacency matrix of a network{p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 17 2}
{cmdab: nwtomatafast}
[{it:{help netname}}] 


{title:Description}

{pstd}
Internally, networks are saved as adjacency matrices in Mata. This command returns the name of the Mata matrix where a network is stored in the return vector. It 
differs from {help nwtomata} in the following way. It only returns a link to the adjacency matrix and does not produce a copy of the adjacency matrix.

This can be useful, when you want to directly interact with the underlying adjacency matrix. But I only recommend this for advanced programmers.
Caution is advised because the relevant meta-information is not updated when changing the adjacency matrix of a network. 



{title:Supported network types}

{pstd}
Binary: yes. Directed: yes. Weighted: yes. Signed: yes. Two-mode: yes - returns a live pointer to the network's own internal matrix (not a copy), independent of any of these properties; changes made through it directly alter the network.

{title:Example}

	{cmd:. nwrandom 5, density(.2) name(net)}
	{cmd:. nwtomatafast net}
	{cmd:. return list}

	  
{title:See also}

	{help nwtomata}, {help nwload}, {help nwsummarize}

{hline}
{pstd}{it:nwcommands version 3.20.0, 12 November 2026} ({help nwversion:check your installed version}){p_end}{* nwversion}
