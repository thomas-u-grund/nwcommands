{smcl}
{* *! version 1.0.0  3sept2014}{...}
{marker topic}
{helpb nw_topical##analysis_centrality:[NW-2.6.1] Centrality}

{title:Title}

{p2colset 9 18 22 2}{...}
{p2col :nwcentrality  {hline 2}}Node centrality measures{p_end}
{p2colreset}{...}


{title:Examples}

{pstd}
Each measure below is computed by its own dedicated command - for example, degree centrality:

	{cmd:. nwwebuse florentine, nwclear}
	{cmd:. nwdegree flomarriage, generate(deg)}
	{cmd:. list deg in 1/5}

    See

{p 8 32 2}
{helpb nwdegree:Degree centrality}

{p 8 32 2}
{helpb nwbetween:Betweenness centrality}

{p 8 32 2}
{helpb nwevcent:Eigenvector centrality}

{p 8 32 2}
{helpb nwcloseness:Closeness centrality}

{p 8 32 2}
{helpb nwkatz:Katz centrality}
