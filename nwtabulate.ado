/***
{smcl}
{* *! 12jul2016: Thomas Grund}{...}
{marker topic}
{helpb nw_topical##information:[NW-2.4] Information}

{title:Tables of networks}

    See

{p 8 32 2}
{helpb nwtab1:nwtabulate oneway}{space 7}for one-way table of network ties

{p 8 32 2}
{helpb nwtab2:nwtabulate twoway}{space 7}for two-way table of networks 

{p 8 32 2}
{helpb nwtab3:nwtabulate twoway}{space 7}for two-way table of network and node attribute

{title:Supported network types}

{pstd}
Binary: yes. Directed: yes. Weighted: not applicable - tabulates tie presence/attribute crossings,
not tie values. Signed: not applicable. Two-mode: not checked.

***/

capture program drop nwtabulate
program nwtabulate
	syntax [anything(name=netname)] [, attribute(varname) *]
	nw_syntax `netname', max(2)

	if `networks' == 1 & "`attribute'" == "" {
		nwtab1 `netname', `options'
	}
	if `networks' == 2 {
		nwtab2 `netname', `options'
	}
	if "`attribute'" != "" {
		nw_syntax `netname', max(1)
		nwtab3 `netname', attribute(`attribute') `options'
	}
	if `networks' > 2 {
		di "{err}Maximum two networks allowed.{txt}"
		exit
	}
end


/***
{smcl}
{* *! 12jul2016: Thomas Grund}{...}

{title:Title}

{p2colset 9 20 23 2}{...}
{p2col :nwtabulate {hline 2}}One-way table of dyads{p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 17 2}
{cmdab: nwtab:ulate} 
[{it:{help netname}}]
[{cmd:,}
{it:{help tabulate_oneway##tabulate1_options:tabulate1_options}}]

{title:Description}

{pstd}
The one-way nwtabulate simply tabulates all ties in the network and shows the distribution of tie
values. It works just as {help tabulate}, but on the level of network ties. The command recognizes when a network is undirected or selflooped.

{pstd}
For example, for a directed network with 5 nodes, the commands displays the distribution of a total of 5 * 4 = 20 tie values. For an undirected network
with 5 nodes, the commands displays the distribution of a total of (5 * 4)/2 = 10 tie values. 

{pstd}
The command makes use of the normal {help tabulate} command, hence, all 
{it:{help tabulate_oneway##tabulate1_options:tabulate1_options}} can be applied. This can be useful to extract the distribution of tie values for further calculation.

{title:Example}
	
   {cmd:. nwwebuse gang}
   {cmd:. nwtabulate gang}
{res}
{txt}   Network:  {res}gang{txt}{col 24}Directed: {res}false{txt}

       gang {c |}      Freq.     Percent        Cum.
{hline 12}{c +}{hline 35}
          0 {c |}{res}      1,116       77.99       77.99
{txt}          1 {c |}{res}        182       12.72       90.71
{txt}          2 {c |}{res}         92        6.43       97.13
{txt}          3 {c |}{res}         25        1.75       98.88
{txt}          4 {c |}{res}         16        1.12      100.00
{txt}{hline 12}{c +}{hline 35}
      Total {c |}{res}      1,431      100.00

	  {pstd}{txt}
In the {it:gang} network, 1116 potential (undirected) co-offending ties are not realized, 182 ties have the value 1,
92 ties have the value 2 and so on.


{title:See also}

    {help nwtab2:two-way nwtabulate}, {help tabulate}

***/
capture program drop nwtab1
program nwtab1
	
	syntax [anything] , [selfloop *]
	preserve
	
	nw_syntax `anything'
	if "`directed'" == "false" {
		local upper = "upper"
	}
	nw_edgelabs `anything'
	local edgelabs r(edgelabs)
	
	nwtoedge `netname', `upper'
	
	local ident = length("`netname'") + 20
	di
	di "{txt}   Network:  {res}`netname'{txt}{col `ident'}Directed : {res}`directed'{txt}"
	di "{txt}                           {txt}{col `ident'}Selfloops: {res}`selfloops'{txt}"
	capture label def elab `edgelabs'
	capture label val `netname' elab
	tab `netname', `options'
	restore
