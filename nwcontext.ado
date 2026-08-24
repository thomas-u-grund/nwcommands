/***
{smcl}
{* *! version 2.0.0  10sept2016 author: Thomas Grund}{...}
{marker topic}
{helpb nw_topical##analysis_other:[NW-2.6.7] Other Analysis Utilities}

{title:Title}

{p2colset 9 19 22 2}{...}
{p2col :nwcontext {hline 2}}Create a context variable{p_end}
{p2colreset}{...}

{title:Syntax}

{p 8 17 2}
{cmdab: nwcontext} 
[{it:{help netname}}]
{cmd:,}
{opth attribute(varname)}
[{opt stat}({it:{help nwcontext##statistic:statistic}})
{opt mode}({it:{help nwcontext##context:context}})
{opth generate(newvarname)}
{opt noweight}]



{synoptset 25 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opth attribute(varname)}}Attribute variable{p_end}
{synopt:{opt stat}({it:{help nwcontext##statistic:statistic}})}Statistic that is used to calculate context variable for node i from attributes of network neighbors{p_end}
{synopt:{opt mode}({it:{help nwcontext##context:context}})}Define network neighbors of node i as either nodes j who receive ties from i, send ties to j or both{p_end}
{synopt:{opth generate(newvarname)}}Name of the context variable to be generated; default = {it:_context_varname}{p_end}
{synopt:{opt noweight}}Ignore valued ties and treats all as binary{p_end}

{synoptline}
{p2colreset}{...}

{synoptset 20 tabbed}{...}
{marker statistic}{...}
{p2col:{it:statistic}}Description{p_end}
{p2line}
{p2col:{cmd: mean}}mean of {help varname} over network neighbors; default
		{p_end}
{p2col:{cmd: max}}maximum of {help varname} over network neighbors
		{p_end}
{p2col:{cmd: min}}minimum of {help varname} over network neighbors
		{p_end}
{p2col:{cmd: sum}}sum of {help varname} over network neighbors
		{p_end}
{p2col:{cmd: sd}}standard deviation of {help varname} over network neighbors
		{p_end}
{p2col:{cmd: meanego}}mean of {help varname} over network neighbors and ego)
		{p_end}
{p2col:{cmd: maxego}}maximum of {help varname} over network neighbors and ego
		{p_end}
{p2col:{cmd: minego}}minimum of {help varname} over network neighbors and ego
		{p_end}
{p2col:{cmd: sumego}}sum of {help varname} over network neighbors and ego
		{p_end}
{p2col:{cmd: sdego}}standard deviation of {help varname} over network neighbors and ego
		{p_end}
		
{p2colreset}{...}
{synoptset 20 tabbed}{...}
{marker context}{...}
{p2col:{it:context}}Description{p_end}
{p2line}
{p2col:{cmd: outgoing}}network neighbors of node i are all nodes j who receive a tie from i; default
		{p_end}
{p2col:{cmd: incoming}}network neighbors of node i are all nodes j who send a tie to i
		{p_end}
{p2col:{cmd: both} or {cmd:either}}network neighbors of node i are all nodes j who either send a tie to i or receive a tie from i ({cmd:either} is the preferred term - matches {help nwneighbor}'s {opt mode()} - {cmd:both} is accepted for backwards compatibility)
		{p_end}


{title:Description}

{pstd}
{cmd:nwcontext} generates a context variable, which holds information about the {it:attribute values} of a node's network neighbors.

{pstd}
For each node the set of network neighbors is specified in {opt mode()}, by default {it:context} = {bf:outgoing}. This means that the new context
variable {it:newvarname}[i] is calculated based on an all values {it:varname}[j], for which there is a tie from node {it:i} to node
{it:j}. A network neighborhood of
node {it:i} can be either 1) all nodes {it:j} to whom i has outgoing ties (default), 2) all nodes {it:j} from whom {it:i} receives incoming ties, or 3) both. In the case 
of valued ties {it:varname}[j] is weighted accordingly.

{pstd}
After that a {it:statistic} defined in {opt stat()} is calculated from all weigthed {it:varname}[j]. By default, the mean is calculated. More formally:

{pmore}
{it:newvarname}[i] = {it:stat}({it:varname}[j]), for all {it:j} with {it:y_ij} > 0

{pstd}
When used with the defaults, the command calculates for each node {it:i} the mean score of its network neighbors on {help varname}.
Valid statistics are: the{bf: mean}, the {bf:max}, the {bf:min}, the {bf:sum} and the {bf:sd} of {help varname}.

{pstd}
Sometimes, however, one might want to calculate statistics including the attribute of ego. One can achieve this by using the ego-extended version of each statistic
({bf:meanego},  {bf:maxego},  {bf:minego},  {bf:sumego} and {bf:sdego}), which are calculated in this way:

{pmore}
{it:newvarname}[i] = {it:stat}({it:varname}[j]), for all {it:j} with {it:y_ij} > 0 or j == i

{title:Scope}
{pstd}
Directed and undirected, weighted and unweighted, one-mode and two-mode.

{title:Remarks}

{pstd}
In the case of undirected networks, no {it: mode} option needs to be specified. 

{pstd}
By default, nodes with missing attributes are excluded from the calculation.

{title:Examples}

{pstd}
This example loads the Florentine marriage data. The variable {it:wealth} indicates how rich each family is. {bf: nwcontext}
generates different variables: {it:w_avg} = average wealth of network neighbors,  {it:w_min} = wealth of poorest network neighbor,
{it:w_min} = wealth of richest network neighbor, {it:w_sd} = standard deviation of wealth over network neighbors.

	{com}. nwwebuse florentine
	{com}. nwcontext flomarriage, attribute(wealth) generate(w_avg)
	{com}. nwcontext flomarriage, attribute(wealth) generate(w_min) stat(min)
	{com}. nwcontext flomarriage, attribute(wealth) generate(w_max) stat(max)
	{com}. nwcontext flomarriage, attribute(wealth) generate(w_sd) stat(sd)

	{com}. list w*
{txt}
     {c TLC}{hline 8}{c -}{hline 10}{c -}{hline 10}{c -}{hline 10}{c -}{hline 10}{c TRC}
     {c |} {res}wealth      w_avg      w_min      w_max       w_sd {txt}{c |}
     {c LT}{hline 8}{c -}{hline 10}{c -}{hline 10}{c -}{hline 10}{c -}{hline 10}{c RT}
  1. {c |} {res}    10        103        103        103          0 {txt}{c |}
  2. {c |} {res}    36   47.66667          8        103   40.33471 {txt}{c |}
  3. {c |} {res}    55       61.5         20        103       41.5 {txt}{c |}
  4. {c |} {res}    44   67.66666          8        146   57.86382 {txt}{c |}
  5. {c |} {res}    20   83.33334         49        146   44.37968 {txt}{c |}
     {c LT}{hline 8}{c -}{hline 10}{c -}{hline 10}{c -}{hline 10}{c -}{hline 10}{c RT}
  6. {c |} {res}    32         36         36         36          0 {txt}{c |}
  7. {c |} {res}     8       42.5         36         48   4.330127 {txt}{c |}
  8. {c |} {res}    42          8          8          8          0 {txt}{c |}
  9. {c |} {res}   103         31         10         55   17.26268 {txt}{c |}
 10. {c |} {res}    48         10         10         10          0 {txt}{c |}
     {c LT}{hline 8}{c -}{hline 10}{c -}{hline 10}{c -}{hline 10}{c -}{hline 10}{c RT}
 11. {c |} {res}    49         70         20        146     54.626 {txt}{c |}
 12. {c |} {res}     3          .          .          .          . {txt}{c |}
 13. {c |} {res}    27         99         48        146   40.10819 {txt}{c |}
 14. {c |} {res}    10       75.5         48        103       27.5 {txt}{c |}
 15. {c |} {res}   146         35         20         49   11.89538 {txt}{c |}
     {c LT}{hline 8}{c -}{hline 10}{c -}{hline 10}{c -}{hline 10}{c -}{hline 10}{c RT}
 16. {c |} {res}    48         46          8        103   41.04469 {txt}{c |}
     {c BLC}{hline 8}{c -}{hline 10}{c -}{hline 10}{c -}{hline 10}{c -}{hline 10}{c BRC}
	
{pstd}
You can plot the florentine marriage network with {it:wealth} as node label to better understand how these values come about:

	{cmd:. nwplot flomarriage, label(wealth)}

{title:See also}

   {help nwneighbor}

***/

