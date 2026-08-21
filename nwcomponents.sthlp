{smcl}
{* *! version 2.0.0  18aug2016 author: Thomas Grund}{...}
{marker topic}
{helpb nw_topical##analysis:[NW-2.6] Analysis}

{title:Title}

{p2colset 9 21 22 2}{...}
{p2col :nwcomponents {hline 2} Calculate network components / largest component}
{p2colreset}{...}

{title:Syntax}

{p 8 17 2}
{cmdab: nwcomponents} 
[{it:{help netlist}}]
[, {opt lgc}
{opth generate(newvarname)
{opt replace}]


{synoptset 25 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opth generate(newvarname)}}Name of the Stata variable that stores information about components; default = {it:_component} or {it:_lgc}{p_end}
{synopt:{opt replace}}Replace existing variable{p_end}
{synopt:{opt lgc}}Calculate membership to largest component{p_end}

{p2colreset}{...}
	
{title:Description}

{pstd}
Calculate the components of a network or a list of networks. A component is a set of nodes that are
only connected among each other. All calculations are performed on the undirected network. Nodes can only belong to one component. 

{pstd}
By default, {cmd:nwcomponents} generates 
a new variable {it:_components} which stores the component membership. When
option {bf:lgc} is specified, the command generates a new variable 
{it:_lgc} which stores information about membership to the largest component.


{title:Stored results}

	Scalars
	  {bf:r(components)}		number of components
	  
	Matrices
	  {bf:r(comp_sizeid)}		distribution over components
	  

{title:Examples}

	{cmd:. nwwebuse florentine, nwclear}
	{cmd:. nwcomponents flomarriage}

	{res}{hline 40}
	{txt}  Network name: {res}flomarriage
	{txt}  Components: {res}2

	 {txt}_component {c |}      Freq.     Percent        Cum.
	{hline 12}{c +}{hline 35}
	{txt}          1 {c |}{res}         15       93.75       93.75
	{txt}          2 {c |}{res}          1        6.25      100.00
	{txt}{hline 12}{c +}{hline 35}
	      Total {c |}{res}         16      100.00{txt}
  
 {pstd}
 This shows that there are two components in the Florentine marriage network. All except one node belong to the first
 component. Some alternative ways how the commands can be used.
 
	{cmd:. nwwebuse glasgow}
	{cmd:. nwcomponents glasgow1, generate(mycomponent)} 
	{cmd:. nwcomponents _all, lgc} 
	{cmd:. nwcomponents _all, lgc generate(mylgc)} 
  

 {title:See also}
 
	{help nwgen}

last certified : 21 Aug 2026
