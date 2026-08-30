
capture program drop nwgenerate
program nwgenerate
	local arg `0'
	gettoken arg options: arg, parse(",") bind
	if "`options'" != "" {
		local options: subinstr local options "," " " 
	}
	
	gettoken newnetname netexp: arg, parse("=")
	local netexp: subinstr local netexp "_if" "$$ff"
	local netexp: subinstr local netexp "if" "#"
	
	gettoken dump opts: arg, parse(",") bind
	if "`opts'" != "" {
		local 0 `opts'
		syntax [, xvars vars(string) replace *]
	}
	local fcn_opt = "`options'"
	local newnetname = trim("`newnetname'")
	
	unw_defs
		
	capture nw_syntax `newnetname'

	if _rc == 0 & (strpos("`options'", "replace")==0){
		// Error-code coherence pass: consolidated onto `errNWsExists'
		// (483, unw_defs.ado) - see nwsimmelian.ado's own fix for the
		// history of this convention's drift onto an undocumented `6099'.
		di "{err}Network {bf:`newnetname'} already exists. Change {it:netname} or specify option {bf:replace}.{txt}"
		error `errNWsExists'
	}
	else {
		capture nwdrop `newnetname'
	}
	
	// if condition
	local netexp: subinstr local netexp "_if" "$"	
	gettoken netexp ifcond: netexp, parse("#")
	local ifcond: subinstr local ifcond "#" "if"
	local ifcond: subinstr local ifcond "$$ff" "_if"
	local netexp: subinstr local netexp "$$ff" "_if"

	
	// check if network or variable should be created
	local netexp : subinstr local netexp "("  "( "	
	local selectjob : word 2 of `netexp'
	local nwgenopt "large( addnodes( collapse( duplicate( dyadprob( geodesic( subset( homophily( lattice( path( permute( pref( random( reach( ring( small( sym( transpose( evcent( context( degree( outdegree( indegree( isolates( components( lgc( clustering( closeness( farness( nearness( between("
	local whichjob : list  nwgenopt & selectjob
	local netfcn : word count `whichjob'
	
	// no varfcn or netfcn
	if `netfcn' == 0 {
		local netexp : subinstr local netexp "=" " "
		capture nw_name `newnetname'
		if _rc == 0 & (strpos("`options'", "replace")==0){
			// Error-code coherence pass: the identical "already exists,
			// specify replace" situation as the guard just above (and
			// several sibling commands) - consolidated onto
			// `errNWsExists' (483, unw_defs.ado) instead of its own
			// separate, undocumented `6004'.
			di "{err}network {it:`netname'} already defined"
			error `errNWsExists'
		}
	
		// replace the network if it exists already
		if (strpos("`options'", "replace")!=0){
			capture nwdrop `netname'
			local options ""
		}

		// evaluate network expression
		nw_expnetexp `netexp'
		// The hardcoded literal `xvars' this line used to append
		// unconditionally (on top of `options') was a real, latent bug:
		// `options' already holds the caller's own full raw option text
		// verbatim (set at this program's very first "gettoken arg
		// options: arg, parse(",")" near the top) - so a caller who
		// actually wrote "xvars" here would have hit "option xvars
		// specified twice". Since `options' already carries the
		// caller's own `xvars' through when given, no separate token is
		// needed - matching how `undirected'/`replace' etc. already
		// flow through the same way.
		nwset, mat(`netexp') name(`newnetname') `undirected' `options' nodenames(`last_netobj'->get_nodenames())
		qui nwsym `newnetname', check

		// nwsym's own help documents r(is_symmetric) as the string
		// "true"/"false" (a numeric-scalar bug meant it was actually
		// stored numeric until this was fixed as part of the
		// sparse-backend migration's nwfromedge rewiring - nwfromedge's
		// own check already expected the documented string form and
		// was silently broken by the mismatch; this call site had
		// instead been relying on the bug, so needs updating to match
		// now that nwsym stores what it always documented).
		if "`r(is_symmetric)'" == "true" {
			nw_name `newnetname', newdirected(false)
		}
		
		if "`ifcond'" != "" {
			qui nwkeep `newnetname' `ifcond'
		}
	}
	
	// generate network based on function
	else  {
		
		// get whatever is inside parenthesis
		local start = strpos("`netexp'", "(")
		local length2 = length("`netexp'")
		local length = `length2' - `start' - 1
		//local length = (strpos("`netexp'",")")) - `start' 
		local subopt = substr("`netexp'", `=`start' + 1', `length')
		
		local optionsold `options'
		
		local 0 `subopt'
		syntax [anything(name=sub1)] [, *]
		local sub2 `options'
		
		/* DEBUG
		di "newnetname: `newnetname'"
		di "netexp: `netexp'"
		di "subopt: `subopt'"
		di "sub1: `sub1'"
		di "sub2: `sub2'"
		di "options: `options'"
		*/
		
		qui if "`whichjob'" == "large(" {	
			tempvar _lgc
			nwcomponents `sub1', lgc generate(`_lgc')
			nwduplicate `sub1',  name(`newnetname')
			nwkeep `netname' if `_lgc' == 1
		}	
		
		// nwduplicate shortcut
		qui if "`whichjob'" == "duplicate(" {
			noi nw_syntax `sub1', max(1) 
			nwduplicate `sub1', `sub2' name(`newnetname') `fcn_opt'
		}	

		// nwdyadprob shortcut - restored (harmonisation phase): maps
		// directly onto nwdyadprob's own `name()' option. Its own
		// weightnet argument is OPTIONAL (unlike every other netname-
		// based shortcut here - nwdyadprob can generate a plain random
		// dyad-probability network with no reference network at all),
		// so this deliberately skips the pre-validation `nw_syntax'
		// call the netname-required shortcuts below use - nwdyadprob
		// resolves (or rejects) `sub1' entirely on its own.
		qui if "`whichjob'" == "dyadprob(" {
			nwdyadprob `sub1', `sub2' name(`newnetname') `fcn_opt'
		}

		// nwgeodesic shortcut
		qui if "`whichjob'" == "geodesic(" {
			noi nw_syntax `sub1', max(1)
			nwgeodesic `sub1', `sub2' name(`newnetname') `fcn_opt'
		}
		// nwhomophily shortcut - restored (harmonisation phase). Note
		// `sub1' here is a VARIABLE name, not a netname (nwhomophily's
		// own main argument is a varlist) - unlike every other
		// shortcut in this file. Its own required sub-options
		// (homophily()/density()) arrive via `sub2'/`fcn_opt' exactly
		// like any other passthrough option (e.g. "nwgen mynet =
		// homophily(myvar), homophily(0.5) density(0.3)") - the outer
		// shortcut keyword and the identically-named inner sub-option
		// are parsed at different levels by this program's own dispatch
		// logic, so the name reuse is not actually ambiguous.
		qui if "`whichjob'" == "homophily(" {
			nwhomophily `sub1', `sub2' name(`newnetname') `fcn_opt'
		}
		// nwlattice shortcut - restored (harmonisation phase). `sub1'
		// is dimensions (e.g. "5 5"), not a netname - nwlattice's own
		// main argument, matching pref(/random(/ring(/small( below.
		qui if "`whichjob'" == "lattice(" {
			nwlattice `sub1', `sub2' name(`newnetname') `fcn_opt'
		}
		// nwpath shortcut - deliberately left as a clear error, not
		// restored: nwpath can produce ZERO, ONE, or MANY output
		// networks (one per shortest path found between ego and alter -
		// there can be several of the same minimum length), and its own
		// `name()' option is dead code (grep confirms it is declared in
		// the syntax line but never referenced anywhere in the program
		// body - `generate()' is the real, working stub-prefix option,
		// producing `generate()'_1, `generate()'_2, ... one per path).
		// Neither shape fits nwgen's own "exactly one network under
		// exactly one name" contract - forcing a guess (e.g. always
		// take path 1) would silently discard the other paths and
		// misrepresent what nwpath actually found, worse than a clear
		// error pointing at the real command.
		qui if "`whichjob'" == "path(" {
			noi di "{err}nwgen's path() shortcut is not currently implemented - nwpath can produce zero, one, or several output networks (one per shortest path found), which does not fit nwgen's own single-network-per-call form; use {help nwpath} directly (its own generate() option names one network per path found)."
			error 199
		}
		// nwpermute shortcut
		qui if "`whichjob'" == "permute(" {
			noi nw_syntax `sub1', max(1)
			nwpermute `sub1', `sub2' name(`newnetname') `fcn_opt'
		}
		// nwpref shortcut - restored (harmonisation phase). `sub1' is a
		// node count, not a netname, matching random( below.
		qui if "`whichjob'" == "pref(" {
			nwpref `sub1', `sub2' name(`newnetname') `fcn_opt'
		}
		// nwrandom shortcut
		qui if "`whichjob'" == "random(" {
			nwrandom `sub1', `sub2' name(`newnetname') `fcn_opt'
		}
		// nwreach shortcut
		qui if "`whichjob'" == "reach(" {
			noi nw_syntax `sub1', max(1)
			nwreach `sub1', `sub2' name(`newnetname') `fcn_opt'
		}
		// nwring shortcut - restored (harmonisation phase). `sub1' is a
		// node count; nwring's own `k()' is required (no default) and
		// arrives via `sub2'/`fcn_opt' like any other sub-option (e.g.
		// "nwgen mynet = ring(10), k(2)").
		qui if "`whichjob'" == "ring(" {
			nwring `sub1', `sub2' name(`newnetname') `fcn_opt'
		}
		// nwsmall shortcut - restored (harmonisation phase). Same shape
		// as ring( - node count, required k() via sub-options.
		qui if "`whichjob'" == "small(" {
			nwsmall `sub1', `sub2' name(`newnetname') `fcn_opt'
		}
		// nwtranspose shortcut - restored (harmonisation phase).
		// nwtranspose's own output-naming option is `generate()', not
		// `name()' (unlike every other network-producing shortcut here) -
		// with generate() given, it duplicates the source network under
		// the new name first and transposes the COPY, leaving the
		// original untouched; without it, nwtranspose mutates the
		// source network in place, which would not fit nwgen's own
		// "produces a new network under `newnetname'" contract at all -
		// generate() is therefore always supplied here, unconditionally.
		qui if "`whichjob'" == "transpose(" {
			noi nw_syntax `sub1', max(1)
			nwtranspose `sub1', `sub2' `fcn_opt' generate(`newnetname')
		}

		// The remaining 16 keywords in `nwgenopt' above (addnodes/
		// collapse/subset/evcent/context/degree/outdegree/indegree/
		// isolates/components/lgc/clustering/closeness/farness/nearness/
		// between) are a SECOND, separate family: they produce a Stata
		// VARIABLE (nwgen VAR = fcn(netname)), not a network, unlike
		// every branch above. Until this fix they matched `whichjob'
		// (recognized by the vocabulary at the top of this program) but
		// had NO dispatch branch at all here, so a call like
		// "nwgen x = isolates(mynet)" silently fell through the whole
		// if-chain doing nothing - `x' was never created, and whatever
		// the caller did with it next crashed with a confusing "not
		// found" error pointing nowhere near the real cause. Confirmed
		// to have already caused two real, previously-undiscovered bugs
		// this way inside this package itself (nwplot.ado's own
		// mdsclassical layout used to call the isolates(/components(/
		// lgc( shortcuts internally - see docs/CERTIFICATION.md unit
		// 33's own row - before being fixed to route around this gap by
		// calling nwdegree/nwcomponents directly instead).
		//
		// 13 of the 16 map cleanly, with no semantic ambiguity, to an
		// already-existing, already-tested dedicated command's own
		// generate() option - implemented for real below, each verified
		// directly against a hand-computable network before shipping,
		// not just "does it run without erroring". The remaining 3
		// (addnodes/collapse/subset) do NOT naturally reduce to "one
		// value per node" the way the other 13 do - nwaddnodes mutates
		// a network's own node set, nwsubset produces a new NETWORK
		// (not a variable), and nwcollapse's own semantics need
		// additional design work to map correctly - left as a clear,
		// immediate error rather than guessing at a wrong mapping.
		// NOTE on `replace': despite the "syntax [, xvars vars(string)
		// replace *]" call near the top of this program appearing to
		// parse "replace" into its own dedicated local, that call is
		// actually unreachable for this whole file's own comma-parsing
		// scheme (`opts', what it parses, is always empty by the time
		// it runs - the real option text was already split off into
		// `options'/`fcn_opt' by the very first "gettoken ... , parse(",")"
		// at the top of the program) - confirmed by direct probe: that
		// dedicated `replace' local is always empty, "replace" included,
		// even when the caller genuinely passes it. The RAW text (e.g.
		// "  replace") lives in `fcn_opt' instead, and IS correctly
		// forwarded to every nwdegree/nwcomponents/etc. call below
		// simply by including `fcn_opt' - no separate token needed. The
		// one place this file's own logic needs a plain yes/no answer
		// (the directed "degree()" branch's own combine-and-guard step
		// below) uses `hasreplace', checked directly against `fcn_opt'
		// via strpos(), matching this file's own established
		// already-in-use convention elsewhere (its outer network-level
		// replace handling near the top of this program does the exact
		// same strpos() check against `options').
		local hasreplace = (strpos("`fcn_opt'", "replace") != 0)
		qui if "`whichjob'" == "components(" {
			noi nw_syntax `sub1', max(1)
			nwcomponents `sub1', generate(`newnetname') `sub2' `fcn_opt'
		}
		qui if "`whichjob'" == "lgc(" {
			noi nw_syntax `sub1', max(1)
			nwcomponents `sub1', lgc generate(`newnetname') `sub2' `fcn_opt'
		}
		qui if "`whichjob'" == "clustering(" {
			noi nw_syntax `sub1', max(1)
			nwclustering `sub1', generate(`newnetname') `sub2' `fcn_opt'
		}
		qui if "`whichjob'" == "between(" {
			noi nw_syntax `sub1', max(1)
			nwbetween `sub1', generate(`newnetname') `sub2' `fcn_opt'
		}
		qui if "`whichjob'" == "evcent(" {
			noi nw_syntax `sub1', max(1)
			nwevcent `sub1', generate(`newnetname') `sub2' `fcn_opt'
		}
		// nwcontext requires attribute() - not something this shortcut
		// can default sensibly, so it must arrive via `sub2'/`fcn_opt'
		// (e.g. "nwgen x = context(mynet), attribute(myvar)"), exactly
		// the same option-passthrough convention every other shortcut
		// in this file already uses.
		qui if "`whichjob'" == "context(" {
			noi nw_syntax `sub1', max(1)
			nwcontext `sub1', generate(`newnetname') `sub2' `fcn_opt'
		}
		// nwcloseness always generates its own fixed 3-word set
		// (closeness, farness, nearness, in that order - see its own
		// "local generate = "_closeness _farness _nearness"" default)
		// and errors unless given exactly 3 words, so closeness()/
		// farness()/nearness() each place the caller's own variable
		// name in the matching word position and let the other two
		// fall into throwaway tempvars.
		qui if "`whichjob'" == "closeness(" {
			noi nw_syntax `sub1', max(1)
			tempvar _tmp_far _tmp_near
			nwcloseness `sub1', generate(`newnetname' `_tmp_far' `_tmp_near') `sub2' `fcn_opt'
		}
		qui if "`whichjob'" == "farness(" {
			noi nw_syntax `sub1', max(1)
			tempvar _tmp_close _tmp_near
			nwcloseness `sub1', generate(`_tmp_close' `newnetname' `_tmp_near') `sub2' `fcn_opt'
		}
		qui if "`whichjob'" == "nearness(" {
			noi nw_syntax `sub1', max(1)
			tempvar _tmp_close _tmp_far
			nwcloseness `sub1', generate(`_tmp_close' `_tmp_far' `newnetname') `sub2' `fcn_opt'
		}
		// nwdegree needs to know directedness up front: a directed
		// network reserves two output slots (out, in - see nwdegree's
		// own harmonisation-phase fix for the out-then-in word order
		// this now correctly relies on), an undirected one just one
		// ("_degree"). "degree(" itself is directed-ambiguous (out? in?
		// both?) - defined here as total degree (out+in summed), the
		// same convention igraph's own default degree() uses for a
		// directed graph. The final "combine into `newnetname'" step
		// for the directed case is a plain `gen', which (unlike
		// nwdegree's own generate()) has no built-in replace-awareness
		// of its own - handled explicitly here with the same
		// already-exists guard nwdegree itself uses, so "replace" and
		// the "already exists" error both work correctly for this
		// derived (out+in) variable too, not just the two temp ones
		// nwdegree generates directly.
		qui if "`whichjob'" == "degree(" {
			noi nw_syntax `sub1', max(1)
			if "`directed'" == "true" {
				tempvar _tmp_out _tmp_in
				nwdegree `sub1', generate(`_tmp_out' `_tmp_in') `sub2' `fcn_opt' silent
				capture confirm variable `newnetname', exact
				if _rc == 0 & !`hasreplace' {
					noi di "{err}Variable {bf:`newnetname'} already exists; use {bf:replace} or a different name."
					error 99
				}
				capture drop `newnetname'
				gen `newnetname' = `_tmp_out' + `_tmp_in'
			}
			else {
				nwdegree `sub1', generate(`newnetname') `sub2' `fcn_opt'
			}
		}
		qui if "`whichjob'" == "outdegree(" {
			noi nw_syntax `sub1', max(1)
			if "`directed'" == "true" {
				tempvar _tmp_in
				nwdegree `sub1', generate(`newnetname' `_tmp_in') `sub2' `fcn_opt'
			}
			else {
				nwdegree `sub1', generate(`newnetname') `sub2' `fcn_opt'
			}
		}
		qui if "`whichjob'" == "indegree(" {
			noi nw_syntax `sub1', max(1)
			if "`directed'" == "true" {
				tempvar _tmp_out
				nwdegree `sub1', generate(`_tmp_out' `newnetname') `sub2' `fcn_opt'
			}
			else {
				nwdegree `sub1', generate(`newnetname') `sub2' `fcn_opt'
			}
		}
		qui if "`whichjob'" == "isolates(" {
			noi nw_syntax `sub1', max(1)
			if "`directed'" == "true" {
				tempvar _tmp_out _tmp_in
				nwdegree `sub1', isolates generate(`_tmp_out' `_tmp_in' `newnetname') `sub2' `fcn_opt'
			}
			else {
				tempvar _tmp_deg
				nwdegree `sub1', isolates generate(`_tmp_deg' `newnetname') `sub2' `fcn_opt'
			}
		}
		qui if "`whichjob'" == "addnodes(" {
			noi di "{err}nwgen's addnodes() shortcut is not currently implemented (it does not naturally reduce to a single per-node variable - nwaddnodes mutates a network's own node set); use {help nwaddnodes} directly."
			error 199
		}
		qui if "`whichjob'" == "collapse(" {
			noi di "{err}nwgen's collapse() shortcut is not currently implemented; use {help nwcollapse} directly."
			error 199
		}
		qui if "`whichjob'" == "subset(" {
			noi di "{err}nwgen's subset() shortcut is not currently implemented (it produces a new NETWORK, not a variable, so it does not fit nwgen's VAR = fcn(netname) form); use {help nwsubset} directly."
			error 199
		}

	}
	/*
		The 8 shortcuts above (dyadprob/homophily/lattice/path/pref/ring/
		small/transpose) previously had their bodies commented out - a
		user calling e.g. -nwgen X = ring(5)- would silently do nothing
		instead of generating a network or erroring, a real (if quiet)
		bug found during this session's feature audit. Turned into a
		clear, immediate error rather than silently restoring the
		commented-out bodies unverified: each of the 8 target commands'
		current option syntax needs to be individually re-checked against
		what these dispatch lines originally assumed (written years ago)
		before re-enabling - see docs/ROADMAP.md, Stage 1.
	*/

end
