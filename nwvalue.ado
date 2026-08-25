/***
{smcl}
{* *! version 15jul2016 author: Thomas Grund}{...}
{marker topic}
{helpb nw_topical##analysis_other:[NW-2.6.7] Other Analysis Utilities}

{title:Title}

{p2colset 9 18 22 2}{...}
{p2col :nwvalue {hline 2}}Returns a tie value{p_end}
{p2colreset}{...}

{title:Syntax}

{p 8 17 2}
{cmdab: nwvalue} 
[{it:{help netname}}][,
{opt ego}({it:nodename})
{opt alter}({it:nodename})
{opth egoid(integer)}
{opth alterid(integer)}]


{title:Description}

{pstd}
The command returns the scalar {it:r(value)} with the value of the tie between the nodes {it:ego} and {it:alter} if those
nodes exists. It also returns the names of those nodes when ids are used. Either the option pair {bf:ego(), alter()} or {bf:egoid(), alterid()} need to be specified.

	  

{title:Supported network types}

{pstd}
Binary: yes. Directed: yes - the raw stored (row=ego, column=alter) cell is returned exactly as stored, respecting direction, never symmetrized. Weighted: yes, natively - returns the tie's own raw stored value. Signed: not checked; a negative value is returned as-is with no special handling. Two-mode: not checked, but not expected to need any - a direct single-cell lookup by node identity.

{title:Examples}

	{cmd:. nwwebuse florentine}
	{cmd:. nwvalue flobusiness, ego("medici") alter("pazzi")}
	{cmd:. nwvalue flobusiness, egoid(2) alterid(9)}
	{cmd:. return list}


{title:See also}
   
   {help nwreplace}
***/

capture program drop nwvalue
program nwvalue
	syntax [anything(name=netname)] [,egoid(integer 0) alterid(integer 0) ego(string) alter(string)]

	// support netname[egoid,alterid] shorthand, equivalent to egoid()/alterid()
	local bracketpos = strpos("`netname'","[")
	if (`bracketpos' != 0) {
		local closepos = strpos("`netname'","]")
		local sep = strpos("`netname'",",")
		local egoid = real(trim(substr("`netname'", `bracketpos' + 1, `sep' - `bracketpos' - 1)))
		local alterid = real(trim(substr("`netname'", `sep' + 1, `closepos' - `sep' - 1)))
		local netname = substr("`netname'", 1, `bracketpos' - 1)
	}

	mata: st_rclear()

	if (!(("`ego'" != "" & "`alter'" != "" ) | (`egoid' != 0 & `alterid' != 0))){
		di "{err}Either options {bf:ego(), alter()} or {bf:egoid(), alterid()} need to be specified."
		error 3000
	}
	nw_syntax `netname', max(1)
	if `"`ego'"' != "" {
		if `"`alter'"' != "" {
			// check that ego and alter are valid
			mata: st_numscalar("r(ego_valid)", `netobj'->has_node(`"`ego'"'))
			mata: st_numscalar("r(alter_valid)", `netobj'->has_node(`"`alter'"'))
			
			if `r(ego_valid)' != 1 {
				di "{err}node {it:`ego'} does not exist in network {bf:`netname'}"
				error 3000
			}
			if `r(alter_valid)' != 1 {
				di "{err}node {it:`alter'} does not exist in network {it:`netname'}"
				error 3000
			}
			
			capture mata: st_numscalar("r(ego_id)", select((1::`nodes'), (`netobj'->get_nodenames() :== "`ego'")'))
			capture mata: st_numscalar("r(alter_id)", select((1::`nodes'), (`netobj'->get_nodenames() :== "`alter'")'))
			capture mata: st_numscalar("r(value)",(*`netobj'->get_matrix())[`r(ego_id)', `r(alter_id)'])
			capture mata: st_global("r(ego)", "`ego'")
			capture mata: st_global("r(alter)", "`alter'")	
		}
	}
	if `egoid' != 0 & `alterid' != 0 & `egoid' <= `nodes' & `alterid' <= `nodes' {
			capture mata: st_numscalar("r(value)",(*`netobj'->get_matrix())[`egoid', `alterid'])
			capture mata: st_numscalar("r(ego_id)", `egoid')
			capture mata: st_numscalar("r(alter_id)", `alterid')
			capture mata: st_global("r(ego)", `netobj'->get_nodenames()[`r(ego_id)'])
			capture mata: st_global("r(alter)", `netobj'->get_nodenames()[`r(alter_id)'])	
	}
	di "`r(value)'"
end

