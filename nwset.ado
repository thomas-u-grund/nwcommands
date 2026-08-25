/***
{smcl}
{* *! 6jul2016 author: Thomas Grund}{...}
{marker topic}
{helpb nw_topical##import:[NW-2.2] Import/Export}

{title:Title}

{p2colset 9 17 23 2}{...}
{p2col :nwset {hline 2}}Declare data to be network data{p_end}
{p2colreset}{...}

{marker syntax}{...}
{title:Syntax}

{pstd}Declare data to be network data

{p 8 15 2}
{cmd:nwset} {it:{help varlist}} [, {it:options} ]

{p 8 15 2}
{cmd:nwset}
,
{opt mat}({it:matamatrix})
[ {it:options} ]

{pstd}Declare a two-mode network from an edgelist of two id variables (see {help nwset##twomode:below})

{p 8 15 2}
{cmd:nwset} {it:{help varname:mode1id}} {it:{help varname:mode2id}} [{it:{help varname:tievalue}}] {cmd:,} {opt twomode} [ {it:options} ]

{pstd}Declare a two-mode network from a Mata matrix or a wide affiliation-matrix {help varlist} (see {help nwset##twomode:below})

{p 8 15 2}
{cmd:nwset} [{it:{help varlist}}] {cmd:,} {opt bipartite} [{opt mat}({it:matamatrix})] [ {it:options} ]

{pstd}Declare a temporal network from an edgelist (see {help nwset##temporal:below})

{p 8 15 2}
{cmd:nwset} {it:{help varname:fromid}} {it:{help varname:toid}} [{it:{help varname:tievalue}}] {cmd:,} {opt time(varname)} [ {it:options} ]

{p 8 15 2}
{cmd:nwset} {it:{help varname:fromid}} {it:{help varname:toid}} [{it:{help varname:tievalue}}] {cmd:,} {opt interval(startvar endvar)} [ {it:options} ]

{p 8 15 2}
{cmd:nwset} {it:{help varname:fromid}} {it:{help varname:toid}} {cmd:,} {opt eventtime(varname)} [ {it:options} ]


{pstd}Display currently existing networks

{p 8 15 2}
{cmd:nwset}


{pstd}Display more details about existing networks

{p 8 15 2}
{cmd:nwset, detail}


{pstd}Clear all networks (but keep Stata variables)

{p 8 15 2}
{cmd:nwset, clear}


{pstd}Clear all networks and Stata variables

{p 8 15 2}
{cmd:nwset, nwclear}


{synoptset 25 tabbed}{...}
{synopthdr}
{synoptline}

{synopt:{opt edgelist}}Declare data in edgelist format{p_end}
{synopt:{opt bipartite}}Declare a two-mode network from a Mata matrix or a wide affiliation-matrix {help varlist} (see {help nwset##twomode:Declare a two-mode network} below){p_end}
{synopt:{opt twomode}}Declare a two-mode network from an edgelist of two (or three, for a valued network) id variables (see {help nwset##twomode:Declare a two-mode network} below){p_end}
{synopt:{opt directed}}Force network to be directed{p_end}
{synopt:{opt undirected}}Force network to be undirected{p_end}
{synopt:{opt name}({it:{help newnetname}})}Name of the new network; default = {it:network}{p_end}
{synopt:{opt labs}({it:lab1, lab2,...})}Node labels{p_end}
{synopt:{opth labsfromvar(varname)}}Use information in varname as node labels{p_end}
{synopt:{opt xvars}}Generate Stata variables for the network{p_end}
{synopt:{opt keeporiginal}}Generate variable {it:_nodeoriginal} with original node id's (when setting from an edgelist){p_end}
{synopt:{opth time(varname)}}Declare a snapshot temporal network - each row's own time value (see {help nwset##temporal:Declare a temporal network} below){p_end}
{synopt:{opt interval(startvar endvar)}}Declare an interval temporal network - each row active for start<=t<end (see {help nwset##temporal:Declare a temporal network} below){p_end}
{synopt:{opth eventtime(varname)}}Declare an event temporal network - each row a timestamped event, not a persistent tie (see {help nwset##temporal:Declare a temporal network} below){p_end}


{title:Description}

{pstd}
This command declares data to be network data (it is very similar to {help xtset} or {help stset}). When networks are 
{help nwimport:imported} or {help nwuse:used} or loaded from the {help nwwebuse:internet} or created from
an {help nwfromedge:edgelist} or created by any other {help nw_topical##generator:network generator}, {bf:nwset} is automatically
invoked. But one can also explicitly declare data to be network data. 

{pstd}
Networks ultimately exist as objects in Mata. Once a network is declared one can interact with it from Stata by referring
to its {help netname}. In practice, this works just as if one would refer to a {help varname} in other commands. The
command sets a new network by assigning it an adjacency matrix. It can also be used to assign various meta-information
to the network.

{pstd}
An adjacency matrix is a simple representation of a network. The adjaceny matrix {it:M} of a one-mode network
has the dimensions {it:nodes} x {it:nodes}. The matrix cell {it:M_ij} = 0 when there is no tie between nodes {it:i}
and {it:j}. In binary networks, {it:M_ij} = 1 when there is a network relationship between nodes {it:i} and {it:j}.
However, networks can also be valued, i.e. {it:M_ij} > 1; in undirected networks {it:M_ij = M_ji}.

{pstd}
The command automatically recognizes if the network is unvalued (only has values 0, 1 or missing) or valued.

{pstd}
There are three ways to explicitly declare data to be network data:

{pstd}
{bf:{ul:1. Declare adjacency matrix from variables}}

{pstd}
Declare the variables in {help varlist} to represent the adjacency matrix of the network. In this case a
{help varlist} (var_1, var_2,..., var_z) needs to be given. Each variable is assumed to stand for one column in the adjacency matrix. 

{pmore}
{it:M_ij = var_i[j]}

{pstd}
When there are more observations {it:n} than variables {it:z}, only the the first {it:z} observations of each variable are considered. When
there are more variables than observations, then only the first {it:n} variables are considered as network data.

{pstd}
In this dummy example, we create 5 new variables v1-v5 and set a network from these variables. It creates an empty network (there 
are no ties).

	{cmd:. nwclear}
	{cmd:. forvalues i = 1/5} {
	{cmd:     gen v`i' = 0}
	{cmd:  }}
	{cmd:. nwset v*}

{pstd}
After that we can display the networks that have been set (see also {help nwsummarize} or {help nwds})

	{cmd:. nwset, detail}
	{hline 50}
	{txt} 1) Current Network
	{hline 50}
	{txt}   Network name: {res}network
	{txt}   Directed: {res}true
	{txt}   Nodes: {res}5
	{txt}   Network id: {res}1
	{txt}   Variables: {res}v1 v2 v3 v4 v5
	{txt}   Labels: {res}v1 v2 v3 v4 v5{txt}

{pstd}
There is exactly one network. When neither {bf:name()}, {bf:vars()}, or {bf:labs()} are specified, the command comes up with 
a suggestion to fill this meta-information.	


{pstd}
{bf:{ul:2. Declare edgelist from variables}}

{pstd}
In this case, the command interprets the variables {help varlist} as egdelist (see {help nwfromedge}). 

{pstd}
An edgelist or arclist is a set of two (or three in the case of a valued network) variables representing
relations. Nodes are identified by entries in the cells.  For example, the data

                 {c TLC}{hline 14}{c -}{c TRC}
                 {c |} {res} fromid  toid {txt}{c |}
                 {c LT}{hline 14}{c -}{c RT}
              1. {c |} {res} 1       2    {txt}{c |}
              2. {c |} {res} 2       3    {txt}{c |}
              3. {c |} {res} 4       2    {txt}{c |}
                 {c BLC}{hline 14}{c -}{c BRC}

{pstd}
stores information about three {it:ties} (1=>2), (2=>3) and (4=>2) among four unique network nodes. The
variables defining the edges can also be {help string} variables. 

                 {c TLC}{hline 25}{c -}{c TRC}
                 {c |} {res} fromid    toid     value{txt}{c |}
                 {c LT}{hline 25}{c -}{c RT}
              1. {c |} {res} Peter     Thomas   1    {txt}{c |}
              2. {c |} {res} Tim       Peter    3    {txt}{c |}
              3. {c |} {res} Mathilde  Thomas   2    {txt}{c |}
                 {c BLC}{hline 25}{c -}{c BRC}

{pstd}
Here, there are also three relationships: (Peter => Thomas), (Tim => Peter) and (Mathilde => Thomas).

{pstd}
The following command declares such data as network data and gives the new network the name {it:mynet}:

	{cmd:. nwset fromid toid value, name(mynet) edgelist}


{pstd}
{bf:{ul:3. Declare adjacency matrix from Mata matrix}}

{pstd}
Set a network from a {it:nodes x nodes} Mata matrix that holds the adjacency matrix of the new network. The option
{bf:mat()} is specified with the name of an existing Mata matrix.

{pstd}
For example, this generates a Mata matrix:

	{cmd:. nwclear}
	{cmd:. mata: net = (0,1,0,0\1,0,0,1\1,1,0,0\1,1,1,0)}
	{cmd:. nwset, mat(net) name(network)}

{pstd}
This also generates a network called {it:network}. When no {bf:name()} for a network is specified, the command makes a valid suggestion (see {help nwvalidate}).
	
{pstd}
Now a network called {it:network} exists and we can interact with it. For example, we can get a summary of the network:
	
	{com}. nwsummarize network, mat
	{res}{hline 50}
	{txt}   Network name: {res} network
	{txt}   Network id: {res} 1
	{txt}   Directed: {res}true
	{txt}   Nodes: {res}4
	{txt}   Arcs: {res}8
	{txt}   Minimum value: {res} 0
	{txt}   Maximum value: {res} 1
	{txt}   Density: {res} .6666666666666666
             {txt}1   2   3   4
          {c TLC}{hline 17}{c TRC}
	1 {c |}  {res}0   1   0   0{txt}  {c |}
	2 {c |}  {res}1   0   0   1{txt}  {c |}
	3 {c |}  {res}1   1   0   0{txt}  {c |}
	4 {c |}  {res}1   1   1   0{txt}  {c |}
          {c BLC}{hline 17}{c BRC}


{marker twomode}{...}
{pstd}
{bf:{ul:4. Declare a two-mode network}}

{pstd}
A two-mode (bipartite) network has two distinct sets of nodes ("modes"), with ties running only
{it:between} the two sets, never within either one - e.g. people and the organisations they belong
to. Two-mode status is stored directly on the network object itself (queryable via
{help nwsummarize} or {help nwname}'s own {bf:r(mode2)}/{bf:r(nodes1)}/{bf:r(nodes2)} results), the
same as directed/valued/selfloop status - there are two ways to declare one, matching the two input
shapes {bf:nwset} already supports for one-mode networks:

{pstd}
{bf:twomode} - from an edgelist of two (or three, for a valued network) id variables, one row per
tie, directly analogous to {bf:edgelist} above. This is generally the more natural form when the
data already looks like a list of affiliations:

	{cmd:. nwclear}
	{cmd:. use "https://raw.githubusercontent.com/thomas-u-grund/nwcommands/develop/data/institutions.dta", clear}
	{cmd:. nwset person institution, twomode name(mynet)}

{pstd}
This also automatically sets each mode's own human-readable description from the variable names
used ({it:person}/{it:institution} here - see {bf:r(mode1desc)}/{bf:r(mode2desc)} in
{help nwname}/{help nwsummarize}), and (if {bf:xvars} is given) generates a {it:_mode} variable
holding each node's own mode ("1" for persons, "2" for institutions - see {help nw2fromedge} for the
full option set this delegates to internally, including {bf:name()}/{bf:xvars}/{bf:keeporiginal}).
{bf:twomode} cannot be combined with {bf:bipartite} - they declare two different input shapes (an
edgelist of ties vs. a wide affiliation matrix, below) that cannot be told apart from a bare
{help varlist} alone, so combining them is rejected as an explicit error rather than guessed at.

{pstd}
{bf:bipartite} - from a Mata matrix, or from a {help varlist} interpreted as a {it:wide} affiliation
matrix (each named variable is one mode-1 node, each observation is one mode-2 node) - the two-mode
analogue of the plain adjacency-matrix forms in sections 1 and 3 above:

	{cmd:. nwclear}
	{cmd:. mata: net = (1,1,0\1,0,1\0,1,1)}
	{cmd:. nwset, mat(net) bipartite name(mynet)}

{pstd}
Here {bf:net} is a 3 (mode 1) x 3 (mode 2) matrix - {bf:bipartite} tells {bf:nwset} the matrix's own
columns are mode-1 nodes and its rows are mode-2 nodes, rather than treating it as an ordinary square
one-mode adjacency matrix.

{pstd}
Ordinary {bf:nw*} commands inspect a network's own two-mode status and behave accordingly rather
than requiring a separate command family for bipartite data - see each command's own help file for
whether it has a native bipartite definition, works on the raw bipartite structure directly, requires
an explicit projection (see {help nw2project} - {bf:nwset} and the rest of the package never project
automatically), or does not support two-mode data at all.


{marker temporal}{...}
{bf:{ul:5. Declare a temporal network}}

{pstd}
Time belongs to edges/ties, not to a separate network copy per timepoint. An edgelist can carry a
temporal dimension via exactly one of three options - {bf:time()}, {bf:interval()}, or
{bf:eventtime()} - matching three distinct semantics that are never conflated:

{p 8 12 2}{bf:time({it:timevar})}{p_end}
{p 12 12 2}{bf:snapshot} semantics: each row's own {it:timevar} value is the single instant that tie
was recorded (e.g. a wave number). Ties from different waves live in the same network object, each
carrying its own recorded time{p_end}
{p 8 12 2}{bf:interval({it:startvar endvar})}{p_end}
{p 12 12 2}{bf:interval} semantics: each row is active for {it:startvar} <= {it:t} < {it:endvar} - a
missing {it:endvar} means the tie is still ongoing (open-ended){p_end}
{p 8 12 2}{bf:eventtime({it:eventtimevar})}{p_end}
{p 12 12 2}{bf:event} semantics: each row is a timestamped relational {it:event}, not a persistent
tie - e.g. a message sent at a particular instant. Event data is never silently treated as an
ordinary graph{p_end}

{pstd}
For example, this declares a snapshot network from three waves of ties:

	{cmd:. nwset ego alter, time(wave) name(mynet)}

{pstd}
A temporal network is otherwise a completely ordinary {bf:nwset}-declared network - {help nwsummarize}
shows its temporal metadata, and {help nwattime} produces an ordinary static network containing only
the ties active at a given timepoint, usable with any {bf:nw*} command exactly like any other network.

{pstd}
{bf:time()}/{bf:interval()}/{bf:eventtime()} cannot currently be combined with {bf:twomode}/
{bf:bipartite} in the same call - a genuine composability gap (a two-mode temporal network) tracked in
docs/ROADMAP.md, not yet supported. This is deliberate groundwork only, per the package's own stated
scope: no full temporal-network modelling subsystem (dynamic centrality, relational-event models,
temporal ERGMs) is implemented or attempted here.



{title:Supported network types}

{pstd}
This command is the primary mechanism by which a network's own binary/directed/weighted/signed/two-mode status is declared in the first place ({opt directed}/{opt undirected}, {opt valued}/{opt unvalued}, {opt bipartite}/{opt twomode}), rather than a command whose own behavior varies by a pre-existing network's type. Signed values (negative ties) are accepted and stored as-is, not validated or rejected.

{title:Remarks}

{pstd}
The command {bf:nwset} or {bf:nwset, detail} without a {help varlist} or {bf:mat()} option, give a list of all
networks that do currently exist in memory. A similar overview is provided by {help nwds} (which is very similar to {help ds}).

{pstd}
Although not really needed, networks can be represented with Stata variables (see {help nwload}). For this purpose, each network
holds some meta-information about which Stata variables should be created when a network is loaded in such a way. This meta-information
can be set wit option {bf:vars()}. When specified, it needs to have as many entries as there are nodes in the network. When not specified, 
the program automatically makes a suggestion for variable names. 

{pstd}
By default, network generators (including {cmd:nwset} itself) only produce a network object - they do NOT load a network as Stata
variables (see {help nwload}). Many network generators allow the option {bf:xvars}, which ADDITIONALLY loads the new network as Stata
variables right away (equivalent to following the generator with a separate {help nwload} call). Leaving {bf:xvars} unspecified keeps
Stata's own variable budget free when one deals with many or large networks - all commands that require a {help netname} still work
even when no Stata variables for that network exist at all, or after {bf: drop _all}. This also means that one can still deal with
larger networks even when using {bf:Small Stata}.

{pstd}
Each node in a network also has a node label. This is a unique name for each node. This meta-information can be set with
option {bf:labs()}. As before, there need to be as many entries as there are nodes in the network. When not specified, the program
automatically labels nodes according the variables that have been set.
	
{pstd}
Whenever a network is set with {bf:nwset}, it is also made the {help nwcurrent:current network}. The current network is always 
the network that has been most recently loaded or generated. Many nwcommands allow that a {help netname} or a {help netlist} is
optional. In case no network is given, all nwcommands generally refer to the current network.

{pstd}
Programmers can use {bf:nwset} to write their own import routines  (see also {help nwimport}) for different network
file formats that are not natively supported by the {bf:nwcommands}.All you need to do is transform your data either in
an adjacency list or an edgelist represented by Stata variables. 

{title:See also}

	{help nodeid}, {help nwname}, {help nwds}, {help nwload}, {help nwvalidate}, {help nwsummarize}, {help nw2fromedge}, {help nw2project}, {help nwattime}, {help nw_intro##limits:feasible network sizes}
***/

