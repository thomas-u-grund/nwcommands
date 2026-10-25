{smcl}
{* *! version 3.5.1  25oct2026}{...}
{marker topic}
{helpb nwtopical##utilities:[NW-2.7] Utilities}

{title:Title}

{p2colset 9 21 23 2}{...}
{p2col :nwversion {hline 2}}Version of nwcommands and of the installed model packages{p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 17 2}
{cmd:nwversion}

{title:Description}

{pstd}
{cmd:nwversion} shows the version and release date of the {cmd:nwcommands} core package and, for each of the four model packages {cmd:nwsaom}, {cmd:nwergm}, {cmd:nwdynam} and {cmd:nwrem}, whether it is installed and in which version.
The model packages are installed separately ({cmd:nwinstall, models}, see {help nwinstall##models:help nwinstall}); each has its own {cmd:version} subcommand, for example {cmd:nwsaom version}.

{pstd}
Versions follow semantic versioning (MAJOR.MINOR.PATCH). A given release can be installed by its tag, for example
{cmd:net install nwcommands, from("https://raw.githubusercontent.com/thomas-u-grund/nwcommands/v3.0.0/") replace}.

{title:Stored results}

{pstd}{cmd:nwversion} stores {cmd:r(version)} (for example {cmd:3.0.0}) and {cmd:r(date)} (for example {cmd:24oct2026}) in {cmd:r()}.

{title:Author}

{pstd}Thomas U. Grund, University College Dublin{p_end}

{hline}
{pstd}{it:nwcommands version 3.5.1, 25 October 2026} ({help nwversion:check your installed version}){p_end}{* nwversion}
