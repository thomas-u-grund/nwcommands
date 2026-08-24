{smcl}
{* *! 21dec2017 author: Thomas Grund}{...}
{marker topic}
{helpb nw_topical##manipulation:[NW-2.5] Manipulation}

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


{title:Also see}

   {help nwpreserve}, {help restore}, {help preserve}

