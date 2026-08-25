/***
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

***/
capture program drop nwtostata
program nwtostata
version 9
syntax, mat(string) [ gen(namelist min=1) stub(string) ]

	mata: st_numscalar("r(rows)", rows(`mat'))
	local rows = r(rows)
	if `rows' > `=_N' {
		set obs `rows'
	}
	// BUGFIX: referenced the undefined local `sub' (the real option is
	// named `stub') so this was always a no-op regardless of whether
	// both gen()/stub() were actually specified - caused no user-
	// visible defect only because the manual check immediately below
	// already enforces the real mutual exclusivity correctly.
	opts_exclusive "`"`gen'"' `"`stub'"'"
	
	if "`gen'" != "" & "`stub'" != "" {
		dis as error "Either option gen or option stub needs to be specified, but not both."
		error 184
	}
	
	
	if "`gen'" == "" & "`stub'" == "" {
		dis as error "Either option gen or option stub needs to be specified."
		error 198
	}

	if "`gen'" != "" {
		foreach x of newlist `gen' {
			quietly gen `x' = .
		}
		mata: st_view(nwtostataview=.,(1,rows(`mat')),tokens("`gen'"))
	}
	
	if "`stub'" != "" {
		mata: st_numscalar("r(cols)", cols(`mat'))
		local cols = r(cols)
		forvalues i = 1/`cols' {
			quietly gen `stub'`i' =.
		}
		unab vars : `stub'*
		mata: st_view(nwtostataview=.,(1,rows(`mat')),tokens("`vars'"))
	}
	mata: nwtostataview[.,.] = `mat'
	capture quietly compress `gen'
	capture quietly compress `stub'*
	mata: mata drop nwtostataview
end
*! v1.5.0 __ 17 Sep 2015 __ 13:09:53
*! v1.5.1 __ 17 Sep 2015 __ 14:54:23
