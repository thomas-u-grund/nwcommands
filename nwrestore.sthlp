{smcl}
{* *! 21dec2017 author: Thomas Grund}{...}
{marker topic}
{helpb nwtopical##manipulation:[NW-2.5] Manipulation}

{title:Title}

{p2colset 9 15 22 2}{...}
{p2col :nwrestore {hline 2}}Restore network data previously preserved{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}{cmd:nwrestore}


{marker description}{...}
{title:Description}

{pstd}
{cmd:nwrestore} restores network data (including all normal Stata variables) previously saved by
{help nwpreserve:nwpreserve} - the network-aware counterpart of Stata's own {help preserve:preserve}/
{help restore:restore} pair. If nothing was preserved (or it was already restored once), {cmd:nwrestore}
reports "Nothing to restore" and does nothing further.

{pstd}
The temporary file {cmd:nwrestore} reads from is deleted once restored, so a given {help nwpreserve:nwpreserve}
call can only be restored once - exactly like Stata's own {help preserve:preserve}/{help restore:restore}.

{title:Examples}

{pstd}
Preserve a network, drop it, then restore it:

	{cmd:. nwclear}
	{cmd:. nwrandom 5, prob(.4) name(mynet)}
	{cmd:. nwpreserve}
	{cmd:. nwdrop mynet}
	{cmd:. nwset}
	{cmd:. nwrestore}
	{cmd:. nwset}

{title:Supported network types}

{pstd}
Binary: yes. Directed: yes. Weighted: yes. Signed: yes. Two-mode: yes - restores the full working state saved by {help nwpreserve}, independent of any of these properties.

{title:Also see}

   {help nwpreserve}, {help restore}, {help preserve}

