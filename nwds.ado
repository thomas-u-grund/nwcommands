/***
{smcl}
{* *! version 1.0.0  24aug2026 author: Thomas Grund}{...}
{marker topic}
{helpb nw_topical##analysis_utility:[NW-2.7] Utility Commands}

{title:Title}

{p2colset 9 15 22 2}{...}
{p2col :nwds {hline 2}}List loaded networks, in the style of Stata's own {help ds}{p_end}
{p2colreset}{...}

{title:Syntax}

{p 8 17 2}
{cmdab: nwds}
[{it:{help netlist}}]
[{cmd:,}
{opt alpha}
{opt not}
{it:ds_options}]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt alpha}}List network names in alphabetical order (the default is creation order){p_end}
{synopt:{opt not}}Invert the selection - list every {it:other} loaded network instead of the ones
named in {it:netlist}{p_end}
{synopt:{it:ds_options}}Any other option is forwarded to Stata's own {help ds} (e.g. {opt varwidth},
which controls the display's own column width){p_end}

{p2colreset}{...}

{title:Description}

{pstd}
{cmd:nwds} lists the networks currently loaded in memory, reusing Stata's own {help ds} command for
the display (network names are shown the way {cmd:ds} shows variable names). With no {it:netlist}, every
loaded network is listed. {bf:r(netlist)} always returns the exact list of network names shown.

{title:Supported network types}

{pstd}
Not applicable - a pure network-listing utility (in the style of Stata's own {help ds}); does not read or depend on any network's own content, directed/valued/two-mode status, or tie values.

{title:Stored results}

	Macros
	  {bf:r(netlist)}		the exact list of network names shown

{title:Examples}

	{cmd:. nwwebuse florentine, nwclear}
	{cmd:. nwds}
	{cmd:. nwds, alpha}

{title:See also}

	{help ds}, {help nwcurrent}, {help nwclear}

***/
capture program drop nwds
program nwds, rclass
	 syntax [anything(name=netname)] , [alpha not *]
	 
	 unw_defs
	 
	 if "`netname'" == "" {
		local netname = "_all"
	 }
	 
	 nw_syntax `netname', max(`nw_max')

	 // BUGFIX: the original code checked `not' - but that local is
	 // ALWAYS empty, a variant of this pass's own established
	 // "no-prefix trap": Stata's syntax parser sees the option name
	 // "not" itself as "no"+"t" and silently creates a toggle local
	 // named after the STEM ("t"), not "not" - confirmed directly
	 // (typing "not" sets `t' to "not"; typing "t" alone, or omitting
	 // the option entirely, leaves `t' empty). So `not' is never
	 // populated at all, regardless of what the caller types - fixed by
	 // checking `t' instead. Once correctly detected, inverts `netname'
	 // against the full set of currently loaded networks (the same
	 // "qui nwset" + "r(nets)" + list-subtraction idiom nwsmall.ado
	 // already uses for an analogous before/after set difference),
	 // before the (unrelated) alpha-sort step below.
	 if "`t'" != "" {
		qui nwset
		local __nwds_allnets `r(nets)'
		local netname : list __nwds_allnets - netname
	 }

	 if "`alpha'" != "" {
		local netname : list sort netname
	 }
	 preserve
	 clear
	 foreach v in `netname' {
		gen `v' = .
	 }
	 ds `netname', `alpha' `options'
	 restore
	 return local netlist "`netname'"
end

