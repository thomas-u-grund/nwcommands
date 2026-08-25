/***
{smcl}
{* *!  14jul2016 Thomas Grund}{...}
{marker topic}
{helpb nw_topical##manipulation:[NW-2.5] Manipulation}

{title:Title}

{p2colset 9 18 22 2}{...}
{p2col :nwreplace  {hline 2}}Replace network{p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 17 2}
{cmdab: nwreplace} 
{it:{cmd:{help nwreplace##netsub:netname[subnet]}}}
{cmd:=}{it:{help netexp}}
[{it:{help nwreplace##conditions:ifego}}]
[{it:{help nwreplace##conditions:ifalter}}]
[{it:{help nwreplace##conditions:if}}]


{title:Description}

{pstd}
Replaces a whole network, a subnetwork or specific tie values with a network expression. This command
is the network version of {help replace}. A {help netexp:network expression} is 
very similar to a normal {help exp:expression} in Stata, but it also accepts {help netname:netnames}. 

{pstd}
One can also replace tie values in networks by 1) loading a network as Stata variables 
(see {help nwload}), 2) changing the Stata variables (see {help replace}) and 3) syncing Stata variables and network afterwards
(see {help nwsync}). However, replacing the networks directly (as shown below) is the faster and preferred method.

{pstd}
One can also change the entire adjaceny matrix of a network with an existing Mata matrix using {help nwreplacemat}.



{title:Supported network types}

{pstd}
Binary: yes. Directed: yes - a replaced value is written to the exact (ego,alter) cell addressed, respecting direction. Weighted: yes, natively - this command's entire purpose is writing arbitrary tie values via an expression. Signed: yes, any value including negative can be assigned. Two-mode: not checked, but not expected to need any - a direct cell/subset write by node identity.

{title:Assign values}

{pstd}
Only replace dyad (2,1) to a constant:

	{bf:. nwset, mat((0,0,1\1,0,0\1,10)) name(mynet)}
	{bf:. nwreplace mynet[2,1] = 55}

{pstd}
Set all dyads x_ij of an existing network {it:mynet} to a constant: 

{pmore}
{bf:. nwreplace mynet = 99}


{title:Network expressions}

{pstd}
A network expresssion is similar to a normal expression in Stata with the addition that it accepts
network names. It can be a simple constant, but also a very complicated expression that consists of 
operators, networks and variables. 

{pstd}
The usual operators are allowed in network expressions. All calculations in a 
network expression are performed element-by-element.

{pstd}
For example, one can calculate the intersection of two networks.

	{bf:nwwebuse florentine, nwclear}
	{bf:nwgen bus_marr = flomarriage * flobusiness}
	
{pstd}
This generates a new network {it:bus_marr}, which takes the values 1 when two Florentine families
have both marriage and business ties. 

{pstd}
A more complicated network expression:

	{bf:gen test = _n}
	{bf:nwgen net = 2 * exp(flomarriage) / flobusiness * test}
	
{pstd}
Basically, one can do all sorts of calculations using network expressions. See
more on network expressions {help netexp:here}.


{title:Network subsets}
{marker netsub}{...}

{pstd}
Set a subnetwork to a constant:

{pmore}
{bf:. nwreplace mynet[(1::4),(1::4)] = 55}

{pstd}
Tie values can also be replaced with the values found in other networks for the corresponding positions. For example, this replaces
the whole network {it:first} with the network {it:second}.


	{bf:. nwclear}
	{bf:. nwrandom 7, density(.2) name(first)}
	{bf:. nwrandom 7, density(.3) name(second)}
	{bf:. nwreplace first = second}

{pstd}
Again, one can limit such a nwreplace command by using network subsetting. Furthermore,
one can use a network expression which performs element-by-element calculations:

	{bf:. nwclear}
	{bf:. nwrandom 6, density(1) name(first)}
	{bf:. nwreplace first = first * 5}
	{bf:. nwreplace first[(1::3),(1::3)] = 0}
	{bf:. nwsummarize first, matonly}

	{res}     {txt}1   2   3   4   5   6
	  {c TLC}{hline 25}{c TRC}
	1 {c |}  {res}.                    {txt}  {c |}
	2 {c |}  {res}0   .                {txt}  {c |}
	3 {c |}  {res}0   0   .            {txt}  {c |}
	4 {c |}  {res}5   5   5   .        {txt}  {c |}
	5 {c |}  {res}5   5   5   5   .    {txt}  {c |}
	6 {c |}  {res}5   5   5   5   5   .{txt}  {c |}
	  {c BLC}{hline 25}{c BRC}
	  
{marker conditions}	  
{title: Network conditions}

{pstd}
For networks different conditions can be used:

	{it:command} {cmd:if} {help netexp}
		
	{it:command} {cmd:ifego} {help exp}

	{it:command} {cmd:ifalter} {help exp}

{pstd}
The first one evaluates the following expression as a network expression (which generates a new temporary network).
For example, this code replaces the {it:first} network with the values of the {it:}second network, but only for the ties where
the {it:third} network is 1. When instead of a network expression a normal expression is given, the if condition 
acts in the same way as the ifego condition.

	{bf:. nwclear}
	{bf:. nwrandom 10, prob(.2) name(first)}
	{bf:. nwrandom 10, prob(.2) name(second)}
	{bf:. nwrandom 10, prob(.2) name(third)}

	{bf:. nwreplace first = second if third == 1}

 {pstd}
 The {bf:ifego} {help exp} condition only replaces those dyads x_ij where the expression is true
 for x_i (the {it:sender} of a tie). For example, this code only multiplies the tie values of a network where the sender of a tie
 has a _nodeid < 5.

	{bf:. nwclear}
	{bf:. nwrandom 6, prob(1) name(mynet)}
	{bf:. nwreplace mynet = 5 * mynet ifego _n > 3 }
	{bf:. nwsummarize mynet, matonly}
	
	{res}     {txt}1   2   3   4   5   6
	  {c TLC}{hline 25}{c TRC}
	1 {c |}  {res}0   1   1   1   1   1{txt}  {c |}
	2 {c |}  {res}1   0   1   1   1   1{txt}  {c |}
	3 {c |}  {res}1   1   0   1   1   1{txt}  {c |}
	4 {c |}  {res}5   5   5   0   5   5{txt}  {c |}
	5 {c |}  {res}5   5   5   5   0   5{txt}  {c |}
	6 {c |}  {res}5   5   5   5   5   0{txt}  {c |}
	  {c BLC}{hline 25}{c BRC}
  {pstd}	
 The {bf:ifalter} condition works in a similar way, but limits changes to those ties where the {it:receiver}
 x_j of a tie has certain attributes.
	
	{bf:. nwclear}
	{bf:. nwrandom 6, prob(1) name(mynet)}
	{bf:. nwreplace mynet = 5 * mynet ifalter _n > 3 }
	{bf:. nwsummarize mynet, matonly}
	
	{res}     {txt}1   2   3   4   5   6
	  {c TLC}{hline 25}{c TRC}
	1 {c |}  {res}0   1   1   5   5   5{txt}  {c |}
	2 {c |}  {res}1   0   1   5   5   5{txt}  {c |}
	3 {c |}  {res}1   1   0   5   5   5{txt}  {c |}
	4 {c |}  {res}1   1   1   0   5   5{txt}  {c |}
	5 {c |}  {res}1   1   1   5   0   5{txt}  {c |}
	6 {c |}  {res}1   1   1   5   5   0{txt}  {c |}
	  {c BLC}{hline 25}{c BRC}
 {pstd}	
 Both {bf:ifego} and {bf:ifalter} can be combined (and could even be combined with the normal {bf:if} condition as well).
	
	{bf:. nwrandom 6, prob(1) name(mynet)}
	{bf:. nwreplace mynet = 5 * mynet ifego _n > 3 ifalter _n > 3 }
	{bf:. nwsummarize mynet, matonly}
	
	{res}     {txt}1   2   3   4   5   6
	  {c TLC}{hline 25}{c TRC}
	1 {c |}  {res}0   1   1   1   1   1{txt}  {c |}
	2 {c |}  {res}1   0   1   1   1   1{txt}  {c |}
	3 {c |}  {res}1   1   0   1   1   1{txt}  {c |}
	4 {c |}  {res}1   1   1   0   5   5{txt}  {c |}
	5 {c |}  {res}1   1   1   5   0   5{txt}  {c |}
	6 {c |}  {res}1   1   1   5   5   0{txt}  {c |}
	  {c BLC}{hline 25}{c BRC}


{pstd}	
All network expressions, network subsetting and network conditions can be combined with each other. 

	{bf:. gen attr= _n * 2}
	{bf:. nwreplace first[(1::3),(1::3)]  = exp(second) * attr ifego _n >= 5 ifalter attr < 4 if third == 1}

{title:Stored results}

	Scalars
	  {bf:r(symmetric)}	1 if the network's updated adjacency matrix is symmetric, 0 otherwise
	  {bf:r(valued)}	1 if the network is valued, 0 otherwise

{title:See also}

	{help nwreplacemat}, {help nwsync}, {help nwload}

***/

