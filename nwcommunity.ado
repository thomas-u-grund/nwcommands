
capture program drop nwcommunity
program nwcommunity, rclass
	version 12
	syntax [anything(name=netname)][, GENerate(string) replace measure(string) SYMmetrize resolution(real 1) algorithm(string) seed(int -1) silent listall ONEmode STARTs(int 30) REPs(int 10) MINModules(int 4) BETA(real 0.01) ITERations(int 2) TRIals(int 10)]
	set more off

	// resolution() had no input validation at all - zero or negative
	// values run without error but push the reported r(modularity) well
	// outside modularity's own normal [-1,1] range (confirmed directly:
	// resolution(-1) on a standard two-triangle bridge network yields
	// r(modularity)=2). Reichardt-Bornholdt resolution is conventionally
	// > 0; validated here rather than silently accepting a value that
	// produces a result the package's own test suite elsewhere asserts
	// should never occur.
	if `resolution' <= 0 {
		di "{err}Option {bf:resolution()} must be > 0."
		exit 198
	}

	local algorithm = lower("`algorithm'")
	if "`algorithm'" == "" {
		local algorithm "louvain"
	}
	_opts_oneof "louvain labelprop dirtlpa leiden infomap" "algorithm" "`algorithm'" 6556

	if `seed' != -1 {
		set seed `seed'
	}

	if `reps' < 1 | `minmodules' < 1 {
		di "{err}Options {bf:reps()} and {bf:minmodules()} must be at least 1."
		exit 198
	}
	if `starts' < 1 {
		di "{err}Option {bf:starts()} must be at least 1."
		exit 198
	}
	if `beta' <= 0 | `trials' < 1 | `iterations' == 0 {
		di "{err}Options {bf:beta()} (> 0), {bf:trials()} (at least 1) and {bf:iterations()} (non-zero) are not valid."
		exit 198
	}

	_nwsyntax `netname', max(9999)

	if `networks' > 1 {
		local k = 1
	}

	qui foreach netname_temp in `netname' {
		_nwsyntax `netname_temp'

		local netmeasure "`measure'"
		if "`netmeasure'" == "" {
			if "`valued'" == "true" {
				local netmeasure "valued"
			}
			else {
				local netmeasure "binary"
			}
		}
		_opts_oneof "binary valued" "measure" "`netmeasure'" 6556

		if "`directed'" == "true" & "`symmetrize'" == "" {
			noi di "{err}{p 0 0 2}Community detection not defined for directed networks. Either specify {bf:symmetrize} or symmetrize the network first (see {help nwsym}).{p_end}"
			exit 198
		}

		if "`generate'" == "" {
			noi di "{err}option {bf:generate()} required."
			exit 198
		}
		local netgenerate "`generate'"

		// Checks the exact suffixed name this iteration is about to
		// create, not the bare stem - Stata's own variable-name
		// abbreviation would otherwise let `confirm variable
		// _community' match an already-existing `_community1' on a
		// later netlist iteration, falsely blocking that iteration
		// even though its own target name is still free. Found while
		// building nwconcor.ado's netlist support (same underlying
		// bug, same fix - see its own certified row).
		capture confirm variable `netgenerate'`k', exact
		if _rc == 0 & "`replace'" == "" {
			noi di "{err}Variable {bf:`netgenerate'`k'} already exists; specify {bf:replace}"
			exit 110
		}

		local val = ("`netmeasure'" == "valued")
		// a two-mode network is scored and searched with Barber's bipartite modularity (R: bipartite::computeModules,
		// the null model counts only pairs of nodes from different modes); onemode gives Newman's Q of the bipartite
		// graph read as a one-mode graph (igraph::cluster_louvain)
		local __bip = ("`is2mode'" == "true" & "`onemode'" == "")
		local __qtype = cond(`__bip', "barber", "newman")
		local __qlab = cond(`__bip', "{space 1}(Barber, two-mode)", "")
		if "`algorithm'" == "dirtlpa" {
			if !`__bip' {
				noi di "{err}{p 0 0 2}{bf:algorithm(dirtlpa)} is for two-mode networks (without the option {bf:onemode}); a one-mode network is searched with {bf:louvain} or {bf:labelprop}.{p_end}"
				exit 198
			}
			if `resolution' != 1 {
				noi di "{err}{p 0 0 2}{bf:algorithm(dirtlpa)} maximises Barber's modularity with the resolution 1; {bf:resolution()} is not available for it.{p_end}"
				exit 198
			}
		}

		if inlist("`algorithm'", "leiden", "infomap") {
			if `__bip' {
				noi di "{err}{p 0 0 2}{bf:algorithm(`algorithm')} is for one-mode networks; a two-mode network is read as a one-mode graph with the option {bf:onemode} (see also {bf:algorithm(dirtlpa)} and the default bipartite Louvain).{p_end}"
				exit 198
			}
			if "`algorithm'" == "infomap" & `resolution' != 1 {
				noi di "{err}{p 0 0 2}{bf:algorithm(infomap)} has no resolution parameter; {bf:resolution()} is not available for it.{p_end}"
				exit 198
			}
		}

		capture confirm new variable `netgenerate'`k'
		if _rc capture drop `netgenerate'`k'
		gen `netgenerate'`k' = .
		mata: st_rclear()
		qui if _N < `nodes' {
			set obs `nodes'
		}
		// align row i of the data set with node i of this network before the
		// positional st_store() below (a data set that was sorted or reordered, or
		// synced to another network such as a two-mode projection, would otherwise
		// receive the values on the wrong rows)
		_nwsyncrows `netname_temp'
		mata: st_rclear()
		_nwsyntax `netname_temp'

		tempname __nw_comm
		if "`algorithm'" == "labelprop" {
			mata: `__nw_comm' = `netobj'->detect_communities_labelprop(`val')
		}
		else if inlist("`algorithm'", "leiden", "infomap") {
			// Leiden (modularity) and Infomap (map equation) in Mata on the symmetric weighted pairs of the network; set seed makes them reproducible
			capture scalar drop __nwcm_codelength
			mata: `__nw_comm' = nw_cm_run(`netobj', `val', "`algorithm'", `resolution', `beta', `iterations', `trials')
		}
		else if "`algorithm'" == "dirtlpa" {
			// Beckett's (2016) DIRT_LPA+ (native only: the kernel 52 of the plugin, generation 12 or later); set seed controls it
			mata: `__nw_comm' = nw2_fastdirt(`netobj', `val', `minmodules', `reps')
			mata: st_local("__fast", strofreal(rows(`__nw_comm') == `nodes'))
			if !`__fast' {
				noi di "{err}{p 0 0 2}{bf:algorithm(dirtlpa)} needs the native plugin of nwcommands 3.10.0 or later (plugin generation 12); the plugin found for this platform is older or missing, or could not run.{p_end}"
				noi di "{err}{p 0 0 2}Update it: {stata nwinstall, all}{space 2}(or reinstall the package with {bf:net install nwcommands, replace}); {bf:algorithm(louvain)} works with any plugin.{p_end}"
				exit 198
			}
		}
		else if `__bip' {
			// native search (plugin generation 10 or later: same algorithm, random starts from a seeded generator, so
			// set seed makes it reproducible); an older plugin or a failure leaves the Mata search
			mata: `__nw_comm' = nw2_fastbip(`netobj', `val', `resolution', `starts')
			mata: st_local("__fast", strofreal(rows(`__nw_comm') == `nodes'))
			if !`__fast' {
				mata: `__nw_comm' = `netobj'->detect_communities_bipartite(`val', `resolution', `starts')
			}
		}
		else {
			mata: `__nw_comm' = `netobj'->detect_communities_louvain(`val', `resolution')
		}
		mata: st_store((1::`nodes'),"`netgenerate'`k'", `__nw_comm')
		// BUGFIX: `val' (already computed above from measure()) used to
		// never be forwarded, so calculate_modularity() always scored on
		// the network's raw valued weights regardless of what measure()
		// requested - measure(binary) was a complete no-op, silently
		// corrupting the reported r(modularity) for the community
		// partition detect_communities_louvain()/labelprop() actually
		// searched for under measure(binary).
		tempname __t1 __t2 __t3
		if `__bip' {
			mata: st_numscalar("`__t1'", `netobj'->calculate_modularity_bipartite(`__nw_comm', `val', `resolution'))
		}
		else {
			mata: st_numscalar("`__t1'", `netobj'->calculate_modularity(`__nw_comm', `val', `resolution'))
		}
		mata: mata drop `__nw_comm'

		// PERFORMANCE/CORRECTNESS FIX: `tab ..., matrow() matcell()'
		// crashes outright ("too many values", r134) once the network
		// has enough distinct communities - confirmed directly:
		// Louvain on a sparse (avg degree ~10) random n=10,000 graph
		// genuinely finds 4,322 communities (not a pathological edge
		// case - large sparse graphs commonly lack strong community
		// structure, so this is expected algorithm behavior, not a
		// bug in detect_communities_louvain() itself), which exceeds
		// Stata's own `tab' command's internal category-count limit.
		// The later `matrix rownames = `rowlabs'' line has the exact
		// same class of failure for the same reason, one level down
		// (a 4,322-token command-line string blows Stata's own
		// matsize-driven row-name-parsing limit, r915) - confirmed
		// directly with an isolated repro completely independent of
		// this command. Both replaced with Mata-native equivalents
		// that never route the community count through a Stata
		// command-line string or `tab''s own tabulation limit at all:
		// a single sort + panelsetup() pass computes the same
		// (id, size) tabulation `tab' used to (O(n log n) instead of
		// paying `tab''s own overhead, and with no category-count
		// ceiling), and `st_matrixrowstripe()' sets the "commN" row
		// labels directly via Mata's own matrix API, which has no
		// analogous token-count limit.
		mata: __nwc_vals = st_data((1::`nodes'), "`netgenerate'`k'")
		mata: __nwc_sorted = sort(__nwc_vals, 1)
		mata: __nwc_info = panelsetup(__nwc_sorted, 1)
		mata: __nwcommunity_comm_number = rows(__nwc_info)
		mata: __nwcommunity_comm_id = __nwc_sorted[__nwc_info[.,1]]
		mata: __nwcommunity_comm_size = __nwc_info[.,2] :- __nwc_info[.,1] :+ 1
		mata: __nwcommunity_comm_share = __nwcommunity_comm_size :/ (sum(__nwcommunity_comm_size))
		mata: __nwcommunity_comm_sizeid = J(__nwcommunity_comm_number, 3, 0)
		mata: __nwcommunity_comm_sizeid[.,1] = __nwcommunity_comm_size
		mata: __nwcommunity_comm_sizeid[.,2] = __nwcommunity_comm_id
		mata: __nwcommunity_comm_sizeid[.,3] = __nwcommunity_comm_share
		mata: __nwcommunity_comm_sizeid = sort(__nwcommunity_comm_sizeid, (-1, 2))
		mata: st_numscalar("`__t2'", __nwcommunity_comm_number)
		mata: st_matrix("`__t3'", __nwcommunity_comm_sizeid)

		matrix colnames `__t3' = size compid share

		return scalar modularity = `__t1'
		if "`algorithm'" == "infomap" {
			return scalar codelength = scalar(__nwcm_codelength)
			capture scalar drop __nwcm_codelength
		}
		return local modularity_type "`__qtype'"
		return scalar communities = `__t2'
		local lcomm = `__t2'
		local lmod = `__t1'

		mata: __nwc_stripe = J(__nwcommunity_comm_number, 2, "")
		mata: __nwc_stripe[., 2] = "comm" :+ strofreal((1::__nwcommunity_comm_number))
		mata: st_matrixrowstripe("`__t3'", __nwc_stripe)
		return matrix comm_sizeid = `__t3'
		mata: mata drop __nwcommunity_comm_number __nwcommunity_comm_share __nwcommunity_comm_id __nwcommunity_comm_size __nwcommunity_comm_sizeid __nwc_vals __nwc_sorted __nwc_info __nwc_stripe

		if "`silent'" == "" {
			noi di "{hline 40}"
			noi di "{txt}  Network name: {res}`netname_temp'"
			noi di "{txt}  Communities: {res}`lcomm'"
			noi di "{txt}  Modularity Q`__qlab': {res}`=strtrim(string(round((`lmod')*1000)/1000,"%9.0g"))'"
			if `lcomm' <= 30 | (`lcomm' <= 1000 & "`listall'" != "") {
				noi tab `netgenerate'`k'
			}
			else if `lcomm' <= 1000 {
				noi tab `netgenerate'`k' if `netgenerate'`k' <= 30
				noi di "{txt}{p 2 2 2}(first 30 of `lcomm' communities shown; use {bf:listall} for the full table){p_end}"
			}
			else {
				noi di "{txt}{p 2 2 2}(the table of the `lcomm' communities is not shown; sizes are in r(comm_sizeid)){p_end}"
			}
			noi di " "
		}
		local k = `=`k' + 1'
	}
	capture mata: mata drop __nwcommunity_*
	capture confirm number 0
end

capture mata: mata drop nw_cm_dense()
capture mata: mata drop nw_cm_first()
capture mata: mata drop nw_cm_aggregate()
capture mata: mata drop nw_lei_move()
capture mata: mata drop nw_lei_refine()
capture mata: mata drop nw_lei_once()
capture mata: mata drop nw_cm_q()
capture mata: mata drop nw_cm_leiden()
capture mata: mata drop nw_im_plogp()
capture mata: mata drop nw_im_plogp1()
capture mata: mata drop nw_im_move()
capture mata: mata drop nw_im_codelength()
capture mata: mata drop nw_im_levels()
capture mata: mata drop nw_cm_infomap()
capture mata: mata drop nw_cm_run()
capture mata: mata drop nw2_fastbip()
capture mata: mata drop nw2_fastdirt()
mata:
// Native bipartite Louvain (kernel 43 of the nwgraph plugin); a 0 x 1 vector when the kernel is not available
real colvector nw2_fastbip(pointer(class nw_def scalar) scalar p, real scalar val, real scalar res, real scalar starts)
{
	real rowvector aux
	real scalar st, n
	real matrix r

	if (st_global("NW_NOFASTKERNELS") != "") return(J(0, 1, .))
	if (nwg_comb_version() < 10) return(J(0, 1, .))
	n = p->get_nodes()
	r = nwg_comb(43, n, nwg_symweights(n, p->edgelist(), val), strtoreal(p->get_modes())', (res, starts, floor(uniform(1, 1) * 2147483646) + 1), aux, st)
	if (st != 0 | rows(r) != n | cols(r) != 1) return(J(0, 1, .))
	return(r)
}

// Beckett's DIRT_LPA+ (kernel 52 of the nwgraph plugin, generation 12 or later); a 0 x 1 vector when the kernel is not available
real colvector nw2_fastdirt(pointer(class nw_def scalar) scalar p, real scalar val, real scalar mini, real scalar reps)
{
	real rowvector aux
	real scalar st, n
	real matrix r

	if (nwg_comb_version() < 12) return(J(0, 1, .))
	n = p->get_nodes()
	r = nwg_comb(52, n, nwg_symweights(n, p->edgelist(), val), strtoreal(p->get_modes())', (mini, reps, floor(uniform(1, 1) * 2147483646) + 1), aux, st)
	if (st != 0 | rows(r) != n | cols(r) != 1) return(J(0, 1, .))
	return(r)
}

// ---------------------------------------------------------------------------------------------------------------
// Leiden (Traag, Waltman and van Eck 2019) and Infomap (Rosvall and Bergstrom 2008) on the symmetric weighted pairs
// of nwg_symweights(); adjacency lists in the arrays of nw_pairs_csr(): the neighbours of node i are
// nb[ptr[i]..ptr[i+1]-1] with the weights w.
// ---------------------------------------------------------------------------------------------------------------

// dense labels 1..k (in order of the first node that carries them)
real colvector nw_cm_dense(real colvector v)
{
	real colvector o, sv, flag, out
	real scalar n
	n = rows(v)
	out = J(n, 1, 0)
	if (n == 0) return(out)
	o = order((v, (1::n)), (1, 2))
	sv = v[o]
	flag = J(n, 1, 1)
	if (n > 1) flag[|2 \ n|] = (sv[|2 \ n|] :!= sv[|1 \ n - 1|])
	out[o] = runningsum(flag)
	return(out)
}

// first-occurrence labels 1..k
real colvector nw_cm_first(real colvector v)
{
	real colvector d, firstpos, r, rk
	real scalar k, i
	d = nw_cm_dense(v)
	k = max(d)
	firstpos = J(k, 1, .)
	for (i = rows(d); i >= 1; i--) firstpos[d[i]] = i
	r = order(firstpos, 1)
	rk = r
	rk[r] = (1::k)
	return(rk[d, 1])
}

// the graph of the communities of rc (dense labels 1..k) as adjacency lists; the weights between communities add
void nw_cm_aggregate(real scalar n, real colvector ptr, real colvector nb, real colvector w, real colvector rc, real scalar k, ///
	real colvector ptr2, real colvector nb2, real colvector w2)
{
	real colvector ea, eb, ew, key, o, ww, idx, cs, ends, ka, deg
	real scalar i, m, j
	m = ptr[n + 1] - 1
	ptr2 = J(k + 2, 1, 1)
	nb2 = J(0, 1, .)
	w2 = J(0, 1, .)
	if (m == 0) return
	ea = J(m, 1, 0)
	for (i = 1; i <= n; i++) if (ptr[i + 1] > ptr[i]) ea[|ptr[i] \ ptr[i + 1] - 1|] = J(ptr[i + 1] - ptr[i], 1, rc[i])
	eb = rc[nb[|1 \ m|], 1]
	ew = w[|1 \ m|]
	j = selectindex(ea :!= eb)
	if (rows(j) == 0) return
	ea = ea[j]
	eb = eb[j]
	ew = ew[j]
	key = ea :* (k + 1) :+ eb
	o = order(key, 1)
	key = key[o]
	ww = ew[o]
	idx = selectindex((1 \ (key[|2 \ rows(key)|] :!= key[|1 \ rows(key) - 1|])))
	cs = runningsum(ww)
	if (rows(idx) == 1) ends = rows(key)
	else ends = (idx[|2 \ rows(idx)|] :- 1) \ rows(key)
	w2 = cs[ends] :- (cs[idx] :- ww[idx])
	ka = floor((key[idx] :- 1) :/ (k + 1))
	nb2 = key[idx] :- ka :* (k + 1)
	deg = J(k, 1, 0)
	for (i = 1; i <= rows(ka); i++) deg[ka[i]] = deg[ka[i]] + 1
	for (i = 1; i <= k; i++) ptr2[i + 1] = ptr2[i] + deg[i]
}

// Leiden, local moving of nodes (fast version with a queue); comm holds labels 1..n and is changed in place
void nw_lei_move(real scalar n, real colvector ptr, real colvector nb, real colvector w, real colvector kn, real colvector comm, real scalar g)
{
	real colvector K, cw, touched, queue, inq, cnt, free
	real scalar nfree, qh, qn, v, c0, c, u, e, nt, t, best, bg, gain, i, kv, tl
	K = J(n, 1, 0)
	cnt = J(n, 1, 0)
	for (i = 1; i <= n; i++) {
		K[comm[i]] = K[comm[i]] + kn[i]
		cnt[comm[i]] = cnt[comm[i]] + 1
	}
	free = J(n, 1, 0)
	nfree = 0
	for (i = n; i >= 1; i--) if (cnt[i] == 0) free[++nfree] = i
	cw = J(n, 1, 0)
	touched = J(n, 1, 0)
	queue = jumble((1::n))
	inq = J(n, 1, 1)
	qh = 1
	qn = n
	while (qn > 0) {
		v = queue[qh]
		qh = (qh == n ? 1 : qh + 1)
		qn--
		inq[v] = 0
		c0 = comm[v]
		kv = kn[v]
		nt = 0
		for (e = ptr[v]; e < ptr[v + 1]; e++) {
			c = comm[nb[e]]
			if (cw[c] == 0) touched[++nt] = c
			cw[c] = cw[c] + w[e]
		}
		K[c0] = K[c0] - kv
		best = c0
		bg = cw[c0] - g * kv * K[c0]
		for (t = 1; t <= nt; t++) {
			c = touched[t]
			gain = cw[c] - g * kv * K[c]
			if (gain > bg + 1e-12) {
				bg = gain
				best = c
			}
		}
		// an empty community has gain 0
		if (bg < -1e-12 & cnt[c0] > 1 & nfree > 0) {
			best = free[nfree]
			nfree--
			bg = 0
		}
		if (best != c0) {
			K[best] = K[best] + kv
			cnt[best] = cnt[best] + 1
			cnt[c0] = cnt[c0] - 1
			if (cnt[c0] == 0) free[++nfree] = c0
			comm[v] = best
			for (e = ptr[v]; e < ptr[v + 1]; e++) {
				u = nb[e]
				if (comm[u] != best & !inq[u]) {
					tl = qh + qn
					if (tl > n) tl = tl - n
					queue[tl] = u
					inq[u] = 1
					qn++
				}
			}
		}
		else K[c0] = K[c0] + kv
		for (t = 1; t <= nt; t++) cw[touched[t]] = 0
	}
}

// Leiden refinement: the refined partition rc (labels 1..n) of the communities comm
void nw_lei_refine(real scalar n, real colvector ptr, real colvector nb, real colvector w, real colvector kn, real colvector comm, ///
	real scalar g, real scalar theta, real colvector rc)
{
	real colvector KS, Kr, ext, sz, cw, touched, cand, gains, order_
	real scalar i, v, s, e, u, c, nt, t, ev, kv, best, mx, tot, r, acc, wv, nc
	KS = J(n, 1, 0)
	for (i = 1; i <= n; i++) KS[comm[i]] = KS[comm[i]] + kn[i]
	rc = (1::n)
	Kr = kn
	sz = J(n, 1, 1)
	ext = J(n, 1, 0)
	for (v = 1; v <= n; v++) {
		for (e = ptr[v]; e < ptr[v + 1]; e++) if (comm[nb[e]] == comm[v]) ext[v] = ext[v] + w[e]
	}
	cw = J(n, 1, 0)
	touched = J(n, 1, 0)
	cand = J(n, 1, 0)
	gains = J(n, 1, 0)
	order_ = jumble((1::n))
	for (i = 1; i <= n; i++) {
		v = order_[i]
		s = comm[v]
		kv = kn[v]
		if (sz[rc[v]] != 1) continue
		// v must be well connected to its community
		if (ext[v] < g * kv * (KS[s] - kv) - 1e-12) continue
		nt = 0
		for (e = ptr[v]; e < ptr[v + 1]; e++) {
			u = nb[e]
			if (comm[u] != s) continue
			c = rc[u]
			if (c == rc[v]) continue
			if (cw[c] == 0) touched[++nt] = c
			cw[c] = cw[c] + w[e]
		}
		// candidates: well-connected refined communities of the same community, with gain >= 0; staying alone has gain 0
		nc = 1
		cand[1] = rc[v]
		gains[1] = 0
		for (t = 1; t <= nt; t++) {
			c = touched[t]
			if (ext[c] >= g * Kr[c] * (KS[s] - Kr[c]) - 1e-12) {
				acc = cw[c] - g * kv * Kr[c]
				if (acc >= 0) {
					nc++
					cand[nc] = c
					gains[nc] = acc
				}
			}
		}
		best = rc[v]
		if (nc > 1) {
			mx = max(gains[|1 \ nc|])
			tot = 0
			for (t = 1; t <= nc; t++) tot = tot + exp((gains[t] - mx) / theta)
			r = runiform(1, 1) * tot
			acc = 0
			best = cand[nc]
			for (t = 1; t <= nc; t++) {
				acc = acc + exp((gains[t] - mx) / theta)
				if (r <= acc) {
					best = cand[t]
					break
				}
			}
		}
		if (best != rc[v]) {
			wv = cw[best]
			c = rc[v]
			ext[best] = ext[best] + ext[c] - 2 * wv
			Kr[best] = Kr[best] + kv
			sz[best] = sz[best] + 1
			sz[c] = 0
			Kr[c] = 0
			rc[v] = best
		}
		for (t = 1; t <= nt; t++) cw[touched[t]] = 0
	}
}

// one pass of the Leiden algorithm from the partition memb (labels of the nodes); returns the new partition
real colvector nw_lei_once(real scalar n, real colvector ptr0, real colvector nb0, real colvector w0, real colvector kn0, real colvector memb, ///
	real scalar g, real scalar theta)
{
	real colvector ptr, nb, w, kn, comm, mp, rc, ptr2, nb2, w2, kn2, newcomm
	real scalar cn, nc, nref, i
	cn = n
	ptr = ptr0
	nb = nb0
	w = w0
	kn = kn0
	comm = nw_cm_dense(memb)
	mp = (1::n)
	while (1) {
		nw_lei_move(cn, ptr, nb, w, kn, comm, g)
		comm = nw_cm_dense(comm)
		nc = max(comm)
		if (nc == cn) break
		nw_lei_refine(cn, ptr, nb, w, kn, comm, g, theta, rc)
		rc = nw_cm_dense(rc)
		nref = max(rc)
		if (nref == cn) break
		nw_cm_aggregate(cn, ptr, nb, w, rc, nref, ptr2, nb2, w2)
		kn2 = J(nref, 1, 0)
		newcomm = J(nref, 1, 0)
		for (i = 1; i <= cn; i++) {
			kn2[rc[i]] = kn2[rc[i]] + kn[i]
			newcomm[rc[i]] = comm[i]
		}
		mp = rc[mp, 1]
		ptr = ptr2
		nb = nb2
		w = w2
		kn = kn2
		comm = nw_cm_dense(newcomm)
		cn = nref
	}
	return(comm[mp, 1])
}

// modularity of a partition on the pairs (Newman's, with the resolution g)
real scalar nw_cm_q(real scalar n, real colvector ptr, real colvector nb, real colvector w, real colvector kn, real colvector comm, real scalar res)
{
	real scalar m2, e, i, inw, tot
	real colvector Kc
	m2 = sum(kn)
	inw = 0
	for (i = 1; i <= n; i++) for (e = ptr[i]; e < ptr[i + 1]; e++) if (comm[nb[e]] == comm[i]) inw = inw + w[e]
	Kc = J(max(comm), 1, 0)
	for (i = 1; i <= n; i++) Kc[comm[i]] = Kc[comm[i]] + kn[i]
	return((inw - res * sum(Kc :^ 2) / m2) / m2)
}

// Leiden with modularity as quality function; the best of `trials' runs of `iter' passes (iter < 0: until stable)
real colvector nw_cm_leiden(real scalar n, real matrix pairs, real scalar res, real scalar theta, real scalar iter, real scalar trials)
{
	real colvector ptr, nb, w, kn, memb, best, prev
	real scalar m2, g, tr, it, q, bq, i, same
	nw_pairs_csr(n, pairs, ptr, nb, w)
	kn = J(n, 1, 0)
	for (i = 1; i <= n; i++) if (ptr[i + 1] > ptr[i]) kn[i] = sum(w[|ptr[i] \ ptr[i + 1] - 1|])
	m2 = sum(kn)
	if (m2 <= 0) return((1::n))
	g = res / m2
	bq = -1e300
	best = (1::n)
	for (tr = 1; tr <= trials; tr++) {
		memb = (1::n)
		it = 0
		while (1) {
			prev = nw_cm_dense(memb)
			memb = nw_lei_once(n, ptr, nb, w, kn, memb, g, theta)
			it++
			if (iter > 0) {
				if (it >= iter) break
			}
			else {
				// until the partition no longer changes (at most 100 passes)
				same = all(nw_cm_first(prev) :== nw_cm_first(memb))
				if (same | it >= 100) break
			}
		}
		q = nw_cm_q(n, ptr, nb, w, kn, memb, res)
		if (q > bq + 1e-12) {
			bq = q
			best = memb
		}
	}
	return(nw_cm_first(best))
}

// x log2 x
real colvector nw_im_plogp(real colvector x)
{
	return(x :* ln(x :+ (x :== 0)) :/ ln(2))
}
real scalar nw_im_plogp1(real scalar x)
{
	if (x <= 0) return(0)
	return(x * ln(x) / ln(2))
}

// greedy node moves for the map equation; comm is changed in place; returns the number of moves
real scalar nw_im_move(real scalar n, real colvector ptr, real colvector nb, real colvector w, real colvector S, real colvector ain, ///
	real colvector comm, real scalar tot)
{
	real colvector mS, mA, cw, touched, ord
	real scalar Q, v, c0, c, e, nt, t, best, bd, moves, sweep, moved, i, d, wa, wb
	real scalar ea, eb, fa, fb, ea2, eb2, fa2, fb2, Sa2, Sb2, Aa2, Ab2, Q2
	mS = J(n, 1, 0)
	mA = J(n, 1, 0)
	for (i = 1; i <= n; i++) {
		mS[comm[i]] = mS[comm[i]] + S[i]
		mA[comm[i]] = mA[comm[i]] + ain[i]
	}
	// exit flow of each module: (S - A_in) / tot
	Q = 0
	for (i = 1; i <= n; i++) if (mS[i] > 0) Q = Q + (mS[i] - mA[i]) / tot
	cw = J(n, 1, 0)
	touched = J(n, 1, 0)
	moves = 0
	for (sweep = 1; sweep <= 200; sweep++) {
		moved = 0
		ord = jumble((1::n))
		for (i = 1; i <= n; i++) {
			v = ord[i]
			c0 = comm[v]
			nt = 0
			for (e = ptr[v]; e < ptr[v + 1]; e++) {
				c = comm[nb[e]]
				if (cw[c] == 0) touched[++nt] = c
				cw[c] = cw[c] + w[e]
			}
			wa = cw[c0]
			ea = (mS[c0] - mA[c0]) / tot
			fa = mS[c0] / tot
			Sa2 = mS[c0] - S[v]
			Aa2 = mA[c0] - ain[v] - 2 * wa
			ea2 = (Sa2 - Aa2) / tot
			fa2 = Sa2 / tot
			if (Sa2 < 1e-300) {
				ea2 = 0
				fa2 = 0
			}
			best = c0
			bd = -1e-10
			for (t = 1; t <= nt; t++) {
				c = touched[t]
				if (c == c0) continue
				wb = cw[c]
				eb = (mS[c] - mA[c]) / tot
				fb = mS[c] / tot
				Sb2 = mS[c] + S[v]
				Ab2 = mA[c] + ain[v] + 2 * wb
				eb2 = (Sb2 - Ab2) / tot
				fb2 = Sb2 / tot
				Q2 = Q - ea - eb + ea2 + eb2
				d = nw_im_plogp1(Q2) - nw_im_plogp1(Q) - 2 * (nw_im_plogp1(ea2) + nw_im_plogp1(eb2) - nw_im_plogp1(ea) - nw_im_plogp1(eb)) ///
					+ nw_im_plogp1(ea2 + fa2) + nw_im_plogp1(eb2 + fb2) - nw_im_plogp1(ea + fa) - nw_im_plogp1(eb + fb)
				if (d < bd) {
					bd = d
					best = c
				}
			}
			if (best != c0) {
				wb = cw[best]
				eb = (mS[best] - mA[best]) / tot
				Q = Q - ea - eb + ea2 + (mS[best] + S[v] - mA[best] - ain[v] - 2 * wb) / tot
				mS[c0] = Sa2
				mA[c0] = Aa2
				mS[best] = mS[best] + S[v]
				mA[best] = mA[best] + ain[v] + 2 * wb
				comm[v] = best
				moved++
				moves++
			}
			for (t = 1; t <= nt; t++) cw[touched[t]] = 0
			cw[c0] = 0
		}
		if (moved == 0) break
	}
	return(moves)
}

// map equation codelength of a partition of the original nodes (undirected flow, bits)
real scalar nw_im_codelength(real scalar n, real colvector ptr, real colvector nb, real colvector w, real colvector S0, real colvector comm, real scalar tot)
{
	real colvector mS, mA, ex, fl
	real scalar k, i, e
	k = max(comm)
	mS = J(k, 1, 0)
	mA = J(k, 1, 0)
	for (i = 1; i <= n; i++) {
		mS[comm[i]] = mS[comm[i]] + S0[i]
		for (e = ptr[i]; e < ptr[i + 1]; e++) if (comm[nb[e]] == comm[i]) mA[comm[i]] = mA[comm[i]] + w[e]
	}
	ex = (mS :- mA) :/ tot
	fl = mS :/ tot
	return(nw_im_plogp1(sum(ex)) - 2 * sum(nw_im_plogp(ex)) - sum(nw_im_plogp(S0 :/ tot)) + sum(nw_im_plogp(ex :+ fl)))
}

// levels of the core algorithm: moves from comm, then aggregation and the same on the aggregated graph, until no move
real colvector nw_im_levels(real scalar n, real colvector ptr, real colvector nb, real colvector w, real colvector S, real colvector ain, ///
	real colvector comm0, real scalar tot)
{
	real colvector comm, rc, ptr2, nb2, w2, S2, a2, agg, inner
	real scalar moves, k, i, e
	comm = comm0
	moves = nw_im_move(n, ptr, nb, w, S, ain, comm, tot)
	rc = nw_cm_dense(comm)
	k = max(rc)
	if (k == n) return(rc)
	nw_cm_aggregate(n, ptr, nb, w, rc, k, ptr2, nb2, w2)
	S2 = J(k, 1, 0)
	a2 = J(k, 1, 0)
	for (i = 1; i <= n; i++) {
		S2[rc[i]] = S2[rc[i]] + S[i]
		a2[rc[i]] = a2[rc[i]] + ain[i]
		for (e = ptr[i]; e < ptr[i + 1]; e++) if (rc[nb[e]] == rc[i]) a2[rc[i]] = a2[rc[i]] + w[e]
	}
	agg = nw_im_levels(k, ptr2, nb2, w2, S2, a2, (1::k), tot)
	return(nw_cm_dense(agg[rc, 1]))
}

// Infomap (undirected, two levels): greedy core algorithm with fine tuning, best of `trials'; codelength in bits
real colvector nw_cm_infomap(real scalar n, real matrix pairs, real scalar trials, real scalar codelen)
{
	real colvector ptr, nb, w, S, ain, comm, best, cand
	real scalar tot, tr, L, bL, one, it, L2, i
	nw_pairs_csr(n, pairs, ptr, nb, w)
	S = J(n, 1, 0)
	for (i = 1; i <= n; i++) if (ptr[i + 1] > ptr[i]) S[i] = sum(w[|ptr[i] \ ptr[i + 1] - 1|])
	tot = sum(S)
	ain = J(n, 1, 0)
	if (tot <= 0) {
		codelen = 0
		return((1::n))
	}
	// everything in one module
	one = -sum(nw_im_plogp(S :/ tot))
	bL = one
	best = J(n, 1, 1)
	for (tr = 1; tr <= trials; tr++) {
		comm = nw_im_levels(n, ptr, nb, w, S, ain, (1::n), tot)
		L = nw_im_codelength(n, ptr, nb, w, S, comm, tot)
		// fine tuning: node moves from the current partition, then aggregation again
		for (it = 1; it <= 20; it++) {
			cand = nw_im_levels(n, ptr, nb, w, S, ain, comm, tot)
			L2 = nw_im_codelength(n, ptr, nb, w, S, cand, tot)
			if (L2 < L - 1e-10) {
				L = L2
				comm = cand
			}
			else break
		}
		if (L < bL - 1e-10) {
			bL = L
			best = comm
		}
	}
	codelen = bL
	return(nw_cm_first(best))
}

// Leiden or Infomap of the network behind p
real colvector nw_cm_run(pointer(class nw_def scalar) scalar p, real scalar val, string scalar alg, real scalar res, real scalar theta, ///
	real scalar iter, real scalar trials)
{
	real matrix pairs
	real colvector r
	real scalar n, cl
	n = p->get_nodes()
	pairs = nwg_symweights(n, p->edgelist(), val)
	if (alg == "leiden") return(nw_cm_leiden(n, pairs, res, theta, iter, trials))
	r = nw_cm_infomap(n, pairs, trials, cl)
	st_numscalar("__nwcm_codelength", cl)
	return(r)
}
end
