/***
{smcl}
{* *! 21dec2017 author: Thomas Grund}{...}
{marker topic}
{helpb nw_topical##manipulation:[NW-2.5] Manipulation}

{title:Title}

{p2colset 9 15 22 2}{...}
{p2col :nwpreserve {hline 2}}Preserve and restore network data{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

    Preserve network data

{p 8 17 2}{cmd:nwpreserve}


    Restore network data

{p 8 16 2}{cmd:nwrestore}


{marker description}{...}
{title:Description}

{pstd}
{cmd:nwpreserve} preserves network data by temporarily saving the current network dataset (including all normal Stata variables) in the working directory.

{pstd}
{cmd:nwrestore} restores network data previously preserved (including all Stata variables).


{title:Also see}
   
   {help restore}, {help preserve}

***/

capture program drop nwpreserve
program nwpreserve
	unw_defs
	capture nwsave `nw_tempfile', replace
	if _rc != 0 {
		di "{err}Cannot write to working directory.{txt}"
	}
end
