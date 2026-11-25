*! nwspmatrix: spatial weighting matrix (spmatrix) from a network, for spregress (3.28.0)
capture program drop nwspmatrix
program nwspmatrix, rclass
	version 15
	syntax [anything(name=netname)] [, Name(name) Weights(string) DIRection(string) Normalize(string) ///
		IDVar(varname numeric) MATrix(name) replace silent]

	_nwsyntax `netname'
	_nw2guard `netname', cmd(nwspmatrix)

	if "`name'" == "" local name "W"
	if "`weights'" == "" local weights "binary"
	if "`direction'" == "" local direction "out"
	if "`normalize'" == "" local normalize "row"
	if !inlist("`weights'", "binary", "valued") {
		di "{err}weights() must be {bf:binary} or {bf:valued}."
		exit 198
	}
	if !inlist("`direction'", "out", "in", "symmetric", "mutual") {
		di "{err}direction() must be {bf:out}, {bf:in}, {bf:symmetric} or {bf:mutual}."
		exit 198
	}
	if !inlist("`normalize'", "row", "none", "spectral", "minmax") {
		di "{err}normalize() must be {bf:row}, {bf:none}, {bf:spectral} or {bf:minmax}."
		exit 198
	}
	if `nodes' < 3 {
		di "{err}The network needs at least 3 nodes."
		exit 198
	}
	if _N < `nodes' {
		di "{err}The data set has `=_N' observations, the network {bf:`netname'} has `nodes' nodes: observation {it:i} must hold node {it:i}."
		exit 198
	}

	// the spatial-unit ID of observation i names node i
	capture quietly spset
	local isset = (`"`r(sp_id)'"' != "")
	if !`isset' {
		capture confirm variable _ID, exact
		if _rc == 0 {
			di "{err}{p 0 0 2}The data have a variable {bf:_ID} but are not {bf:spset}; {bf:spset} would replace its values. Rename or drop {bf:_ID} first.{p_end}"
			exit 110
		}
	}
	if "`idvar'" != "" {
		if `isset' quietly spset `idvar', modify
		else quietly spset `idvar'
	}
	else if !`isset' {
		capture confirm variable _nwid, exact
		if _rc quietly generate double _nwid = _n
		quietly spset _nwid
	}
	capture quietly spset
	local spid "`r(sp_id)'"
	if "`spid'" == "" local spid "_ID"

	tempname W ids
	nwtomatafast `netname'
	local srcmata "`r(mata)'"
	mata: `W' = nw_spmatrix_build(`srcmata', `nodes', "`directed'" == "true", "`weights'", "`direction'", "`normalize'")
	mata: `ids' = st_data((1::`nodes'), "`spid'")
	mata: st_local("nisol", strofreal(sum(rowsum(`W') :== 0)))
	mata: st_local("nties", strofreal(sum(`W' :!= 0)))
	mata: st_local("neg", strofreal(min(`W') < 0))
	if `neg' {
		mata: mata drop `W' `ids'
		di "{err}The network has negative tie values; a spatial weighting matrix cannot hold them (use weights(binary))."
		exit 198
	}

	// row normalisation is done here (isolates keep a row of zeros); the other kinds by Stata
	local snorm "none"
	if inlist("`normalize'", "spectral", "minmax") local snorm "`normalize'"
	local rep ""
	if "`replace'" != "" local rep "replace"
	capture noisily spmatrix spfrommata `name' = `W' `ids', normalize(`snorm') `rep'
	if _rc {
		local rc = _rc
		mata: mata drop `W' `ids'
		if `rc' == 111 di "{err}Specify {bf:replace} to overwrite it."
		exit `rc'
	}
	if "`matrix'" != "" {
		capture mata: st_matrix("`matrix'", `W')
		if _rc {
			di "{err}Cannot store a `nodes' x `nodes' Stata matrix (matsize too small); the spatial weighting matrix {bf:`name'} was created."
		}
	}
	mata: mata drop `W' `ids'

	return local name "`name'"
	return local weights "`weights'"
	return local direction "`direction'"
	return local normalize "`normalize'"
	return local network "`netname'"
	return scalar nodes = `nodes'
	return scalar ties = `nties'
	return scalar isolates = `nisol'
	if "`silent'" == "" {
		di "{hline 40}"
		di "{txt}  Network name: {res}`netname'"
		di "{txt}  Spatial weighting matrix: {res}`name'{txt} (`nodes' places)"
		di "{txt}  Weights: {res}`weights'{txt}, direction: {res}`direction'{txt}, normalisation: {res}`normalize'"
		di "{txt}  Nonzero cells: {res}`nties'{txt}; nodes without ties (row of zeros): {res}`nisol'"
		di "{txt}  Spatial-unit ID: {res}`spid'"
	}
end

capture mata: mata drop nw_spmatrix_build()
mata:
// Weighting matrix of the first n nodes: no self-loops; directed ties read as sent (out), received (in),
// the larger value of both directions (symmetric) or the smaller one (mutual); optional row normalisation
// (a node without ties keeps a row of zeros).
real matrix nw_spmatrix_build(real matrix A0, real scalar n, real scalar directed, string scalar weights,
	string scalar direction, string scalar normalize)
{
	real matrix A
	real colvector rs
	A = editmissing(A0[1::n, 1::n], 0)
	A = A - diag(diagonal(A))
	if (weights == "binary") A = (A :!= 0)
	if (directed) {
		if (direction == "in") A = A'
		else if (direction == "symmetric") A = (A :>= A') :* A + (A :< A') :* A'
		else if (direction == "mutual") A = (A :<= A') :* A + (A :> A') :* A'
	}
	if (min(A) >= 0 & normalize == "row") {
		rs = rowsum(A)
		A = A :/ (rs + (rs :== 0))
	}
	return(A)
}
end
