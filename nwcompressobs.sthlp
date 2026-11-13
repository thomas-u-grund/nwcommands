{smcl}
{* *! version 1.0.0  3sept2014}{...}
{marker topic}
{helpb nwtopical##programming:[NW-2.9] Programming}

{title:Title}

{p2colset 9 15 22 2}{...}
{p2col :nwcompressobs {hline 2}}Drop observations that no network needs{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 13 2}{cmd:nwcompressobs}


{title:Description}

{pstd}
Compresses the observations in Stata. Deletes every observation in which all variables are missing (an empty
string or the system missing value), such as the extra observations that are not needed to represent the largest
network. An observation that holds a node name or any other non-missing value is kept.


{title:Network types}

{pstd}
The command works the same for every network type (see {help nwnetworktypes}).{p_end}


{title:Limits}

{pstd}
All-missing observations are found by testing every variable against "" or . (string and numeric variables).


{title:Examples}

	{cmd:. nwclear}
	{cmd:. nwrandom 20, prob(.2)}
	{cmd:. set obs 50}
	{cmd:. nwcompressobs}


{title:See also}

  {help nwdrop}, {help clear}

{hline}
{pstd}{it:nwcommands version 3.24.0, 13 November 2026} ({help nwversion:check your installed version}){p_end}{* nwversion}
