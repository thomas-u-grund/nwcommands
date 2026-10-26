{smcl}
{* *! version 1.0.0  26oct2026 author: Thomas Grund}{...}
{marker topic}
{helpb nwtopical##analysis_cohesion:[NW-2.6.2] Cohesion, Components & Subgroups}

{viewerjumpto "Syntax" "nw2motifs##syntax"}{...}
{viewerjumpto "Description" "nw2motifs##description"}{...}
{viewerjumpto "Options" "nw2motifs##options"}{...}
{viewerjumpto "Motifs and positions" "nw2motifs##table"}{...}
{viewerjumpto "Examples" "nw2motifs##examples"}{...}
{viewerjumpto "Stored results" "nw2motifs##results"}{...}
{viewerjumpto "Supported network types" "nw2motifs##types"}{...}
{viewerjumpto "References" "nw2motifs##references"}{...}
{title:Title}

{p2colset 5 18 20 2}{...}
{p2col:{bf:nw2motifs} {hline 2}}Bipartite motifs of a two-mode network{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 16 2}
{cmd:nw2motifs} [{it:netname}] [{cmd:,} {opt six:node} {opt gen:erate(stub)} {opt replace} {opt mat:rix(name)} {opt norm:alise} {opt posn:orm(type)} {opt silent}]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt six:node}}count the motifs of six nodes too: 44 motifs and 148 node positions instead of 17 and 46{p_end}
{synopt:{opt gen:erate(stub)}}store the node position counts in the variables {it:stub}1, {it:stub}2, ... (one per position, one row per node){p_end}
{synopt:{opt replace}}replace existing variables{p_end}
{synopt:{opt mat:rix(name)}}store the node position counts in a Stata matrix (one row per node, columns np1, np2, ...); only if the network has no more nodes than a matrix may have rows{p_end}
{synopt:{opt norm:alise}}add the four normalised frequencies of {cmd:bmotif::mcount} to the motif table{p_end}
{synopt:{opt posn:orm(type)}}normalise the node position counts as {cmd:bmotif::node_positions}: {cmd:none} (default), {cmd:sum}, {cmd:position}, {cmd:sizeclass}, {cmd:sizeclass_plus1}, {cmd:sizeclass_NAzero}, {cmd:levelsize}, {cmd:levelsize_plus1}, {cmd:levelsize_NAzero}, {cmd:motif}, {cmd:motif_plus1}, {cmd:motif_NAzero}{p_end}
{synopt:{opt silent}}suppress the output{p_end}
{synoptline}


{marker description}{...}
{title:Description}

{pstd}
{cmd:nw2motifs} is the form of {help nwmotifs} for a two-mode network: {cmd:nwmotifs} uses it by default on a two-mode network (and {opt onemode} forces the 4-node census of the bipartite graph). The two names give the same result with the same options.

{pstd}
{cmd:nw2motifs} counts the bipartite motifs of a two-mode network: the small connected patterns of ties between two sets of nodes that make up the building blocks of species-by-site, plant-pollinator and membership networks (Baker et al. 2015; Simmons et al. 2019, {it:Methods in Ecology and Evolution}). There are 17 motifs of two to five nodes and 27 more of six nodes (44 in all), and each motif has one or more {it:positions} (46 for the five-node set, 148 with six nodes): the nodes of a motif that are not equivalent, such as the end and the middle of a path. The command gives two things.

{phang2}1. The {bf:motif table}, the number of times each motif occurs in the network (what {cmd:bmotif::mcount} returns), shown on screen and returned in {cmd:r(motifs)}.{p_end}
{phang2}2. The {bf:node position counts}, for every node the number of times it holds each position (what {cmd:bmotif::node_positions} returns), stored in variables with {opt generate()} or in a matrix with {opt matrix()}. They quantify the structural role of a node, for example in a plant-pollinator network.{p_end}

