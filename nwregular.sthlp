{smcl}
{* *! version 1.0.0  12nov2026 author: Thomas Grund}{...}
{marker topic}
{helpb nwtopical##analysis_positions:[NW-2.6.4] Positions, roles and similarity}

{title:Title}

{p2colset 9 22 24 2}{...}
{p2col :nwregular {hline 2}}Classes of regularly equivalent nodes{p_end}
{p2colreset}{...}

{title:Syntax}

{p 8 17 2}
{cmd:nwregular} [{it:{help netname}}]{cmd:,} {opth gen:erate(newvar)} [{opt replace} {opt silent}]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opth gen:erate(newvar)}}variable for the class of each node; required{p_end}
{synopt:{opt replace}}overwrite an existing variable{p_end}
{synopt:{opt silent}}do not show the table of classes{p_end}
{synoptline}

{title:Description}

{pstd}
{cmd:nwregular} finds the classes of regularly equivalent nodes of a network (the maximal regular
equivalence). Two nodes are regularly equivalent if, whenever one of them has a tie to some node,
the other has a tie to a node of the same class, and the same holds for the ties they receive
(White and Reitz 1983). Unlike structural equivalence ({help nwdissimilar}, {help nwconcor},
{help nwhierarchy}), regular equivalence does not require the same contacts, only the same kind of
contacts: two team leaders who are each asked by their own juniors and each ask the same head are
regularly but not structurally equivalent.

{pstd}
The classes are found step by step (CATREGE for binary data; Borgatti and Everett 1993): all nodes
start in one class; a class is split whenever two of its members differ in the set of classes they
send ties to or receive ties from; this is repeated until no class splits. Tie values are ignored
(any nonzero value is a tie), and so are self-loops. On an undirected network all nodes with at
least one tie fall into one class.

{pstd}
The exact classes are all or nothing on many real networks: when every node sends and receives ties,
all nodes are in one class; a few nodes without sent or without received ties can split the network
into classes of single nodes. Exact regular equivalence suits networks whose ties follow levels or
kinds, such as formal hierarchies or food webs.

{title:Stored results}

{pstd}
{cmd:nwregular} stores the following in {cmd:r()}:

{synoptset 15 tabbed}{...}
{p2col 5 15 19 2: Scalars}{p_end}
{synopt:{cmd:r(classes)}}number of classes{p_end}
{p2col 5 15 19 2: Matrices}{p_end}
{synopt:{cmd:r(image)}}classes x classes; 1 if members of the row class send ties to members of the column class{p_end}

{title:Examples}

{pstd}A small office: juniors ask team leaders, team leaders ask the head{p_end}
{phang2}{cmd:. nwclear}{p_end}
{phang2}{cmd:. clear}{p_end}
{phang2}{cmd:. input str8 ego str8 alter}{p_end}
{phang2}{cmd:. "Anna" "Gwen"}{p_end}
{phang2}{cmd:. "Sophie" "Gwen"}{p_end}
{phang2}{cmd:. "Fion" "Leh"}{p_end}
{phang2}{cmd:. "Magalie" "Leh"}{p_end}
{phang2}{cmd:. "Gwen" "Antonia"}{p_end}
{phang2}{cmd:. "Leh" "Antonia"}{p_end}
{phang2}{cmd:. end}{p_end}
{phang2}{cmd:. nwset ego alter, edgelist directed name(firm)}{p_end}
{phang2}{cmd:. nwregular firm, generate(regular)}{p_end}
{phang2}{cmd:. matrix list r(image)}{p_end}

{title:References}

{phang}
Borgatti, S. P., and M. G. Everett. 1993. Two algorithms for computing regular equivalence.
{it:Social Networks} 15: 361-376.

{phang}
White, D. R., and K. P. Reitz. 1983. Graph and semigroup homomorphisms on networks of relations.
{it:Social Networks} 5: 193-234.

{title:Also see}

{psee}
{help nwconcor}, {help nwhierarchy}, {help nwdissimilar}, {help nwsimilar}, {help nwcollapse}
{p_end}

{hline}
{pstd}{it:nwcommands version 3.24.0, 13 November 2026} ({help nwversion:check your installed version}){p_end}{* nwversion}
