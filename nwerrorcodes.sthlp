{smcl}
{* *! version 1.0.0  24aug2026}{...}
{marker topic}
{helpb nwtopical##utilities:[NW-2.7] Utilities}

{title:Title}

{p2colset 9 20 22 2}{...}
{p2col :nwerrorcodes {hline 2}}Return codes of nwcommands{p_end}
{p2colreset}{...}


{title:Description}

{pstd}
The commands of {cmd:nwcommands} stop with two kinds of return codes: a small set of codes defined by
this package for situations that recur across many commands and have no natural Stata code (network
not found, network already exists, node not found, ...), and Stata's own codes, used for their
standard meaning (invalid syntax, variable already defined, file not found, ...).

{pstd}
The two tables below list every code that the commands of the core package raise themselves, and
in which situations. When Stata itself stops inside a command (for example a file that cannot be
read, or too little memory), its own code is passed on unchanged; see {help error} and
{bf:[P] error} for all of Stata's codes. The model packages ({cmd:nwsaom}, {cmd:nwergm},
{cmd:nwdynam}, {cmd:nwrem}) describe their messages in their own help files.

{pstd}
Use these codes when you catch errors in a do-file ({cmd:capture ...} followed by
{cmd:if _rc == 482 ...}): a code keeps its meaning in every command.

{pstd}
Inside a program the package-specific codes are also available as local macros from
{cmd:unw_defs.ado}, e.g. {cmd:`}{cmd:errNWsNotFound}{cmd:'} instead of the bare number {bf:482}.


{title:Package-specific codes}

{synoptset 8 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{bf:480}}Network creation failed ({cmd:errNWsCreate}){p_end}
{synopt:{bf:482}}Network not found ({cmd:errNWsNotFound}){p_end}
{synopt:{bf:483}}Network already exists; specify {bf:replace}, {bf:nwreplace} or the command's own override option, or choose another name ({cmd:errNWsExists}){p_end}
{synopt:{bf:484}}Network too large to be held as a dense matrix ({cmd:errDenseTooLarge}){p_end}
{synopt:{bf:485}}A node (by name or id) does not exist in the network, or a node id is out of range ({cmd:errNodeNotFound}){p_end}
{synopt:{bf:999}}Loading would discard the networks in memory; specify {bf:nwclear} or {bf:nwappend} ({cmd:errNWsDataLoss}){p_end}
{synopt:{bf:6056}}Two networks that must have the same size do not ({cmd:errNWsSizeMismatch}){p_end}
{synopt:{bf:6077}}A {help netexp} expression is empty or has unmatched parentheses ({cmd:errNetexpMalformed}){p_end}
{synopt:{bf:6082}}A matrix given by the user has the wrong shape (not square, wrong dimensions) ({cmd:errMatrixShape}){p_end}
{synopt:{bf:6088}}The command or option does not support two-mode networks ({cmd:errTwoModeUnsupported}){p_end}
{synopt:{bf:6556}}An option's value is not one of the values it allows ({cmd:errOptValue}){p_end}
{synopt:{bf:6705}}A file or data format that is not supported was requested or detected ({cmd:errFormatUnsupported}){p_end}
{synoptline}
{p2colreset}{...}


{title:Stata codes used by the commands}

{synoptset 8 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{bf:4}}{cmd:nwinstall} building the Mata library: the data in memory would be cleared; save them and type {cmd:clear all} first{p_end}
{synopt:{bf:9}}{cmd:nwinstall} building a native plugin: the compiler stopped{p_end}
{synopt:{bf:109}}Type mismatch: a string variable where a numeric one is needed (for example {cmd:nwset, eventtime()}, {cmd:group()} of {cmd:nwbrokerage}){p_end}
{synopt:{bf:110}}A Stata variable already exists (for example a {cmd:generate()} target of a measure such as {cmd:nwdegree}, {cmd:nwbetween} or {cmd:nwplot});
specify {cmd:replace} or another name. {bf:483} is the code for a {it:network} that already exists{p_end}
{synopt:{bf:111}}Something named in an option was not found (a variable, a Mata matrix, a cluster){p_end}
{synopt:{bf:125}}A number is out of its allowed range (for example a probability outside 0 to 1, a number of nodes below 2){p_end}
{synopt:{bf:184}}Options that may not be combined ({cmd:nwtostata}){p_end}
{synopt:{bf:198}}Invalid syntax: a required option is missing, options are combined that exclude each other, or an option is given a value of the wrong kind{p_end}
{synopt:{bf:199}}A function of {cmd:nwgenerate} that is not available{p_end}
{synopt:{bf:301}}No estimates of a previous {cmd:nwqap} in memory{p_end}
{synopt:{bf:402}, {bf:499}}{cmd:nwdyadprob}: tie probabilities that are negative or all zero{p_end}
{synopt:{bf:416}}Missing values where every observation needs a value (for example events without sender, receiver or time in {cmd:nwset, eventtime()}){p_end}
{synopt:{bf:459}}The data contradict what was declared (for example ties within a mode of a two-mode network, data rows not in node order, cluster levels that are not nested){p_end}
{synopt:{bf:498}}Other checks of the data or the results (for example inconsistent {cmd:maximum()} and {cmd:minimum()}, a model package that needs a newer core){p_end}
{synopt:{bf:503}}A Mata vector given by the user has the wrong length{p_end}
{synopt:{bf:601}, {bf:602}}A file was not found, or a file to be written already exists (specify {cmd:replace}){p_end}
{synopt:{bf:621}}{cmd:nwpreserve}: the networks are already preserved{p_end}
{synopt:{bf:900}}The network has too many nodes to be held in one Stata variable per node{p_end}
{synopt:{bf:908}}The network has more nodes than a Stata matrix can hold ({help limits:c(max_matdim)}){p_end}
{synopt:{bf:2000}, {bf:2001}}No observations, or fewer observations than needed (for example fewer rows of data than the network has nodes){p_end}
{synopt:{bf:3300}}{cmd:nwdyadprob}: more ties requested than there are dyads with a positive probability{p_end}
{synopt:{bf:3499}}The Mata library of nwcommands is missing or out of date; run {cmd:nwinstall}{p_end}
{synoptline}
{p2colreset}{...}


{title:Examples}

{pstd}
Catch a package-specific error code programmatically:

	{cmd:. nwclear}
	{cmd:. capture nwname doesnotexist}
	{cmd:. display _rc}
	{cmd:. if _rc == 482 {c -(}}
	{cmd:.     display "network not found"}
	{cmd:. {c )-}}


{title:See also}

{help nwcommands}, {help nwtopical}

{hline}
{pstd}{it:nwcommands version 3.24.0, 13 November 2026} ({help nwversion:check your installed version}){p_end}{* nwversion}