{pstd}
A motif occurrence is a set of nodes whose subgraph, with {it:all} the ties between them, is connected and has the shape of the motif; an occurrence is counted once however many ways it can be read (the motifs are induced subgraphs, so a path of two rows and two columns and a four-cycle are two different motifs, and a set of four nodes is exactly one of them). The first mode of the network (mode 1) forms the {it:rows} of the biadjacency matrix of {cmd:bmotif} and the second mode the {it:columns}; the numbering of the motifs and of the positions is the one of {cmd:bmotif} (Simmons et al.), listed in the table below. The motif table equals {cmd:bmotif::mcount} and the position counts {cmd:bmotif::node_positions} (bmotif 2.0.2) exactly, on a toy network, the Southern women, the Swedish directors, a subsample of them and 34 random networks.

{pstd}
The counting runs in the compiled plugin of nwcommands and needs no matrices of the size of the network: the 5,092 directors and 455 firms of {cmd:ftdirectors_se} (5,669 ties) take 0.04 seconds for the motifs and positions up to five nodes, and 0.05 seconds with {opt sixnode}; a random network of 1,000 and 150 nodes with 14,800 ties takes 0.05 and 0.9 seconds. (The R function takes about a minute for the five-node set on the directors.) The time with {opt sixnode} grows quickly with the density and the number of nodes of the smaller mode. Counts are held as doubles, so they are exact up to 9 x 10^15. The command stops with a message when the plugin of the installed copy is older than the command or missing for the platform: update the installation ({cmd:net install nwcommands, replace}) and restart Stata.

{pstd}
The node position counts of a node that is in no motif (an isolate) are zero. In the variables and the matrix the nodes are in the order of the network, the rows of the matrix of {cmd:bmotif} being the nodes of mode 1 in that order and its columns those of mode 2; the position ids {it:np1} to {it:np148} are those of {cmd:bmotif} ({it:stub}1 holds position 1).


{marker options}{...}
{title:Options}

{phang}
{opt sixnode} counts the motifs of six nodes (motifs 18 to 44, positions 47 to 148) as well. Without it only the motifs up to five nodes are counted (17 motifs, 46 positions), as {cmd:bmotif} does by default.

{phang}
{opt generate(stub)} stores the counts of the positions in double variables {it:stub}1 to {it:stub}46 ({it:stub}148 with {opt sixnode}), one row per node of the network in the order of the nodes. The data set is aligned with the network first, as in the other node-level commands. Existing variables stop the command unless {opt replace} is given.

{phang}
{opt matrix(name)} stores the same table as a Stata matrix with one row per node and the columns np1, np2, ... The matrix is limited by the largest matrix Stata allows (800 rows in Stata BE); for larger networks use {opt generate()}.

{phang}
{opt normalise} adds to {cmd:r(motifs)} (and to the display) the four normalisations of {cmd:bmotif::mcount}: {cmd:normalise_sum} (the frequency as a share of all motifs counted), {cmd:normalise_sizeclass} (as a share of the motifs with the same number of nodes), {cmd:normalise_levelsize} (as a share of the motifs with the same number of rows and columns; motifs that are alone in their class always give 1) and {cmd:normalise_nodesets} (as a share of the number of node sets that could form the motif, choose(rows, a) times choose(columns, b)). A share whose denominator is zero is missing.

{phang}
{opt posnorm(type)} divides the node position counts (in the variables and the matrix) as {cmd:bmotif::node_positions(normalisation = )} does: {cmd:sum} by the number of times the node holds any position (row sums); {cmd:position} by the number of times any node holds the position (column sums); {cmd:sizeclass} by the node's count in the positions of motifs with the same number of nodes; {cmd:levelsize} by its count in the positions of motifs with the same number of rows and columns; {cmd:motif} by its count in the positions of the same motif. The suffix {cmd:_plus1} adds one to all counts first (so that nodes outside a class are not missing); the suffix {cmd:_NAzero} replaces the missing values of a node that holds none of the positions of the class by 0. Without them such values are missing. It needs {opt generate()} or {opt matrix()}; the table {cmd:r(motifs)} is not affected.

{phang}
{opt silent} suppresses the output.


{marker table}{...}
{title:The motifs and their node positions}

