{smcl}
{* *! version 2.1  13may2019 author: Thomas Grund}{...}
{marker topic}
{helpb nwtopical##import:[NW-2.2] Import/Export}

{title:Title}

{p2colset 9 14 22 2}{...}
{p2col :nwsave  {hline 2}}Save network data in a file{p_end}
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
{bf:nwsave} saves all networks (and Stata variables) currently in memory on disk. The
command saves data in its own file format {bf:.nwdta}. Network data saved in this way
can be loaded with {help nwuse}. Notice that the command {help save} does not save
network data.


{title:Network types}

{pstd}
{bf:Directed:}, {bf:Valued:}, {bf:Signed:} stored as they are. {bf:Two-mode:} yes - the file holds the ties between
the modes only, the mode of every node and the node attributes (5,000 + 500 nodes take about a megabyte). See
{help nwnetworktypes}.{p_end}

{pstd}
{bf:Temporal:} yes. A network declared with {cmd:time()}, {cmd:interval()} or {cmd:eventtime()} in {help nwset} is saved with its
times: every event of an event network (sender, receiver, time and value, in the order they were given), every observation of
a tie of a snapshot network (a tie can come and go), every interval of an interval network, the temporal type and the names
of the time variables. {help nwuse} brings back exactly these data. The file also holds the ties of such a network aggregated over all times, as
for every network, so that an earlier version of nwcommands loads the aggregated network without times. A file that holds no temporal network has none of the
time columns.{p_end}


{title:Limits}

{pstd}
A network is stored as its list of ties, so the file of a large network is small (a two-mode network of 5,092 + 455 nodes and 5,669 ties takes 1.2 MB).{p_end}
{pstd}
Networks of different sizes can be saved in one file and come back with their own sizes. The node attributes (the Stata variables) are one table for the whole file, one row per node, so they belong to
the networks only if the networks have the same nodes; keep attributes of different groups in separate files.{p_end}
{pstd}
For all commands at network sizes of 1,000 to 100,000 nodes see the web page {browse "https://nwcommands.org/nwcommands/size-limits/":How large a network can I analyze?}


{title:Examples}
        
{pstd}
This example creates 5 new random networks and {help nwsave:saves} them as {it:mynets}. A new dataset called {it:mynets.nwdta} is created in the working directory.

        {cmd:. nwclear}
        {cmd:. nwrandom 20, ntimes(5) prob(.2)}
        {cmd:. nwsave mynets}

{pstd}
After this, one can easily load these 5 networks in a new Stata session just as if one would load a normal Stata dataset. 

        {cmd:. nwuse mynets}


{title:See also}

        {help nwuse}, {help nwwebuse}, {help save}

{hline}
{pstd}{it:nwcommands version 3.24.0, 13 November 2026} ({help nwversion:check your installed version}){p_end}{* nwversion}
