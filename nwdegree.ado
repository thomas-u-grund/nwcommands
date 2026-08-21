/***
{smcl}
{* *!  4jul2016 author: Thomas Grund}{...}
{marker topic}
{helpb nw_topical##analysis:[NW-2.6] Analysis}

{title:Title}

{p2colset 9 17 22 2}{...}
{p2col :nwdegree {hline 2} Degree centrality and distribution}
{p2colreset}{...}


{title:Syntax}

{p 8 17 2}
{cmdab: nwdegree} 
[{it:{help netname}}]
[{cmd:,}
{opth alpha(real)}
{opt generate}({it:{help varlist:varlist}})
{opt replace}
{opt silent}
{opt isolates}
{opt standardize}
{opt in}({it:{help tabulate_oneway##tabulate1_options:tabulate_opt}})
{opt out}({it:{help tabulate_oneway##tabulate1_options:tabulate_opt}})
{it:{help tabulate_oneway##tabulate1_options:tabulate_opt}}
]

{synoptset 25 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt alpha}}Tuning parameter for valued networks; default = 0{p_end}
{synopt:{opt generate}({it:{help varlist}})}Generate variables for degree, outdegree, indegree, isolate{p_end}
{synopt:{opt replace}}Overwrite existing variables {it:varlist}{p_end}
{synopt:{opt silent}}Surpress output{p_end}
{synopt:{opt isolates}}Generate variable for network isolates{p_end}
{synopt:{opt standardize}}Divide degree or strength by N - 1{p_end}
{synopt:{opt in}({it:{help tabulate_oneway##tabulate1_options:tabulate_opt}})}Options for tabulating {it:indegree}{p_end}
{synopt:{opt out}({it:{help tabulate_oneway##tabulate1_options:tabulate_opt}})}Options for tabulating {it:outdegree}{p_end}
{synopt:{it:{help tabulate_oneway##tabulate1_options:tabulate_opt}}}Options for tabulating {it:degree}{p_end}
{synoptline}
{p2colreset}{...}


{title:Description}

{pstd}
{cmd:nwdegree} calculates the generalized degree centrality of the nodes as outlined in Opsahl et al (2010) for the (un-)weighted, (un-directed) networks in {help netlist} . By default, the command generates the Stata variables {it:_degree} 
for an undirected network. When the network is directed the command generates by default {it:_outdegree} and {it:_indegree} unless something else is specified in {opt generate()}. It also tabulates the newly generated variables.

{pstd}
Following Opsahl et al. (2010) the degree centrality C_i of node i is defined as:

{pmore}
{it:C_i = k_i * ( s_i / k_i ) ^ alpha}

{pstd}
where {it:k_i} is the number of ties that node {it:i} is involved in (regardless of tie values) and {it:s_i} is the sum of the tie values of these ties. When {it:alpha = 0} (default), this generalized
degree centrality gives the number of ties that a node has. When {it:alpha = 1}, it gives the node strength, i.e. the sum of the tie values that a node is involved in. For unvalued networks the
value of {it:alpha} does not matter. 

{pstd}
Option {bf:isolates} generates the variable {it:_isolate} that indicates if a node is an isolate (not connected to any
other node).

{pstd}
Option {bf:standardize} divides the centrality scores by N - 1, where N = number of nodes in a network.

{pstd}
{cmd:nwdegree} accepts a {help netlist} (e.g. {bf:nwdegree glasgow1 glasgow2}), calculating degree
centrality independently for each network in the list. When more than one network is given, the
default output variable names get the network's own name appended (e.g. {it:_degree_glasgow1},
{it:_degree_glasgow2}, or {it:_indegree_glasgow1}/{it:_outdegree_glasgow1} for a directed network);
a single-network call is unaffected and keeps the plain default names ({it:_degree}, or
{it:_indegree}/{it:_outdegree}) exactly as before. Explicit {opt generate()} names are suffixed the
same way when more than one network is processed. {bf:r()} results (e.g. {bf:r(dg_central)}) reflect
whichever network was processed last, matching this package's convention for other {help netlist}
commands.


{title:Supported network types}

{pstd}
Binary: yes. Directed: yes - generates separate {it:_indegree}/{it:_outdegree} (or {it:_instrength}/
{it:_outstrength} for a valued network) automatically. Weighted: {bf:W1}, native - the Opsahl et al.
(2010) generalized degree formula above is the command's default and only formulation, controlled
by {opt alpha()}; weight meaning is tie strength, used directly (not a distance). Signed: not
checked. Two-mode: not checked.


{title:References}

{pstd}
Tore Opsahl, Filip Agneessens, John Skvoretz (2010). Node centrality in weighted networks: Generalizing degree and shortest paths. {it:Social Networks} 32 (3), 245-251.


{title:Examples}

{pstd}This is the example used in Opsahl et al. (2010, Table 1):

	{com}. nwclear
	{com}. nwset, mat((.,4,4,0,0,0\
		4,.,2,1,1,0\
		4,2,.,0,0,0\
		0,1,0,.,0,0\
		0,1,0,0,.,7\
		0,0,0,0,7,.)) undirected labs(A, B, C, D, E, F)
{res}
	{com}. qui nwdegree, alpha(0)
	. qui nwdegree, alpha(0) generate(deg0)
	. qui nwdegree, alpha(.5) generate(deg0_5)
	. qui nwdegree, alpha(1) generate(deg1)
	. qui nwdegree, alpha(1.5) generate(deg1_5)

	. list deg*
{txt}
     {c TLC}{hline 6}{c -}{hline 11}{c -}{hline 6}{c -}{hline 11}{c TRC}
     {c |} {res}deg0      deg0_5   deg1      deg1_5 {txt}{c |}
     {c LT}{hline 6}{c -}{hline 11}{c -}{hline 6}{c -}{hline 11}{c RT}
  1. {c |} {res}   2           4      8          16 {txt}{c |}
  2. {c |} {res}   4   5.6568542      8   11.313708 {txt}{c |}
  3. {c |} {res}   2   3.4641016      6   10.392304 {txt}{c |}
  4. {c |} {res}   1           1      1           1 {txt}{c |}
  5. {c |} {res}   2           4      8          16 {txt}{c |}
     {c LT}{hline 6}{c -}{hline 11}{c -}{hline 6}{c -}{hline 11}{c RT}
  6. {c |} {res}   1   2.6457512      7    18.52026 {txt}{c |}
     {c BLC}{hline 6}{c -}{hline 11}{c -}{hline 6}{c -}{hline 11}{c BRC}

	
{pstd}
In the following example, the degree distributions for in- and outdegree are saved in Stata matrices {it:matindeg} and {it:matoutdeg}:

	{cmd:. nwwebuse glasgow}
	{cmd:. nwdegree glasgow1, in(matcell(matindeg)) out(matcell(matoutdeg))}
	{cmd:. mat list matindeg}
	
{pstd}
The next example saves the out- and indegree centrality in the variables {it:myout} and {it:myin} and the information about isolates in {it:myisolate}.

	{cmd:. nwdegree glasgow1, generate(myout myin mysiolate) isolates}
	
	
{title:See also}

   {help nwbetween}, {help nwcloseness}, {help nwcluster}, {help nwevcent}, {help nwkatz} 
***/

