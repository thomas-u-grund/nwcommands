/***
{smcl}
{* *! version 2.0 author: Thomas Grund}{...}
{marker topic}
{helpb nw_topical##generator:[NW-2.3] Generators}
{marker top2}
{helpb nw_topical##manipulation:[NW-2.5] Manipulation}


{title:Title}

{p2colset 9 20 22 2}{...}
{p2col :nwtranspose {hline 2}}Transpose a network{p_end}
{p2colreset}{...}

{title:Syntax}

{p 8 17 2}
{cmdab: nwtranspose} 
[{it:{help netname}}]
[{cmd:,}
{cmd:generate}({it:{help newnetname}})
{opt name}({it:{help newnetname}})
{opt replace}]

{synoptset 25 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt generate}({it:{help newnetname}})}Save transpose as new network (alias: {opt name()}, matching the rest of this group){p_end}
{synopt:{opt replace}}if a network named {it:newnetname} already exists, drop it and use this name anyway{p_end}

{synoptline}
{p2colreset}{...}
	
{title:Description}

{pstd}
Simply transposes a network, i.e. a directed tie from node {it:i} to node {it:j} is transformed in a 
directed tie from node {it:j} to node {it:i}. By default, {cmd:nwtranspose} replaces a network, but you 
can specify that it should create a new network instead with {bf:generate()}. 



{title:Supported network types}

{pstd}
Binary: yes. Directed: yes - this command's entire purpose is transposing a network's adjacency matrix (a no-op for a genuinely symmetric undirected network). Weighted: yes, tie values are transposed along with tie presence. Signed: yes, values (including negative) are preserved as-is. Two-mode: not applicable - transposing a bipartite incidence structure would swap its two modes, which is exactly what {help nw2project} and the {help nw2toedge}/{help nw2fromedge} family are for instead.

{title:Examples}

	{com}. nwclear
	. nwrandom 5, prob(.3) name(net)
	{com}. nwsummarize net, matonly
	
	{res}     {txt}1   2   3   4   5
          {c TLC}{hline 21}{c TRC}
	1 {c |}  {res}0   0   1   0   0{txt}  {c |}
	2 {c |}  {res}1   0   0   0   0{txt}  {c |}
	3 {c |}  {res}0   0   0   1   0{txt}  {c |}
	4 {c |}  {res}1   1   0   0   1{txt}  {c |}
	5 {c |}  {res}0   0   1   0   0{txt}  {c |}
          {c BLC}{hline 21}{c BRC}

	{com}. nwtranspose net, generate(net_transp)
	{com}. nwsummarize net_transp, matonly
	
	{res}     {txt}1   2   3   4   5
          {c TLC}{hline 21}{c TRC}
	1 {c |}  {res}0   1   0   1   0{txt}  {c |}
	2 {c |}  {res}0   0   0   1   0{txt}  {c |}
	3 {c |}  {res}1   0   0   0   1{txt}  {c |}
	4 {c |}  {res}0   0   1   0   0{txt}  {c |}
	5 {c |}  {res}0   0   0   1   0{txt}  {c |}
          {c BLC}{hline 21}{c BRC}

***/

capture program drop nwtranspose
program nwtranspose
	version 9
	// Naming consistency (moderate-severity pass, generators_derived
	// group): every other command in this group (nwdyadprob/
	// nwhomophily/nwexpand/nwdissimilar/nwsimilar/nwsubset/nwshared)
	// uses `name()' to name a new output network; nwtranspose alone used
	// `generate()'. Added `name()' as a working alias, kept `generate()'
	// for backward compatibility.
	syntax [anything(name=netname)], [ generate(string) name(string) replace]
	if "`generate'" != "" & "`name'" != "" {
		di "{err}Specify only one of {bf:generate()} or {bf:name()} (they are the same option) - not both."
		error 198
	}
	if "`name'" != "" {
		local generate "`name'"
	}
	unw_defs

	nw_syntax `netname', max(1)
	local netobj1 `netobj'

	if ("`generate'" != ""){
		// BUGFIX: nwduplicate's own collision guard silently
		// auto-renames the DUPLICATE to `generate'_1 on a name
		// collision (leaving it as an orphaned, never-used stray
		// network), but this line still operated on the literal
		// string `generate' regardless - so `nw_syntax `generate''
		// below resolved to the ORIGINAL, pre-existing network of
		// that name (not the fresh duplicate), and the transpose then
		// silently overwrote ITS edge matrix in place. Fixed with the
		// same explicit "error unless replace" collision guard
		// nwsubset.ado's own generate()/name() option already uses,
		// rather than relying on nwduplicate's own silent auto-rename
		// (which nwduplicate itself doesn't even report back to the
		// caller - there is no way to recover the actual name used).
		capture nw_syntax `generate', other(_check)
		if _rc == 0 {
			if "`replace'" == "" {
				// Error-code coherence pass: consolidated onto
				// `errNWsExists' (483, unw_defs.ado) - see
				// nwsimmelian.ado's own fix for the history of this
				// convention's drift onto an undocumented `6099'.
				di "{err}Network {bf:`generate'} already exists. Use option {bf:replace} or specify a different {bf:generate()}."
				error `errNWsExists'
			}
			nwdrop `generate'
		}
		nwduplicate `netname', name(`generate')
		local netname `generate'
	}
	nw_syntax `netname', max(1)
	local netobj2 `netobj'
	
	mata: `netobj2'->set_edge((*`netobj1'->get_matrix())')
	
end