end

/***
{smcl}
{* *! 12jul2016: Thomas Grund}{...}

{title:Title}

{p2colset 9 20 23 2}{...}
{p2col :nwtabulate {hline 2}}Two-way table of two networks{p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 17 2}
{cmdab: nwtab:ulate} 
{it:{help netname:netname1}}
{it:{help netname:netname2}}
[{cmd:,}
{opth permutations(integer)}
{opt plot}
{opt plotoptions}({it:{help tabplot:tabplot_options}})
{opt eiplot}
{opt eiplotoptions}({it:{help kdensity:kdensity_options}})
{it:{help tabulate twoway:tabulate2_options}}]


{synoptset 25 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt plot}}Make a tabplot{p_end}
{synopt:{opt eiplot}}Make a plot for significance of E-I-index{p_end}
{synopt:{opth permutations(integer)}}QAP permutations for significance of E-I-index{p_end}

{title:Description}

{pstd}
Teh command produces the network version of {help tabulate twoway} for two networks. It
shows the overlap of ties for two networks that share the same nodes (see {help nodeid}) on the dyadic level. The
command essentially transforms {it:netname1} and {it:netname2} in edgelist format (see {help nwtoedge})
and runs a normal {help tabulate twoway}, hence,
all {help tabulate twoway:tabulate2_options} can be used as well.  

{pstd}
When at least one of the networks {it:netname1} or {it:netname2} is directed, the command produces a full edgelist for the networks with
two entries for the node pair (i,j). 

{pstd}
The command also calculates the E-I-index (Krackhardt and Stern 1988). The Krackhardt E/I Ratio
is a social network measure of the relative density of internal connections within a social group 
compared to the number of connections that group has to the external world. Applied to two networks the number of internal
connections refers to the number of times that the tie value for the pair (i,j) is the same in {it:netname1} and {it:netname2}.

	{it:E-I-index = (E - I) / (E + I)}

{pstd}
where I (internal) is the number of ties within a social group G and E is 
the number of ties to the external world (outside of group G). The E-I-index ranges 
between -1 (only within-group ties exist) and 1 (only between-group ties exist). 

{pstd}
More intuitively, the E-I-index simply calculates the number of 
ties off the diagonal (in the table produced by the command)
by the total number of ties. By default, the command runs 100 QAP
permutations of the network (see {help nwqap}) to obtain a p-value
for the E-I-index. Basically, the network is randomly permuted and the
E-I-index is calculated again to obtain a distribution for the E-I-index
under the condition that the network and the attribute are unrelated.


{title:Example}

{pstd}
This loads the Florentine {help netexample:data} and shows the overlap between
the networks {it:flomarriage} and {it:flobusiness}. Both have the same nodes, i.e. 16 Florentine families. 

     {com}. nwwebuse florentine, nwclear
     {com}. nwtabulate flomarriage flobusiness
{res}
     {txt}   Network1:  {res}flomarriage{txt}{col 36}Directed : {res}false{txt}
     {txt}                           {txt}{col 36}Selfloops: {res}false{txt}
     {res}{txt}   Network2:  {res}flobusiness{txt}{col 36}Directed : {res}false{txt}
     {txt}                           {txt}{col 36}Selfloops: {res}false{txt}

     flomarriag {c |}      flobusiness
              e {c |}         0          1 {c |}     Total
     {hline 11}{c +}{hline 22}{c +}{hline 10}
              0 {c |}{res}        93          7 {txt}{c |}{res}       100 
     {txt}         1 {c |}{res}        12          8 {txt}{c |}{res}        20 
     {txt}{hline 11}{c +}{hline 22}{c +}{hline 10}
          Total {c |}{res}       105         15 {txt}{c |}{res}       120 

     {txt}   E-I Index: {res}-.683{txt} p-value: {res}0{txt}

	
{pstd}
There are 120 possible (undirected) ties between Florentine families that can overlap in the two networks. There are 8 undirected ties
where families have both a marriage and a business relationship. In contrast, there are 7 undirected pairs of families with a business, but not with a marriage
relationship.


{title:See also}

	{help nwtab1:one-way nwtabulate}, {help nwtab3:two-way nwtabulate attribute}, {help nwcorrelate}, {help nwqap}, {help tabulate}

***/