{pstd}
The numbering is that of {cmd:bmotif} (the figure of its vignette "bmotif-dictionary"). {it:r1}, {it:r2}, ... are the rows (nodes of mode 1) and {it:c1}, {it:c2}, ... the columns (nodes of mode 2) of an occurrence; "r1:12" means that row r1 is tied to columns c1 and c2. The last column lists the position id of each row node, then (after the bar) of each column node, in the order r1, r2, ... | c1, c2, ...; nodes with the same id play the same role. The positions of motif {it:m} are the consecutive ids from the smallest to the largest listed. Every row-column pair that is not listed is not tied.

{col 3}motif{col 9}nodes{col 15}r x c{col 23}ties{col 53}positions (rows | columns)
{hline 75}
{col 3}1{col 9}2{col 15}1 x 1{col 23}r1:1{col 53}2 | 1
{col 3}2{col 9}3{col 15}1 x 2{col 23}r1:12{col 53}4 | 3 3
{col 3}3{col 9}3{col 15}2 x 1{col 23}r1:1 r2:1{col 53}6 6 | 5
{col 3}4{col 9}4{col 15}3 x 1{col 23}r1:1 r2:1 r3:1{col 53}8 8 8 | 7
{col 3}5{col 9}4{col 15}2 x 2{col 23}r1:12 r2:1{col 53}12 11 | 10 9
{col 3}6{col 9}4{col 15}2 x 2{col 23}r1:12 r2:12{col 53}14 14 | 13 13
{col 3}7{col 9}4{col 15}1 x 3{col 23}r1:123{col 53}16 | 15 15 15
{col 3}8{col 9}5{col 15}4 x 1{col 23}r1:1 r2:1 r3:1 r4:1{col 53}18 18 18 18 | 17
{col 3}9{col 9}5{col 15}3 x 2{col 23}r1:12 r2:1 r3:1{col 53}22 21 21 | 20 19
{col 3}10{col 9}5{col 15}3 x 2{col 23}r1:12 r2:2 r3:1{col 53}25 24 24 | 23 23
{col 3}11{col 9}5{col 15}3 x 2{col 23}r1:12 r2:12 r3:1{col 53}29 29 28 | 27 26
{col 3}12{col 9}5{col 15}3 x 2{col 23}r1:12 r2:12 r3:12{col 53}31 31 31 | 30 30
{col 3}13{col 9}5{col 15}2 x 3{col 23}r1:123 r2:1{col 53}35 34 | 33 32 32
{col 3}14{col 9}5{col 15}2 x 3{col 23}r1:13 r2:12{col 53}38 38 | 37 36 36
{col 3}15{col 9}5{col 15}2 x 3{col 23}r1:123 r2:12{col 53}42 41 | 40 40 39
{col 3}16{col 9}5{col 15}2 x 3{col 23}r1:123 r2:123{col 53}44 44 | 43 43 43
{col 3}17{col 9}5{col 15}1 x 4{col 23}r1:1234{col 53}46 | 45 45 45 45
{col 3}18{col 9}6{col 15}5 x 1{col 23}r1:1 r2:1 r3:1 r4:1 r5:1{col 53}48 48 48 48 48 | 47
{col 3}19{col 9}6{col 15}4 x 2{col 23}r1:12 r2:1 r3:1 r4:1{col 53}52 51 51 51 | 50 49
{col 3}20{col 9}6{col 15}4 x 2{col 23}r1:12 r2:2 r3:1 r4:1{col 53}57 55 56 56 | 54 53
{col 3}21{col 9}6{col 15}4 x 2{col 23}r1:12 r2:12 r3:1 r4:1{col 53}61 61 60 60 | 59 58
{col 3}22{col 9}6{col 15}4 x 2{col 23}r1:12 r2:12 r3:2 r4:1{col 53}64 64 63 63 | 62 62
{col 3}23{col 9}6{col 15}4 x 2{col 23}r1:12 r2:12 r3:12 r4:1{col 53}68 68 68 67 | 66 65
{col 3}24{col 9}6{col 15}4 x 2{col 23}r1:12 r2:12 r3:12 r4:12{col 53}70 70 70 70 | 69 69
{col 3}25{col 9}6{col 15}3 x 3{col 23}r1:123 r2:1 r3:1{col 53}74 73 73 | 72 71 71
{col 3}26{col 9}6{col 15}3 x 3{col 23}r1:123 r2:2 r3:1{col 53}77 78 78 | 75 75 76
{col 3}27{col 9}6{col 15}3 x 3{col 23}r1:13 r2:12 r3:1{col 53}81 81 82 | 79 80 80
{col 3}28{col 9}6{col 15}3 x 3{col 23}r1:23 r2:12 r3:1{col 53}87 88 86 | 84 85 83
{col 3}29{col 9}6{col 15}3 x 3{col 23}r1:123 r2:12 r3:1{col 53}94 93 92 | 91 90 89
{col 3}30{col 9}6{col 15}3 x 3{col 23}r1:13 r2:12 r3:12{col 53}98 99 99 | 97 96 95
{col 3}31{col 9}6{col 15}3 x 3{col 23}r1:123 r2:12 r3:12{col 53}103 102 102 | 101 101 100
{col 3}32{col 9}6{col 15}3 x 3{col 23}r1:123 r2:23 r3:1{col 53}108 107 106 | 104 105 105
{col 3}33{col 9}6{col 15}3 x 3{col 23}r1:123 r2:123 r3:1{col 53}112 112 111 | 110 109 109
{col 3}34{col 9}6{col 15}3 x 3{col 23}r1:23 r2:13 r3:12{col 53}114 114 114 | 113 113 113
{col 3}35{col 9}6{col 15}3 x 3{col 23}r1:123 r2:13 r3:12{col 53}118 117 117 | 116 115 115
{col 3}36{col 9}6{col 15}3 x 3{col 23}r1:123 r2:123 r3:12{col 53}122 122 121 | 120 120 119
{col 3}37{col 9}6{col 15}3 x 3{col 23}r1:123 r2:123 r3:123{col 53}124 124 124 | 123 123 123
{col 3}38{col 9}6{col 15}2 x 4{col 23}r1:1234 r2:1{col 53}128 127 | 126 125 125 125
{col 3}39{col 9}6{col 15}2 x 4{col 23}r1:134 r2:12{col 53}133 132 | 131 129 130 130
{col 3}40{col 9}6{col 15}2 x 4{col 23}r1:1234 r2:12{col 53}137 136 | 135 135 134 134
{col 3}41{col 9}6{col 15}2 x 4{col 23}r1:124 r2:123{col 53}140 140 | 139 139 138 138
{col 3}42{col 9}6{col 15}2 x 4{col 23}r1:1234 r2:123{col 53}144 143 | 142 142 142 141
{col 3}43{col 9}6{col 15}2 x 4{col 23}r1:1234 r2:1234{col 53}146 146 | 145 145 145 145
{col 3}44{col 9}6{col 15}1 x 5{col 23}r1:12345{col 53}148 | 147 147 147 147 147
{hline 75}