capture program drop nwcontext
program nwcontext 
	version 9
	syntax [anything(name=netname)],  ATTRibute(string) [ stat(string) mode(string) GENerate(string) noweight REPlace ]
	nw_syntax `netname', max(1)
	
	if "`stat'" == "" {
		local stat = "mean"
	}
	
	_opts_oneof "mean max min sum sd meanego maxego minego sumego sdego" "stat" "`stat'" 6556
	if "`mode'" == "" {
		local mode = "outgoing"
	}
	// "either" is the package-wide canonical term for this concept (see
	// NWCOMMANDS_COMMAND_STYLE.md and nwneighbor's own mode(), which
	// already used it) - accepted here as a synonym for the pre-existing
	// "both" and normalized to it immediately below, so the rest of this
	// command's logic (which checks the literal string "both") needs no
	// further changes and "both" keeps working exactly as before.
	_opts_oneof "incoming outgoing both either" "mode" "`mode'" 6556
	if "`mode'" == "either" {
		local mode "both"
	}
	
	capture confirm variable `generate'
	if _rc == 0 & "`replace'" == "" {
		di "{err}Variable {bf:`generate'} already exists; use {bf:replace}"
		err 99
	}
	if "`generate'" == "" {
		local generate _context_`attribute'
	}
	capture drop `generate'
	
	nw_datasync `netname'
	nw_syntax `netname', max(1)

	if ("`stat'" == "") {
		local stat = "mean"
	}
	
	if ("`weight'" == "noweight"){
		local net_matrix (*`netobj'->get_matrix_unvalued())
	}
	else {
		local net_matrix (*`netobj'->get_matrix())
	}
	
	mata: __attr = J(`nodes', 1, 0)
	if `nodes' >= _N {
		local validCase = _N
		mata: __attr[(1::`validCase')] = st_data((1,`validCase'), "`attribute'")
	}
	else {
		mata: __attr[(1::`nodes')] = st_data((1,`nodes'), "`attribute'")
	}
	
	if ("`mode'" == "incoming") {
		local net_matrix (`net_matrix')'
	}
	if ("`mode'" == "both") {
		local net_matrix ((`net_matrix')' + `net_matrix')
	}
	local net_matrix ((`net_matrix') :* (__attr :!= .)')
	mata: __contextNet = (`net_matrix')
	mata: _editmissing(__attr,0)
	mata: _editmissing(__contextNet, 0)

	if ("`stat'" == "mean"){
		mata: __context = (__contextNet * __attr) :/ (rowsum(__contextNet))
	}
	
	if ("`stat'" == "meanego"){
		mata: _diag(__contextNet, 1)
		// BUGFIX: referenced the undeclared Mata variables `contextNet'/
		// `attr' instead of `__contextNet'/`__attr' (the names actually
		// populated earlier in this program, used by every other stat
		// branch) - always failed with "variable not found", r(3499).
		mata: __context = (__contextNet * __attr) :/ (rowsum(__contextNet))
	}
	
	if ("`stat'" == "sd"){
		mata: __netVal = rowsum(__contextNet)
		mata: __avgContext = (__contextNet * __attr) :/ __netVal
		mata: _editvalue(__contextNet,0,.)
		mata: __diffContext = (__contextNet :* __attr') :- __avgContext
		mata: __context = sqrt(rowsum(__diffContext :* __diffContext):/rowsum(__contextNet))
		mata: mata drop __netVal __diffContext __avgContext 
	}
	
	if ("`stat'" == "sdego"){
		mata: _diag(__contextNet, 1)
		mata: __netVal = rowsum(__contextNet)
		mata: __avgContext = (__contextNet * __attr) :/ __netVal
		mata: _editvalue(__contextNet,0,.)
		mata: __diffContext = (__contextNet :* __attr') :- __avgContext
		mata: __context = sqrt(rowsum(__diffContext :* __diffContext):/rowsum(__contextNet))
		mata: mata drop __netVal __diffContext __avgContext 
	}
	
	if ("`stat'" == "max"){
		mata: _editvalue(__contextNet,0,.)
		mata: __context = rowmax(__contextNet :* __attr')
	}
	
	if ("`stat'" == "maxego"){
		// BUGFIX: a stray trailing "4" after the closing paren made this
		// a Mata syntax error ("invalid syntax", r(3000)) on every call,
		// unlike the four other identical `_diag(__contextNet, 1)' calls
		// elsewhere in this file.
		mata: _diag(__contextNet, 1)
		mata: _editvalue(__contextNet,0,.)
		mata: __context = rowmax(__contextNet :* __attr')
	}
	
	if ("`stat'" == "min"){	
		mata: _editvalue(__contextNet,0,.)
		mata: __context = rowmin(__contextNet :* __attr')
	}
	
	if ("`stat'" == "minego"){	
		mata: _diag(__contextNet, 1)
		mata: _editvalue(__contextNet,0,.)
		mata: __context = rowmin(__contextNet :* __attr')
	}
	
	if ("`stat'" == "sum"){
		mata: __contextNet
		mata: __attr
		mata: __context = (__contextNet * __attr) 
	}
	
	if ("`stat'" == "sumego"){
		mata: _diag(__contextNet, 1)
		mata: __context = (__contextNet * __attr) 
	}
	
	//mata: _editvalue(__context,0,.)
	if "`mat'" != "" {
		mata: `mat' = __context
	}
	else {
		capture generate `generate' = .
		mata: st_store((1, `nodes'), "`generate'",__context)
	}
	mata: mata drop __context __attr __contextNet   
end

