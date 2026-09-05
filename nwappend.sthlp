{smcl}
{* *! version 2.1  13may2019 author: Thomas Grund}{...}
{marker topic}
{helpb nwtopical##import:[NW-2.2] Import/Export}

{title:Title}

{p2colset 9 14 22 2}{...}
{p2col :nwappend {hline 2}}Append network dataset{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 15 2}
{cmdab:nwappend} {cmd:using} {it:{help filename}} [{cmd:,} {opt force}]

{pstd}
You may enclose {it:filename} in double quotes and must do so if
{it:filename} contains blanks or other special characters.

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt force}}if a network in {it:using dataset} has the same name as one already loaded, auto-renumber the incoming network to a fresh name instead of erroring (see {help:nwvalidate}) - leaves the existing network untouched, unlike {opt replace} elsewhere in this group (e.g. {help nwset}), which overwrites in place{p_end}
{synoptline}
{p2colreset}{...}


{marker description}{...}
{title:Description}

{pstd}
This command appends a Stata-format network dataset ({it:using dataset}) to the
currently loaded network data ({it:master dataset}). If a {it:{help filename}} is specified without an
extension, {cmd:.nwdta} is assumed.

{marker description}{...}

{title:Supported network types}

{pstd}
Binary: yes. Directed: yes. Weighted: yes. Signed: yes. Two-mode: yes - appends node-level Stata data from another dataset, independent of any of these properties.

{title:Remarks}

{pstd}
The command stops with an error when the same network names appear in the master and in the using
dataset unless option {bf:force} is used. This option causes changes the network names of the {it:using data} (see {help:nwvalidate}).

{pstd}
Node attributes are merged together. When the same nodes appear in both the {it:master} and the {it:using dataset}
with the same node attribute, the node attribute of the {it:using dataset} is used. 

{pstd}


{title:See also}

        {help nwuse}, {help nwwebuse}, {help nwsave}, {help append}

last certified : 24 Aug 2026
