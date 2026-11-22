{smcl}
{* *! version 1.0.4  20nov2014 author: Thomas Grund}{...}
{marker topic}
{helpb nwtopical##import:[NW-2.2] Import/Export}

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
Load a network from Schoch's collection {it:networkdata} (needs R with the package igraph)

{p 8 16 2}
{cmd:nwwebuse} {cmd:schoch} {it:name} [{cmd:,} {it:options}]

{p 8 16 2}
{cmd:nwwebuse} {it:name}{cmd:, schoch} [{it:options}]

{p 8 16 2}
{cmd:nwwebuse} {cmd:schoch} [{cmd:, list}]

{p 8 16 2}
{cmd:nwwebuse} {cmd:schoch} {cmd:list}

{p 8 16 2}
{cmd:nwwebuse} {cmd:schoch} {cmd:describe} {it:name}


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
{it:https://nwcommands.org/examples}, a copy of the {cmd:data} folder of the nwcommands repository on GitHub. If
the website cannot be reached, {cmd:nwwebuse} loads the same file from GitHub
({it:https://raw.githubusercontent.com/thomas-u-grund/nwcommands/main/data}).

{pstd}
Several {help netexample:network datasets} are available from this source. If {it:filename} is specified without a suffix, {cmd:.dta} is assumed.

{pstd}
{cmd:nwwebuse} {cmd:schoch} {it:name} loads one of the networks of the R package {it:networkdata} by David Schoch
({it:https://github.com/schochastics/networkdata}), for example {cmd:nwwebuse schoch karate}. The data are not part of
nwcommands: {cmd:nwnetworkdata} downloads them from Schoch's repository the first time you ask for a data set and keeps
them in a cache, and converts them with R, so {bf:R with the package igraph is needed} for this one reader (the other data sets
of {cmd:nwwebuse} need no R). Every load prints which network was loaded and where the data come from. Cite the collection and the original
source of each data set; see {help nwnetworkdata} and {browse "https://nwcommands.org/datasets/schoch/":nwcommands.org/datasets/schoch}.
{cmd:nwwebuse schoch} alone gives an overview; {cmd:nwwebuse schoch list} lists all data sets and {cmd:nwwebuse schoch describe} {it:name}
shows one. Options (for example {cmd:name()}, {cmd:element()}) are passed to {cmd:nwnetworkdata}.

{pstd}
{cmd:nwwebuse} {cmd:query} reports the URL from which network datasets will be obtained.

{pstd}
{cmd:nwwebuse} {cmd:set} allows you to specify the URL to be used as the source
for network datasets.

{pstd}
{cmd:nwwebuse} {cmd:set} without arguments resets the source
to {it:https://nwcommands.org/examples}.


{marker option}{...}


{title:Option}

{phang}
{cmd:nwclear} specifies that it is okay to replace all network data in memory, even
though the current network data have not been saved to disk.


{title:Network types}

{pstd}
The command works the same for every network type (see {help nwnetworktypes}).{p_end}


{marker examples}{...}
{title:Examples}

{pstd}Report URL from which network datasets will be obtained{p_end}
{phang2}{cmd:. nwwebuse query}

{pstd}Change URL from which datasets will be obtained{p_end}
{phang2}{cmd:. nwwebuse set http://www.zzz.edu/users/~sue}

{pstd}Reset URL to the default{p_end}
{phang2}{cmd:. nwwebuse set}

{pstd}Load the {help netexample:Florentine network dataset} that is stored at
https://nwcommands.org/examples{p_end}
{phang2}{cmd:. nwwebuse florentine}

{pstd}Equivalent to above command{p_end}
{phang2}{cmd:. nwwebuse https://nwcommands.org/examples/florentine}{p_end}


{title:See also}

	{help nwuse}, {help nwimport}, {help webuse}

{hline}
{pstd}{it:nwcommands version 3.35.0, 22 November 2026} ({help nwversion:check your installed version}){p_end}{* nwversion}
