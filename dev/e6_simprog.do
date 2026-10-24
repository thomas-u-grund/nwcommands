capture program drop e6simcase
program define e6simcase
	args tag spec label ref
	_nwsyntax `tag', max(1)
	_nwergm_constr, spec(`spec') nodes(`nodes') directed(`directed') twomode(`is2mode') matobj(`netobj') weights(default)
	local dir = ("`directed'" == "true")
	mata: G = e6_graph(*(`netobj'->get_matrix_mod(0,`dir')), `dir')
	if `con_hasdyad' mata: G.set_dyadmask(__ncon_free)
	mata: M = ErgmModel(); M.init(); td1 = ErgmTermData(); td2 = ErgmTermData(); td3 = ErgmTermData()
	mata: M.addterm("edges", 1, &stat_edges(), &change_edges(), td1, ("edges"))
	if `dir' {
		mata: M.addterm("mutual", 1, &stat_mutual(), &change_mutual(), td2, ("mutual"))
		mata: td3.levels = 2; M.addterm("istar", 1, &stat_istar(), &change_istar(), td3, ("istar_2"))
		mata: th = (-0.8, 0.5, 0.05)
	}
	else {
		mata: M.addterm("triangle", 1, &stat_triangle(), &change_triangle(), td2, ("triangle"))
		mata: td3.levels = 2; M.addterm("kstar", 1, &stat_kstar(), &change_kstar(), td3, ("kstar_2"))
		mata: th = (-0.2, 0.15, 0.03)
	}
	mata: rc0 = ErgmNativeSetup(M, 2, G)
	mata: M.con_par = __ncon_par; M.con_cols = __ncon_cols
	mata: smp = ErgmMCMCSample(M, G, th, 20000, 200, 20000, &ergm_propose_tnt())
	mata: st_numscalar("e6_simz", e6_zcmp(smp, "`ref'", "`label'"))
end
mata:
mata set matastrict off
real scalar e6_zcmp(real matrix smp, string scalar ref, string scalar label)
{
	string rowvector rows, pr
	real scalar j, nb, bsz, b, se, z, mx
	real colvector bm
	rows = tokens(ref, ";")
	rows = select(rows, rows :!= ";")
	nb = 20; bsz = floor(rows(smp) / nb); mx = 0
	for (j = 1; j <= cols(rows); j++) {
		pr = tokens(rows[j], ",")
		pr = select(pr, pr :!= ",")
		bm = J(nb, 1, 0)
		for (b = 1; b <= nb; b++) bm[b] = mean(smp[((b-1)*bsz+1)::(b*bsz), j])
		se = sqrt(variance(bm) / nb)
		z = (mean(smp[., j]) - strtoreal(pr[1])) / sqrt(se^2 + strtoreal(pr[2])^2 + 1e-12)
		printf("  %s stat%g: R %9.4f (se %6.4f)  nwergm %9.4f (se %6.4f)  z=%6.2f\n", label, j, strtoreal(pr[1]), strtoreal(pr[2]), mean(smp[., j]), se, z)
		mx = max((mx, abs(z)))
	}
	return(mx)
}
end

