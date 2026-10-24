capture program drop nwrecode
program nwrecode
	version 9
	syntax anything(name=arg) [, into(string) generate(string) prefix(string) *]

	if "`arg'" == "" {
		exit
	}
	
	if "`into'" != "" {
		local generate "`into'"
	}
	
	local ruleStart = strpos("`arg'", "(")
	local netname = substr("`arg'",1, `=`ruleStart'-1')
	local rules = substr("`arg'",`ruleStart',.)

	// was "_nwsyntax_other `netname', max(9999)" - _nwsyntax_other is
	// incompatible with the modern network storage architecture (it
	// references a legacy nw_mata<id> Mata global that no longer
	// exists - the same bug already found and fixed in nwcloseness
	// this session). _nwsyntax's own other() option gives the exact
	// same othernetname/othernodes/otherid/otherdirected naming
	// convention _nwsyntax_other used, so it's a direct drop-in.
	_nwsyntax `netname', max(9999) other(other)

	preserve
	tokenize `generate'
	local i = 1
	foreach onenet in `othernetname' {
		// was "_nwsyntax `onenet'" - the deprecated _nwsyntax wrapper
		// never re-exports `directed' at all (only netobj/id/netname/
		// networks), so this local was always empty; _nwsyntax
		// exports it directly.
		_nwsyntax `onenet'
		local onedirected `directed'

		// The recode is applied to the DISTINCT tie values (with the number
		// of dyads holding each, zeros included), not to a listing of all
		// N x N dyads: Stata's own recode on a small dataset, so every rule
		// form recode knows works, and then the stored ties take the new
		// values.  O(ties).
		drop _all
		mata: `netobj'->value_counts_to_vars(0, "`onenet'", "__nwrec_fq")
		qui gen double __nwrec_old = `onenet'
		if `"`options'"' == "" {
			qui recode `onenet' `rules'
		}
		else {
			recode `onenet' `rules', `options'
		}
		mata: st_local("__fast", strofreal(nw_recode_fastok(st_data(., "__nwrec_old"), st_data(., "`onenet'"))))
		mata: st_local("__nchg", strofreal(sum(st_data(., "__nwrec_fq") :* (st_data(., "`onenet'") :!= st_data(., "__nwrec_old"))), "%18.0g"))
		di "{txt}(" string(`__nchg', "%18.0gc") " changes made to `onenet')"

		if `__fast' {
			// every target: the network itself, or a copy of it
			local targets ""
			local inplace = ("`generate'" == "" & "`prefix'" == "")
			if "`prefix'" != "" {
				nwvalidate `prefix'`onenet'
				local prefixtarget = r(validname)
				nwduplicate `onenet', name(`prefixtarget')
				local targets "`targets' `prefixtarget'"
			}
			if "`generate'" != "" {
				if "``i''" != "" {
					nwvalidate ``i''
					local gentarget = r(validname)
					nwduplicate `onenet', name(`gentarget')
					local targets "`targets' `gentarget'"
				}
				else {
					local inplace 1
				}
			}
			foreach tg in `targets' {
				_nwsyntax `tg'
				mata: st_numscalar("__nwrec_sym", `netobj'->recode_weights(st_data(., "__nwrec_old"), st_data(., "`onenet'")))
				mata: `netobj'->set_directed(1 - st_numscalar("__nwrec_sym"))
			}
			if `inplace' {
				_nwsyntax `onenet'
				mata: st_numscalar("__nwrec_sym", `netobj'->recode_weights(st_data(., "__nwrec_old"), st_data(., "`onenet'")))
				nwname `onenet', newdirected(`onedirected')
			}
			capture scalar drop __nwrec_sym
		}
		else {
			// a rule that gives the empty dyads a value, or turns ties into
			// missing values: the whole matrix is recoded
			mata: __nwrec_o = st_data(., "__nwrec_old")
			mata: __nwrec_n = st_data(., "`onenet'")
			_nwrecode_dense `onenet', rules(`"`rules'"') generate("`generate'") prefix("`prefix'") gi(`i') onedirected(`onedirected')
			capture mata: mata drop __nwrec_o __nwrec_n
		}
		local i = `i' + 1
	}
	restore
end


// The general case of nwrecode: the matrix itself is recoded cell by cell
// (the distinct-value map __nwrec_o -> __nwrec_n is in Mata).
capture program drop _nwrecode_dense
program _nwrecode_dense
	syntax anything(name=onenet), rules(string) [generate(string) prefix(string) gi(integer 1) onedirected(string)]

	tokenize `generate'
	_nwsyntax `onenet'
	mata: __nwrec_M = nw_recode_matrix(`netobj'->get_matrix_copy(), __nwrec_o, __nwrec_n)
	if "`generate'" == "" & "`prefix'" == "" {
		nwreplacemat `onenet', newmat(__nwrec_M)
	}
	else {
		if "`prefix'" != "" {
			nwvalidate `prefix'`onenet'
			local prefixtarget = r(validname)
			nwduplicate `onenet', name(`prefixtarget')
			nwreplacemat `prefixtarget', newmat(__nwrec_M)
		}
		if "`generate'" != "" {
			if "``gi''" != "" {
				nwvalidate ``gi''
				local gentarget = r(validname)
				nwduplicate `onenet', name(`gentarget')
				nwreplacemat `gentarget', newmat(__nwrec_M)
			}
			else {
				nwreplacemat `onenet', newmat(__nwrec_M)
			}
		}
	}
	mata: mata drop __nwrec_M
	nwname `onenet', newdirected(`onedirected')
end

*! v1.5.0 __ 17 Sep 2015 __ 13:09:53
*! v1.5.1 __ 17 Sep 2015 __ 14:54:23
