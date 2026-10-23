*! nwergm_p: predict after nwergm (R: predict.ergm, conditional tie probabilities)
capture program drop nwergm_p
program nwergm_p
	version 14
	syntax [anything] [if] [in] [, PR XB MATrix(name) FRame(name)]
	capture confirm number 0
	if "`matrix'" == "" & "`frame'" == "" {
		di as err "predict after nwergm needs matrix(name) or frame(name): the predictions are dyadic (one per dyad)"
		exit 198
	}
	if "`pr'`xb'" == "" local pr pr
	if "`pr'" != "" & "`xb'" != "" {
		di as err "options pr and xb are mutually exclusive"
		exit 198
	}
	local depvar "`e(depvar)'"
	local directed "`e(directed)'"
	local nodes = e(nodes)
	_nwsyntax `depvar', max(1)
	capture mata: st_local("__cn", invtokens(__nwergm_last_M.coefnames))
	if _rc {
		di as err "the fitted model is no longer in memory; re-fit with nwergm before predict"
		exit 498
	}
	tempname b
	matrix `b' = e(b)
	local cn : colnames `b'
	if e(curved) {
		di as err "predict is not available for models with a curved (free-decay) term"
		exit 198
	}
	if "`cn'" != "`__cn'" {
		di as err "the fitted model is no longer in memory; re-fit with nwergm before predict"
		exit 498
	}
	tempname G P
	mata: `G' = ErgmGraph()
	mata: `G'.init(`nodes', ("`directed'"=="true"))
	mata: ergm_netobj_to_graph(`netobj', `G', ("`directed'"=="true"))
	capture confirm number 0
	if "`is2mode'" == "true" mata: `G'.set_bipartite(strtoreal(`netobj'->get_modes())')
	tempname MM
	if e(nmissing) > 0 mata: `MM' = __nwergm_missmat
	else mata: `MM' = J(`nodes', `nodes', 0)
	mata: `P' = ergm_predict_data(__nwergm_last_M, `G', st_matrix("`b'"), `MM')
	if "`pr'" != "" mata: `P'[., 3] = 1 :/ (1 :+ exp(-`P'[., 3]))
	if "`matrix'" != "" {
		mata: st_matrix("`matrix'", ergm_predict_matrix(`P', `nodes', ("`directed'"=="true"), `MM'))
		di as txt "(matrix `matrix' contains the " cond("`pr'" != "", "conditional tie probabilities", "conditional log-odds") "; missing dyads are .)"
	}
	if "`frame'" != "" {
		mata: st_local("nrowsP", strofreal(rows(`P')))
		capture frame drop `frame'
		frame create `frame' double(tail head p)
		frame `frame': qui set obs `nrowsP'
		frame `frame': mata: st_store(., ("tail","head","p"), `P')
		di as txt "(frame `frame' contains one row per informative dyad: tail, head, " cond("`pr'" != "", "p = conditional tie probability", "p = conditional log-odds") ")"
	}
	mata: mata drop `G' `P' `MM'
end
