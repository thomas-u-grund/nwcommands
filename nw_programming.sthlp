{smcl}
{* *! version  30nov2014}{...}
{phang}
{help nwcommands:NW-5 programming} {hline 2} Network programming


{title:Contents}	
			
{col 14}Section{col 31}Description
{col 14}{hline 46}
{help nw_programming##programming:{col 14}{bf:[NW-5.1]}{...}{col 31}{bf:Writing own programs}}

{help nw_programming##modernprogramming:{col 14}{bf:[NW-5.2]}{...}{col 31}{bf:Modern (class-based, sparse-backend) programming}}

{help nw_programming##internaldesign:{col 14}{bf:[NW-5.3]}{...}{col 31}{bf:Internal design (legacy, pre-2016)}}




{marker programming}{...}
{title:Writing own network programs}

{pstd}
Writing own network programs is very easy. The nwcommands offer several helper programs that can be
included in such programs (see e.g. {help nwtomata}, {help nw_syntax}).

{pstd}
Let us write our own program {it:myindegree} to calculte indegree centrality (see {help nwdegree}) of a
network {help netname}. Let us program it in such a way that it can be called with a {help netname} as an argument
and an option {bf:generate()} to save the result.

	{com}capture program drop myindegree
	program myindegree
		syntax [anything(name=netname)] , [ generate(string)]

		nw_syntax `netname'
		nwtomata `netname', mat(net)

		local generate = cond("`generate'"=="", "_myindegree", "`generate'")

		mata: indegree = colsum(net)'
		getmata `generate' = indegree, force
		mata: mata drop indegree net
	end{txt}

{pstd}
The logic of this little program is that after normal use of {help syntax}, {help nw_syntax} is called to check if {it:anything}
is a valid network and (if necessary) unabbreviates it (this is very similar to {help syntax}). By default, nw_syntax only allows one
network in {it:anything}, which is just what we want. When used with the defaults, nw_syntax also leaves a local macro {it:netname} behind
which holds the unabbreviated network name. Next, in {bf:nwtomata} we refer to this {it:netname} and obtain a Mata matrix {it:net} from
this network.

{pstd}
The line {bf:local generate = cond("`generate'"=="", "_myindegree", "`generate'")} just assigns
a default variable name in case option {bf:generate()} is unspecified.

{pstd}
Now we have the adjacency matrix of the network and can easily calcualted {it:indegree} as {bf:colsum(net)'}.

{pstd}
Lastly, we bring the result, which is stored in the Mata matrix {it:indegree}, back to Stata with {bf:getmata}. 

{pstd}
The program is called like this using the {help netexample:Florentine data}. It generates the Stata variable {it:myindegree_flomarriage}.

	{cmd:. nwwebuse florentine, nwclear}
	{cmd:. myindegree flomarriage, generate(myindegree_flomarriage)}	

	
	
{title:Writing own network generator}

{pstd}
Let us write another simple program which takes an existing network as an argument, inverses the adjacency matrix and saves the result as a new network.

	{com}capture program drop myinverse
	program myinverse
		syntax [anything(name=netname)] , [ generate(string)]

		nw_syntax `netname'
		nwtomata `netname', mat(net)

		local generate = cond("`generate'"=="", "_myinverse", "`generate'")

		mata: inverse = (net :== 0)
		nwset, mat(inverse) name("`generate'")
		mata: mata drop net inverse
	end{txt}

{pstd}
As you can see, the structure of the program is very similar to the one above. The first few lines
are almost identical. Again, we perform some checks and obtain the adjacency matrix of the network
as Mata matrix {it:net}. The line {bf:mata: inverse = (net :== 0)} simply inverts a binary matrix.
Afterwards, all we have to do is {help nwset} a new network using the option {bf:mat()}.

{pstd}
Now we can generate the network {it:flomarriage_inverse} as the inverse of {it:flomarriage} like this:

	{cmd:. nwwebuse florentine, nwclear}
	{cmd:. myinverse flormarriage, name(flomarriage_inverse)}
	

{marker modernprogramming}{...}
{title:Modern (class-based, sparse-backend) programming}

{pstd}
The examples above ({bf:[NW-5.1]}) and the "Internal design" section below ({bf:[NW-5.3]}) describe
the package's original (pre-2016) architecture, where a network was a loose collection of global
macros plus a dense Mata matrix. That architecture is superseded. Since network state moved to real
Mata classes (currently: {bf:NWs} - the session-wide container; {bf:NWsdef} - a named collection of
networks; {bf:NWdef} - one network, aliased {bf:nw_def} in most command code), and since a sparse
CSR/CSC edge index was added alongside the still-present dense adjacency matrix, {it:new} commands
should follow the conventions in this section, not the ones above. This section exists because the
package's own roadmap and certification standard call for documenting the internal programming API
as it matures - the patterns and pitfalls below were all discovered first-hand while extending the
package (see {help nwkcore}, {help nwaltergen}, {help nwsimindex}, {help nwcug} for worked examples
of every pattern described here).

{pstd}
{bf:Entering a network's context.} Use {bf:nw_syntax}, not the historical {bf:_nwsyntax}. Called as
{bf:nw_syntax `netname'}, it leaves behind (via {help c_local}) a standard set of local macros every
command relies on:

	{col 6}{bf:netobj}{col 20}a Mata pointer expression, {bf:`nws'.pdefs[`id']}, usable directly
	inside any {bf:mata:} line as {bf:`netobj'->method()}
	{col 6}{bf:nodes}{col 20}number of nodes (also the row/column count of the dense matrix, and
	the valid range for node indices used with the sparse accessors below)
	{col 6}{bf:directed}, {bf:valued}, {bf:is2mode}, {bf:selfloops}{col 20}"true"/"false" strings
	{col 6}{bf:netname}{col 20}the resolved, unabbreviated network name
	{col 6}{bf:labs}{col 20}comma-joined node names, ready for {bf:nwset, ... labs(`labs')}

{pstd}
{bf:Writing a per-node statistic.} The established convention (not enforced by the language, but
followed by every {bf:calculate_*()} method added since the sparse backend) is: add a method to the
{bf:NWdef} class in {bf:unw_core.do} that returns a {bf:real matrix} (an {it:n} x 1 column vector,
row {it:i} = node {it:i}'s value), then call it from the {bf:.ado} file like this:

	{com}nw_syntax `netname'
	tempname __nw_result
	mata: `__nw_result' = `netobj'->calculate_something()
	mata: st_store((1::`nodes'), "`generate'", `__nw_result')
	mata: mata drop `__nw_result'{txt}

{pstd}
{bf:Sparse accessors.} {bf:NWdef} maintains a lazily-built CSR (out-neighbors) / CSC (in-neighbors,
directed only) index alongside the dense matrix. Prefer these over the dense
{bf:get_matrix()}/{bf:get_matrix_mod()} pointer whenever the underlying algorithm only ever touches a
node's actual neighbors (most centrality, cohesion, and similarity measures do) - it is both faster on
large sparse networks and, in practice, easier to get right, since dense-matrix code invites the
missing-diagonal and broadcasting pitfalls described below.

	{col 6}{bf:neighbors(i)}{col 25}column vector of {it:i}'s out-neighbors (all neighbors, for an
	undirected network)
	{col 6}{bf:neighbors_in(i)}{col 25}column vector of {it:i}'s in-neighbors (same as
	{bf:neighbors(i)} for undirected)
	{col 6}{bf:degree(i)}, {bf:degree_in(i)}{col 25}neighbor counts, O(1)
	{col 6}{bf:has_edge(i,j)}, {bf:edge_weight(i,j)}{col 25}single-edge lookups
	{col 6}{bf:edgelist()}{col 25}sparse-native (source, target, weight) triplet enumeration

{pstd}
For directed networks, whether "neighbor" should mean out-neighbors, in-neighbors, or the union of
both depends on what question the statistic answers - not on convention alone. This session settled
on two different defaults for two different kinds of question, and both are worth following rather
than re-deciding case by case: an {it:undirected-sense structural} question (is this node in a dense
core? do these two nodes' neighborhoods overlap?) uses the union of both directions
({help nwkcore}, {help nwsimindex}); a {it:directional influence/exposure} question (what are my
contacts' attribute values?) uses out-neighbors only ({help nwaltergen}).

{pstd}
{bf:Pitfalls found the hard way this session.} Every one of these produced a real, working-as-
intended-until-tested bug during this package's own development - each is worth reading once rather
than rediscovering:

{p 6 10 2}
1. A Mata function argument that expects to write through a pointer or output parameter must receive
an actual macro reference, not a quoted string - wrapping a {bf:tempname} macro in quotes
(e.g. {bf:"`__nwnew'"} instead of {bf:`__nwnew'}) turns pass-by-reference into a string literal and
silently breaks the call. Prefer a plain value-returning Mata function
({bf:mata: `__nwnew' = somefunction(...)}) over a void function with output parameters wherever
possible - it sidesteps this class of bug entirely, and is the pattern used throughout this section.
{p_end}

{p 6 10 2}
2. {bf:selectindex()} preserves the orientation of its input (row in, row out; column in, column
out) - it does not always return a column vector. Transpose explicitly when the input might be a row
vector (e.g. a string row vector of mode labels) and downstream code assumes column indexing.
{p_end}

{p 6 10 2}
3. A single missing value anywhere in a matrix poisons an entire dot-product sum through ordinary
Mata matrix multiplication. This package's own no-self-loop convention represents a missing diagonal
as {bf:.} (see {bf:nwtomata}) - any {bf:net*net}-style product on such a matrix silently returns all
missing unless the diagonal is zeroed first ({bf:_diag(net, J(n,1,0))}).
{p_end}

{p 6 10 2}
4. Mata's elementwise operators ({bf::+}, {bf::*}, ...) do {bf:not} broadcast a column vector against
a row vector the way NumPy or R do - {bf:colvec :+ colvec'} is a conformability error, not a
silently-wrong {it:n} x {it:n} result. Build the {it:n} x {it:n} sum/product explicitly instead:
{bf:(colvec * J(1,n,1)) :+ (J(n,1,1) * colvec')}.
{p_end}

{p 6 10 2}
5. {bf:return scalar x = ...} only {it:publishes} {bf:r(x)} to the calling context once the current
program actually exits - {bf:r(x)} reads as missing from inside the same program body that just set
it. Any display logic that runs after a {bf:return scalar} but before the program ends must reference
the underlying local or Stata scalar directly, not {bf:r(x)}.
{p_end}

{p 6 10 2}
6. Referencing an r-class result that was never set, e.g. {bf:r(typo_name)}, does not raise an error
- it silently evaluates to missing. A validation guard that only checks for an empty string will miss
this; check for {bf:"."} as well.
{p_end}

{p 6 10 2}
7. A successful {bf:assert} or {bf:di} does {bf:not} reset Stata's ambient {bf:_rc}. If an earlier
{bf:capture badcmd} block left {bf:_rc} non-zero, it stays non-zero for the rest of that do-file's
execution regardless of what runs afterward. Code that inspects {bf:_rc} after running an entire
do-file (as {bf:nw_helpwriter} does, to decide whether to certify a command's documentation) should
use {bf:capture noisily do file.do} and check {it:that} capture's own {bf:_rc}, not the ambient value.
{p_end}

{p 6 10 2}
8. The single-line interactive form {bf:mata: if (cond) statement} is not valid syntax for Mata's
one-statement command mode ("unexpected end of line"). Restructure to avoid a bare conditional on an
interactive {bf:mata:} line - e.g. an empty-index assignment such as {bf:x[idx] = val} is already a
safe no-op in Mata when {bf:idx} has zero rows, so the guarding {bf:if} is often unnecessary in the
first place.
{p_end}

{p 6 10 2}
9. A literal pair of backtick characters used as markdown-style emphasis inside a {bf:.ado} file's
comment (e.g. two backticks around a word, as inline code-style emphasis is sometimes written in
other languages) - anywhere in the file, doc header or program body
alike - crashes {bf:nw_helpwriter}'s line-copy loop with a genuine "too few quotes" parse error, since
that loop macro-processes every line of the file unconditionally before deciding whether to write it.
Use plain quotes for emphasis in comments instead of backticks.
{p_end}

{p 6 10 2}
10. This codebase compiles with {bf:set matastrict on} throughout {bf:unw_core.do} - every local used
in a Mata function must be declared ({bf:real scalar}, {bf:real matrix}, {bf:pointer(...)}, etc.)
before use, including loop counters and temporaries that a looser Mata script would let you introduce
implicitly.
{p_end}

{pstd}
{bf:Testing and certification.} Every new or modified {bf:calculate_*()} method or command should get
a {bf:cscripts/test_X.do} file, following the {bf:cscript} + {bf:do unw_core.do} + hand-computable
worked examples pattern used throughout the existing suite - see any file added or extended this
session for the current house style. After a dev-mode pass, copy the file to
{bf:lib/cscripts_prod/} with {bf:do unw_core.do} stripped and
{bf:adopath + "<repo>/lib"} prepended, and confirm it also passes against the {it:compiled}
{bf:lib/lnwcommands.mlib} (rebuilt via {bf:lib/build.do} whenever {bf:unw_core.do} changes) - this is
the only way to catch a mismatch between the Mata source and what actually ships. Regenerate a
command's {bf:.sthlp} with {bf:nw_helpwriter `cmdname'} after any change to its
{bf:/*** ... ***/} doc header; it also re-certifies (appends a "last certified" line) whenever the
command's own test file passes.


{marker internaldesign}{...}
{title:Internal design (legacy, pre-2016)}

{pstd}
This section documents the {it:original} (pre-2016) network storage design; see {bf:[NW-5.2]} above
for how the package actually works today. It is kept here for historical/reference value only - do
not use this design for new code.

{pstd}
So far, networks are stored in Stata as "quasi-objects", that means they are not internally stored as real Stata objects, but as a
loose collection of global macros and Mata matrices that behave together like an object. In future versions of the nwcommands, the
internal design is likely to change to draw on proper object-oriented programming available in Stata.

{pstd}
The {help macro:global macro} {bf:nwtotal} holds the total number of networks in memory. When the first network is loaded, generated or set, this
macro is initialized to 1.

{pstd}
Whenever a network is generated a set of other global macros holding some meta-information about this network are initialized as well. For example,
the following code produces a random network and shows the relevant global macros afterwards:

	{com}. nwclear
	. nwrandom 4, prob(.2)
	{com}. macro list{txt}
	
{txt}{p 10 26}nwlabs_1:{space 7}{res}{res}net1 net2 net3 net4
{p_end}
{txt}{p 10 26}nwsize_1:{space 7}{res}{res}4
{p_end}
{txt}{p 10 26}nwdirected_1:{space 3}{res}{res}true
{p_end}
{txt}{p 10 26}nw_1:{space 11}{res}{res}net1 net2 net3 net4
{p_end}
{txt}{p 10 26}nwname_1:{space 7}{res}{res}random
{p_end}
{txt}{p 10 26}nwtotal_mata:{space 3}{res}{res}1
{p_end}
{txt}{p 10 26}nwtotal:{space 8}{res}{res}1
{p_end}
{txt}
	
{pstd}
Furthermore, most importantly a Mata matrix called {it:nw_mata1} has been generated as well, 
which holds the adjacency matrix of the network.

	{com}. mata: mata desc

      {txt}# bytes   type                        name and extent
{hline 79}
{res}          128   {txt}real matrix                 {res}nw_mata1{txt}[4,4]
{hline 79}

	{com}. mata: nw_mata1
      {res}       {txt}1   2   3   4
          {c TLC}{hline 17}{c TRC}
	1 {c |}  {res}0   1   1   1{txt}  {c |}
	2 {c |}  {res}0   0   1   0{txt}  {c |}
	3 {c |}  {res}0   0   0   0{txt}  {c |}
	4 {c |}  {res}1   0   0   0{txt}  {c |}
          {c BLC}{hline 17}{c BRC}

		  
{pstd}
All nwcommands internally operate with this design. Hence, manipulating some of these
global macros or Mata matrices without using the proper nwcommands can cause problems and 
crashes.


{title:See also}

	{help _nwevalnetexp}, {help nw_syntax}, {help nwtomata}
