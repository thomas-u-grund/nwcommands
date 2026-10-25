{smcl}
{* *! version 2.1  13may2019 author: Thomas Grund}{...}
{marker topic}
{helpb nwtopical##import:[NW-2.2] Import/Export}

{title:Title}

{p2colset 9 14 22 2}{...}
{p2col :nwsave  {hline 2}}Save network data in file{p_end}
{p2colreset}{...}

{title:Syntax}

{p 8 17 2}
{cmdab: nwsave}
{it:{help filename}}
[{cmd:,}
{cmd:replace}
{opt old}]


{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{cmd: replace}}overwrite existing dataset{p_end}
{synopt:{opt old}}save in a Stata-version-backward-compatible format (uses {help saveold} internally instead of {help save}){p_end}


{title:Description}

{pstd}
{bf:nwsave} saves all networks (and Stata variables) currently in memory on disk. Since version 2.1 the
command saves data in its own file format {bf:.nwdta}. Network data saved in this way
can be loaded with {help nwuse}. Notice that the command {help save} does not save
network data.


{title:Supported network types}

{pstd}
Binary: yes. Directed: yes. Weighted: yes. Signed: yes. Two-mode: yes - the file holds the ties between the two modes only (the pairs of nodes inside one mode are not stored), the mode of every node and the node attributes, so a network with 5,000 + 500 nodes takes about a megabyte; {help nwuse} restores the same network. Files written by earlier versions (which listed every pair of nodes) are still read by {cmd:nwuse}, and files written now can be read by earlier versions.

{title:Examples}
        
{pstd}
This example creates 5 new random networks and {help nwsave:saves} them as {it:mynets}. A new dataset called {it:mynets.nwdta} is created in the working directory.

        {cmd:. nwclear}
        {cmd:. nwrandom 20, ntimes(5) prob(.2)}
        {cmd:. nwsave mynets}

{pstd}
After this, one can easily load these 5 networks in a new Stata session just as if one would load a normal Stata dataset. 

        {cmd:. nwuse mynets}
        

{title:Limits}

{pstd}
A network is stored as its list of ties, so the file of a large network is small (a two-mode network of 5,092 + 455 nodes and 5,669 ties takes 1.2 MB).
{pstd}
For all commands at network sizes of 1,000 to 100,000 nodes see the web page {browse "https://nwcommands.org/nwcommands/size-limits/":How large a network can I analyze?}

{title:See also}

        {help nwuse}, {help nwwebuse}, {help save}
last certified : 24 Aug 2026

{hline}
{pstd}{it:nwcommands version 3.4.1, 25 October 2026} ({help nwversion:check your installed version}){p_end}{* nwversion}
