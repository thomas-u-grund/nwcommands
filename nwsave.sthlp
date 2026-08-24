{smcl}
{* *! version 2.1  13may2019 author: Thomas Grund}{...}
{marker topic}
{helpb nw_topical##import:[NW-2.2] Import/Export}

{title:Title}

{p2colset 9 14 22 2}{...}
{p2col :nwsave  {hline 2}}Save network data in file{p_end}
{p2colreset}{...}

{title:Syntax}

{p 8 17 2}
{cmdab: nwsave} 
{it:{help filename}}
[{cmd:,}
{cmd:replace}]


{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{cmd: replace}}overwrite existing dataset{p_end}


{title:Description}

{pstd}
{bf:nwsave} saves all networks (and Stata variables) currently in memory on disk. Since version 2.1 the
command saves data in its own file format {bf:.nwdta}. Network data saved in this way
can be loaded with {help nwuse}. Notice that the command {help save} does not save
network data.


{title:Supported network types}

{pstd}
Binary: yes. Directed: yes. Weighted: yes. Signed: yes. Two-mode: yes - saves the full network object to disk exactly as stored, independent of any of these properties.

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
last certified : 24 Aug 2026