{pstd}
Examples: motif 1 is a single tie (positions 2 for the row and 1 for the column); motifs 2 and 3 are the two-ties stars (one row with two columns, two rows with one column); motif 5 is the path of two rows and two columns and motif 6 the four-cycle; motif 7 and motif 4 are the stars with three columns and three rows. Positions 1 to 2 are those of the two-node motif, 3 to 6 of the three-node motifs, 7 to 16 of the four-node motifs, 17 to 46 of the five-node motifs and 47 to 148 of the six-node motifs.


{marker examples}{...}
{title:Examples}

{pstd}A toy network of 6 persons (mode 1, the rows) and 4 groups (mode 2, the columns):{p_end}

{phang2}{cmd:. clear}{p_end}
{phang2}{cmd:. input str3 p str3 g}{p_end}
{phang2}{cmd:. "p1" "g1"}{p_end}
{phang2}{cmd:. "p1" "g2"}{p_end}
{phang2}{cmd:. "p2" "g1"}{p_end}
{phang2}{cmd:. "p2" "g2"}{p_end}
{phang2}{cmd:. "p2" "g3"}{p_end}
{phang2}{cmd:. "p3" "g2"}{p_end}
{phang2}{cmd:. "p3" "g3"}{p_end}
{phang2}{cmd:. "p4" "g3"}{p_end}
{phang2}{cmd:. "p4" "g4"}{p_end}
{phang2}{cmd:. "p5" "g4"}{p_end}
{phang2}{cmd:. "p6" "g4"}{p_end}
{phang2}{cmd:. "p6" "g1"}{p_end}
{phang2}{cmd:. end}{p_end}
{phang2}{cmd:. nw2fromedge p g, name(toy)}{p_end}
{phang2}{cmd:. nw2motifs toy, normalise}{p_end}

