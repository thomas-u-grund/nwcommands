{smcl}
{* *! version 1.0.0  24aug2026}{...}
{marker topic}
{helpb nw_topical##utilities:[NW-2.7] Utilities}

{title:Title}

{p2colset 9 20 22 2}{...}
{p2col :nw_errorcodes {hline 2}}What this package's own custom return codes mean{p_end}
{p2colreset}{...}

{title:Description}

{pstd}
Most errors raised by {cmd:nw*} commands are Stata's own standard return codes, used for their
usual meaning (e.g. {bf:198} invalid syntax, {bf:99} a Stata variable already exists). A number of
recurring, network-specific situations do not have a natural existing Stata code, so this package
defines its own small set of custom codes instead of inventing a new number per command. This page
documents every one of them - if you catch one of these programmatically (e.g. {cmd:capture ...} /
{cmd:if _rc == 482}), this is the authoritative list of what it means and which commands can raise
it.

{pstd}
These codes are also available as named local macros from {cmd:unw_defs.ado} (used internally by
this package's own commands) - e.g. {cmd:`}{cmd:errNWsNotFound}{cmd:'} instead of the bare number
{bf:482}.

{title:Package-specific codes}

{synoptset 8 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{bf:480}}Network creation failed ({cmd:errNWsCreate}){p_end}
{synopt:{bf:481}}Duplicate node name ({cmd:errNodeDupName}){p_end}
{synopt:{bf:482}}Network not found ({cmd:errNWsNotFound}){p_end}
{synopt:{bf:483}}Network already exists; specify {bf:replace} (or an equivalent override option) ({cmd:errNWsExists}){p_end}
{synopt:{bf:484}}Network too large for dense-matrix materialization ({cmd:errDenseTooLarge}){p_end}
{synopt:{bf:6056}}Two networks required to be the same size are not ({cmd:errNWsSizeMismatch}){p_end}
{synopt:{bf:6077}}A {help netexp} expression is empty or has unmatched parentheses ({cmd:errNetexpMalformed}){p_end}
{synopt:{bf:6082}}A user-supplied Mata/Stata matrix has the wrong shape (not square, wrong dimensions, etc.) ({cmd:errMatrixShape}){p_end}
{synopt:{bf:6088}}This command/option does not support two-mode networks ({cmd:errTwoModeUnsupported}){p_end}
{synopt:{bf:6556}}An option's value is not one of its documented allowed set ({cmd:errOptValue}){p_end}
{synopt:{bf:6705}}An unsupported file/data format was requested or detected ({cmd:errFormatUnsupported}){p_end}
{synopt:{bf:999}}Loading would discard unsaved data in memory; specify {bf:nwclear} or {bf:nwappend} ({cmd:errNWsDataLoss}){p_end}
{synoptline}
{p2colreset}{...}

{title:Standard Stata codes used package-wide}

{pstd}
Two ordinary Stata codes are used consistently, package-wide, for their own standard meaning -
not reinvented as custom codes:

{phang}
{bf:99} - a {bf:Stata variable} (a per-node output column, e.g. from {bf:generate()}) already
exists; specify {bf:replace}. This is distinct from {bf:483} above, which is about a {bf:network},
not a Stata variable.

{phang}
{bf:198} - invalid syntax, or a required option (or a required combination of mutually exclusive
options) was not satisfied.

{title:Background}

{pstd}
Before this registry existed, several of these situations had drifted onto multiple different
ad-hoc numbers across different commands (e.g. "network already exists" independently used both
{bf:483} in one command and an undocumented {bf:6099} in several others; "two networks must be the
same size" appeared as {bf:100}, {bf:6055}, {bf:6056}, and {bf:60033} depending which command you
called) - purely accidental drift, not a deliberate design. Commands have since been consolidated
onto the single codes above; a command-specific validation that genuinely does not fit any of
these may still raise its own distinct code, but should not silently reuse one of the numbers on
this page for an unrelated situation.

{title:See also}

{help nwcommands}, {help nw_topical}
