{smcl}
{* *! version 2.1  13may2019 author: Thomas Grund}{...}
{marker topic}
{helpb nwtopical##import:[NW-2.2] Import/Export}

{title:Title}

{p2colset 9 14 22 2}{...}
{p2col :nwuse  {hline 2}}Load Stata network dataset{p_end}
{p2colreset}{...}

{title:Syntax}

{p 8 17 2}
{cmdab: nwuse}
{it:{help filename}}
[{cmd:,}
{cmd:nwclear}
{cmd:nwappend}
{opt force}]

{p 8 17 2}
{cmdab: nwwebuse}
{it:{help netexample}}
[{cmd:,}
{cmd:nwclear}]


{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt nwclear}}clear memory before loading dataset{p_end}
{synopt:{opt nwappend}}append to existing data{p_end}
{synopt:{opt force}}when combined with {opt nwappend}, if the incoming data contains a network with the same name as one already in memory, auto-renumber the incoming network to a fresh name instead of erroring - unlike {opt replace} elsewhere in this group (e.g. {help nwset}), which overwrites the existing network in place under the same name, {opt force} leaves the existing network untouched{p_end}

        
{title:Description}

{pstd}
{bf:nwuse} loads a Stata network dataset previously saved with {help nwsave}. This includes all networks and Stata variables. If {it:{help filename}}
is specified without an extension, {bf:.nwdta} is assumed. If your {it:filename} contains embedded spaces, remember to enclose
it in double quotes.

     

{title:Supported network types}

{pstd}
Binary: yes. Directed: yes. Weighted: yes. Signed: yes. Two-mode: yes - loads a network exactly as it was saved, independent of any of these properties.

{title:Examples}
        
{pstd}
This example creates 5 new random networks and {help nwsave:saves} them as {it:mynets}.A new dataset called {it:mynets.nwdta} is created in the working directory with the networks and all Stata variables.

        {cmd:. nwclear}
        {cmd:. nwrandom 20, ntimes(5) prob(.2)}
        {cmd:. nwsave mynets}
		{cmd:. nwclear}

{pstd}
One can bring the data back with:
	
        {cmd:. nwuse mynets}
		
{pstd}
This load the Florentine dataset from the internet and appends it to the existing data.

        {cmd:. nwwebuse florentine, nwappend}       
        
{title:See also}

        {help nwwebuse}, {help nwsave}, {help use}, {help nwappend}
