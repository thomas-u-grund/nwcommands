{smcl}
{* *! version 3.19.0  11nov2026}{...}

{title:nwcommands {hline 2} Network analysis in Stata}

{pstd}
nwcommands imports, generates, describes, analyzes and plots networks in Stata. It has 134 commands, most of them
with a dialog box. Tutorials, data sets and manuals are at {browse "https://nwcommands.org"}.
{p_end}

{col 14}Section{col 31}Description
{col 14}{hline 56}
{help nwintro:{col 14}{bf:[NW-1]}{col 31}{bf:Introduction}}
{col 31}{it:what the package does, requirements, network size and speed}
{help nwtopical:{col 14}{bf:[NW-2]}{col 31}{bf:Commands by topic}}
{help nwalphabetical:{col 14}{bf:[NW-3]}{col 31}{bf:Commands in alphabetical order}}
{help nwstart:{col 14}{bf:[NW-4]}{col 31}{bf:Getting started}}
{col 31}{it:a first session and the tutorials}
{help nwprogramming:{col 14}{bf:[NW-5]}{col 31}{bf:Programming}}
{col 31}{it:how networks are stored; writing your own commands}
{help nwinstall:{col 14}{bf:[NW-6]}{col 31}{bf:Installation and updates}}
{help nwinternals:{col 14}{bf:[NW-7]}{col 31}{bf:Internal helper programs}}


{title:Installation}

{pstd}
If you have installed only the package {cmd:nwcommands} so far, {stata "nwinstall, all":nwinstall, all}
downloads the commands, help files and dialog boxes; see {help nwinstall}. {help nwversion} shows the installed version.
{p_end}

{title:Statistical network models}

{pstd}
The statistical models are separate packages that need this core. Install them with {stata "nwinstall, models":nwinstall, models}.
{p_end}

{p2colset 8 18 20 2}{...}
{p2col:{bf:{browse "https://nwcommands.org/nwsaom/":nwsaom}}}Stochastic actor-oriented models (SAOM): network and behavior dynamics between observed waves{p_end}
{p2col:{bf:{browse "https://nwcommands.org/nwergm/":nwergm}}}Exponential random graph models (ERGM) for cross-sectional networks{p_end}
{p2col:{bf:{browse "https://nwcommands.org/nwdynam/":nwdynam}}}Dynamic network actor models (DyNAM): choice and rate models for event sequences{p_end}
{p2col:{bf:{browse "https://nwcommands.org/nwrem/":nwrem}}}Relational event models (REM) for timed interaction events{p_end}
{p2colreset}{...}

{title:Author}

{pstd}
Thomas U. Grund, RWTH Aachen University{break}
{browse "mailto:thomas.u.grund@gmail.com":thomas.u.grund@gmail.com}{break}
{browse "https://github.com/thomas-u-grund/nwcommands"}
{p_end}

{pstd}
Questions and bug reports: {browse "https://nwcommands.org/help/"}. How to cite: {help nwintro##citation:[NW-1.7]}.
nwcommands is free software under the GNU General Public License, version 3, as are the model packages.
{p_end}

{hline}
{pstd}{it:nwcommands version 3.19.0, 11 November 2026} ({help nwversion:check your installed version}){p_end}{* nwversion}
