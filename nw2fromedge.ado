/***
{smcl}
{* *! version 4jul2016 author: Thomas Grund}{...}
{marker topic}
{helpb nw_topical##import:[NW-2.2] Import/Export}

{title:Title}

{p2colset 9 19 22 2}{...}
{p2col :nw2fromedge {hline 2}}Import two-mode network data from edgelist{p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 17 2}
{cmdab: nw2fromedge} 
{it:{help varname:level1}}
{it:{help varname:level2}}
[{it:{help varname:tievalue}}]
[{it:{help if}}]
[{cmd:,}
{it:{help nwfromedge:nwfromedge_options}}
]

{p2colreset}{...}

{title:Description}

{pstd}
{cmd:nw2fromedge} imports a two-mode network from a dataset in edgelist format. It is very similar to {help nwfromedge}. 

{pstd} 
A two-mode network consists of two sets of units (e. g. people and events) and relations connect the two sets, e. g. participation
of people in social events. Some examples are: 

{pmore}
- Membership in institutions - people, institutions, is a member, e.g. directors and commissioners on the boards of corporations.

{pmore}
- Voting for suggestions - polititians, suggestions, votes for.

{pmore}
- Citation network, where first set consists of authors,
the second set consists of articles/papers,
connection is a relation author cites a paper.

{pmore}
- Co-autorship networks - authors, papers, is a (co)author.
A corresponding graph is called bipartite graph – lines
connect only vertices from one to vertices from another set –
inside sets there are no connections.


{marker edgelist}{...}
{pstd}
An edgelist is a set of two (or three in the case of a valued network) variables representing
relations. Nodes are identified by entries in the cells.  For example, the data

	{com}. use "https://raw.githubusercontent.com/thomas-u-grund/nwcommands/master/data/institutions.dta", clear
	{com}. list _all
	{txt}
		{c TLC}{hline 10}{c -}{hline 11}{c -}{hline 7}{c TRC}
		{c |} {res}  person   institu~n   years {txt}{c |}
		{c LT}{hline 10}{c -}{hline 11}{c -}{hline 7}{c RT}
	     1. {c |} {res}  Thomas      Oxford       5 {txt}{c |}
	     2. {c |} {res}   Peter      Oxford       7 {txt}{c |}
	     3. {c |} {res}     Tim      Oxford       4 {txt}{c |}
	     4. {c |} {res}   Peter         LiU       1 {txt}{c |}
	     5. {c |} {res}     Tim         LiU       1 {txt}{c |}
		{c LT}{hline 10}{c -}{hline 11}{c -}{hline 7}{c RT}
	     6. {c |} {res}  Thomas         LiU       1 {txt}{c |}
	     7. {c |} {res}Mathilde        UdeM       5 {txt}{c |}
	     8. {c |} {res}  Thomas        UdeM       1 {txt}{c |}
	     9. {c |} {res} Michael         ETH       3 {txt}{c |}
	    10. {c |} {res} Michael   Groningen       5 {txt}{c |}
		{c LT}{hline 10}{c -}{hline 11}{c -}{hline 7}{c RT}
	    11. {c |} {res}  Thomas         ETH       1 {txt}{c |}
		{c BLC}{hline 10}{c -}{hline 11}{c -}{hline 7}{c BRC}

{pstd}
stores information about the affiliation of individual researchers.  

{pstd}
The following command declares such data as two-mode network data:

	{cmd:. nw2fromedge person institution, name(mynet)}
					
{pstd}
Besides setting the network, this also creates a new variable {it:_nwmode}, which has the value 1 for persons (Peter, Tim,
Thomas, Michael, Mathilde) and value 2 for institutions (LiU, UdeM, Oxford, ETH, Groningen).

{pstd}
{help nwplot} has no bipartite-specific logic of its own, so nodes are {bf:not} colored by mode
automatically; pass the {it:_nwmode} variable this command creates to {opt color()} (or
{opt symbol()}) explicitly to tell the two node sets apart at a glance:

	{cmd:. nwplot mynet, color(_nwmode)}

{marker project_stat}{...}
{marker project_level}{...}

{title:Supported network types}

{pstd}
Two-mode: **T1**, native - this command's entire purpose is building a two-mode network directly from an edge list (ego/alter columns drawn from two distinct node sets). Binary: yes. Directed: not applicable - two-mode ties are inherently undirected affiliations. Weighted: yes, via a third edge-list column. Signed: not checked.

{title:One-mode projection}

{pstd}
Sometimes one wants to collapse a two-mode network to a one-mode network (see {help nw2project}). This is called a one-mode projection. Such a projection is a simplification of the network to nodes
of one level only. For example, in our example one can either collapse to the level of persons or to the level of institutions. The level to which one wants to collapse is
specified in option {bf:project()}. 

{pstd}
For example, this loads the data above as a one-mode projection on level 1 (persons):

	{cmd: nw2project mynet, project(1) name(myproject1)}

{pstd}
This generates a network {it:myproject1} with five unique actors (Peter, Tim, Thomas, Michael and Mathilde). By default, a one-mode projection
on one level generates ties between nodes (on this level) when they have at least one network neighbor on the 
other level in common. In our case, projecting to the level of persons creates ties between persons when they share
at least one institution. By default, such a one-mode projection is a valued network, where the
tie values indicate how many institutions individuals share. To illustrate this, 
let us consider the relationship between Peter and Thomas. In this example, they share
two institutions: Oxford and LiU.

{pmore}
Thomas - LiU

{pmore}
Peter  - LiU

{pmore}
Thomas - Oxford

{pmore}
Peter  - Oxford

{pstd}
A one-mode projection to the level of persons generates a tie between Thomas and Peter with value 2, because
they share two institutions. A one-mode projection to the level of institutions would generate a tie
with value 2 between the institutions Oxford and LiU, because they share two persons (Peter and Thomas).

{pstd}
When ties in the original network are valued there are several ways how the value of projected ties is generated. Option {opt stat()} can
be one of the following: {bf:min, max, minmax, sum, mean}. To illustrate what each one of them calculates tie values for
the projection, let us consider the relationship between Peter and Thomas. They share two institutions: Oxford and LiU.

{pmore}
Thomas - LiU    - 1 year

{pmore}
Peter  - LiU    - 1 year

{pmore}
Thomas - Oxford - 5 years

{pmore}
Peter  - Oxford - 7 years

{pstd}
The option {bf:stat(min)} takes the overall minimum from all these ties and generates the projection:

{pmore}
Peter - Thomas  - 1 year

{pstd}
The option {bf:stat(max)} takes the overall maximum from all these ties and generates the projection:

{pmore}
Peter - Thomas  - 7 years

{pstd}
The option {bf:stat(sum)} takes the sum over all these ties and generates the projection:

{pmore}
Peter - Thomas  - 14 years

{pstd}
The option {bf:stat(mean)} takes the sum over all these ties and generates the projection:

{pmore}
Peter - Thomas  - 3.5 years

{pstd}
The option {bf:stat(minmax)} takes for each institution Peter and Thomas share the minimum (Oxford = 5, LiU = 1) and 
and takes the maximum out of these scores as tie value. Substantially, this corresponds to the 
longest time that Peter and Thomas were at the same institution. This is the default option. 

{pmore}
Peter - Thomas  - 5 years
 
	
{title:Also see}
	
	{help nwfromedge}, {help nw2project}, {help nw2set}

***/