capture program drop nwdegree
program nwdegree
	version 9
	syntax [anything(name=netname)],[ replace standardize silent isolates alpha(real 0.0) GENerate(string) in(string) outputoff out(string) *]
	set more off

	// This command's own doc has always described netlist (multi-network)
	// behavior ("In case degree centrality is calculated for z networks
	// at the same time... the command generates the variables
	// _outdegree_z and _indegree_z for each network"), but the code
	// never actually implemented it: "nw_syntax ..., max(1)" capped the
	// argument to exactly one network, and what looked like the start of
	// a loop ("if networks > 1 { local k = 1 ... }") never actually
	// wrapped anything - the rest of the body ran once unconditionally
	// and referenced an undefined netname_temp local throughout. This
	// is exactly the "netname vs netlist" example NWCOMMANDS_COMMAND_
	// STYLE.md itself cites as the model case for genuine netlist
	// support (independent per-network degree calculation has obvious,
	// useful semantics), so this was finished rather than just
	// documented as unsupported. Single-network calls (still the common
	// case) are unaffected: default output variable names have no
	// suffix, exactly as before.
	nw_syntax `netname', max(9999)
	// The "networks" local gets clobbered by the inner nw_syntax call
	// below (which re-parses one network at a time and resets it to 1
	// each iteration) - capture the true total here, before the loop
	// starts, matching the convention already used elsewhere in this
	// package (e.g.
	// nwcomponents/nwcommunity check the "networks" local before
	// entering their own loops, not inside them).
	local totalnetworks = `networks'

	qui foreach netname_temp in `netname' {
		nw_syntax `netname_temp'

		// Plain degree has no meaningful definition on a two-mode
		// network's own square-matrix sense (every node's "neighbors"
		// are structurally confined to the opposite mode already, and
		// the natural normalisation differs by mode) - nwdegree used
		// to just silently compute it anyway, on whatever the raw
		// bipartite adjacency happened to contain, producing a
		// plausible-looking but meaningless number with no warning at
		// all (confirmed empirically before this fix - a real,
		// previously-undiscovered instance of exactly the "Category A"
		// silent-wrong-result gap this initiative's own audit was
		// looking for). Redirects to nw2degree instead, the same
		// already-established, already-tested pattern nwclustering.ado
		// uses for its own identical situation - not a warning about
		// anything wrong with the data, so styled as an ordinary
		// {txt} note rather than {err} (nwclustering's own version of
		// this message uses {err}, arguably inconsistent with "don't
		// call normal expected behaviour a warning"; not changed here
		// to avoid an unrelated, out-of-scope edit to that file).
		// nw2degree's own option set (generate()/replace/silent) is
		// smaller than nwdegree's one-mode-specific one
		// (alpha()/isolates/standardize/in()/out()/outputoff, none of
		// which have a bipartite equivalent) - forwarding only what
		// applies and naming explicitly, not silently, whatever was
		// requested but doesn't carry over.
		if "`is2mode'" == "true" {
			local ignored_opts ""
			if "`alpha'" != "0" local ignored_opts "`ignored_opts' alpha()"
			if "`isolates'" != "" local ignored_opts "`ignored_opts' isolates"
			if "`standardize'" != "" local ignored_opts "`ignored_opts' standardize"
			if "`in'" != "" local ignored_opts "`ignored_opts' in()"
			if "`out'" != "" local ignored_opts "`ignored_opts' out()"
			if "`outputoff'" != "" local ignored_opts "`ignored_opts' outputoff"
			noi di "{txt}note: `netname_temp' is a two-mode network - using {bf:nw2degree} instead."
			if "`ignored_opts'" != "" {
				noi di "{txt}      the following option(s) have no bipartite equivalent and were ignored:{bf:`ignored_opts'}"
			}
			noi nw2degree `netname_temp', generate(`generate') `replace' `silent'
			continue
		}

		tempvar included
		nw_datasync `netname_temp', generate(`included')
		local nodes_temp `nodes'

		tempname outdegree
		tempname indegree

		mata: `outdegree' = `netobj'->get_outdegree(`alpha')
		mata: `indegree' = `netobj'->get_indegree(`alpha')

		local netgenerate "`generate'"
		if "`isolates'" != "" & ("`netgenerate'" == "")  {
			local netgenerate "_isolates"
		}
		else if ("`directed'" == "true") {
			if "`netgenerate'" == "" {
				local netgenerate "_indegree _outdegree"
				if "`valued'" == "true" {
					local netgenerate "_instrength _outstrength"
				}
			}
		}
		else {
			if "`netgenerate'" == "" {
				local netgenerate "_degree"
				if "`valued'" == "true" {
					local netgenerate "_strength"
				}
			}
		}
		// Multi-network output naming, per NWCOMMANDS_COMMAND_STYLE.md's
		// established convention (basevar_<netname> suffix): only
		// applied when more than one network is actually being
		// processed, so a single-network call's output names are
		// unchanged from before this fix.
		if `totalnetworks' > 1 {
			local suffixed ""
			foreach onevar of local netgenerate {
				local suffixed "`suffixed' `onevar'_`netname_temp'"
			}
			local netgenerate "`suffixed'"
		}

		local _degree : word 1 of `netgenerate'
		local _indegree : word 2 of `netgenerate'
		local _outdegree : word 1 of `netgenerate'
		local _isolate: word 1 of `netgenerate'

		// BUGFIX: this whole per-network body runs inside the outer
		// "qui foreach netname_temp in `netname' { ... }" loop above, so
		// a plain "di" here was silently swallowed by that enclosing
		// qui - the user got nothing but a bare, unexplained r(99), with
		// no indication of which variable already existed or why (the
		// exact complaint this was found while diagnosing: nwplot's own
		// internal degree/isolates computation, elsewhere, left stale
		// _outdegree/_indegree/_isolates variables behind after a
		// compound "capture drop A B C D" silently failed in its
		// entirety - see nwplot.ado's own fix - and the next call to
		// generate those same names hit this guard with no visible
		// explanation at all). "noi" makes this diagnostic actually
		// reach the user, matching how every other user-facing message
		// in this same command body is already marked.
		//
		// Also fixed a separate, adjacent typo found in the same line:
		// this loop referenced `_isolates' (plural) which is never
		// defined anywhere - `_isolate' (singular, set two lines above)
		// is the real local - so the isolates target variable's own
		// existence was never actually checked here at all, silently
		// falling through to a bare "capture generate" later instead of
		// this guard's own clear error message.
		foreach c in `_degree' `_indegree' `_outdegree' `_isolate' {
			capture confirm variable `c', exact
			if _rc == 0 & "`replace'" == "" {
				noi di "{err}Variable {bf:`c'} already exists; use {bf:replace} or {bf:generate()}"
				err 99
			}
			capture drop `c'
		}

		if ("`directed'" == "false"){
			capture generate `_degree' = .
			mata: st_store((1,`nodes_temp'), "`_degree'", `outdegree')
		}
		else {
			capture generate `_outdegree' = .
			capture generate `_indegree' = .
			mata: st_store((1,`nodes_temp'), "`_outdegree'", `outdegree')
			mata: st_store((1,`nodes_temp'), "`_indegree'", `indegree')
		}

		if "`standardize'" != "" {
			capture replace `_degree' = `_degree' / (`nodes_temp' - 1)
			capture replace `_outdegree' = `_outdegree' / (`nodes_temp' - 1)
			capture replace `_indegree' = `_indegree' / (`nodes_temp' - 1)
		}

		if "`isolates'" != "" {
			capture generate `_isolate' = .
			sum `_isolate'
			if "`directed'" == "true" {
				replace `_isolate' = (`_outdegree' == 0) * (`_indegree'==0) if `included' == 1
			}
			else {
				replace `_isolate' = (`_degree' == 0)  if `included' == 1
			}
		}

		if "`silent'" == "" {
			noi di "{hline 40}"
			noi di "{txt}  Network name: {res}`netname_temp'"
			noi di "{hline 40}"
			if "`isolates'" == "" {
				noi di "{txt}    Degree distribution"
				if "`directed'" == "true"{
					noi tab `_indegree' if `included' == 1, `in'
					noi tab `_outdegree' if `included' == 1, `out'
				}
				else {
					noi tab `_degree' if `included' == 1, `options'
				}
			}
			else {
				noi di "{txt}    Isolates"
				noi tab `_isolate' if `included' == 1, `in'
			}
		}

		mata: st_rclear()

		if "`isolates'" == "" {
			if ("`directed'" == "false") {
				mata: st_numscalar("r(dg_central)", sum(J(`nodes_temp',1,max(`outdegree')) :- `outdegree') / ((`nodes_temp' - 2) * (`nodes_temp' - 1)))
				if "`silent'" == "" {
					noi di
					noi di "{txt}   Degree centralization:: {res}" + `=round(`r(dg_central)',0.001)'
				}
			}
			else {
				mata: st_numscalar("r(indg_central)", sum(J(`nodes_temp',1,max(`indegree')) :- `indegree') / ((`nodes_temp' - 1) * (`nodes_temp' - 1)))
				mata: st_numscalar("r(outdg_central)", sum(J(`nodes_temp',1,max(`outdegree')) :- `outdegree') / ((`nodes_temp' - 1) * (`nodes_temp' - 1)))
				if "`silent'" == "" {
					noi di
					noi di "{txt}   Indegree centralization:: {res}" + `=round(`r(indg_central)',0.001)'
					noi di "{txt}   Outdegree centralization:: {res}" + `=round(`r(outdg_central)',0.001)'
				}
			}
		}
		capture drop `included'
		mata: mata drop `outdegree' `indegree'
	}

end

