{smcl}
{* *! harmonisation phase: nwrecode-based convenience wrapper author: Thomas Grund}{...}
{marker topic}
{helpb nwtopical##manipulation:[NW-2.5] Manipulation}

{title:Title}

{p2colset 9 20 27 2}{...}
{p2col :nwdichotomize {hline 2}}Dichotomize a network at a threshold (built on {help nwrecode}){p_end}
{p2colreset}{...}

{title:Syntax}

{p 8 22 2}
{cmdab: nwdichotomize}
{it:{help netlist}}
{cmd:,}
{opt threshold(#)}
[{opth generate(newnetlist)} {opt prefix(str)}]

{synoptset 20 tabbed}{...}
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
is greater than or equal to {opt threshold()} becomes 1, every other dyad (including missing
ties) becomes 0. It is a thin convenience wrapper around {help nwrecode} - internally it is
exactly equivalent to

	{cmd:. nwrecode} {it:netname} {cmd:(}{it:threshold}{cmd:/max=1) (min/max=0)}

- given its own name specifically so the common "binarize at a cutoff" operation does not require
knowing {help nwrecode}'s own general recode-rule syntax. For anything beyond a single cutoff
(multiple bands, missing-value handling, etc.), use {help nwrecode} directly.

{pstd}
As with {help nwrecode} (and following the package's general convention - see
{browse "NWCOMMANDS_COMMAND_STYLE.md":the style guide}'s "Output creation" section - for commands
where in-place modification is the default), the network is dichotomized in place unless
{opt generate()} or {opt prefix()} is specified, in which case the original is left untouched and
the result is saved under a new name instead.

{title:Supported network types}

{pstd}
Binary: yes (a no-op - every value is already either 0 or 1, so {opt threshold(1)} leaves it
unchanged). Directed: yes. Weighted: yes - this is its primary use case. Signed: not checked -
a negative value below {opt threshold()} is treated the same as any other sub-threshold value.
Two-mode: not checked directly, but inherits whatever {help nwrecode}/{help nwtoedge} support for
two-mode data.

{title:Examples}

{pstd}
Build a small valued trade network (export values between three countries), then dichotomize it at
100, in place:

	{cmd:. clear}
	{cmd:. mata: M = (0,150,40 \ 90,0,220 \ 60,30,0)}
	{cmd:. nwset, mat(M) name(trade) directed labs(A,B,C)}
	{cmd:. nwdichotomize trade, threshold(100)}

{pstd}
Same, but keep the original valued network and save the binary version under a new name:

	{cmd:. nwdichotomize trade, threshold(100) generate(trade_binary)}

last certified : 28 Aug 2026
