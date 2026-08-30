
capture program drop nwhierarchy
program nwhierarchy, rclass
	// was the deprecated _nwsyntax wrapper, which only re-exports 4
	// locals (netobj/id/netname/networks) - the same bug class fixed
	// repeatedly elsewhere this session. Nothing below actually
	// referenced any of the locals that wrapper fails to export
	// (confirmed empirically - this file ran correctly even before
	// this change), but switched to the modern nw_syntax anyway for
	// consistency with the rest of the package and to keep the new
	// groups()/equivgen() code below (added in this same unit) safe
	// against ever needing one of those locals in the future.
	syntax [anything(name=netname)] [, dismat(string) disnet(string) linkage(string) type(string) context(string) clear add GROUPS(int -1) EQUIVgen(string) generate(string) replace * ]
	// Naming consistency (moderate-severity pass, community_spectral
	// group): the rest of this group (nwcommunity/nwspectral) and the
	// wider package convention both use `generate()' for "write a
	// per-node partition-id variable" - this command's own help text
	// even describes `equivgen()''s own output as mirroring
	// nwcomponents' `generate()'-produced output shape exactly. Added
	// `generate()' as a working alias, kept `equivgen()' for backward
	// compatibility.
	if "`equivgen'" != "" & "`generate'" != "" {
		di "{err}Specify only one of {bf:equivgen()} or {bf:generate()} (they are the same option) - not both."
		error 198
	}
	if "`generate'" != "" {
		local equivgen "`generate'"
	}
	nw_syntax `netname'

	if "`clear'" == "" & "`add'" == "" {
		local add = "add"
	}

	if "`linkage'" == "" {
		local linkage = "singlelinkage"
	}

	if "`dismat'" == "" {
		local dismat "mymat"
		if "`disnet'" != "" {
			nwtomatafast `disnet'
			mata: st_matrix("`dismat'", `r(mata)')
		}
		else {
			nwdissimilar `netname', type(`type') context(`context') name(_temp_dissimilar)
			nwtomatafast _temp_dissimilar
			mata: st_matrix("`dismat'", `r(mata)')
			nwdrop _temp_dissimilar
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
	if `groups' > 0 {
		local nwhier_clustername "_nwhierarchy_role"
		capture cluster drop `nwhier_clustername'
		clustermat `linkage' `dismat', name(`nwhier_clustername') `add' `clear' `options'

		local netgenerate "`equivgen'"
		if "`netgenerate'" == "" {
			local netgenerate = "_role"
		}
		capture confirm variable `netgenerate', exact
		if _rc == 0 & "`replace'" == "" {
			di "{err}Variable {bf:`netgenerate'} already exists; specify {bf:replace}"
			err 99
		}
		capture drop `netgenerate'
		cluster generate `netgenerate' = groups(`groups'), name(`nwhier_clustername')
		return scalar groups = `groups'
		return local rolevar "`netgenerate'"
	}
	else {
		clustermat `linkage' `dismat', `options' `add' `clear'
	}
	qui nwload `netname', labelonly
end








	
*! v1.5.0 __ 17 Sep 2015 __ 13:09:53
*! v1.5.1 __ 17 Sep 2015 __ 14:54:23
