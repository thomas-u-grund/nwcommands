{smcl}
{* *! version 2.0.0  8jul2016}{...}
{marker topic}
{helpb nw_topical##information:[NW-2.4] Information}

{title:Title}

{p2colset 5 18 22 2}{...}
{p2col :nwtriads  {hline 2}}Triad census of the network{p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 17 2}
{cmdab: nwtriads} 
[{help netname}]

{title:Description}

{pstd}
Returns the triad census of the network (or a list of networks). This is a way to characertize a network based on its triads.

{pstd}
Each unique triad (triple of nodes {it:i}, {it:j}, and {it:k})
in a directed network can be one of the following:

	003  = i,j,k, empty triad.
	012  = i->j, k, triad with a single directed edge.
	102  = i<->j, k, triad with a reciprocated connection between two vertices.
	021D = i<-j->k, triadic out-star.
	021U = i->j<-k triadic in-star.
	021C = i->j->k, directed line.
	111D = i<->j<-k
	111U = i<->j->k.
	030T = i->j<-k, i->k.
	030C = i<-j<-k, i->k.
	201  = i<->j<->k.
	120D = i<-j->k, i<->k.
	120U = i->j<-k, i<->k.
	120C = i->j->k, i<->k.
	210  = i->j<->k, i<->k.
	300  = i<->j<->k, i<->k,  complete triad.
 
 {pstd}
 This is the so called MAN notation. As in {help nwdyads} it characterized a triad
 by the number of 1) mutual dyads, 2) asymmetric dyads and 3) null dyads. For example,
 MAN = 102 means that there is one mutual dyad and two null dyads.


{title:Supported network types}

{pstd}
Binary: yes. Directed: yes - this is the command's native case; the full 16-type MAN
classification requires a genuine directed/asymmetric-dyad distinction. Undirected: the command
still runs, but 12 of the 16 categories (everything except {bf:_003}/{bf:_102}/{bf:_201}/{bf:_300})
are not meaningful for undirected data and reliably return 0, since an undirected network
has no asymmetric ties by construction - {cmd:nwtriads} prints a note to this effect when called on
an undirected network. Weighted: not applicable (a triad census is inherently a binary/dichotomous
count). Signed: not checked. Two-mode: not checked.


{title:Examples}
	
{com}. webnwuse glasgow, nwclear
{res}
{com}. nwtriads glasgow3
{res}
{txt}    Triad census: {res} glasgow3{txt}

{txt}{ralign 10:003}{col 12}{c |}{ralign 10:012}{col 24}{c |}{ralign 10:021D}{col 36}{c |}{ralign 10:021U}{col 48}{c |}
{hline 11}{c +}{hline 11}{c +}{hline 11}{c +}{hline 11}{c +}
{res}{ralign 10:16086}{col 12}{c |}{ralign 10:1401}{col 24}{c |}{ralign 10:4}{col 36}{c |}{ralign 10:8}{col 48}{c |}

{txt}{ralign 10:021C}{col 12}{c |}{ralign 10:030T}{col 24}{c |}{ralign 10:030C}{col 36}{c |}{ralign 10:102}{col 48}{c |}
{hline 11}{c +}{hline 11}{c +}{hline 11}{c +}{hline 11}{c +}
{res}{ralign 10:7}{col 12}{c |}{ralign 10:1}{col 24}{c |}{ralign 10:0}{col 36}{c |}{ralign 10:1969}{col 48}{c |}

{txt}{ralign 10:120D}{col 12}{c |}{ralign 10:120U}{col 24}{c |}{ralign 10:120C}{col 36}{c |}{ralign 10:111D}{col 48}{c |}
{hline 11}{c +}{hline 11}{c +}{hline 11}{c +}{hline 11}{c +}
{res}{ralign 10:3}{col 12}{c |}{ralign 10:28}{col 24}{c |}{ralign 10:33}{col 36}{c |}{ralign 10:4}{col 48}{c |}

{txt}{ralign 10:111U}{col 12}{c |}{ralign 10:201}{col 24}{c |}{ralign 10:210}{col 36}{c |}{ralign 10:300}{col 48}{c |}
{hline 11}{c +}{hline 11}{c +}{hline 11}{c +}{hline 11}{c +}
{res}{ralign 10:1}{col 12}{c |}{ralign 10:17}{col 24}{c |}{ralign 10:26}{col 36}{c |}{ralign 10:12}{col 48}{c |}

{txt}     Transitivity: {res}.4830508474576271

{pstd}
{txt}This example shows, e.g. that in the {it:glasgow3} network, there are 12 triads where all nodes {it:i}, {it:j} and {it:k} are directely connected with each other.


{title:Stores results}

	Scalars:
		{bf:r(_003)}	empty triad
		{bf:r(_012)}	triad with one asymmetric dyad and two null dyads.
		...
		{bf:r(_300)}	complete triad
		
	Macros:
		{bf:r(name)}	name of the network
		
		
{title:See also}

	{help nwdyads}



