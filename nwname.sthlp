{smcl}
{* *! version 2.0  13may2019 author: Thomas Grund}{...}
{marker topic}
{helpb nw_topical##information:[NW-2.4] Information}
{marker top2}
{helpb nw_topical##manipulation:[NW-2.5] Manipulation}

{title:Title}

{p2colset 9 15 22 2}{...}
{p2col :nwname {hline 2}}Obtain and change meta-information of a network{p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 17 2}
{cmdab: nwname} 
[{it:{help netname}}]
[,{opth id(int)}
{opth newname(newnetname)}
{opth newtitle(string)}
{opt newdirected(boolean)}
{opt new2mode(boolean)}
{opt newvalued(boolean)}
{opt newselfloop(boolean)}
{opth newlabsfromvar(varname)}
{opth newcaption(string)}
{opth newprovenance(string)}
{opth newmodes(string)}
{opth newmode1desc(string)}
{opth newmode2desc(string)}
]

{synoptset 27 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opth id(int)}}network ID{p_end}
{synopt:{opt newname}({help newnetname})}new name of the network{p_end}
{synopt:{opth newtitle(string)}}new title of the network{p_end}
{synopt:{opt newdirected}(boolean)}force change: directed = {it:true}, not directed = {it:false}{p_end}
{synopt:{opt new2mode}(boolean)}force change: twomode = {it:true}, not twomode = {it:false}{p_end}
{synopt:{opt newvalued}(boolean)}force change: valued = {it:true}, unvalued = {it:false}{p_end}
{synopt:{opt newselfloop}(boolean)}force change: selfloops = {it:true}, no selfloops = {it:false}{p_end}
{synopt:{opth newlabsfromvar(varname)}}new node labels (saved in Stata variable){p_end}
{synopt:{opth newcaption(string)}}new caption/description text for the network{p_end}
{synopt:{opth newprovenance(string)}}new provenance/source note for the network{p_end}
{synopt:{opth newmodes(string)}}new mode assignment for a two-mode network's own nodes (see {help nw2set:introduction to two-mode networks}); an empty value is a deliberate no-op{p_end}
{synopt:{opth newmode1desc(string)}}new description of mode 1 (two-mode networks){p_end}
{synopt:{opth newmode2desc(string)}}new description of mode 2 (two-mode networks){p_end}
{synoptline}
{p2colreset}{...}

{title:Description}

{pstd}
{cmd:nwname} obtains and changes the meta-information of a network.



{title:Supported network types}

{pstd}
Not applicable in the usual sense - this command reports and *sets* a network's own directed/valued/two-mode/self-loop status and other metadata directly; it is the mechanism by which those properties are themselves declared, not something whose behavior varies by them.

{title:Examples}

{pstd}
This loads the Florentine data and returns various information about the {it:flobusiness} network.
	
	{cmd:. nwwebuse florentine}
	{cmd:. nwname flobusiness}
	{cmd:. return list}

{pstd}
This changes the name of the network {it:flobusiness} into {it:flob}. This could also be achieved with {help nwrename}.
	
	{cmd:. nwname flobusiness, newname(flob)}
	{cmd:. return list}

{title:Stored results}

	{bf:nwname} stores the following in {bf:r()}:

	Scalars
	  {bf:r(id)}		internal ID of the network
	  {bf:r(nodes)}		number of nodes in the network
	  {bf:r(nodes1)}	number of mode-1 nodes (two-mode networks only)
	  {bf:r(nodes2)}	number of mode-2 nodes (two-mode networks only)
	  {bf:r(selfloops)}	number of self-loops
	  {bf:r(missing_edges)}	number of missing (undefined) dyads

	Macros
	  {bf:r(netname)}	name of the network
	  {bf:r(title)}		title/label of the network
	  {bf:r(caption)}	caption/description text, if set
	  {bf:r(provenance)}	provenance/source note, if set
	  {bf:r(directed)}	{bf:true}/{bf:false}
	  {bf:r(valued)}	{bf:true}/{bf:false}
	  {bf:r(mode2)}		{bf:true}/{bf:false} - whether the network is two-mode
	  {bf:r(selfloop)}	{bf:true}/{bf:false} - whether the network permits self-loops
	  {bf:r(temporal)}	{bf:true}/{bf:false} - whether the network is temporal
	  {bf:r(temporaltype)}	temporal storage type, if {bf:r(temporal)} is {bf:true}
	  {bf:r(timevar)}/{bf:r(startvar)}/{bf:r(endvar)}/{bf:r(eventtimevar)}	the underlying temporal variable name(s) actually used, depending on {bf:r(temporaltype)}
	  {bf:r(labs)}		comma-separated node labels
	  {bf:r(vars)}		Stata variable names used to represent the network
	  {bf:r(modes)}		mode assignment string for a two-mode network's own nodes
	  {bf:r(mode1desc)}	description of mode 1 (two-mode networks only)
	  {bf:r(mode2desc)}	description of mode 2 (two-mode networks only)

 {title:See also}
 
	{help nwsummarize}, {help nwset}, {help nwload}
last certified : 24 Aug 2026
