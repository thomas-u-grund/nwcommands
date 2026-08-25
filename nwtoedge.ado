/***
{smcl}
{* *! 12jul2016 author: Thomas Grund}{...}
{marker topic}
{helpb nw_topical##import:[NW-2.2] Import/Export}

{title:Title}

{p2colset 9 18 22 2}{...}
{p2col :nwtoedge {hline 2}}Convert network to edgelist{p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 17 2}
{cmdab: nwtoedge} 
[{it:{help netlist}}]
[{cmd:,}
{opth egovars(varlist)}
{opth altervars(varlist)}
{opth ego(newvarname)}
{opth alter(newvarname)}
{opth comparevars(varlist)}
{opt comparemode}({it:{help nwexpand##expand_mode:mode}})]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opth egovars(varlist)}}Keep attributes of sending nodes{p_end}
{synopt:{opth altervars(varlist)}}Keep attributes of receiving nodes {p_end}
{synopt:{opth ego(newvarname)}}Sender of ties; default = {it:_ego}{p_end}
{synopt:{opth alter(newvarname)}}Receiver of ties; default = {it:_alter}{p_end}
{synopt:{opth comparevars(varlist)}}Add an ego/alter comparison column for each variable (e.g. {it:same}, {it:dist}){p_end}
{synopt:{opt comparemode}({it:{help nwexpand##expand_mode:mode}})}Comparison used for {opt comparevars()}; default = {it:same}{p_end}
{synopt:{opt compress}}Compress edgelist{p_end}
{synopt:{opt full}}List both {it:(i,j)} and {it:(j,i)} for an undirected network's dyads, rather than only one entry per dyad; forced automatically whenever any network in a {help netlist} is directed{p_end}
{synopt:{opt upper}}List only one entry per undirected dyad (the default; see {opt full} above) - has no effect and is suppressed with a warning on a directed network{p_end}
{synopt:{opt numeric}}Return every possible node pair (a full node x node grid), not just actual ties; only allowed with a single network{p_end}
{synopt:{opt ignore2mode}}Treat a two-mode network like a one-mode one - suppress the mode indicator that would otherwise be added to {opt egovars()}/{opt altervars()} automatically{p_end}
{synopt:{opt isolates0}}reserved; not currently implemented{p_end}

{p2colreset}{...}


{title:Description}

{pstd}
{cmd:nwtoedge} makes an edgelist from a network or a list of networks. 

{pstd}
An edgelist of a single network {help netname} produced by {cmd:nwtoedge} is a set of three variables representing
the relations in the network. The first variable ({it:_ego}) gives the {help nodeid}
of the sending node {it:i} of a relationship; the second variable ({it:_alter}) gives the {help nodeid} of the 
receiving node {it:j}. Lastly, the variable {it:netname} saves information about the 
dyad pair ({it:i},{it:j}) in the network {it:netname}. 

{pstd}
When a network is undirected only one entry for the dyad pair ({it:i},{it:j})
is generated, unless option {opt full} is specified. 

{pstd}
When the command is used with a {help netlist}, it generates one new variable for each network {it:netname} in the list. If only one
of the networks in {help netlist} is directed, the option {opt full} is enforced.

{pstd}
One can also include node attributes (saved as normal Stata variables) in the edgelist. Option {opt egovars()} 
generates new variables that match the attributes of the sender of a tie (ego); option {opt altervars()} 
generates new variables that match the attributes of the receiver of a tie (alter).

{pstd}
For example, 

	{cmd:. nwwebuse glasgow1}
	{com}. nwtoedge glasgow1, egovars(sport1)
	{com}. list
{txt}
      {c TLC}{hline 9}{c -}{hline 7}{c -}{hline 10}{c -}{hline 13}{c TRC}
      {c |} {res}_ego    _alter    glasgow1   from_sport1 {txt}{c |}
      {c LT}{hline 9}{c -}{hline 7}{c -}{hline 10}{c -}{hline 13}{c RT}
   1. {c |} {res}      1       1          0       regular {txt}{c |}
   2. {c |} {res}      1       2          0       regular {txt}{c |}
   3. {c |} {res}      1       3          0       regular {txt}{c |}
   4. {c |} {res}      1       4          0       regular {txt}{c |}
   5. {c |} {res}      1       5          0       regular {txt}{c |}
      {c LT}{hline 9}{c -}{hline 7}{c -}{hline 10}{c -}{hline 13}{c RT}
   6. {c |} {res}      1       6          0       regular {txt}{c |}
		.....
      {c LT}{hline 9}{c -}{hline 7}{c -}{hline 10}{c -}{hline 13}{c RT}
  11. {c |} {res}      1      11          1       regular {txt}{c |}
  12. {c |} {res}      1      12          0       regular {txt}{c |}
  13. {c |} {res}      1      13          0       regular {txt}{c |}
  14. {c |} {res}      1      14          1       regular {txt}{c |}
  15. {c |} {res}      1      15          0       regular {txt}{c |}
      {c LT}{hline 9}{c -}{hline 7}{c -}{hline 10}{c -}{hline 13}{c RT}
		.....	  
	  
{pstd}
loads the {help netexample:Glasgow data} and transforms the network {it:glasgow1} in an edgelist. For example, {it:glasgow1[11] = 1} means,
that there is a network tie from node 1 to node 11. It also generates a new variable {it:from_sport1},
which holds in this case information about the attribute of the sender of a tie on the original variable {it:sport1}.				 

{pstd}
For two-mode networks see {help nw2set:introduction to two-mode networks}) and {help nw2toedge}.

{pstd}
The command can also transform two (or more) networks in edgelists at the same time. 

	{cmd:. nwtoedge glasgow1 glasgow2}
	
{pstd}
This generates a dataset with one variable for each network, {it:glasgow1} and {it:glasgow2}:

	{com}. list
{txt}
      {c TLC}{hline 9}{c -}{hline 7}{c -}{hline 10}{c -}{hline 10}{c TRC}
      {c |} {res}_ego    _alter    glasgow1   glasgow2 {txt}{c |}
      {c LT}{hline 9}{c -}{hline 7}{c -}{hline 10}{c -}{hline 10}{c RT}
   1. {c |} {res}      1       1          0          0 {txt}{c |}
   2. {c |} {res}      1       2          0          0 {txt}{c |}
   3. {c |} {res}      1       3          0          0 {txt}{c |}
   4. {c |} {res}      1       4          0          0 {txt}{c |}
   5. {c |} {res}      1       5          0          0 {txt}{c |}
      {c LT}{hline 9}{c -}{hline 7}{c -}{hline 10}{c -}{hline 10}{c RT}
   6. {c |} {res}      1       6          0          0 {txt}{c |}
   7. {c |} {res}      1       7          0          0 {txt}{c |}
   8. {c |} {res}      1       8          0          0 {txt}{c |}
   9. {c |} {res}      1       9          0          0 {txt}{c |}
  10. {c |} {res}      1      10          0          1 {txt}{c |}
      {c LT}{hline 9}{c -}{hline 7}{c -}{hline 10}{c -}{hline 10}{c RT}
  11. {c |} {res}      1      11          1          0 {txt}{c |}
  12. {c |} {res}      1      12          0          0 {txt}{c |}
  13. {c |} {res}      1      13          0          0 {txt}{c |}
  14. {c |} {res}      1      14          1          1 {txt}{c |}
  15. {c |} {res}      1      15          0          0 {txt}{c |}
 		.....

{pstd}
{opth comparevars(varlist)} adds an ego/alter {it:comparison} column for each listed variable,
alongside (not instead of) whatever {opt egovars()}/{opt altervars()} already add - e.g. "do ego
and alter share the same value" or "how far apart are their values", rather than just the two raw
values side by side. {opt comparemode()} picks which comparison (any {help nwexpand##expand_mode:
nwexpand mode} - {bf:same} (the default), {bf:dist}, {bf:absdist}, {bf:distinv}, {bf:absdistinv},
{bf:sender}, {bf:receiver}) applies to every variable in {opt comparevars()}; each variable is
internally expanded via {help nwexpand} itself (so the exact same, already-certified comparison
logic is used, not a reimplementation) and the resulting column is named {it:mode_varname} -
matching {help nwexpand}'s own default naming - e.g. {opt comparevars(sport1)} with the default
{bf:comparemode(same)} adds a column named {it:same_sport1}. {bf:dist}/{bf:distinv}/{bf:sender}/
{bf:receiver} comparisons are directional (ego's value relative to alter's, not the reverse), so
adding one automatically triggers the same "any directed network in the list forces {opt full}"
rule already used for a mixed directed/undirected {help netlist} - every dyad appears in both
directions, so the signed comparison is preserved correctly for both.

	{cmd:. nwwebuse glasgow, nwclear}
	{cmd:. nwtoedge glasgow1, comparevars(sport1) comparemode(same)}
	{cmd:. nwtoedge glasgow1, comparevars(sport1) comparemode(dist)}


{title:Supported network types}

{pstd}
Binary: yes. Directed: yes. Weighted: yes, tie values are carried into the edge list. Signed: not checked. Two-mode: yes - see {help nw2toedge} for the two-mode-specific counterpart, though this command's own {opt egovars()}/{opt altervars()} two-mode handling is used internally by several other commands directly on a two-mode network too.

{title:See also}
	
	{help nwfromedge}, {help nw2toedge}, {help nwsave}, {help nwexpand}

***/

