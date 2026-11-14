{smcl}
{* *! version 1.0.6  23aug2014 author: Thomas Grund}{...}
{marker topic}
{helpb nwtopical##import:[NW-2.2] Import/Export}

{title:Title}

{p2colset 9 18 22 2}{...}
{p2col :nwimport  {hline 2}}Import a network from a Pajek, UCINET, GML or edge list file{p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 17 2}
{cmdab: nwimport} 
{it:{help filename}}
, 
{opt type}({it:{help nwimport##import_type:import_type}}[, {it:{help nwimport##type_sub:type_sub}}])
[{opth name(newnetname)}
{opt forcedirected}
{opt forceundirected}
{opt nwclear}
{opt clear}
{opt nwappend}
{opt xvars}]


{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opth name(newnetname)}}name of the imported network; default = {it:filename}{p_end}
{synopt:{opt forcedirected}}force network to be directed{p_end}
{synopt:{opt forceundirected}}force network to be undirected{p_end}
{synopt:{opt nwclear}}clear all data and networks{p_end}
{synopt:{opt clear}}same as {opt nwclear}{p_end}
{synopt:{opt nwappend}}append to existing data{p_end}
{synopt:{opt xvars}}also generate Stata variables for the imported network (see {help nwload}){p_end}

{synoptset 20 tabbed}{...}
{marker import_type}{...}
{p2col:{it:import_type}}Description{p_end}
{p2line}
{p2col:{cmd: pajek}}network is given in {browse "https://docs.gephi.org/desktop/User_Manual/Import/Pajek_NET_Format/":Pajek NET file format}
		{p_end}
{p2col:{cmd: ucinet}}network is given in {help nwimport##ucinet:Ucinet file format}
		{p_end}
{p2col:{cmd: matrix}}network is given as an {help nwimport##matrix:adjacency matrix} (e.g. Excel, txt)
		{p_end}
{p2col:{cmd: edgelist}}network is given as an {help nwimport##edgelist:edgelist} (e.g. Excel, txt)
		{p_end}
{p2col:{cmd: compressed}}network is given as a {help nwimport##compressed:compressed edgelist} (e.g. txt, CSV)
		{p_end}
{p2col:{cmd: gml}}network is given in {browse "https://docs.gephi.org/desktop/User_Manual/Import/GML_File_Format/":GML file format}
	{p_end}
{p2col:}The tie value is read from the {cmd:value} or {cmd:weight} key of an edge (1 if absent) and the direction from the {cmd:directed} key of the graph.{p_end}


{synoptset 20 tabbed}{...}
{marker type_sub}{...}
{p2col:{it:type_sub}}Description{p_end}
{p2line}
{p2col:{cmd: rownames}}matrix: the file's first {it:column} holds each row's node name as text (no header row) - see {help nwimport##matrix:Import raw adjacency matrix}'s own row-labeled example
		{p_end}
{p2col:{cmd: colnames}}matrix: {it:not needed} when the file's first {it:row} already holds node names as text - that shape is recognized automatically without any {it:type_sub} at all
		{p_end}
{p2col:{opth delimiter(string)}}matrix, edgelist: specify the delimiter explicitly (for an edge list in a text file; {cmd:tab} for a tab)
		{p_end}		
{p2col:{opt keeporiginal}}edgelist, compressed: keeps original nodeid's of nodes
		{p_end}			
{p2col:{opt eventtime}}edgelist: the last column is the time of an event; the network is an event network (see {help nwimport##edgelist_time:edge lists with times}){p_end}
{p2col:{opt time}}edgelist: the last column is the time of a snapshot (wave) of the tie{p_end}
{p2col:{opt interval}}edgelist: the last two columns are the start and the end of an interval{p_end}
{p2col:{opt directed}, {opt undirected}}edgelist with times: the direction of the network (the file does not hold it){p_end}


{title:Description}

{pstd}
Imports networks from popular network file formats. The command automatically recognizes whether networks are directed or undirected. However, options
{bf:forcedirected} and {bf:forceundirected} can be used to override automatic detection.

{pstd}
The following network formats are supported:

{pmore}{help nwimport##ucinet:- Ucinet}{p_end}
{pmore}{help nwimport##pajek:- Pajek}{p_end}
{pmore}{help nwimport##matrix:- Raw adjacency matrix}{p_end}
{pmore}{help nwimport##edgelist:- Raw edgelist}{p_end}
{pmore}{help nwimport##compressed:- Compressed edgelist}{p_end}
{pmore}{help nwimport##gml:- GML}{p_end}

{pstd}
{it:{help filename}} can also be a URL, so networks can be imported directly from the internet
without downloading a local copy first, e.g.:

{phang}
{cmd:. nwimport "https://nwcommands.org/examples/edgelist_example.txt", type(edgelist)}{p_end}


{marker ucinet}{...}
{title:Import Ucinet DL format}

{pstd}
{cmd:nwimport} can import the most common Ucinet DL format types: {it:fullmatrix, lowerhalf, edgelist1, nodelist1}. It also supports
multiple networks ({it:nm > 0), diagonal = absent, labels:, matrix labels:, level labels:, labels embedded, row labels embedded, col labels embedded}. A rectangular matrix (nr
rows, nc columns, format fullmatrix, with row labels and col labels) is read as a two-mode network, the rows being the first mode. For a detailed description of the Ucinet .dl file format see
{browse "https://docs.gephi.org/desktop/User_Manual/Import/UCINET_DL_Format/":here}
or the {browse "https://pages.uoregon.edu/vburris/hc431/Ucinet_Guide.pdf":Ucinet manual}.

{phang}
{bf:Example 1:}{p_end}
	dl n=4 format=fullmatrix
	data:	
	0 1 1 0	
	1 0 1 1
	1 1 0 0
	0 1 0 0 

{phang}
{bf:Example 2:}{p_end}
	dl n = 4, nm = 2
	labels:
	GroupA,GroupB,GroupC,GroupD
	matrix labels:
	Marriage,Business
	data:
	0 1 0 1
	1 0 0 0
	0 0 1 0
	1 0 0 1

	0 1 1 1
	1 0 0 0
	1 0 0 1
	1 0 1 0
	
{phang}
{bf:Example 3:}{p_end}
	dl n = 4
	format = lowerhalf
	labels:
	Sanders,Skvoretz
	S.Smith,T.Smith
	data:
	2
	1 2
	1 1 2
	0 1 0 2
	
{phang}
{bf:Example 4:}{p_end}
	DL n=5
	format = edgelist1
	labels:
	george, sally, jim, billy, jane
	data:
	1 2
	1 3
	2 3
	3 1
	4 3

{phang}
{bf:Example 5:}{p_end}
	DL n=5
	format = edgelist1
	labels embedded:
	data:
	george sally
	george jim
	sally jim
	billy george
	jane jim


{marker pajek}{...}
{title:Import Pajek .net format}

{pstd}
{cmd:nwimport} can import the most common Pajek .net formats: {it:*arcs, *edges, *arcslist, *edgeslist, *matrix}, with vertex
labels read from the file's own {it:*Vertices} block. Two-mode networks are not supported. For a detailed description of the
Pajek .net file format see {browse "https://docs.gephi.org/desktop/User_Manual/Import/Pajek_NET_Format/":here}.


{marker matrix}{...}
{title:Import raw adjacency matrix}

{pstd}
This imports networks that are in raw matrix format. Data can be saved as .txt, .xls or anything else. As delimiters "tab" "," ";" and " " are allowed. Furthermore, row
and/or column names can be included as well. This import option can be used to load networks from e.g. Excel. When data has already been opened/entered to Stata,
{help nwset} declares data as network data.

{phang}
{bf:Example 1:}{p_end}
	0 1 1 0
	1 0 0 0
	0 0 0 1
	0 1 0 0

{phang}
{bf:Example 2:}{p_end}
	thomas,peter,susan,kim
	0,1,1,0
	1,0,0,0
	0,0,0,1
	0,1,0,0

{pstd}
Notice that the command recognises when node names are given in the first row (Example 2 above) - {bf:type(matrix)}
with no suboptions already produces the correct 4-node network from that file, since the header row becomes each
node's own variable name and {cmd:nwimport} labels nodes from variable names by default; {bf:rownames}/{bf:colnames}
are {it:not} needed for this shape and should be omitted here.

{pstd}
{bf:rownames}/{bf:colnames} are for the opposite shape instead: a raw matrix with node names given as an explicit
first {it:column} of text (no header row at all), e.g.

	thomas,0,1,1,0
	peter,1,0,0,0
	susan,0,0,0,1
	kim,0,1,0,0

{pstd}
which requires {bf:type(matrix, rownames)} to read that first column as node labels rather than data.

{pstd}
Furthermore, the raw dataset can also contain additional attributes. When there are more variables than cases, all remaining
variables are treated as attributes. 

{phang}
{bf:Example 2:}{p_end}
	thomas,peter,susan,kim, sex
	0,1,1,0, male
	1,0,0,0, male
	0,0,0,1, female
	0,1,0,0, male


{marker edgelist}{...}
{title:Import raw edgelist}

{pstd}
This imports networks in {help nwfromedge##edgelist:raw edgelist format}. Data can already be in Stata-dta format. Otherwise, delimiters "tab" "," ";" and " " are allowed. When two columns are given
a non-valued network is loaded, when three columns are given a valued network is loaded. In case edgelist data has already been entered/opened
in Stata, {help nwfromedge} generates a network. Node labels can be embedded in the edgelist.

{phang}
{bf:Example 1:}{p_end}
	1 2
	1 4
	2 4
	4 3

{phang}
{bf:Example 2:}{p_end}
	peter,thomas,1
	thomas,susan,4
	susan,thomas3
	geoff,john,2

{marker edgelist_time}{...}
{pstd}
{bf:Edge lists with times.} The options {cmd:eventtime}, {cmd:time} and {cmd:interval} read a list that holds times, as written by {help nwexport} for a temporal network:
{it:ego alter} [{it:value}] {it:time}, or {it:ego alter} [{it:value}] {it:start end} for {cmd:interval}; the value column is there when the list has one column more.
The columns must be numeric where they hold times and values. The network is declared as {help nwset} declares it with {cmd:eventtime()},
{cmd:time()} or {cmd:interval()}, one row per event or observation, and keeps the direction given by {cmd:directed} or {cmd:undirected} (the
direction is not detected for a list with times). A list with a value and a time has four columns and is refused without one of the options.{p_end}

	{cmd:. nwimport calls.txt, type(edgelist, eventtime directed) name(calls)}

{marker compressed}{...}
{title:Import compressed edgelist}

{pstd}
This imports networks in compressed edgelist format. As delimiter "," is allowed. 

{phang}
{bf:Example 1:}{p_end}
	AS,MI,NY,TX
	TX,CA
	IL,AL,SD
	AL,MI,CA,NY

{phang}
{bf:Example 2:}{p_end}
	peter,thomas,mathilde,tim
	thomas,susan
	susan
	geoff,john,michael


{marker twomode}{...}
{title:Network types}

{pstd}
{bf:Directed:} detected from the file; {opt forcedirected} / {opt forceundirected} override it. {bf:Valued:} tie
values are read where the format has them. {bf:Two-mode:} yes - the formats written by {help nwexport} come back as
two-mode networks with level labels (not UCINET); a tie inside a mode is refused (error 459). {bf:Signed:} yes. {bf:Temporal:} edge lists with times
(see {help nwimport##edgelist_time:edge lists with times}). See {help nwnetworktypes}.{p_end}

{hline}
{pstd}{it:nwcommands version 3.25.0, 14 November 2026} ({help nwversion:check your installed version}){p_end}{* nwversion}
