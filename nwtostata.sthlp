{smcl}
{* *! version 1.0.0  24aug2026 author: Thomas Grund}{...}
{marker topic}
{helpb nw_topical##utilities:[NW-2.7] Utilities}

{title:Title}

{p2colset 9 18 22 2}{...}
{p2col :nwtostata {hline 2}}Copy a Mata matrix into Stata variables{p_end}
{p2colreset}{...}

{title:Syntax}

{p 8 17 2}
{cmdab: nwtostata}
{cmd:,}
{opt mat(matamatrix)}
({opt gen(namelist)} {cmd:|} {opth stub(string)})

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt mat(matamatrix)}}name of the Mata matrix to copy into Stata variables{p_end}
{synopt:{opt gen(namelist)}}one new Stata variable name per column of {it:matamatrix}{p_end}
{synopt:{opth stub(string)}}generate columns as {it:stub}{cmd:1}, {it:stub}{cmd:2}, ... instead of naming
them individually{p_end}
{synoptline}
{p2colreset}{...}

{title:Description}

{pstd}
{cmd:nwtostata} is the reverse of {help nwtomata}: it copies an existing Mata matrix
{it:matamatrix} into new Stata variables, one column per variable, one row per observation
(creating additional observations if the dataset does not already have enough). Exactly one of
{opt gen()} or {opt stub()} must be specified - {opt gen()} names each new variable individually
(one name per column of {it:matamatrix}); {opt stub()} instead generates however many
{it:stub}{cmd:1}, {it:stub}{cmd:2}, ... columns are needed to hold every column of {it:matamatrix}.

{pstd}
This is a low-level utility for programmers moving data between Mata and Stata directly; ordinary
use of the package does not need it - see {help nwtomata}/{help nwload} for the normal way to bring
a network's own data into Stata.

{title:Supported network types}

{pstd}
Not applicable - {cmd:nwtostata} copies an arbitrary, already-existing Mata matrix into Stata
variables and has no notion of a network or its properties; any directed/weighted/signed/two-mode
handling happened whenever {it:matamatrix} was itself produced.

{title:Examples}

	{cmd:. mata: m = (1,2 \ 3,4 \ 5,6)}
	{cmd:. nwtostata, mat(m) gen(a b)}
	{cmd:. list}

	{cmd:. mata: m = (1,2 \ 3,4 \ 5,6)}
	{cmd:. nwtostata, mat(m) stub(col)}
	{cmd:. list}

{title:See also}

	{help nwtomata}, {help nwload}

last certified : 24 Aug 2026
