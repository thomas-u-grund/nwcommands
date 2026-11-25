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
{synopt:{opt nwclear}}replace the data and the networks in memory with the imported ones{p_end}
{synopt:{opt clear}}same as {opt nwclear}{p_end}
{synopt:{opt nwappend}}add the network to those in memory{p_end}
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
{p2col:{cmd: rownames}}matrix: the first {it:column} holds the node names; needed only where this cannot be seen, e.g. numbers as names without a header row ({help nwimport##matrix:matrix})
		{p_end}
{p2col:{cmd: colnames}}matrix: the first {it:row} holds the node names; needed only where this cannot be seen
		{p_end}
{p2col:{cmd: noheader}}edgelist (text file): the first line is a tie, not a header ({help nwimport##edgelist:edgelist}){p_end}
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
Imports networks from popular network file formats. A Pajek file with ties in an {it:*Arcs} (or {it:*Arcslist}) section and a GML file with
{cmd:directed 1} give a directed network, also when every tie is reciprocated; Pajek {it:*Edges} (or {it:*Edgeslist}) and GML {cmd:directed 0} give an
undirected one. UCINET DL files, matrices, edge lists, Pajek {it:*Matrix} and GML files without {cmd:directed} do not say: a network with a symmetric
matrix is then undirected, any other directed. For matrices and edge lists, option {bf:directed} (on its own or inside {opt type()}) declares the
network directed. {bf:forcedirected} and {bf:forceundirected} override this.

{pstd}
{bf:Data in memory.} A failed import changes nothing: data, networks and the current network stay as they are, also with {opt nwclear} or
{opt clear}. With networks in memory, {opt nwappend} or {opt nwclear} is required. A successful import leaves the data in memory unchanged, with two
exceptions. With {opt nwclear} or {opt clear} the data and the networks are replaced. If there are no data (no variables and no observations), the
data set holds what the file gives: the node names ({cmd:_nwnode}) of an edge list, or the matrix columns and node attributes of a matrix.
{opt xvars} adds the variables of the network to the data.

{pstd}
{bf:Node names} cannot hold commas or double quotes. In names read from a file, commas become blanks and double quotes apostrophes, with a suffix
_2, _3, ... where two names become equal; a note says so.

{pstd}
{bf:Self-loops} (ties of a node with itself) in Pajek, GML, UCINET and edge list files are imported, and the network allows self-loops. The diagonal of a
file read with {cmd:type(matrix)} is ignored, and so is a node listed with itself in a compressed edge list.

{pstd}
The following network formats are supported:

{pmore}{help nwimport##ucinet:- Ucinet}{p_end}
{pmore}{help nwimport##pajek:- Pajek}{p_end}
{pmore}{help nwimport##matrix:- Raw adjacency matrix}{p_end}
{pmore}{help nwimport##edgelist:- Raw edgelist}{p_end}
{pmore}{help nwimport##compressed:- Compressed edgelist}{p_end}
{pmore}{help nwimport##import_type:- GML}{p_end}

{pstd}
{it:{help filename}} can also be a URL, so networks can be imported directly from the internet
without downloading a local copy first, e.g.:

{phang}
{cmd:. nwimport "https://nwcommands.org/examples/edgelist_example.txt", type(edgelist)}{p_end}


{marker ucinet}{...}
{title:Import Ucinet DL format}

{pstd}
{cmd:nwimport} can import the most common Ucinet DL format types: {it:fullmatrix, lowerhalf, edgelist1, nodelist1}. It also supports
multiple networks ({it:nm > 0), diagonal = absent, labels:, matrix labels:, level labels:, labels embedded, row labels embedded, col labels embedded}.
Labels are separated by commas or blanks; a label that holds a blank, comma or semicolon is written in double quotes. A DL file does not say whether a
network is directed: specify {opt forcedirected} to keep a directed network whose ties are all reciprocated as directed. A rectangular matrix (nr
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
labels read from the file's own {it:*Vertices} block. {it:*Matrix} follows a {it:*Vertices n} line and holds n lines with n numbers each (a value other
than 0 is a tie from the node of the line to the node of the column); it is not read for two-mode networks. {it:*Vertices n n1} declares a two-mode
network. For a detailed description of the
Pajek .net file format see {browse "https://docs.gephi.org/desktop/User_Manual/Import/Pajek_NET_Format/":here}.


{marker matrix}{...}
{title:Import raw adjacency matrix}

{pstd}
This imports networks that are in raw matrix format, from a text file or an Excel file. In a text file the delimiters "tab" ";" "," and " " are
recognised (or give {opt delimiter()}); in a file separated by semicolons or tabs a decimal comma (1,5) is read. Row and/or column names can be
included; the same rules apply to text and Excel files. When data has already been opened/entered to Stata,
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
Names in the first row (Example 2), in the first column, or in both are recognised without suboptions:

	thomas,0,1,1,0
	peter,1,0,0,0
	susan,0,0,0,1
	kim,0,1,0,0

{pstd}
A first column or first row that holds text where numbers are expected holds names. Numbers are taken as names when the first row and the first column
hold the same numbers and the corner cell is empty or text, or when there is only a first row of distinct numbers (not all 0 or 1) and one line more
than columns. Otherwise, say so with {cmd:type(matrix, rownames)}, {cmd:type(matrix, colnames)} or both. If both the first row and the first column
hold names, the nodes are named after the first column; the same names in a different order are refused.

{pstd}
Cells of the matrix must be numbers; a blank cell, {cmd:.} or {cmd:NA} is a missing tie value. Anything else stops the import with a message, as does
a matrix with fewer columns than rows.

{pstd}
The file can also contain node attributes: when there are more columns than rows, all further columns are attributes, numeric or text. They are in the
data after an import into an empty data set or with {opt nwclear} ({it:Data in memory} in the Description).

{phang}
{bf:Example 3:}{p_end}
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
in Stata, {help nwfromedge} generates a network. Node labels can be embedded in the edgelist. A line with a node and an empty second field declares
a node without a tie from that line; a line with the same node twice (and a value other than 0) is a self-loop.

{pstd}
When the two columns hold numbers, the nodes are named {bf:n} followed by the number (node 10 becomes {bf:n10}), as
{help nwfromedge} does. This also applies to an edge list written by {help nwexport} from a network whose node names
are numbers.

{pstd}
{bf:Header line.} In a text or Excel file, the first line is read as a header, not as a tie, if its first two fields are (in any case)
{it:from to}, {it:source target}, {it:ego alter}, {it:sender receiver}, {it:sender recipient}, {it:node1 node2}, {it:id1 id2}, {it:src dst} or
{it:tail head} and neither word occurs again in these two columns, or if the third field is a word while all other lines hold numbers (or nothing)
there. A text file with numbers as node names can also have its column names recognised as such. {cmd:type(edgelist, noheader)} reads the first line
of a text file as a tie.

{pstd}
The list does not say whether a network is directed. A list with each tie of an undirected network once, as {help nwexport} writes it, is read as
directed unless {opt forceundirected} is specified; a list in which every tie is reciprocated is read as undirected unless {opt directed} or
{opt forcedirected} is specified. Nodes without ties are not in a list written by {help nwexport}.

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
	susan,thomas,3
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
{bf:Directed:} as the file declares it, otherwise detected from the ties; {opt forcedirected} / {opt forceundirected} override it. {bf:Valued:} tie
values are read where the format has them. {bf:Two-mode:} yes - the formats written by {help nwexport} come back as
two-mode networks with level labels (not UCINET); a tie inside a mode is refused (error 459). {bf:Signed:} yes. {bf:Temporal:} edge lists with times
(see {help nwimport##edgelist_time:edge lists with times}). See {help nwnetworktypes}.{p_end}

{hline}
{pstd}{it:nwcommands version 3.37.2, 25 November 2026} ({help nwversion:check your installed version}){p_end}{* nwversion}