capture program drop nwreplace
program nwreplace, rclass
	local arg =`"`0'"'
	gettoken netname nonet: arg, parse("=")
	local netname = trim("`netname'")

	// specific enrtries are given
	local ego = strpos("`netname'","[") 
	local alter = strpos("`netname'","]") 
	local sep = strpos("`netname'",",")
	local subset = substr("`netname'",`ego',.)
	if (`ego' != 0) {
		local e1 = `ego' + 1
		local e2 = `sep' - `ego' - 1
		local a1 =  `sep' + 1
		local a2 = `alter' - `sep' - 1
		local n1 = `ego' - 1
		local egoid = substr("`netname'", `e1', `e2')
		local alterid = substr("`netname'", `a1', `a2')
		local netname = substr("`netname'", 1, `n1')
	}

	nw_syntax `netname'
	nw_datasync `netname'
	
	local newcmd0 "(*`netobj'->get_matrix())"
	local newcmd "(*`netobj'->get_matrix())`subset'"
	
	capture mata: `newcmd'
	if _rc != 0 {
		di "{err}{it:nwsubset} {bf:`subset'} invalid"
		error 6400
	}
	
	if "`netname'" == "=" {
		di "{err}{it:networkname} required before ="
		error 6001
	}
	
	// get rid of first equal sign
	local nonet = substr(trim(`"`nonet'"'),2,.)
	
	// separate conditions
	local inpos = strpos(`"`nonet'"', " in ")
	local ifpos = strpos(`"`nonet'"', " if ")
	local ifegopos = strpos(`"`nonet'"', " ifego ")
	local ifalterpos = strpos(`"`nonet'"'," ifalter ")
	
	if (`inpos' == 0) { 
		local inpos = "" 
	}
	if (`ifpos' == 0) { 
		local ifpos = "" 
	}
	if (`ifegopos' == 0) { 
		local ifegopos = "" 
	}
	if (`ifalterpos' == 0) { 
		local ifalterpos = "" 
	}
	capture numlist "`ifpos' `ifegopos' `ifalterpos' `inpos'", sort
	local condition "`r(numlist)'"
	local condlength = wordcount("`condition'")

	forvalues i = 1 / `condlength' {
		local w = word("`condition'", `i')
		if ("`w'" == "`inpos'"){
			local inend = word("`condition'", `=`i' + 1')
			if "`inend'" == "" {
				local inend = "."
			}
			local incmd = substr(`"`nonet'"', `=`inpos'  + 4', `=`inend' - `inpos' - 4')
		}
		if ("`w'" == "`ifpos'"){
			local ifend = word("`condition'", `=`i' + 1')
			if "`ifend'" == "" {
				local ifend = "."
			}
			local ifcmd = substr(`"`nonet'"', `=`ifpos'  + 4', `=`ifend' - `ifpos' - 4')
		}
		if ("`w'" == "`ifegopos'"){
			local ifegoend = word("`condition'", `=`i' + 1')
			if "`ifegoend'" == "" {
				local ifegoend = "."
			}
			local ifegocmd = substr(`"`nonet'"', `=`ifegopos'  + 7', `=`ifegoend' - `ifegopos' - 7')
		}
		if ("`w'" == "`ifalterpos'"){
			local ifalterend = word("`condition'", `=`i' + 1')
			if "`ifalterend'" == "" {
				local ifalterend = "."
			}
			local ifaltercmd = substr(`"`nonet'"', `=`ifalterpos'  + 9', `=`ifalterend' - `ifalterpos' - 9')
		
		}
	}

	local firstcond = word("`condition'",1) 
	if "`firstcond'"=="" {
		local firstcond = "."
	}
	local netexp = substr(`"`nonet'"',1, `firstcond') 
	local netexp `"(`netexp')"'
	nw_expnetexp `netexp', nodes(`nodes')
	local newnetexp `netexp'

	local cndcmd "J(`nodes',`nodes',1)"
	if `"`ifcmd'"' != "" {
		local netexp ""
		capture nw_expnetexp `ifcmd', nodes(`nodes')
		local ifnetexp `"`netexp'"'
		local cndcmd `"`cndcmd' :* `ifnetexp'"'
	}
	
	if `"`ifegocmd'"' != "" {
		local netexp ""
		capture nw_expnetexp `ifegocmd', nodes(`nodes')
		local ifegonetexp `"`netexp'"'
		local cndcmd `"(`cndcmd') :* (`ifegonetexp')"'
	}
	
	if `"`ifaltercmd'"' != "" {
		local netexp ""
		capture nw_expnetexp `ifaltercmd', nodes(`nodes')
		local ifalternetexp `"`netexp'"'
		local cndcmd `"(`cndcmd') :* (`ifalternetexp')'"'
	}

	if `"`cndcmd'"' != "" {
		local cmd `"`newcmd' = ((`newnetexp' :* (`cndcmd')) + (`newcmd0' :* ((`cndcmd') :!= 1)))`subset'"'  
	}
	else {
		local cmd `"`newcmd' = (`newnetexp')`subset'"'
	}
	
	mata: `cmd'
	mata: `netobj'->invalidate_sparse()

	nw_syntax `netname'
	mata: st_numscalar("r(symmetric)", `netobj'->check_symmetry())
	mata: st_numscalar("r(valued)", `netobj'->check_valued())
	if ("`directed'"=="false" & `r(symmetric)'==0) {
		nw_name `netname', newdirected(false)
	}
	if ("`valued'" == "false" & "`r(valued)'" == "false"){
		nw_name `netname', newvalued(true)
	}
	// BUGFIX: r(symmetric)/r(valued) were computed via raw
	// st_numscalar("r(...)", ...) but this program was never declared
	// rclass, and its own final `nwsync' call (a separate ado
	// invocation) clears the r()-results area before nwreplace itself
	// returns - so these values were always wiped, never visible to a
	// caller, despite being genuinely computed (not simply unused). Kept
	// the existing internal computation (still needed for the
	// directed/valued checks just above, before nwsync ever runs) but
	// captured into plain locals first, then re-exposed via `return
	// scalar' - which, unlike raw st_numscalar, survives whatever a
	// nested command does internally, since Stata only finalizes an
	// rclass program's own returned r()-results once the program itself
	// actually exits.
	local __symmetric = `r(symmetric)'
	local __valued = `r(valued)'
	nwsync `netname'
	return scalar symmetric = `__symmetric'
	return scalar valued = `__valued'

end