capture program drop nwtab2
program nwtab2
	syntax anything(name=netname) [, eiplot eiplotoptions(string) unvalued plot plotoptions(string) permutations(integer 100) *]
		
	if "`plot'" != "" {
		capture which tabplot
		if _rc != 0 {
			capture ssc install tabplot
		}
	}
	
	local netname0 `netname'
	nw_syntax `netname', max(2) min(2)
	local upper = "upper"
	foreach net in `netname' {
		nw_syntax `net'
		if "`directed'" == "true" {
			local upper = ""
		}
	}
	
	preserve
	nwtoedge `netname0', `upper'
	
	local net1: word 1 of `netname0'
	nw_edgelabs `net1'
	capture label def elab1 `r(edgelabs)'
	capture label val `net1' elab1
	
	local net2: word 2 of `netname0'
	nw_edgelabs `net2'
	capture label def elab2 `r(edgelabs)'
	capture label val `net2' elab2

	local ident = length("`netname'") + 20
	di
	nw_syntax `net1'
	local netobj1 `netobj'
	di "{txt}   Network1:  {res}`net1'{txt}{col `ident'}Directed : {res}`directed'{txt}"
	di "{txt}                           {txt}{col `ident'}Selfloops: {res}`selfloops'{txt}"
	nw_syntax `net2'
	local netobj2 `netobj'
	di "{txt}   Network2:  {res}`net2'{txt}{col `ident'}Directed : {res}`directed'{txt}"
	di "{txt}                           {txt}{col `ident'}Selfloops: {res}`selfloops'{txt}"

	tempname tableres tablecol tablerow
	tabulate `netname0', matcell(`tableres') matcol(`tablecol') matrow(`tablerow') `options'
	
	capture qui matrix list `tableres'
	if _rc != 0 {
		exit
	}
	
	if "`plot'" != "" {
		tabplot `net1' `net2', horizontal plotregion(margin(b = 0)) `plotoptions'
	}
	
	tempname __nwtable __nwcol __nwrow __nwinternal __nwexternal __nwei_index 
	mata: `__nwtable' = st_matrix("`tableres'")
	mata: `__nwcol' = st_matrix("`tablecol'")
	mata: `__nwrow' = st_matrix("`tablerow'")
	mata: `__nwinternal' = sum(diagonal(`__nwtable'))
	mata: `__nwexternal' = sum(`__nwtable') - `__nwinternal'
	mata: `__nwei_index' = (`__nwexternal' - `__nwinternal') / (`__nwexternal' + `__nwinternal')
	
	mata: st_global("r(netname1)", "`net1'")
	mata: st_global("r(netname2)", "`net2'")
	mata: st_numscalar("r(EI_index)", floatround(`__nwei_index'))
	mata: st_matrix("r(table)", `__nwtable')
	mata: st_matrix("r(col)", `__nwcol')
	mata: st_matrix("r(row)", `__nwrow')
	
    mata: mata drop `__nwtable' `__nwcol' `__nwrow' `__nwinternal' `__nwexternal' `__nwei_index' 
	
	local EI_index = `r(EI_index)'

	tempname EI_qap out pvalue
	capture _return drop res1
	_return hold res1
	
	qui if `permutations' > 1  {

		mata: `EI_qap' = rep_EInet(`permutations', `netobj1'->get_matrix_copy(), `netobj2'->get_matrix_copy())
		if `EI_index' > 0 {
			mata: `out' = sum(`EI_qap' :>= `EI_index')
		}
		else {
			mata: `out' = sum(`EI_qap' :<= `EI_index')	
		}
		mata: `pvalue' = `out' / `permutations'
		mata: mata drop `out'
		
		drop _all
		getmata EI_simulated = `EI_qap'
		gen EI_observed = `EI_index'
		if "`save'"!= "" {
			di "QAP results saved as: `save'" 
			save "`save'", replace
		}
		
		qui sum EI_simulated
		local xmin = min(`EI_index',r(min))
		local xmax = max(`EI_index',r(max))
		local bandwidth `= 1 / `nodes''
		if "`eiplot'" != "" {
			kdensity EI_simulated, xscale(range(`xmin' `xmax')) title("") bwidth(`bandwidth') ytitle("Density") xtitle("E-I Index") xline(`EI_index',lpattern(dash)) xlabel(#5) note(`"based on `permutations' QAP permutations of network `net1'"') `eiplotoptions'	
		}		
	}
	_return restore res1
	capture mata: st_numscalar("r(EI_pvalue)", floatround(`pvalue'))

    capture mata: mata drop `EI_out' `pvalue'  `EI_qap'
	di "{txt}   E-I Index: {res}" _continue
	di round(float(`r(EI_index)'),0.001) _continue
	di "{txt}   p-value: {res}" _continue
	di round(float(`r(EI_pvalue)'),0.001)

	restore

end

/***
{smcl}
{* *! 12jul2016: Thomas Grund}{...}

{title:Title}

{p2colset 9 20 23 2}{...}
{p2col :nwtabulate {hline 2}}Two-way table of network and node attribute{p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 17 2}
{cmdab: nwtab:ulate} 
{it:{help netname:netname}}
{cmd:,}
{opth attribute(varname)}
[{opth permutations(integer)}
{opt plot}
{opt plotoptions}({it:{help tabplot:tabplot_options}})
{opt eiplot}
{opt eiplotoptions}({it:{help kdensity:kdensity_options}})
{it:{help tabulate twoway:tabulate2_options}}]


{synoptset 25 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opth attribute(varname)}}Node-level attribute{p_end}
{synopt:{opt plot}}Make a tabplot{p_end}
{synopt:{opt eiplot}}Make a plot for significance of E-I-index{p_end}
{synopt:{opth permutations(integer)}}QAP permutations for significance of E-I-index{p_end}

{title:Description}

{pstd}
When one network and one attribute is given in option {opt attribute()}, the command
produces a two-way table that indicates the number of ties between
network nodes with certain attributes (tie values are not considered). This can be used to 
detect homophily in a network (the tendency for ties to exist between similar 
nodes). 

{pstd}
The command also calculates the E-I-index (Krackhardt and Stern 1988). The Krackhardt E/I Ratio
is a social network measure of the relative density of internal connections within a social group 
compared to the number of connections that group has to the external world.

	{it:E-I-index = (E - I) / (E + I)}

{pstd}
where I (internal) is the number of ties within a social group G and E is 
the number of ties to the external world (outside of group G). The E-I-index ranges 
between -1 (only within-group ties exist) and 1 (only between-group ties exist). 

{pstd}
More intuitively, the E-I-index simply calculates the number of 
ties off the diagonal (in the table produced by the command)
by the total number of ties. By default, the command runs 100 QAP
permutations of the network (see {help nwqap}) to obtain a p-value
for the E-I-index. Basically, the network is randomly permuted and the
E-I-index is calculated again to obtain a distribution for the E-I-index
under the condition that the network and the attribute are unrelated.


{title:Example}

{pstd}
This loads the Florentine {help netexample:data} and shows the attributes of the sending and receiving nodes for those pairs (i,j) who are connected
with each other. In this case, it shows the marriage connections between Florentine families who both have a seat in the civic council and so on. For example,
there are 12 undirected marriage ties between two Florentine families where both have a seat in the civic council. There are 4 marriage ties where one family
has a seat in the civic council and the other one does not. 


     {com}. nwwebuse florentine, nwclear
     {com}. nwtabulate flomarriage, attribute(seat)
     {res}
     {txt}   Network:  {res}flomarriage{txt}{col 36}Directed : {res}false{txt}
     {txt}                           {txt}{col 36}Selfloops: {res}false{txt}
     {txt}   Attribute:  {res}seat{txt}
     {res}
                {txt}{c |}      seat_alter
       seat_ego {c |}         0          1 {c |}     Total
     {hline 11}{c +}{hline 22}{c +}{hline 10}
              0 {c |}{res}         0          4 {txt}{c |}{res}         4 
     {txt}         1 {c |}{res}         4         12 {txt}{c |}{res}        16 
     {txt}{hline 11}{c +}{hline 22}{c +}{hline 10}
          Total {c |}{res}         4         16 {txt}{c |}{res}        20 

     {txt}   E-I Index: {res}-.2{txt}   p-value: {res}.84

	

{title:See also}
{pstd}
	{help nwtab1:one-way nwtabulate}, {help nwtab2:two-way nwtabulate network}, {help nwcorrelate}, {help nwqap}, {help tabulate}

***/


capture program drop nwtab3
program nwtab3
	syntax anything(name=netname), attribute(varname) [, eiplot eiplotoptions(string) unvalued plot plotoptions(string) permutations(integer 100) *]
		
	if "`plot'" != "" {
		capture which tabplot
		if _rc != 0 {
			capture ssc install tabplot
		}
	}
	
	nw_syntax `netname', max(1) min(1)
	
	local upper = "upper"
	foreach net in `netname' {
		nw_syntax `net'
		if "`directed'" == "true" {
			local upper = ""
		}
	}
	
	preserve	
	
	local ident = length("`netname'") + 20
	di ""
	di "{txt}   Network:  {res}`netname'{txt}{col `ident'}Directed : {res}`directed'{txt}"
	di "{txt}                           {txt}{col `ident'}Selfloops: {res}`selfloops'{txt}"

	di "{txt}   Attribute:  {res}`attribute'{txt}"
	
	nwtoedge `netname', egovars(`attribute') altervars(`attribute') full

	unw_defs
	nw_syntax `netname'
	
	qui keep if `netname' != 0 & `netname' != .
	tempname tableres tablecol tablerow
	if "`directed'" == "true" {
		tabulate `attribute'`nw_ego' `attribute'`nw_alter'  , matcell(`tableres') matcol(`tablecol') matrow(`tablerow') `options'
	}
	else {	
		qui gen _temp = mod(_n,2)
		tabulate `attribute'`nw_ego' `attribute'`nw_alter' if _temp == 0. , matcell(`tableres') matcol(`tablecol') matrow(`tablerow') `options'
	}
	
	if "`plot'" != "" {
		tabplot `attribute'`nw_ego' `attribute'`nw_alter', horizontal plotregion(margin(b = 0)) `plotoptions'
	}
	
	tempname __nwtable __nwcol __nwrow __nwinternal __nwexternal __nwei_index 
	mata: `__nwtable' = st_matrix("`tableres'")
	mata: `__nwcol' = st_matrix("`tablecol'")
	mata: `__nwrow' = st_matrix("`tablerow'")
	mata: `__nwinternal' = sum(diagonal(`__nwtable'))
	mata: `__nwexternal' = sum(`__nwtable') - `__nwinternal'
	mata: `__nwei_index' = (`__nwexternal' - `__nwinternal') / (`__nwexternal' + `__nwinternal')
	
	// BUGFIX: was `r(netname1)'/`r(netname2)' set from `net1'/`net2' -
	// copy-pasted verbatim from nwtab2 (the network+network branch
	// above), but this program (nwtab3, the network+attribute branch)
	// has only one network and one attribute, and never defines `net1'/
	// `net2' anywhere in its own scope - both always came back missing
	// (.), silently, since `capture'-free `mata:' calls referencing an
	// undefined local just interpolate an empty string rather than
	// erroring. Replaced with this program's own actual identifiers.
	mata: st_global("r(netname)", "`netname'")
	mata: st_global("r(attribute)", "`attribute'")
	mata: st_numscalar("r(EI_index)", floatround(`__nwei_index'))
	mata: st_matrix("r(table)", `__nwtable')
	mata: st_matrix("r(col)", `__nwcol')
	mata: st_matrix("r(row)", `__nwrow')

	capture mata: mata drop `__nwtable' `__nwcol' `__nwrow' `__nwinternal' `__nwexternal' `__nwei_index' 
	
	local EI_index = `r(EI_index)'

	tempname EI_qap out pvalue
	capture _return drop res1
	_return hold res1
	
	restore
	preserve
	
	nw_datasync `netname'
	
	tempvar group
	egen `group' = group(`attribute')
	
	qui if `permutations' > 1  {
		nw_syntax `netname'
		mata: `EI_qap' = rep_EIattr(`permutations', `netobj'->get_matrix_copy(), st_data((1::`nodes'),"`group'"))
		if `EI_index' > 0 {
			mata: `out' = sum(`EI_qap' :>= `EI_index')
		}
		else {
			mata: `out' = sum(`EI_qap' :<= `EI_index')	
		}
		mata: `pvalue' = `out' / `permutations'
		mata: mata drop `out'
		
		drop _all
		getmata EI_simulated = `EI_qap'
		gen EI_observed = `EI_index'
		if "`save'"!= "" {
			di "QAP results saved as: `save'" 
			save "`save'", replace
		}
		
		qui sum EI_simulated
		local xmin = min(`EI_index',r(min))
		local xmax = max(`EI_index',r(max))
		local bandwidth `= 1 / `nodes''
		if "`eiplot'" != "" {
			kdensity EI_simulated, xscale(range(`xmin' `xmax')) title("") bwidth(`bandwidth') ytitle("Density") xtitle("E-I Index") xline(`EI_index',lpattern(dash)) xlabel(#5) note(`"based on `permutations' QAP permutations of network `net1'"') `eiplotoptions'	
		}		
	}

	restore
	
	_return restore res1
	
	capture mata: st_numscalar("r(EI_pvalue)", floatround(`pvalue'))
	capture mata: mata drop `EI_out' `pvalue'  `EI_qap'
		
	
	di "{txt}   E-I Index: {res}" _continue
	di round(float(`r(EI_index)'),0.001) _continue
	di "{txt}   p-value: {res}" _continue
	di round(float(`r(EI_pvalue)'),0.001)
	di ""


end



capture mata : mata drop rep_EInet()
capture mata : mata drop rep_EIattr()

mata:
real matrix rep_EInet(real scalar reps, real matrix net1, real matrix net2) {
	real scalar nsize, total, EI, i
	real matrix intern, extern, permutationVec, perm_net
	
	net1 = (net1:!=0 :& net1 !=.)
	nsize = cols(net1)
	
	total = nsize * (nsize - 1)
	intern = J(reps, 1, 0)
	extern = J(reps, 1, 0)
	
	for (i = 1; i <= reps; i ++) {
		permutationVec = unorder(nsize)
		perm_net = net1[permutationVec, permutationVec]
		intern[i] = sum(perm_net :== net2)
	}
	extern = total :- intern
	EI = (extern :- intern) :/ (extern :+ intern)
	return(EI)
}

real matrix rep_EIattr(real scalar reps, real matrix net1, real matrix attr) {
	real scalar nsize, total, EI, i
	real matrix intern, extern, permutationVec, perm_net, attr1, attr2
	
	net1 = (net1:!=0 :& net1 != .)
	nsize = cols(net1)
	total = sum(net1)
	
	intern = J(reps, 1, 0)
	extern = J(reps, 1, 0)
	
	attr1 = J(1,nsize,attr)
	attr2 = J(nsize,1,attr')
	
	for (i = 1; i <= reps; i ++) {
		permutationVec = unorder(nsize)
		perm_net = net1[permutationVec, permutationVec]
		intern[i] = sum(perm_net :* (attr1:== attr2))
	}
	extern = total :- intern
	EI = (extern :- intern) :/ (extern :+ intern)
	return(EI)
}
end

