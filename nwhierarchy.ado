
capture program drop nwhierarchy
program nwhierarchy, rclass
	// when the command stops with an error, the data set is left as it was (preserve restores it)
	// after an error the current network is the one it was before
	unw_defs
	local __nwc_cur ""
	capture mata: st_local("__nwc_cur", `nws'.get_current_name())
	preserve
	capture noisily _nwhierarchy_main `0'
	local __nwc_rc = _rc
	return add
	if `__nwc_rc' {
		if "`__nwc_cur'" != "" capture mata: `nws'.make_current_from_name("`__nwc_cur'")
		exit `__nwc_rc'
	}
	restore, not
	capture confirm number 0
end

capture program drop _nwhierarchy_main
program _nwhierarchy_main, rclass
	// was the deprecated _nwsyntax wrapper, which only re-exports 4
	// locals (netobj/id/netname/networks) - the same bug class fixed
	// repeatedly elsewhere this session. Nothing below actually
	// referenced any of the locals that wrapper fails to export
	// (confirmed empirically - this file ran correctly even before
	// this change), but switched to the modern _nwsyntax anyway for
	// consistency with the rest of the package and to keep the new
	// groups()/equivgen() code below (added in this same unit) safe
	// against ever needing one of those locals in the future.
	syntax [anything(name=netname)] [, dismat(string) disnet(string) linkage(string) type(string) context(string) clear add GROUPS(int -1) EQUIVgen(string) generate(string) replace force * ]
	// Naming consistency (moderate-severity pass, community_spectral
	// group): the rest of this group (nwcommunity/nwspectral) and the
	// wider package convention both use `generate()' for "write a
	// per-node partition-id variable" - this command's own help text
	// even describes `equivgen()''s own output as mirroring
	// nwcomponents' `generate()'-produced output shape exactly. Added
	// `generate()' as a working alias, kept `equivgen()' for backward
	// compatibility.
	if "`equivgen'" != "" & "`generate'" != "" {
		di "{err}{p 0 0 2}Specify only one of {bf:equivgen()} or {bf:generate()} (they are the same option) - not both.{p_end}"
		exit 198
	}
	if "`generate'" != "" {
		local equivgen "`generate'"
	}
	_nwsyntax `netname'
	_nw2guard `netname', cmd(nwhierarchy)
	if `nodes' < 2 {
		di "{err}{p 0 0 2}Network {bf:`netname'} has fewer than 2 nodes; there is nothing to cluster.{p_end}"
		exit 2001
	}

	if "`clear'" == "" & "`add'" == "" {
		local add = "add"
	}

	if "`linkage'" == "" {
		local linkage = "singlelinkage"
	}

	// Stata's clustermat is O(n^3) in time and keeps the dissimilarity matrix as a Stata matrix (at most 11,000 rows in
	// Stata/BE): 3,000 nodes take 45 s, 5,000 nodes 170 s, 10,000 nodes more than 20 minutes
	if `nodes' > 6000 & "`force'" == "" & "`dismat'" == "" {
		di "{err}{p 0 0 2}nwhierarchy clusters the dense `nodes' x `nodes' dissimilarity matrix with Stata's clustermat: about `=round(45*(`nodes'/3000)^3/60)' minutes. It is refused above 6,000 nodes; option {bf:force} runs it anyway.{p_end}"
		exit 484
	}

	if "`dismat'" == "" {
		// a matrix of the command's own: a Stata matrix of the user is never overwritten
		tempname __nwhmat
		local dismat "`__nwhmat'"
		if "`disnet'" != "" {
			nwtomatafast `disnet'
			mata: st_matrix("`dismat'", `r(mata)')
		}
		else {
			// Stata's clustermat is the slow part: measured in Stata/BE 1,000 nodes 3 s, 5,000 nodes 165 s
			if `nodes' > 2000 {
				di "{txt}{p 0 0 2}(note: clustering `nodes' nodes with Stata's clustermat takes minutes){p_end}"
			}
			if "`type'" == "manhatten" local type "manhattan"
			tempname __nwhdis
			nwdissimilar `netname', type(`type') context(`context') name(`__nwhdis')
			nwtomatafast `__nwhdis'
			mata: st_matrix("`dismat'", `r(mata)')
			nwdrop `__nwhdis'
			mata: st_local("__nwh_miss", strofreal(hasmissing(st_matrix("`dismat'"))))
			if `__nwh_miss' {
				di "{err}{p 0 0 2}Some dissimilarities are missing, which clustering cannot use; the usual reason is missing ties in {bf:`netname'}. Give them a value first (for example {bf:nwrecode `netname' (.=0)}).{p_end}"
				exit 504
			}
		}
	}

	// groups() closes the "role/position analysis" workflow this
	// command was originally packaged for: nwdissimilar computes
	// structural-equivalence distances, nwhierarchy (via clustermat)
	// builds a dendrogram from them, but turning that dendrogram into
	// a single per-node "which equivalence class does this node
	// belong to" variable previously required the caller to already
	// know Stata's own cluster-analysis postestimation syntax
	// (cluster generate ..., groups(#)) and, less obviously, the
	// auto-generated cluster-object name clustermat picks when none is
	// given (_clus_1, _clus_2, ... - not returned in r(), so it
	// cannot be recovered programmatically). groups() does exactly
	// that hand-off internally, using a fixed, deterministic cluster
	// name of its own (dropped and recreated on every call, matching
	// nwcomponents'/nwclique's own generate()/replace convention) so
	// the resulting role/position variable is available as an ordinary
	// Stata variable in one call, mirroring nwcomponents' own
	// component-id-variable output shape exactly.
	// clustermat, add needs exactly one observation per node: further observations are set aside and put back
	local __rest 0
	if "`add'" != "" & _N > `nodes' {
		tempfile __all __more
		qui save `__all'
		qui drop in 1/`nodes'
		qui save `__more'
		qui use `__all', clear
		qui keep in 1/`nodes'
		local __rest 1
	}
	if `groups' > 0 {
		local nwhier_clustername "_nwhierarchy_role"
		capture cluster drop `nwhier_clustername'
		clustermat `linkage' `dismat', name(`nwhier_clustername') `add' `clear' `options'

		// generate()/equivgen() is required (suite-wide
		// generate()-required style decision, 2026-09-05): this
		// command's whole purpose is producing this variable, so -
		// matching Stata's own egen/predict convention - there is no
		// default name to silently fall back to.
		if "`equivgen'" == "" {
			di "{err}option {bf:generate()} (or its {bf:equivgen()} alias) required."
			exit 198
		}
		local netgenerate "`equivgen'"
		capture confirm variable `netgenerate', exact
		if _rc == 0 & "`replace'" == "" {
			di "{err}Variable {bf:`netgenerate'} already exists; specify {bf:replace}"
			exit 110
		}
		capture confirm new variable `netgenerate'
		if _rc capture drop `netgenerate'
		cluster generate `netgenerate' = groups(`groups'), name(`nwhier_clustername')
		return scalar groups = `groups'
		return local rolevar "`netgenerate'"
	}
	else {
		clustermat `linkage' `dismat', `options' `add' `clear'
	}
	if `__rest' qui append using `__more'
	qui nwload `netname', labelonly
end








	
*! v1.5.0 __ 17 Sep 2015 __ 13:09:53
*! v1.5.1 __ 17 Sep 2015 __ 14:54:23
