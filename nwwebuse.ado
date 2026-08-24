/***
{smcl}
{* *! version 1.0.4  20nov2014 author: Thomas Grund}{...}
{marker topic}
{helpb nw_topical##import:[NW-2.2] Import/Export}

{title:Title}

{p2colset 9 17 23 2}{...}
{p2col :nwwebuse {hline 2}}Load network data over the web{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{phang}
Load network data over the web

{p 8 16 2}
{cmd:nwwebuse} [{cmd:"}]{it:{help filename}}[{cmd:"}] [{cmd:,} {cmd:nwclear}]


{phang}
Report URL from which datasets will be obtained

{p 8 16 2}
{cmd:nwwebuse} {cmd:query}


{phang}
Specify URL from which network dataset will be obtained

{p 8 16 2}
{cmd:nwwebuse} {cmd:set} [{it:http://}]{it:url}[{cmd:/}]


{phang}
Reset URL to default

{p 8 16 2}
{cmd:nwwebuse} {cmd:set}


{marker description}{...}
{title:Description}

{pstd}
{cmd:nwwebuse} {it:filename} loads the specified network dataset, obtaining it
over the web and {help nwset:sets all networks} in this dataset. By default, datasets are obtained from
{it:https://raw.githubusercontent.com/thomas-u-grund/nwcommands/develop/data}.

{pstd}
Several {help netexample:network datasets} are available from this source. If {it:filename} is specified without a suffix, {cmd:.dta} is assumed.

{pstd}
{cmd:nwwebuse} {cmd:query} reports the URL from which network datasets will be obtained.

{pstd}
{cmd:nwwebuse} {cmd:set} allows you to specify the URL to be used as the source
for network datasets.

{pstd}
{cmd:nwwebuse} {cmd:set} without arguments resets the source
to {it:https://raw.githubusercontent.com/thomas-u-grund/nwcommands/develop/data}.


{marker option}{...}

{title:Supported network types}

{pstd}
Binary: yes. Directed: yes. Weighted: yes. Signed: yes. Two-mode: yes - fetches and loads an example dataset exactly as published; the specific dataset fetched determines which of these properties the resulting network actually has, not this command itself.

{title:Option}

{phang}
{cmd:nwclear} specifies that it is okay to replace all network data in memory, even
though the current network data have not been saved to disk.


{marker examples}{...}
{title:Examples}

{pstd}Report URL from which network datasets will be obtained{p_end}
{phang2}{cmd:. nwwebuse query}

{pstd}Change URL from which datasets will be obtained{p_end}
{phang2}{cmd:. nwwebuse set http://www.zzz.edu/users/~sue}

{pstd}Reset URL to the default{p_end}
{phang2}{cmd:. nwwebuse set}

{pstd}Load the {help netexample:Florentine network dataset} that is stored at
https://raw.githubusercontent.com/thomas-u-grund/nwcommands/develop/data{p_end}
{phang2}{cmd:. nwwebuse florentine}

{pstd}Equivalent to above command{p_end}
{phang2}{cmd:. nwwebuse https://raw.githubusercontent.com/thomas-u-grund/nwcommands/develop/data/florentine}{p_end}

{title:See also}

	{help nwuse}, {help nwimport}, {help webuse}

last certified : 23 Aug 2026
***/
*! Date        : 23oct2015
*! Version     : 2.2
*! Author      : Thomas Grund, University College Dublin
*! Email	   : thomas.u.grund@gmail.com
*
* GitHub migration (2026-08-23): the default $nwwebpath rerouted from the
* now-dead nwcommands.org host to this project's own new GitHub repository
* (raw.githubusercontent.com), resolving a gap previously logged in
* docs/CERTIFICATION.md's own Pending list ("nwcommands.org's own data host
* is dead"). Points at the "develop" branch specifically (the actually
* current, complete branch - `master` was found to be a stale, diverged
* legacy line during this same migration, NOT simply an older point on the
* same history) - a user can still override via `nwwebuse set <path>` at
* any time, and `$nwwebpath` remains the single, centralized place this
* would need to change again (e.g. to a versioned/tagged path for a future
* stable release) rather than a hardcoded literal scattered across files.
*
* webnwuse/nwwebuse consolidation (2026-08-23): this command used to be a
* one-line wrapper around webnwuse.ado, which held the real implementation -
* backwards from every other command pair in this package (the shorter,
* more consistently-named form should be the real one). webnwuse.ado/
* webnwuse.sthlp are gone; this file now holds the actual implementation
* directly, and every doc-header example/cross-reference across the
* package was updated from `webnwuse` to `nwwebuse` in the same pass.

capture program drop nwwebuse
program nwwebuse
	// The former `old' option dispatched to a command literally named
	// `nwuse_old' - never a real Stata idiom the way `save'/`saveold' is
	// (contrast nwsave.ado's own `old' option) - which was archived to
	// old/ado/ as a confirmed dead-on-arrival duplicate during an earlier
	// harmonisation cleanup, so `old' has raised a hard "command not
	// found" on every use since. Its underlying legacy metadata format
	// (bare _format/_nets/... Stata variables) predates even the plain-
	// .dta fallback nwuse.ado already handles natively today (see that
	// file's own _nw_format/_nw_nets/... convention), and no such
	// old-format dataset remains hosted at $nwwebpath - removed outright
	// rather than reviving a triply-obsolete path with no current use
	// case.
	syntax anything [, * nwclear]

	`nwclear'
	capture drop _running

	local subcommand = word("`anything'",1)
	local path = "\$nwwebpath"
	local thispath = "`path'"

	if "`subcommand'" != "set" {
		if "`thispath'" == "" | "`thispath'" == "\" {
			global nwwebpath = "https://raw.githubusercontent.com/thomas-u-grund/nwcommands/develop/data"
		}
	}

	if "`subcommand'" == "set" {
		local subcmd2 = word("`anything'",2)
		if  "`subcmd2'" == "" {
			global nwwebpath = "https://raw.githubusercontent.com/thomas-u-grund/nwcommands/develop/data"
		}
		else {
			global nwwebpath = word("`anything'",2)
		}
		exit
	}
	if "`subcommand'" == "query" {
		di `"{txt}(prefix now "{bf:$nwwebpath}")"'
		exit
	}

	local path = "\$nwwebpath"
	local thispath = "`path'"
	local webname = subinstr("`anything'", ".dta","",99)
	if substr("`webname'",1,4) == "http" {
		nwuse `webname', `options'
	}
	else {
		nwuse `thispath'/`webname', `options'
	}
	// Several of this package's own example datasets are plain .dta
	// files, not a saved nwsave() network (see nwuse.ado's own comment)
	// - nwuse already detects that case and leaves the plain dataset
	// loaded as-is, with no network for `nwload' to act on. Wrapped in
	// `capture' so that case exits cleanly instead of surfacing
	// `nwload''s own "no current network" error as if this command had
	// failed.
	capture qui nwload, labelonly
end
