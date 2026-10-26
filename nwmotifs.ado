capture program drop nwmotifs
program nwmotifs, rclass
	version 9
	syntax [anything(name=netname)] [, silent PLOT NAME(string) ONEmode SIXnode GENerate(string) replace MATrix(string) NORMalise POSNorm(string)]

	_nwsyntax `netname', max(1)
	// A two-mode network gets the bipartite motifs (Simmons et al. 2019, bmotif) by default; onemode counts the 4-node motifs of the
	// bipartite graph read as a one-mode graph (the result of earlier versions).  nw2motifs is an alias of this form.
	if "`is2mode'" == "true" & "`onemode'" == "" {
		if "`plot'" != "" | "`name'" != "" {
			di "{err}Options {bf:plot} and {bf:name()} have no two-mode form; {bf:onemode} gives the one-mode census of the bipartite graph."
			error 198
		}
		_nwmotifs_two `netname', `sixnode' generate(`generate') `replace' matrix(`matrix') `normalise' posnorm(`posnorm') `silent'
		return add
		capture confirm number 1
		exit
	}
	if "`sixnode'`generate'`replace'`matrix'`normalise'`posnorm'" != "" {
		di "{err}Options {bf:sixnode}, {bf:generate()}, {bf:matrix()}, {bf:normalise} and {bf:posnorm()} belong to the two-mode form and need a two-mode network (and are not used with {bf:onemode}); see {help nw2motifs}."
		error 198
	}
	local __vnquiet = cond("`silent'" != "", "quiet", "")
	_nwvaluednote `netname', `__vnquiet'
	if r(shown) == 1 {
		noi di `"`r(msg)'"'
	}

	if "`directed'" == "true" {
		di "{txt}Note: {bf:`netname'} is directed - the 4-node motif census below"
		di "{txt}treats every tie as undirected (a directed 4-node census has 218"
		di "{txt}distinct isomorphism classes and is not attempted here); see"
		di "{txt}{help nwtriads} for a genuinely directed 3-node census."
	}

	tempname mc
	mata: `mc' = `netobj'->calculate_motif4()

	// BUGFIX: a plain `mata: st_numscalar("r(x)", ...)' poke does NOT
	// survive past this program's own exit when the program is declared
	// `rclass' - Stata's rclass wrapper discards any "r(x)" scalar that
	// was not published via the formal `return' command, confirmed via
	// an isolated repro (a two-line rclass program that pokes r(foo)
	// directly leaves `return list' empty; the identical program
	// without `, rclass' keeps it). nwtriads.ado uses the same raw-poke
	// pattern and happens to work only because it was never declared
	// `rclass' in the first place - not a safe pattern to copy for a
	// genuinely rclass command. Fixed by reading each count back into a
	// local first, then publishing via `return scalar', matching every
	// other command built this session (nwfactions/nwmaxflow/
	// nwmatching/nwpagerank/nwrandomwalk/nwlambda).
	// strofreal() without a format keeps 9 significant digits, which cut counts above 999,999,999
	// (a 1,000-node network has 4 x 10^10 4-node sets); %21.0g keeps every digit of an integer count
	mata: st_local("__nwmotifs_path", strofreal(`mc'[1], "%21.0g"))
	mata: st_local("__nwmotifs_star", strofreal(`mc'[2], "%21.0g"))
	mata: st_local("__nwmotifs_cycle", strofreal(`mc'[3], "%21.0g"))
	mata: st_local("__nwmotifs_paw", strofreal(`mc'[4], "%21.0g"))
	mata: st_local("__nwmotifs_diamond", strofreal(`mc'[5], "%21.0g"))
	mata: st_local("__nwmotifs_k4", strofreal(`mc'[6], "%21.0g"))
	mata: st_local("__nwmotifs_disc", strofreal(`mc'[7], "%21.0g"))

	return scalar path = `__nwmotifs_path'
	return scalar star = `__nwmotifs_star'
	return scalar cycle = `__nwmotifs_cycle'
	return scalar paw = `__nwmotifs_paw'
	return scalar diamond = `__nwmotifs_diamond'
	return scalar k4 = `__nwmotifs_k4'
	return scalar disconnected = `__nwmotifs_disc'
	return local netname "`netname'"

	// Display from the locals computed above, not from r(): r(x) reads
	// as missing from inside the same program body that just called
	// "return scalar x = ..." (r() is only published to the CALLER once
	// this program exits) - the same gotcha documented in nwcug.ado's
	// own header comment, found there via an identical bug in
	// nw2project.ado earlier this session.
	if "`silent'" == "" {
		di
		di "{txt}    4-node motif census: {res}`netname'{txt}"
		di
		di "{txt}{ralign 14:path}{col 16}{c |}{ralign 14:star}{col 32}{c |}{ralign 14:cycle}{col 48}{c |}{ralign 14:paw}{col 64}{c |}"
		di "{hline 15}{c +}{hline 15}{c +}{hline 15}{c +}{hline 15}{c +}"
		di "{res}{ralign 14:`__nwmotifs_path'}{col 16}{c |}{ralign 14:`__nwmotifs_star'}{col 32}{c |}{ralign 14:`__nwmotifs_cycle'}{col 48}{c |}{ralign 14:`__nwmotifs_paw'}{col 64}{c |}"
		di
		di "{txt}{ralign 14:diamond}{col 16}{c |}{ralign 14:k4}{col 32}{c |}{ralign 14:disconn.}{col 48}{c |}"
		di "{hline 15}{c +}{hline 15}{c +}{hline 15}{c +}"
		di "{res}{ralign 14:`__nwmotifs_diamond'}{col 16}{c |}{ralign 14:`__nwmotifs_k4'}{col 32}{c |}{ralign 14:`__nwmotifs_disc'}{col 48}{c |}"
	}

	// plot(): a bar chart of the 7 motif-category counts, via this
	// package's own established preserve/rebuild-a-plotting-dataset/
	// restore convention (matching nwcug's own plot() for its null
	// distribution, and the identical addition just made to
	// nwtriads.ado). Reads from the SAME locals the display block above
	// uses, not from r() - r(x) reads as missing from inside this same
	// program body, since it was published via the formal `return'
	// command (see the BUGFIX comment above).
	if "`plot'" != "" {
		if "`name'" == "" {
			local name "motifs"
		}
		preserve
		qui drop _all
		qui set obs 7
		qui gen long catcode = _n
		label define __nwmotifs_catlbl 1 "path" 2 "star" 3 "cycle" ///
			4 "paw" 5 "diamond" 6 "k4" 7 "disconnected", replace
		label values catcode __nwmotifs_catlbl
		qui gen double count = .
		qui replace count = `__nwmotifs_path' if catcode==1
		qui replace count = `__nwmotifs_star' if catcode==2
		qui replace count = `__nwmotifs_cycle' if catcode==3
		qui replace count = `__nwmotifs_paw' if catcode==4
		qui replace count = `__nwmotifs_diamond' if catcode==5
		qui replace count = `__nwmotifs_k4' if catcode==6
		qui replace count = `__nwmotifs_disc' if catcode==7
		graph bar (asis) count, over(catcode, label(angle(45))) ///
			ytitle("Count") ///
			title("4-node motif census: `netname'", size(medium)) ///
			bar(1, fcolor(gs12) lcolor(gs6)) ///
			legend(off) name(`name', replace)
		restore
		di as txt "(plot saved as {bf:`name'}; motif-category counts for `netname')"
	}
end

capture program drop _nwmotifs_two
program _nwmotifs_two, rclass
	version 12
	// Bipartite motifs of a two-mode network: the 17 motifs of 2 to 5 nodes (44 with six nodes) of Simmons et al.
	// (2019, bmotif), their frequencies and the number of times every node takes each of the 46 (148) node positions.
	//   nw2motifs [netname] [, sixnode generate(prefix) replace matrix(name) normalise posnorm(type) silent]
	// Runs in the native plugin (kernel 50); equals bmotif::mcount and bmotif::node_positions (bmotif 2.0.2).
	syntax [anything(name=netname)] [, SIXnode GENerate(string) replace MATrix(string) NORMalise POSNorm(string) silent]

	_nwsyntax `netname', max(1)
	if "`is2mode'" != "true" {
		di "{err}nwmotifs: onemode is required to use the one-mode form of this network."
		error 198
	}
	local six = ("`sixnode'" != "")
	local P = cond(`six', 148, 46)
	local NM = cond(`six', 44, 17)

	if "`posnorm'" == "" local posnorm "none"
	local pn "none sum position sizeclass sizeclass_plus1 sizeclass_NAzero levelsize levelsize_plus1 levelsize_NAzero motif motif_plus1 motif_NAzero"
	local okpn : list posnorm in pn
	if !`okpn' {
		di "{err}posnorm() must be one of: `pn'"
		error 198
	}
	if "`posnorm'" != "none" & "`generate'`matrix'" == "" {
		di "{err}posnorm() needs generate() or matrix(): it normalises the node position counts."
		error 198
	}
	if "`generate'" != "" {
		capture confirm names `generate'1
		if _rc {
			di "{err}generate() must be a valid variable name stub (the variables are {it:stub}1, {it:stub}2, ...)."
			error 198
		}
		if length("`generate'") > 28 {
			di "{err}generate(): the stub is too long."
			error 198
		}
		if "`replace'" == "" {
			forvalues i = 1/`P' {
				capture confirm variable `generate'`i', exact
				if _rc == 0 {
					di "{err}Variable {bf:`generate'`i'} already exists; specify {bf:replace}"
					error 110
				}
			}
		}
	}
	if "`matrix'" != "" {
		capture confirm names `matrix'
		if _rc {
			di "{err}matrix() must be a valid matrix name."
			error 198
		}
		if `nodes' > c(max_matdim) {
			di "{err}matrix(): the network has `nodes' nodes and Stata matrices are limited to " c(max_matdim) " rows; use {bf:generate()} for the node position counts."
			error 908
		}
	}

	local __vnquiet = cond("`silent'" != "", "quiet", "")
	_nwvaluednote `netname', `__vnquiet'
	if r(shown) == 1 {
		noi di `"`r(msg)'"'
	}

	tempname mot
	mata: nw2m_run(`netobj', `six', "`normalise'" != "", "`posnorm'", "`mot'")
	if scalar(__nw2m_rc) != 0 {
		local rc = scalar(__nw2m_rc)
		scalar drop __nw2m_rc
		if `rc' == 1 {
			di "{err}{bf:nw2motifs} runs in the native plugin of nwcommands and the plugin of this installation is older than the command (or there is no plugin for this platform)."
			di "{err}Update the installation: {bf:net install nwcommands, from(https://raw.githubusercontent.com/thomas-u-grund/nwcommands/main/) replace} and restart Stata."
			exit 198
		}
		di "{err}nw2motifs: the native plugin ran out of memory or returned an unexpected result."
		exit 198
	}
	scalar drop __nw2m_rc

	if "`generate'" != "" {
		forvalues i = 1/`P' {
			capture confirm variable `generate'`i', exact
			if _rc == 0 drop `generate'`i'
		}
		qui if _N < `nodes' {
			set obs `nodes'
		}
		_nwsyncrows `netname'
		mata: nw2m_store("`generate'", `P')
	}
	if "`matrix'" != "" {
		capture matrix drop `matrix'
		mata: nw2m_tomatrix("`matrix'")
	}
	capture mata: mata drop __nw2m_pc
	local __dummy = 1

	// motifs: motif, nodes, frequency [, normalised]
	if "`normalise'" != "" {
		matrix colnames `mot' = motif nodes frequency normalise_sum normalise_sizeclass normalise_levelsize normalise_nodesets
	}
	else {
		matrix colnames `mot' = motif nodes frequency
	}

	if "`silent'" == "" {
		di "{txt}Bipartite motifs of {res}`netname'{txt}: `=cond(`six', "2 to 6", "2 to 5")' nodes; rows = mode 1 (`n1' nodes), columns = mode 2 (`n2' nodes)"
		if "`normalise'" == "" {
			di "{hline 42}"
			di "{txt}{ralign 6:motif}{ralign 7:nodes}{ralign 9:r x c}{ralign 20:frequency}"
			di "{hline 42}"
			forvalues m = 1/`NM' {
				mata: st_local("__rc", nw2m_rxc(`m'))
				local nn = `mot'[`m', 2]
				local ff = strtrim(string(`mot'[`m', 3], "%20.0f"))
				di "{res}{ralign 6:`m'}{ralign 7:`nn'}{ralign 9:`__rc'}{ralign 20:`ff'}"
			}
			di "{hline 42}"
		}
		else {
			di "{hline 88}"
			di "{txt}{ralign 5:motif}{ralign 6:nodes}{ralign 7:r x c}{ralign 17:frequency}{ralign 11:sum}{ralign 11:sizeclass}{ralign 11:levelsize}{ralign 11:nodesets}"
			di "{hline 88}"
			forvalues m = 1/`NM' {
				mata: st_local("__rc", nw2m_rxc(`m'))
				local nn = `mot'[`m', 2]
				local ff = strtrim(string(`mot'[`m', 3], "%17.0f"))
				local line "{res}{ralign 5:`m'}{ralign 6:`nn'}{ralign 7:`__rc'}{ralign 17:`ff'}"
				forvalues j = 4/7 {
					local v = `mot'[`m', `j']
					if missing(`v') local line "`line'{ralign 11:.}"
					else local line "`line'{ralign 11:`=string(`v', "%9.5f")'}"
				}
				di "`line'"
			}
			di "{hline 88}"
		}
		if "`generate'" != "" di "{txt}Node position counts stored in {bf:`generate'1} to {bf:`generate'`P'} (position ids of bmotif), nodes in network order."
	}

	return matrix motifs = `mot'
	return scalar sixnode = `six'
	return scalar n_mode1 = `n1'
	return scalar n_mode2 = `n2'
	return local netname "`netname'"
	return local posnorm "`posnorm'"
end

capture mata: mata drop nw2m_run()
capture mata: mata drop nw2m_store()
capture mata: mata drop nw2m_tomatrix()
capture mata: mata drop nw2m_rxc()
capture mata: mata drop nw2m_dict()
capture mata: mata drop nw2m_groups()
capture mata: mata drop nw2m_norm()
capture mata: mata drop nw2m_motifs()
mata:
// The dictionary of bmotif 2.0.2: for every motif its rows a, its columns b, its first and its last node position id.
real matrix nw2m_dict()
{
	return((1,1,1,2 \ 1,2,3,4 \ 2,1,5,6 \ 3,1,7,8 \ 2,2,9,12 \ 2,2,13,14 \ 1,3,15,16 \ 4,1,17,18 \ 3,2,19,22 \ 3,2,23,25 \
		3,2,26,29 \ 3,2,30,31 \ 2,3,32,35 \ 2,3,36,38 \ 2,3,39,42 \ 2,3,43,44 \ 1,4,45,46 \ 5,1,47,48 \ 4,2,49,52 \ 4,2,53,57 \
		4,2,58,61 \ 4,2,62,64 \ 4,2,65,68 \ 4,2,69,70 \ 3,3,71,74 \ 3,3,75,78 \ 3,3,79,82 \ 3,3,83,88 \ 3,3,89,94 \ 3,3,95,99 \
		3,3,100,103 \ 3,3,104,108 \ 3,3,109,112 \ 3,3,113,114 \ 3,3,115,118 \ 3,3,119,122 \ 3,3,123,124 \ 2,4,125,128 \ 2,4,129,133 \
		2,4,134,137 \ 2,4,138,140 \ 2,4,141,144 \ 2,4,145,146 \ 1,5,147,148))
}

string scalar nw2m_rxc(real scalar m)
{
	real matrix D
	D = nw2m_dict()
	return(strofreal(D[m, 1]) + "x" + strofreal(D[m, 2]))
}

// column groups (first, last) of the positions for the normalisations: kind 1 = size class (nodes of the motif),
// 2 = level size (rows x columns of the motif), 3 = motif
real matrix nw2m_groups(real scalar kind, real scalar six)
{
	real matrix D, G
	real scalar m, nm, key, last
	D = nw2m_dict()
	nm = six ? 44 : 17
	G = J(0, 2, .)
	last = .
	for (m = 1; m <= nm; m++) {
		if (kind == 1) key = D[m, 1] + D[m, 2]
		else if (kind == 2) key = D[m, 1] * 10 + D[m, 2]
		else key = m
		if (key != last) G = G \ (D[m, 3], D[m, 4])
		else G[rows(G), 2] = D[m, 4]
		last = key
	}
	return(G)
}

// the normalisations of bmotif:::normalise_node_positions() for the position counts of all nodes
real matrix nw2m_norm(real matrix pc, string scalar type, real scalar six)
{
	real matrix x, G
	real scalar g, kind, plus1, nazero
	string scalar base

	if (type == "none") return(pc)
	x = pc
	if (type == "sum") return(x :/ rowsum(x))
	if (type == "position") return(x :/ colsum(x))
	plus1 = (substr(type, -6, .) == "_plus1")
	nazero = (substr(type, -7, .) == "_NAzero")
	base = type
	if (plus1) base = substr(type, 1, strlen(type) - 6)
	if (nazero) base = substr(type, 1, strlen(type) - 7)
	kind = (base == "sizeclass" ? 1 : (base == "levelsize" ? 2 : 3))
	if (plus1) x = x :+ 1
	G = nw2m_groups(kind, six)
	for (g = 1; g <= rows(G); g++) {
		x[., (G[g, 1]..G[g, 2])] = x[., (G[g, 1]..G[g, 2])] :/ rowsum(x[., (G[g, 1]..G[g, 2])])
	}
	if (nazero) x = editmissing(x, 0)
	return(x)
}

// the motif table (bmotif::mcount): motif, nodes, frequency [, normalise_sum, normalise_sizeclass, normalise_levelsize, normalise_nodesets]
real matrix nw2m_motifs(real matrix pc, real scalar six, real scalar norm, real scalar n1, real scalar n2)
{
	real matrix D, out, G
	real colvector f, nodes, sets
	real scalar m, nm, g
	real colvector cs

	D = nw2m_dict()
	nm = six ? 44 : 17
	f = J(nm, 1, 0)
	nodes = D[1::nm, 1] :+ D[1::nm, 2]
	for (m = 1; m <= nm; m++) f[m] = sum(colsum(pc[., (D[m, 3]..D[m, 4])])) / nodes[m]
	out = ((1::nm), nodes, f)
	if (norm) {
		sets = J(nm, 1, .)
		for (m = 1; m <= nm; m++) sets[m] = comb(n1, D[m, 1]) * comb(n2, D[m, 2])
		out = out, f :/ sum(f)
		// size class and level size: groups of motifs
		cs = J(nm, 1, .)
		for (m = 1; m <= nm; m++) cs[m] = f[m] / sum(select(f, nodes :== nodes[m]))
		out = out, cs
		cs = J(nm, 1, .)
		for (m = 1; m <= nm; m++) cs[m] = f[m] / sum(select(f, (D[1::nm, 1] :== D[m, 1]) :& (D[1::nm, 2] :== D[m, 2])))
		out = out, cs, f :/ sets
	}
	return(out)
}

// runs the kernel; the position counts stay in the external __nw2m_pc (n x P, network order); the motif table goes to a Stata matrix
void nw2m_run(pointer(class nw_def scalar) scalar p, real scalar six, real scalar norm, string scalar posnorm, string scalar mname)
{
	real matrix el, T, R, M
	real colvector md, cross
	real rowvector aux
	real scalar st, n, P, n1, n2
	transmorphic pc

	st_numscalar("__nw2m_rc", 2)
	if (nwg_comb_version() < 11) {
		st_numscalar("__nw2m_rc", 1)
		return
	}
	n = p->get_nodes()
	P = six ? 148 : 46
	md = strtoreal(p->get_modes())'
	n1 = sum(md :== 1)
	n2 = sum(md :== 2)
	el = p->edgelist()
	T = J(0, 3, .)
	if (rows(el) > 0) {
		cross = ((md[el[., 1]] :== 1) :& (md[el[., 2]] :== 2)) :| ((md[el[., 1]] :== 2) :& (md[el[., 2]] :== 1))
		cross = cross :& (el[., 3] :< .) :& (el[., 3] :> 0)
		T = select(el, cross)
	}
	R = nwg_comb(50, n, T, md, (six), aux, st)
	if (st != 0) return
	if (rows(R) == 0 & n > 0) R = J(n, P, 0)
	if (rows(R) != n | cols(R) != P) return
	M = nw2m_motifs(R, six, norm, n1, n2)
	st_matrix(mname, M)
	st_local("n1", strofreal(n1))
	st_local("n2", strofreal(n2))
	R = nw2m_norm(R, posnorm, six)
	external real matrix __nw2m_pc
	__nw2m_pc = R
	st_numscalar("__nw2m_rc", 0)
}

void nw2m_store(string scalar stub, real scalar P)
{
	external real matrix __nw2m_pc
	real rowvector idx
	string rowvector nm
	real matrix D
	real scalar i, m
	string scalar lab

	D = nw2m_dict()
	nm = J(1, P, "")
	for (i = 1; i <= P; i++) nm[i] = stub + strofreal(i)
	idx = st_addvar("double", nm)
	st_store((1::rows(__nw2m_pc)), idx, __nw2m_pc)
	for (i = 1; i <= P; i++) {
		for (m = 1; m <= 44; m++) if (i >= D[m, 3] & i <= D[m, 4]) break
		lab = "bmotif position " + strofreal(i) + " (motif " + strofreal(m) + ": " + strofreal(D[m, 1]) + " rows, " + strofreal(D[m, 2]) + " columns)"
		st_varlabel(idx[i], lab)
	}
}

void nw2m_tomatrix(string scalar name)
{
	external real matrix __nw2m_pc
	string matrix cs
	real scalar P, i
	P = cols(__nw2m_pc)
	st_matrix(name, __nw2m_pc)
	cs = J(P, 2, "")
	for (i = 1; i <= P; i++) cs[i, 2] = "np" + strofreal(i)
	st_matrixcolstripe(name, cs)
}
end