capture program drop nw2fromedge
program nw2fromedge
	syntax varlist(min=2 max=3) [if] [, xvars * ]
	
	local group1 : word 1 of `varlist'
	local group2 : word 2 of `varlist'
	local value : word 3 of `varlist'
	
	// Check if the same numbers are used for the two modes
	capture confirm numeric variable `group1'
	qui if _rc == 0 {
		capture confirm numeric variable `group2'
		if _rc == 0 {
			qui sum `group1'
			local g1min = r(min)
			local g1max = r(max)
			qui sum `group2'
			local g2min = r(min)
			local g2max = r(max)
			if (`g1max' >= `g2min') {
				replace `group2' = `group2' + `g1max'
			}
		}
	}
	
	// Check if the same strings are used for the two modes
	capture confirm string variable `group1'
	qui if _rc == 0 {
		capture confirm string variable `group2'
		tempfile g1 
		tempfile g2
		preserve
		keep `group1'
		rename `group1' id
		save `g1'
		restore
		preserve
		keep `group2'
		rename `group2' id
		merge m:n id using `g1'
		sum _merge
		restore
		
		// Same name used for both mode 1 and mode 2, need to distinguish
		if `r(max)' == 3 {
			replace `group1' = "m1_" + `group1'
			replace `group2' = "m2_" + `group2'
		}
	}
	
	
	preserve
	unw_defs

	tempfile dic1
	tempvar temp
	tempname modes
	tempname group1labels

	// BUGFIX: node modes must be assigned by which of the two edgelist
	// variables (group1 vs group2) a node's label actually came from -
	// not by node *position*. nwfromedge (called below) numbers nodes by
	// sorting the *combined* set of labels from both variables together
	// (see its own use of "stack `fromvar' `tovar' ... sort ... egen
	// _nodeid = group(...)"), so group1's labels and group2's labels end
	// up interleaved in node-index order whenever they don't happen to
	// sort into two separate alphabetical blocks - not a rare edge case,
	// just any dataset where a mode-2 label alphabetically precedes a
	// mode-1 label (e.g. persons "Peter"/"Thomas"/"Tim" and institutions
	// "LiU"/"Oxford" - "LiU" and "Oxford" both sort before "Peter").
	// Confirmed empirically: the old code's "the first `mode1' nodes are
	// group1" assumption silently mislabeled the modes of a plain
	// 3-person/2-institution example this way. Fixed by recording
	// group1's actual distinct label set here (Mata state survives the
	// upcoming preserve/restore, unlike the dataset) and, once the
	// network's own node order is known, assigning each node's mode by
	// direct label lookup instead of by position.
	//
	// Node labels aren't always the raw variable values verbatim: when
	// both edgelist variables are numeric, nwfromedge (below) builds
	// final node labels as "n" + the numeric value (see its own
	// `rawtype' == "numeric" branch) rather than the bare number - the
	// label set collected here must match that exactly, or every
	// membership lookup below would silently fail to match and every
	// node would fall back to the "2" default.
	capture confirm numeric variable `group1'
	local group1numeric = (_rc == 0)
	capture confirm numeric variable `group2'
	local group2numeric = (_rc == 0)

	keep `group1'
	gen `temp' = 1
	collapse (mean) `temp', by(`group1')
	if `group1numeric' & `group2numeric' {
		tempvar group1lab
		gen `group1lab' = "n" + strofreal(`group1')
		mata: `group1labels' = st_sdata(., "`group1lab'")
	}
	else {
		mata: `group1labels' = st_sdata(., "`group1'")
	}
	qui count
	local mode1 = r(N)
	restore

	qui nwfromedge `group1' `group2' `value' `if', `options' `xvars' undirected
	nw_syntax

	mata: `modes' = modes_from_labels(`netobj'->get_nodenames(), `group1labels')'
	mata: `netobj'->set_2mode(1)
	mata: `netobj'->set_modes(`modes')
	mata: `netobj'->set_description_mode1("`group1'")
	mata: `netobj'->set_description_mode2("`group2'")
	mata: `netobj'->clean_matrix_2mode()

	nw_syntax
	nw_datasync
	capture order `nw_nodename' `nw_mode'
	
end



