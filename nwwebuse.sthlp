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
{it:https://raw.githubusercontent.com/thomas-u-grund/nwcommands/master/data}.

{pstd}
Several {help netexample:network datasets} are available from this source. If {it:filename} is specified without a suffix, {cmd:.dta} is assumed.

{pstd}
{cmd:nwwebuse} {cmd:query} reports the URL from which network datasets will be obtained.

{pstd}
{cmd:nwwebuse} {cmd:set} allows you to specify the URL to be used as the source
for network datasets.

{pstd}
{cmd:nwwebuse} {cmd:set} without arguments resets the source
to {it:https://raw.githubusercontent.com/thomas-u-grund/nwcommands/master/data}.


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
https://raw.githubusercontent.com/thomas-u-grund/nwcommands/master/data{p_end}
{phang2}{cmd:. nwwebuse florentine}

{pstd}Equivalent to above command{p_end}
{phang2}{cmd:. nwwebuse https://raw.githubusercontent.com/thomas-u-grund/nwcommands/master/data/florentine}{p_end}

{title:See also}

	{help nwuse}, {help nwimport}, {help webuse}

last certified : 23 Aug 2026
