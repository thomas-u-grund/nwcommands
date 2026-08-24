/***
{smcl}
{* *! 12jul2016 author: Thomas Grund}{...}
{marker topic}
{helpb nw_topical##manipulation:[NW-2.5] Manipulation}

{title:Title}

{p2colset 9 14 22 2}{...}
{p2col :nwsym  {hline 2}}Symmetrize network{p_end}
{p2colreset}{...}

{title:Syntax}

{p 8 17 2}
{cmdab: nwsym} 
[{it:{help netname}}]
[{cmd:,}
{opt mode}({it:{help nwsym##mode:mode}})
{opt check}
{opth generate(newntename)}
{opt noreplace}]

{synoptset 25 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt mode}({it:{help nwsym##mode:mode}})}Logic for creating an undirected tie{p_end}
{synopt:{opt check}}Check if network is symmetric (regardless of whether is declared as directed or undirected){p_end}
{synopt:{opt generate}({it:{help newnetname}})}Save symmetrization as new network{p_end}
{synopt:{opt noreplace}}Do not symmetrize in place; requires {opt generate()} (errors otherwise, since there would be nothing else to do){p_end}

{p2colreset}{...}
{synoptset 20 tabbed}{...}
{marker mode}{...}
{p2col:{it:mode}}Description{p_end}
{p2line}
{p2col:{cmd: max}}Maximum of tie values (i,j) and (j,i); default
		{p_end}
{p2col:{cmd: min}}Minimum of tie values (i,j) and (j,i)
		{p_end}

{synoptline}
{p2colreset}{...}
	
{title:Description}

{pstd}
Symmetrizes a network and changes the meta-information of a network, i.e. it transforms a directed network in an undirected
network. The logic for this transformation is defined by {bf:mode()}. 

{pstd}
By default, an undirected tie is formed when there is either a tie from node {it:i} to node {it:j} or
a tie from node {it:j} to node {it:i}; {bf:mode(max)}. 

{pmore}
{it:M_ij = max( M_ij, M_ji )}

{pstd}
Alternatively, with {bf:mode(min)} an undirected tie is only formed when there are both ties from node {it:i} to
node {it:j} and a tie from node {it:j} to node {it:i}. 

{pmore}
{it:M_ij = min( M_ij, M_ji )}

{pstd}
When not specified otherwise, the network {help netname} is replaced with the symmetrized network. Option
In case {opt generate()} is specified the new symmetrized network is saved as {help netname:newnetname}.

{pstd}
Option {bf:check} tests if the underlying adjacency matrix of the network is symmetric (but does not 
symmetrize the network). Notice that this is 
independent of any meta-information saved together with the network (see {help nwname}). Hence, a network can be set as directed, but still be
symmetric. In contrast, all undirected networks are by default also symmetric.

{pstd}
The logic for valued networks works in exactly the same way. 



{title:Supported network types}

{pstd}
Binary: yes. Directed: yes - this command's entire purpose is converting a directed network to an undirected one (or checking whether it already is). Weighted: yes - {opt mode()} controls how the two directions' tie values are combined (e.g. max/min/sum) when they differ. Signed: not checked. Two-mode: not applicable - a bipartite network's own cross-mode structure has no "direction" to symmetrize in the first place.

{title:Examples}

{pstd}
This loads the Glasgow data and symmetrizes the network {it:glasgow1}. After that the originally directed network has become undirected.

	{cmd:. nwwebuse glasgow, nwclear}
	{cmd:. nwsym glasgow1}
	
	{cmd:. nwsym glasgow1, check}
	{res}{hline 50}
	{txt}   Network name: {res} glasgow1
	{txt}   Directed: {res}false
	{txt}   Symmetric: {res}true{txt}

	
{pstd}
This example only checks for symmetry, but does not change anything. Notice that by default {bf:nwrandom} produces a directed network. However,
a complete network (produced with {opt prob(1))}, where everybody is connected with everybody else, is also symmetric.
	
	{com}. nwrandom 10, prob(1)
	{com}. nwsym, check
	{res}{hline 50}
	{txt}   Network name: {res} network
	{txt}   Directed: {res}true
	{txt}   Symmetric: {res}true{txt}

	
{title:Stored results}

	Macros:
	  {bf:r(is_symmetric)}	"true" or "false"
	  {bf:r(name)}		name of the network
	 

***/

capture program drop nwsym
program nwsym
	version 9.0
	// `vars(string)' removed - it was accepted by syntax but never
	// referenced anywhere in this file's body (a fully dead,
	// undocumented no-op; confirmed via a direct probe).
	syntax [anything(name=netname)][, check generate(string) noreplace mode(string)]
	nw_syntax `netname', max(1)


	if "`check'" != "" {
		tempname __is_symmetric
		mata: st_numscalar("`__is_symmetric'", `netobj'->check_symmetry())
		if (`__is_symmetric' == 1) {
			mata: st_global("r(is_symmetric)", "true")
		}
		else {
			mata: st_global("r(is_symmetric)", "false")
		}
		mata: st_global("r(name)", "`netname'")
		di "{hline 50}"
		di "{txt}   Network name: {res} `netname'"
		di "{txt}   Directed: {res}`directed'"
		di "{txt}   Symmetric: {res}`r(is_symmetric)'"
		exit
	}

	// BUGFIX: `noreplace' was accepted by syntax but never referenced
	// anywhere in this file's body - a network was always symmetrized/
	// replaced in place when generate() was not given, regardless of
	// noreplace. Implemented its evidently-intended meaning: `noreplace'
	// without `generate()' has no non-destructive target to write to,
	// so it now errors clearly instead of silently doing the in-place
	// replace it was supposed to refuse. Per Stata's own "no"-prefixed
	// option convention, declaring a bare `noreplace' in `syntax'
	// populates a local named after the STEM - `replace' (holding
	// "noreplace" when passed, empty otherwise) - not `noreplace'
	// itself, which is never populated at all (the exact same trap
	// class fixed repeatedly elsewhere in this package - nwcloseness/
	// nwkatz/nwevcent/nwbetween).
	if "`replace'" != "" & "`generate'" == "" {
		di "{err}Option {bf:noreplace} requires {bf:generate()} - there would otherwise be nothing else to do."
		error 198
	}

	if "`mode'" == "" {
		local mode = "max"
	}

	// Consistency: was `nw_optsoneof' - the legacy, near-duplicate
	// validator this package has otherwise fully migrated away from
	// (23 other files, including this command's own sibling
	// nw2project.ado, already use `_opts_oneof'; nwsym.ado was the last
	// real caller of the old one).
	_opts_oneof "max min sum mean" "mode" "`mode'" 6555

	if ("`generate'" != ""){
		nwduplicate `netname', name(`generate')
		nw_syntax
		mata: `netobj'->symmetrize("`mode'")
	}
	else{
		nw_syntax `netname'
		mata: `netobj'->symmetrize("`mode'")
	}
	nwsync `netname'
end