capture program drop nwset	
program nwset
syntax [varlist (default=none)][, valued unvalued nodenames(string) overwrite REPLACE bipartite TWOmode biprownames(varname) selfloop labs(string) vars(string) keeporiginal xvars clear nwclear nooutput edgelist name(string) labsfromvar(string) edgelabs(string asis) detail mat(string) undirected directed time(varname) interval(varlist min=2 max=2) eventtime(varname)]
// `overwrite' was declared here but never actually connected to any
// check anywhere in this file (confirmed directly: it was the ONLY
// occurrence of the word in the whole file) - a network name
// collision has always silently auto-picked a different valid name
// via nw_validate below and warned, regardless of whether `overwrite'
// was given. `replace' is the real, now-wired option (matching this
// package's own naming convention elsewhere, e.g. nwgenerate's
// `replace'); `overwrite' is kept as a backward-compatible alias for
// any existing caller already passing it (it did nothing before, so
// no prior behavior is lost by finally giving it one).
if "`overwrite'" != "" local replace "replace"

	// twomode is a genuinely different declaration shape from
	// bipartite, not a synonym for it - bipartite (long-established,
	// left completely unchanged) takes a Mata matrix or a *wide*
	// affiliation-matrix varlist (each named variable is one mode-1
	// node, each observation is one mode-2 node); twomode instead
	// takes exactly the same "two (or three, for a valued network) ID
	// variables, one row per tie" edgelist shape nwset's own one-mode
	// edgelist option already uses (see edgelist below) - the two-mode
	// analogue of it, and the literal syntax requested when this
	// option was added: nwset person organisation, twomode. That exact
	// shape already existed as the separate nw2fromedge command
	// (unchanged, still directly callable, and still what this
	// delegates to internally - not reimplemented a second time here)
	// - twomode's only job is making it reachable through nwset itself
	// too, matching how nwfromedge is reachable both directly and via
	// nwset's own edgelist option. Kept as a clearly distinct option
	// name (not folded into bipartite) specifically to avoid any
	// ambiguity between "these variables are wide-format mode-1 nodes"
	// and "these variables are a two-column edgelist" - the two shapes
	// cannot be told apart from the variable list alone.
	if "`twomode'" != "" & "`bipartite'" != "" {
		di "{err}options {bf:twomode} and {bf:bipartite} cannot be combined - they declare two different input shapes (an edgelist of ties vs. a wide affiliation matrix); use whichever one matches your data."
		error 198
	}
	if "`twomode'" != "" {
		if "`time'" != "" | "`interval'" != "" | "`eventtime'" != "" {
			di "{err}combining temporal declaration ({bf:time}/{bf:interval}/{bf:eventtime}) with {bf:twomode}/{bf:bipartite} in the same call is not yet supported - declare the two-mode network first, then use {help nwattime} once composability lands (see docs/ROADMAP.md)."
			error 198
		}
		if "`varlist'" == "" {
			di "{err}option {bf:twomode} requires exactly two (or three, for a valued network) variables: the mode-1 id, the mode-2 id, and optionally a tie value."
			error 198
		}
		local twomode_nvars : word count `varlist'
		if `twomode_nvars' < 2 | `twomode_nvars' > 3 {
			di "{err}option {bf:twomode} requires exactly two (or three, for a valued network) variables; got `twomode_nvars'."
			error 198
		}
		if "`name'" == "" {
			local name "network"
		}
		// nwset's own syntax line takes no [if] qualifier at all (see
		// above) - a bare "if ..." after the comma would already have
		// been rejected by the "syntax" command itself, before this
		// code ever runs, so none is threaded through here.
		nw2fromedge `varlist', name(`name') `xvars' `keeporiginal'
		exit
	}
	// Temporal metadata declaration (two-mode/temporal architecture
	// initiative, Part II) - groundwork only: distinguishes snapshot
	// (time()), interval (interval()), and event (eventtime())
	// semantics per the user's own specification, storing per-edge
	// time value(s) alongside the ordinary edgelist topology rather
	// than pretending a network has no temporal dimension at all.
	// Composability with twomode/bipartite is intentionally NOT
	// attempted in this pass (tracked in docs/ROADMAP.md) - errors
	// clearly below rather than silently doing something wrong.
	if "`time'" != "" | "`interval'" != "" | "`eventtime'" != "" {
		local ntemporal_opts = ("`time'" != "") + ("`interval'" != "") + ("`eventtime'" != "")
		if `ntemporal_opts' > 1 {
			di "{err}options {bf:time}, {bf:interval}, and {bf:eventtime} are mutually exclusive - a network has exactly one temporal semantics (snapshot, interval, or event)."
			error 198
		}
		if "`twomode'" != "" | "`bipartite'" != "" {
			di "{err}combining temporal declaration ({bf:time}/{bf:interval}/{bf:eventtime}) with {bf:twomode}/{bf:bipartite} in the same call is not yet supported - declare the two-mode network first, then use {help nwattime} once composability lands (see docs/ROADMAP.md)."
			error 198
		}
		if "`varlist'" == "" {
			di "{err}declaring temporal metadata requires an edgelist varlist: {it:ego alter} [{it:value}]."
			error 198
		}
		local temporal_nvars : word count `varlist'
		if `temporal_nvars' < 2 | `temporal_nvars' > 3 {
			di "{err}temporal edgelist declaration requires exactly two (or three, for a valued network) variables; got `temporal_nvars'."
			error 198
		}
		if "`name'" == "" {
			local name "network"
		}

		local ego : word 1 of `varlist'
		local alter : word 2 of `varlist'
		local ivstart ""
		local ivend ""
		if "`time'" != "" {
			confirm numeric variable `time'
		}
		if "`eventtime'" != "" {
			confirm numeric variable `eventtime'
		}
		if "`interval'" != "" {
			local ivstart : word 1 of `interval'
			local ivend : word 2 of `interval'
			confirm numeric variable `ivstart' `ivend'
		}

		// Resolve ego/alter to the exact string LABELS nwfromedge
		// (called below) will end up using as node names, mirroring
		// its own top-of-file numeric/string harmonization exactly
		// (see nw2fromedge.ado's near-identical comment for the fuller
		// explanation of why this must match: numeric-only pairs get
		// an "n"-prefix, mixed numeric/string pairs do not) - captured
		// as Mata state (survives past nwfromedge's own internal
		// dataset manipulation, unlike Stata variables) before calling
		// it, then used afterward to resolve each row's node-label
		// pair to indices by LABEL, not position.
		capture confirm numeric variable `ego'
		local egonumeric = (_rc == 0)
		capture confirm numeric variable `alter'
		local alternumeric = (_rc == 0)
		tempvar egolab alterlab
		if `egonumeric' & `alternumeric' {
			qui gen `egolab' = "n" + strofreal(`ego')
			qui gen `alterlab' = "n" + strofreal(`alter')
		}
		else if `egonumeric' & !`alternumeric' {
			qui gen `egolab' = strofreal(`ego')
			qui gen `alterlab' = trim(`alter')
		}
		else if !`egonumeric' & `alternumeric' {
			qui gen `egolab' = trim(`ego')
			qui gen `alterlab' = strofreal(`alter')
		}
		else {
			qui gen `egolab' = trim(`ego')
			qui gen `alterlab' = trim(`alter')
		}

		tempname __lab1 __lab2 __tval __tval2
		mata: `__lab1' = st_sdata(., "`egolab'")
		mata: `__lab2' = st_sdata(., "`alterlab'")
		// `__tval2' is only actually populated on the interval() branch
		// below - given a harmless placeholder value here unconditionally
		// so the unconditional (non-capture) cleanup drop near the end of
		// this block always has something real to drop. An earlier
		// version used `capture mata: mata drop `__tval2'' instead,
		// which is the wrong fix: capture swallows the "not found" error
		// on the time()/eventtime() branches (where `__tval2' was never
		// created) but leaves Stata's own `_rc' polluted with that
		// failure's return code, since nothing runs afterward to reset
		// it - so the CALLER of nwset would see a stray nonzero _rc even
		// though nwset itself succeeded. Found via a direct probe: the
		// exact same nwset call reported _rc==0 under `set trace on'
		// (trace happens to touch _rc as a side effect) but _rc==111
		// without it - a real, confusing bug, not a flaky test.
		mata: `__tval2' = J(0,1,.)
		if "`time'" != "" {
			mata: `__tval' = st_data(., "`time'")
		}
		if "`eventtime'" != "" {
			mata: `__tval' = st_data(., "`eventtime'")
		}
		if "`interval'" != "" {
			mata: `__tval' = st_data(., "`ivstart'")
			mata: `__tval2' = st_data(., "`ivend'")
		}

		qui nwfromedge `varlist', name(`name') `xvars' `keeporiginal' `undirected' `replace'
		nw_syntax `name'
		mata: st_local("symmetric", strofreal(!(`netobj'->is_directed_boolean())))

		if "`time'" != "" {
			mata: `netobj'->set_edge_time(build_edge_value_matrix(`netobj'->get_nodenames(), `__lab1', `__lab2', `__tval', `symmetric'))
			mata: `netobj'->set_temporal_type("snapshot")
			mata: `netobj'->set_timevar("`time'")
		}
		else if "`eventtime'" != "" {
			// event ties are NOT folded into the ordinary edge matrix
			// at all - raw sender/receiver/eventtime triplets only,
			// resolved to node indices here so eventlist() consumers
			// don't have to repeat the label lookup - see unw_core.do's
			// own comment on `eventlist' for the full rationale (this
			// package must not silently pretend a raw event stream is
			// an ordinary persistent-tie graph). build_eventlist() is a
			// standalone Mata function (unw_core.do), not an inline
			// for-loop here, after confirming (during the unit-41
			// mode-assignment fix) that Stata's one-line interactive
			// `mata:' command form does not reliably parse a for-loop
			// with a braced multi-statement body.
			mata: `netobj'->set_eventlist(build_eventlist(`netobj'->get_nodenames(), `__lab1', `__lab2', `__tval'))
			mata: `netobj'->set_temporal_type("event")
			mata: `netobj'->set_eventtimevar("`eventtime'")
		}
		else {
			mata: `netobj'->set_edge_interval(build_edge_value_matrix(`netobj'->get_nodenames(), `__lab1', `__lab2', `__tval', `symmetric'), build_edge_value_matrix(`netobj'->get_nodenames(), `__lab1', `__lab2', `__tval2', `symmetric'))
			mata: `netobj'->set_temporal_type("interval")
			mata: `netobj'->set_startvar("`ivstart'")
			mata: `netobj'->set_endvar("`ivend'")
		}
		mata: `netobj'->set_temporal(1)
		mata: mata drop `__lab1' `__lab2' `__tval' `__tval2'
		exit
	}
	set more off
	unw_defs

	// `clear'/`nwclear' used to `exit' unconditionally, even when the
	// same call also carried a creation request (a non-empty varlist -
	// edgelist/twomode/bipartite/temporal forms - or mat()). That made
	// e.g. "nwset ego alter, edgelist name(mini) nwclear" silently wipe
	// the registry and return without ever creating "mini" - nwset
	// itself reported no error, since from its own point of view it
	// successfully executed the "clear" form; the failure only
	// surfaced later, when something else referenced "mini" and hit
	// the emptied registry (a confusing "type mismatch:
	// exp.exp: transmorphic found where struct expected" instead of a
	// clean "network not found"). The .sthlp only documents clear/
	// nwclear as standalone forms, but nothing in the syntax line
	// stopped a caller from combining one onto a creation call as a
	// natural "clear anything old, then set this" shorthand. Now only
	// exits early when clearing is the ONLY thing being requested;
	// otherwise the clear happens as a side effect BEFORE the
	// `nws_create()' step below (not after - `nwclear' itself drops
	// the whole `nw' Mata registry object, so running it after
	// `nws_create()' had already built a fresh one would immediately
	// destroy it again) and execution falls through into the normal
	// creation path. Combining `nwclear' with a varlist-based creation
	// form (edgelist/twomode/temporal) is not made to work by this fix
	// - `nwclear' wipes the Stata dataset those forms read their own
	// source columns from, so the two are inherently in tension; that
	// combination surfaces as an ordinary "variable not found"-style
	// error now instead of a silent no-op, which is the actual bug
	// this fixes. `mat()' is unaffected (its input is a Mata
	// expression, not dataset columns) and works correctly combined
	// with either `clear' or `nwclear'.
	if "`clear'" != "" & "`varlist'`mat'" == "" {
		// `nwdrop' has never accepted a `netonly' option (confirmed
		// directly: `nwdrop.ado's own syntax line only declares
		// `clean') - this call has always errored ("option netonly not
		// allowed", r(198)), meaning `nwset, clear' was completely
		// broken before this fix, not merely a corner case. Plain
		// `nwdrop _all' already does exactly what `clear' is
		// documented to do (drop all networks, leave the Stata dataset
		// untouched) - confirmed directly - so `netonly' was pure
		// vestigial cruft, not a missing feature to add.
		nwdrop _all
		exit
	}
	if "`nwclear'" != "" & "`varlist'`mat'" == "" {
		nwclear
		exit
	}
	if "`clear'" != "" {
		// same fix as the standalone-form branch above (`netonly' was
		// never a real nwdrop option).
		nwdrop _all
	}
	if "`nwclear'" != "" {
		nwclear
	}

	capture mata: `nw'
	if (_rc != 0) {
		if ("`varlist'" != "" | "`mat'" != ""){
			mata: `nw' = nws_create()
		}
	}

	if "`edgelist'" != "" {
		local labsfromvar ""
	}

	local numnets = 0
	mata: st_rclear()
	local max_nodes = 0
	local allnames ""
	
	qui if "`edgelist'" != "" {
		qui nwfromedge `varlist', name(`name') `xvars' `keeporiginal' `undirected' `replace'
		exit
	}
	
	// display information about network
	if ("`varlist'" == "" & "`mat'" == "") {
		capture mata: `nw'
		if _rc == 0 {
			mata: st_numscalar("r(networks)", `nws'.get_number())
			mata: st_global("r(nets)", `nws'.get_names())
			if  ("`output'" == "") {
				di "{txt}(`r(networks)' networks)"
				di "{hline 20}"
				forvalues  i = 1/`r(networks)' {
					local onename : word `i' of `r(nets)'
					di "      {res}`onename'"
				}
			}
		}
		else {
			di "{txt}(0 networks)"
			mata: st_numscalar("r(networks)", 0)
			mata: st_global("r(nets)", "")	
		}
		exit
	}
	
	// set a new network
	else {
		tempname __nwnew
		tempname __nwnodenames
		tempname __modes

		// Captured BEFORE the "network" default below, so the
		// collision check right after can tell an explicit name(foo)
		// apart from an unspecified one - only an explicit, caller-
		// chosen name is held to the create/replace convention used
		// elsewhere in the package (nwgenerate's own `replace' guard);
		// letting the anonymous "network"/"network_1"/... default keep
		// auto-numbering on collision matches nwfromedge's own
		// documented behavior for the same unspecified-name case and
		// is not something the caller expressed any intent about.
		local name_given = ("`name'" != "")

		if "`name'" == "" {
			local name "network"
		}

		nw_validate `name'
		if "`r(exists)'"=="true" {
			if "`replace'" != "" {
				// keep the caller's own requested name and drop the
				// existing network under it first, rather than
				// switching to an auto-generated alternative name -
				// this is the only place that name collision is
				// actually decided, so this is the one place `replace'
				// needs to hook in. nwdrop itself drops the whole `nw'
				// Mata registry object once the last network is gone
				// (confirmed directly in nwdrop.ado) - if the network
				// being replaced was the only one registered, the
				// creation path below would otherwise find no `nw' to
				// register the replacement into, so it is rebuilt here
				// exactly the same way the top of this program already
				// does when `nw' does not yet exist at all.
				nwdrop `name'
				capture mata: `nw'
				if (_rc != 0) mata: `nw' = nws_create()
			}
			else if `name_given' {
				// An explicit name(foo) collision must not silently
				// diverge to foo_1 - that left "foo" itself untouched
				// while the caller's later references to "foo" kept
				// hitting stale data, exactly the silent-destructive-
				// operation trap the create/replace convention exists
				// to prevent. Errors instead, matching nwgenerate's own
				// message shape for the same situation.
				// Error-code coherence pass: consolidated onto
				// `errNWsExists' (483, unw_defs.ado) - see
				// nwsimmelian.ado's own fix for the history of this
				// convention's drift onto an undocumented `6099'.
				di "{err}Network `name' already exists. Specify option {bf:replace} to overwrite it."
				error `errNWsExists'
			}
			else {
				di "{txt}Warning! Switched to netname {res}`r(validname)'{txt} because {res}`name'{txt} already in use."
				local name = r(validname)
			}
		}

		// set network from varlist
		if ("`varlist'" != "") {
			mata: `__nwnew' = check_bipartite(st_data(.,"`varlist'"), "`bipartite'")
			mata: `__modes' = J(rows(`__nwnew'), 1, 2)
			
			if "`bipartite'"  != "" {
				local mode1 : word count `varlist'
				mata: `__modes'[(1::`mode1'),1] = J(`mode1', 1, 1)
			}
			mata: `__modes'=strofreal(`__modes')'
		}
		
		// set network from mata matrix
		if ("`mat'" != "") {
			// mat() has always evaluated its own argument as a bare
			// Mata expression - a literal expression like `(0,1\1,0)'
			// parses directly as an anonymous Mata matrix constant
			// regardless, but a bare NAME referring to an existing
			// STATA matrix does not auto-import into Mata (Mata has no
			// such convenience) - confirmed directly: `matrix define X
			// = (0,1\1,0)' then `nwset, mat(X)' failed with "X not
			// found" (r(3499)) before this fix. Every existing internal
			// caller of `nwset, mat(...)' in this package happens to
			// always pass either a literal expression or an existing
			// MATA variable name (both already work, since Mata
			// variables ARE directly usable as bare expressions) -
			// only a genuine Stata matrix name was ever unsupported.
			// Detected via `confirm matrix', then copied into Mata
			// explicitly via `st_matrix()' first; a literal expression
			// or Mata variable name fails `confirm matrix' harmlessly
			// (it is not a valid/existing Stata matrix name) and falls
			// through to the original, unchanged behavior.
			capture confirm matrix `mat'
			if _rc == 0 {
				tempname __nwmatcopy
				mata: `__nwmatcopy' = st_matrix("`mat'")
				local mat "`__nwmatcopy'"
			}
			mata: mode1 = cols(`mat')
			mata: st_local("mode1", strofreal(mode1))
			mata: `__nwnew' = check_bipartite(`mat',"`bipartite'")
			mata: `__modes' = J(cols(`__nwnew'), 1, 2)
			mata: `__modes'[(1::mode1),1] = J(mode1, 1, 1)
			mata: `__modes'=strofreal(`__modes')'
		}
				
		// generate nodenames if not specified
		if "`varlist'" != "" {
			local labs = ""
			foreach var of varlist `varlist' {
				local labs = "`labs'`var',"
			}
		}

		local notvalid 0
		
		if "`labs'" != "" & "`labsfromvar'" == "" {
			mata: `__nwnodenames' = (get_nodenames_from_string(`"`labs'"', rows(`__nwnew'),"`cDftNodepref'"))'
		}
		if "`labsfromvar'" != "" {
			capture tostring `labsfromvar', replace
			if "`bipartite'" == "" {
				mata: `__nwnodenames' = (st_sdata((1::rows(`__nwnew')),"`labsfromvar'"))'
			}
			else {
				mata: `__nwnodenames' = (st_sdata(.,"`labsfromvar'"))'
			}
			
			if("`varlist'" != "" & "`bipartite'" != ""){
				mata: `__nwnodenames' = (tokens("`varlist'"),`__nwnodenames')
			}
			if("`varlist'" != "" & "`bipartite'" == ""){
				mata: `__nwnodenames' = `__nwnodenames'[(1::rows(`__nwnew'))] 
			}
			if("`mat'" != "") {
				mata: `__nwnodenames' = (J(rows(`__nwnew'),1,"`cDftNodepref'") + get_node_suffix(rows(`__nwnew')))'
			}
			
			mata: st_local("notvalid", strofreal(cols(`__nwnodenames') != cols(`__nwnew')))
		}

		if (("`labs'" == "" & "`labsfromvar'" == "") | `notvalid' != 0) {
			mata: `__nwnodenames' = (J(rows(`__nwnew'),1,"`cDftNodepref'") + get_node_suffix(rows(`__nwnew')))'
		}
		
		mata: st_rclear()
		mata: st_numscalar("r(networks)", `nws'.get_number())
		mata: st_global("r(names)", `nws'.get_names())
		mata: `nws'.add("`name'")
		
		nw_syntax `name'
		mata: `netobj'->create_by_name(`__nwnodenames')
		mata: `netobj'->set_name("`name'")
		mata: `netobj'->set_edge(`__nwnew')
		mata: `netobj'->set_directed("`undirected'" == "")
		mata: `netobj'->set_selfloop("`selfloop'" == "selfloop")
	
		if "`nodenames'" != "" {
			mata: `netobj'->set_nodenames(`nodenames')
		}

		// vars() lets a caller explicitly name the Stata variables
		// nwload will later materialize this network into, overriding
		// update_nodesvar()'s own auto-derived-from-node-names default
		// (called internally by create_by_name() above). Documented
		// since at least this file's own doc header ("can be set wit
		// option vars()"), but the option itself had been silently
		// dropped from this syntax line at some point - confirmed via
		// direct probe that nwlattice.ado's own `` nwset, vars(...) ``
		// call crashed with "option vars() not allowed" before this
		// fix, the actual root cause behind nwlattice's own long-open
		// Pending item (previously misdiagnosed as a missing
		// nwvalidvars.ado, which turned out to be a red herring - see
		// docs/CERTIFICATION.md).
		if "`vars'" != "" {
			mata: st_local("nwsetvarsnodes", strofreal(rows(`__nwnew')))
			local varscount : word count `vars'
			if `varscount' != `nwsetvarsnodes' {
				di "{err}option {bf:vars()} needs to have as many entries as there are nodes in the network ({bf:`nwsetvarsnodes'})."
				error 6070
			}
			mata: `netobj'->set_nodesvar(tokens("`vars'"))
		}

		if "`undirected'" != "" | "`bipartite'" != "" {
			nwsym `name'
		}

		if "`bipartite'" != "" {
			mata: `netobj'->set_2mode(1)
			mata: `netobj'->set_modes(`__modes')
			mata: `netobj'->set_nodes_mode1(`mode1')
		}
		
		// check if network is valued or not
		mata: `netobj'->set_valued(`netobj'->check_valued())
		
		nw_datasync
	}
	
	 capture mata: mata drop mode1
	 capture mata: mata drop `__modes'
	 capture mata: mata drop `__nwnew' 
	 capture mata: mata drop `__nwnodenames'
end

capture mata: mata drop check_bipartite()
capture mata: mata drop get_2mode_edge()

// get_node_suffix()/get_nodenames_from_string()/get_nodenames_from_var()
// moved to unw_core.do (sparse-backend migration, nwfromedge.ado's own
// rewiring) - shared with nwfromedge.ado's sparse-native construction,
// which cannot safely depend on this file's own Mata block having
// already been loaded first. This file's own callers below are
// unaffected - the functions are still callable by the same names,
// just defined in the always-loaded core file now instead of here.

mata:
real matrix get_2mode_edge(real matrix edge){
	real scalar r, c, n
	real matrix edge2
	
	r = rows(edge)
	c = cols(edge)
	n = r + c
	
	edge2 = J(n,n, .)
	edge2[((c + 1)::n), (1::c)]= edge
	edge2[(1::c),((c+1)::n)] = edge'
	return(edge2)
}


real matrix check_bipartite(real matrix edge, string scalar bip){
	real scalar m

	if (bip == "bipartite"){
		edge = get_2mode_edge(edge)
	}
	else {
		m = min((rows(edge), cols(edge)))
		edge = edge[(1::m),(1::m)]
	}
	return(edge)
}
end