capture program drop nwtoedge
program nwtoedge
	version 9
	syntax [anything(name=netname)][, isolates0 compress upper egovars(varlist) altervars(varlist) numeric ///
	ego(name) alter(name) full ignore2mode comparevars(varlist) comparemode(string)]

	unw_defs
	nw_syntax `netname', max(9999)
	local nets `netname'

	// comparevars()/comparemode(): ego/alter comparison columns (e.g.
	// "does this dyad share the same category?", "how far apart are
	// ego's and alter's values?") - the Stage 5 roadmap item this adds.
	// Rather than duplicating nwexpand's own same/dist/absdist/distinv/
	// absdistinv/sender/receiver vocabulary, each compare variable is
	// expanded into its own dyadic network via nwexpand itself (already
	// certified, unmodified), auto-named "`comparemode'_`var'" (nwexpand's
	// own default naming when name() is omitted) - then simply appended
	// to `nets', so every downstream step (the directed/full check, tie
	// extraction, merging) needs no changes at all: it already treats
	// every entry in `nets' identically regardless of where it came from.
	// dist()/distinv()/sender()/receiver() networks are directed by
	// construction (ego's value minus alter's is not alter's minus
	// ego's) - nwtoedge's own pre-existing "any directed network in the
	// list forces full" rule already handles this correctly with no
	// extra logic, giving both (i,j) and (j,i) rows so the signed
	// comparison is preserved in both directions.
	if "`comparevars'" != "" {
		if "`comparemode'" == "" {
			local comparemode "same"
		}
		// network(): without it, nwexpand falls back to its own generic
		// "n1".."nK" node labels instead of the actual network's labels -
		// silently breaking the (ego,alter) merge below, since it then
		// treats the comparison network's dyads as an entirely different
		// node set from every real network in `nets' (confirmed via a
		// direct probe: the merge produced the union of both label sets
		// instead of matching them, before this fix).
		local firstnet : word 1 of `netname'
		foreach cvar of varlist `comparevars' {
			qui nwexpand `cvar', mode(`comparemode') network(`firstnet') nodes(`nodes')
			local nets "`nets' `comparemode'_`cvar'"
		}
	}

	if "`ego'" == "" {
		local ego = "`nw_ego'"
	}
	if "`alter'" == "" {
		local alter = "`nw_alter'"
	}	

	foreach net in `nets' {
		nw_datasync `net'
	}
	
	// Deal with two-mode networks
	if "`is2mode'" == "true"  & "`ignore2mode'" == ""{
		local egovars "`nw_mode' `egovars'"
		local altervars "`nw_mode' `altervars'"
	}

	// Handle attributes of nodes
	qui if "`egovars'" != "" {
		preserve
		tempfile fromfile
		keep `nw_nodename' `egovars' 
		foreach var of varlist `egovars' {
			rename `var' `var'`ego'
		}
		save `fromfile'
		restore
	}
	
	qui if "`altervars'" != "" {
		preserve
		tempfile tofile
		keep `nw_nodename' `altervars'
		foreach var of varlist `altervars' {
			rename `var' `var'`alter'
		}
		save `tofile'
		restore
	}
	
	
	// Check if there is at least one directed network in the list
	qui foreach net in `nets' {
		nw_syntax `net'
		if "`directed'" == "true" {
			local full = "full"
		}
	}

	local i = 0
	qui foreach net in `nets' {
		nw_syntax `net'
		tempfile __nwedgelist`i'
		
		if "`upper'" != "" & "`directed'" == "true" {
			noi di "{txt}Warning! Network {res}`net'{txt} is directed. Option {res}upper{txt} surpressed." 
		}
		mata: __nwedgelist`i' = (`netobj'->get_edgelist((("`upper'" != "" | "`directed'" == "false") & "`full'" == "")))[,(1::5)]
		preserve
		drop _all
		tempvar include
		tempvar transp
		getmata (`ego' `alter' `net' `include' `transp') = __nwedgelist`i', force
		destring `include', replace force
		capture drop if `include' != 1
		capture drop `include'
		destring `net', replace force
		mata: mata drop __nwedgelist`i'
		save `__nwedgelist`i''
		restore
		local i = `i' + 1
	}
	
	local morethanone = `=`i' > 1'
	
	qui drop _all
	qui use `__nwedgelist0'

	qui forvalues j = 1/`=`i'-1' {
		merge m:n (`ego' `alter') using `__nwedgelist`j'', nogenerate
	}
	
	qui if trim("`egovars'") != "" {
		capture drop `nw_nodename'
		gen `nw_nodename' = `ego'
		merge m:n (`nw_nodename') using `fromfile', nogenerate 
	}
	qui if trim("`altervars'") != "" {
		capture drop `nw_nodename'
		gen `nw_nodename' = `alter'
		merge m:n (`nw_nodename') using `tofile', nogenerate 
	}
	qui capture drop `nw_nodename'
	sort `ego' `alter'
	qui if "`compress'" != "" {
		tempvar t
		gen `t' = 0
		foreach net in `nets' {
			replace `t' = `t' + abs(`net')
		}
		drop if `t' == 0
	}
	
	qui foreach net in `nets' {
		capture drop if `net' == `missing2'
	}
	
	if "`numeric'" != "" {
		if `morethanone' != 0 {
			// Was print-only (di "{err}...") with no `error' call, so
			// execution fell through into a plain node x node numeric grid
			// that no longer matched the multi-network merge already
			// performed above - the documented constraint was never
			// actually enforced. Package standard 198 (invalid syntax /
			// unsatisfied required-option combination, unw_defs.ado).
			di "{err}Programming option {bf:numeric} only allowed for one network."
			exit 198
		}
		drop `ego' `alter'
		
		mata: __nwedgelist = vec(J(`nodes',1,(1::`nodes'))), vec(J(1,`nodes',(1::`nodes'))')
		getmata (`ego' `alter') = __nwedgelist, force
		mata: mata drop __nwedgelist
	}

end	
