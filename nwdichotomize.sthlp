{smcl}
{* *! harmonisation phase: nwrecode-based convenience wrapper author: Thomas Grund}{...}
{marker topic}
{helpb nwtopical##manipulation:[NW-2.5] Manipulation}

{title:Title}

{p2colset 9 20 27 2}{...}
{p2col :nwdichotomize {hline 2}}Dichotomize a network at a threshold{p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 22 2}
{cmdab: nwdichotomize}
{it:{help netlist}}
{cmd:,}
{opt threshold(#)}
[{opth generate(newnetlist)} {opt prefix(str)}]

{synoptset 22 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt threshold(#)}}cutoff value; dyads with a value {bf:>= #} become 1, all others become 0{p_end}
{synopt:{opth generate(newnetlist)}}save the dichotomized network(s) under new name(s); default is to replace the original network(s) in place{p_end}
{synopt:{opt prefix(str)}}generate new networks with {it:str} prefix, instead of replacing in place{p_end}
{synoptline}
{p2colreset}{...}


{title:Description}

{pstd}
{cmd:nwdichotomize} converts a valued (weighted) network into a binary one: any dyad whose value
is greater than or equal to {opt threshold()} becomes 1, every other dyad becomes 0 (a missing
tie value stays missing, as with Stata's {help recode} rule {it:min/max}). It is a thin convenience wrapper around {help nwrecode} - internally it is
exactly equivalent to

	{cmd:. nwrecode} {it:netname} {cmd:(}{it:threshold}{cmd:/max=1) (min/max=0)}

{pstd}
It has its own name so that the common "binarize at a cutoff" operation does not require
knowing {help nwrecode}'s own general recode-rule syntax. For anything beyond a single cutoff
(multiple bands, missing-value handling, etc.), use {help nwrecode} directly.

{pstd}
As with {help nwrecode} (and following the package's general convention for commands
where in-place modification is the default), the network is dichotomized in place unless
{opt generate()} or {opt prefix()} is specified, in which case the original is left untouched and
the result is saved under a new name instead.


{title:Network types}

{pstd}
{bf:Directed:} yes. {bf:Valued:} the purpose of the command; a 0/1 network is left unchanged by {opt threshold(1)}.
{bf:Two-mode:} yes - the flag, the modes and the level labels are kept. {bf:Signed:} a negative value is treated as
any other value below {opt threshold()}. See {help nwnetworktypes}.{p_end}


{title:Limits}

{pstd}
See {help nwrecode}: 1,000 / 5,000 / 20,000 nodes in 0.03 / 0.07 / 0.3 seconds, random directed network with 10 ties per node.


{title:Examples}

{pstd}
Build a small valued trade network (export values between three countries), then dichotomize it at
100, in place:

	{cmd:. clear}
	{cmd:. mata: M = (0,150,40 \ 90,0,220 \ 60,30,0)}
	{cmd:. nwset, mat(M) name(trade) directed labs(A,B,C)}
	{cmd:. nwdichotomize trade, threshold(100)}

{pstd}
Instead of the in-place call, keep the original valued network and save the binary version under a new name:

	{cmd:. nwdichotomize trade, threshold(100) generate(trade_binary)}

{hline}
{pstd}{it:nwcommands version 3.20.1, 12 November 2026} ({help nwversion:check your installed version}){p_end}{* nwversion}
