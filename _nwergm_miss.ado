*! _nwergm_miss: missing-dyad (NA tie) handling for nwergm
capture program drop _nwergm_miss
program _nwergm_miss, rclass
	version 14
	gettoken sub 0 : 0, parse(" ,")
	if "`sub'" == "detect" {
		// detect, netobj(ptr) directed(str) is2mode(str) nodes(#) netname(str) [constrained]
		syntax , NETOBJ(string) [DIRECTED(string) TWOMODE(string) NODES(integer 0) NETNAME(string) CONSTRAINED]
		tempname nm
		capture mata: mata drop __nwergm_missmat
		mata: __nwergm_missmat = ergm_missing_dyads(*(`netobj'->get_matrix()), ("`directed'"=="true"), ("`twomode'"=="true"), ///
			("`twomode'"=="true" ? __nwergm_last_G.mode : J(`nodes',1,0)))
		mata: st_numscalar("`nm'", ergm_count_missing(__nwergm_missmat, ("`directed'"=="true")))
		return scalar nmiss = scalar(`nm')
		if scalar(`nm') > 0 {
			di as txt "Note: network {bf:`netname'} has " as res scalar(`nm') as txt " missing dyad(s); they are excluded from the (pseudo)likelihood and handled as in R's ergm (missing-data MCMLE)."
			mata: ergm_impute_missing(__nwergm_last_G, __nwergm_missmat)
		}
		else {
			capture mata: mata drop __nwergm_missmat
		}
		exit
	}
	di "{err}_nwergm_miss: unknown subcommand"
	error 198
end