{pstd}Node positions of the Southern women and events, with the shares of each woman's positions among the positions of motifs of the same size:{p_end}

{phang2}{cmd:. nwuse davis, nwclear}{p_end}
{phang2}{cmd:. nw2motifs davis, generate(np) posnorm(sizeclass) silent}{p_end}
{phang2}{cmd:. summarize np1-np6}{p_end}

{pstd}All 44 motifs of the toy network, with the position counts in a matrix:{p_end}

{phang2}{cmd:. nw2motifs toy, sixnode matrix(P) silent}{p_end}
{phang2}{cmd:. matrix list r(motifs)}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:nw2motifs} stores in {cmd:r()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:r(sixnode)}}1 if the motifs of six nodes were counted{p_end}
{synopt:{cmd:r(n_mode1)}}number of nodes of mode 1 (rows){p_end}
{synopt:{cmd:r(n_mode2)}}number of nodes of mode 2 (columns){p_end}

{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:r(motifs)}}17 x 3 (44 x 3 with {opt sixnode}): motif, nodes, frequency; 17 x 7 (44 x 7) with {opt normalise}, with the columns normalise_sum, normalise_sizeclass, normalise_levelsize and normalise_nodesets added{p_end}

{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:r(netname)}}name of the network{p_end}
{synopt:{cmd:r(posnorm)}}the normalisation of the node position counts{p_end}
{p2colreset}{...}


{marker types}{...}
{title:Supported network types}

{pstd}
Binary: yes. Directed: not applicable (a two-mode network is undirected). Valued: a tie counts when its value is above zero; the values are ignored and the command prints the usual one-line note on a valued network (bmotif's mean weight of the motifs is not offered). Two-mode: yes - native, the command needs a two-mode network and counts the motifs of the two modes as {cmd:bmotif} does (mode 1 = rows). For one-mode networks the 4-node census is {help nwmotifs}.


{marker valued}{...}
{title:Valued networks}

{pstd}
A network is valued when it was created with tie values (see {help nwnetworktypes}). Motif counts are defined on the presence of ties: a tie of a valued network is present when its value is above zero, as {cmd:bmotif} converts a weighted matrix. The weighted measures of {cmd:bmotif} (the mean weight of the occurrences of a motif and the weighted position measures) are not offered. On a valued network the command prints "(note: tie values are ignored; this measure is binary)".

{marker twomode}{...}
{title:Two-mode networks}

{pstd}
Two-mode: yes, the command needs a two-mode network (one-mode networks are refused with error 198; use {help nwmotifs} for the 4-node census of a one-mode network). The nodes of mode 1 are the rows and those of mode 2 the columns of the biadjacency matrix of {cmd:bmotif}. For one-mode networks the 4-node census of {help nwmotifs} counts all subgraphs; {cmd:nw2motifs} is its two-mode counterpart.


{marker references}{...}
{title:References}

{phang}
Baker, N., R. Kaartinen, T. Roslin, and D. B. Stouffer. 2015. Species' roles in food webs show fidelity across a highly variable oak forest. {it:Ecography} 38: 130-139.

{phang}
Simmons, B. I., M. J. M. Sweering, M. Schillinger, L. V. Dicks, W. J. Sutherland, and R. Di Clemente. 2019. bmotif: A package for motif analyses of bipartite networks. {it:Methods in Ecology and Evolution} 10: 695-701.

{phang}
Stouffer, D. B., M. Sales-Pardo, M. I. Sirer, and J. Bascompte. 2012. Evolutionary conservation of species' roles in food webs. {it:Science} 335: 1489-1492.


{title:Also see}

{psee}
{help nwmotifs}, {help nw2set}, {help nw2nested}, {help nw2clustering}, {help nw2degree}, {help nwnetworktypes}

{hline}
{pstd}{it:nwcommands version 3.8.0, 26 October 2026} ({help nwversion:check your installed version}){p_end}{* nwversion}
