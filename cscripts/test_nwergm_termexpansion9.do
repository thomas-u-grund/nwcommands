cscript

do unw_ergm.do

/*
	Certifies term-expansion wave 9: the directed "reciprocated two-path"
	(RTP) shared-partner definition for gwesp/gwdsp/gwnsp/esp/dsp
	(td.sptype == "RTP") - the fifth and last of R ergm's own `type='
	directed shared-partner definitions, following OTP (wave 5) and
	ITP/OSP/ISP (wave 8). RTP(i,j) = #{k : i<->k and k<->j} (k != j),
	where a<->b means BOTH has_edge(a,b) and has_edge(b,a) - fresh-
	checked against the real `statnet/ergm' C source's own
	`espRTP_change' comment ("configurations for edge i->j such that
	i<->k and j<->k (with k!=j)", `src/changestats_dgw_sp.h'), not just
	an R-level type-comment table. `shared_partners_rtp()' is checked
	against an independent O(n) brute-force definition, exactly like
	wave 8's ITP/OSP/ISP certification. Every gwesp/gwdsp/gwnsp/esp/dsp
	RTP variant is additionally checked with the same brute-force
	ErgmCertifyChangeStat() every other term in this suite uses (change
	statistic vs. from-scratch recompute over many random toggles) and
	the same "sums to a known total" identities waves 5/8 used. RTP's
	own distinctive structural property - toggling arc i->j can only
	affect ANOTHER dyad's RTP value when the reverse arc j->i already
	exists - gets its own dedicated, targeted test beyond what the
	generic ErgmCertifyChangeStat() cross-check already implies, since
	getting that gate backwards would silently zero out every real
	effect while still passing a change-stat check that happened to
	average out on the test network.
*/

mata:
mata set matastrict off

void build_dir_net(class ErgmGraph G, real scalar n, real scalar p, real scalar seed) {
	real scalar i, j
	rseed(seed)
	G.init(n, 1)
	for (i=1; i<=n; i++) {
		for (j=1; j<=n; j++) {
			if (i==j) continue
			if (runiform(1,1) < p) G.toggle(i,j)
		}
	}
}

// brute-force RTP count, independent of ErgmGraph's own neighbor lists
// and of shared_partners_rtp()/mutual_neighbors() - scan every possible
// k directly against has_edge(), matching the literal C-source type
// comment verbatim ("i<->k and j<->k (with k!=j)").
real scalar brute_rtp(class ErgmGraph G, real scalar i, real scalar j){
	real scalar k, cnt
	cnt = 0
	for (k=1; k<=G.n; k++) {
		if (k==i | k==j) continue
		if (G.has_edge(i,k) & G.has_edge(k,i) & G.has_edge(k,j) & G.has_edge(j,k)) cnt++
	}
	return(cnt)
}

// brute-force mutual-neighbor set, independent of mutual_neighbors()
// itself - a plain O(n) scan checking has_edge() both ways.
real rowvector brute_mutual_neighbors(class ErgmGraph G, real scalar x){
	real scalar k, cnt
	real rowvector out
	out = J(1, G.n, 0)
	cnt = 0
	for (k=1; k<=G.n; k++) {
		if (k==x) continue
		if (G.has_edge(x,k) & G.has_edge(k,x)) {
			cnt++
			out[cnt] = k
		}
	}
	return(cnt ? out[1..cnt] : J(1,0,0))
}

void test_rtp_matches_bruteforce(){
	class ErgmGraph scalar G
	real scalar n, i, j, maxdiff

	n = 18
	G = ErgmGraph()
	build_dir_net(G, n, 0.25, 9401)
	maxdiff = 0
	for (i=1; i<=n; i++) {
		for (j=1; j<=n; j++) {
			if (i==j) continue
			maxdiff = max((maxdiff, abs(G.shared_partners_rtp(i,j) - brute_rtp(G,i,j))))
		}
	}
	printf("test_rtp_matches_bruteforce: maxdiff=%g\n", maxdiff)
	assert(maxdiff == 0)
	printf("test_rtp_matches_bruteforce: OK\n")
}
test_rtp_matches_bruteforce()

void test_mutual_nb_bruteforce(){
	class ErgmGraph scalar G
	real scalar n, x, maxdiff
	real rowvector a, b

	n = 17
	G = ErgmGraph()
	build_dir_net(G, n, 0.3, 9402)
	maxdiff = 0
	for (x=1; x<=n; x++) {
		a = sort(G.mutual_neighbors(x)', 1)'
		b = sort(brute_mutual_neighbors(G,x)', 1)'
		if (cols(a) != cols(b)) maxdiff = maxdiff + 1
		else if (cols(a) > 0) maxdiff = maxdiff + sum(abs(a - b))
	}
	printf("test_mutual_nb_bruteforce: maxdiff=%g\n", maxdiff)
	assert(maxdiff == 0)
	printf("test_mutual_nb_bruteforce: OK\n")
}
test_mutual_nb_bruteforce()

// --- RTP symmetry sanity check: shared_partners_rtp(i,j) ==
//     shared_partners_rtp(j,i) - a property OTP/ITP do NOT have, and
//     the whole reason RTP's own dsp form (like OSP/ISP's) needs the
//     x2 doubling convention certified below.
void test_rtp_symmetric(){
	class ErgmGraph scalar G
	real scalar n, i, j, maxdiff, d

	n = 16
	G = ErgmGraph()
	build_dir_net(G, n, 0.25, 9403)
	maxdiff = 0
	for (i=1; i<=n; i++) {
		for (j=1; j<=n; j++) {
			if (i==j) continue
			d = abs(G.shared_partners_rtp(i,j) - G.shared_partners_rtp(j,i))
			if (d > maxdiff) maxdiff = d
		}
	}
	printf("test_rtp_symmetric: maxdiff=%g\n", maxdiff)
	assert(maxdiff == 0)
	printf("test_rtp_symmetric: OK\n")
}
test_rtp_symmetric()

// --- RTP's own distinctive gate: toggling i->j must leave EVERY other
//     dyad's RTP value (and hence the whole-model gwesp/gwdsp/esp/dsp
//     change statistic beyond the toggled dyad's own "own dyad" term)
//     completely unaffected whenever the reverse arc j->i is absent -
//     confirmed directly against espRTP_change's/dspRTP_change's own
//     htedge gate, not just implied by ErgmCertifyChangeStat() passing
//     on average. dsp has no "own dyad" term at all, so its change
//     statistic must be EXACTLY zero in this case - the sharpest
//     possible version of this check.
void test_rtp_gate_no_reverse(){
	class ErgmGraph scalar G
	class ErgmTermData scalar tdg, tdd
	real scalar n, i, j, trial
	real rowvector chg

	n = 14
	G = ErgmGraph()
	build_dir_net(G, n, 0.2, 9404)
	tdg = ErgmTermData()
	tdg.decay = 0.6
	tdg.sptype = "RTP"
	tdd = ErgmTermData()
	tdd.levels = (0\1\2\3)
	tdd.sptype = "RTP"

	for (trial=1; trial<=40; trial++) {
		i = ceil(runiform(1,1)*n)
		j = ceil(runiform(1,1)*n)
		if (i==j) continue
		if (G.has_edge(j,i)) continue		// only the no-reverse-arc case
		chg = change_gwdsp_rtp(G, i, j, tdg)
		assert(max(abs(chg)) == 0)
		chg = change_dsp_rtp(G, i, j, tdd)
		assert(max(abs(chg)) == 0)
	}
	printf("test_rtp_gate_no_reverse: OK\n")
}
test_rtp_gate_no_reverse()

void certify_gw_family(string scalar sptype, real scalar seedbase){
	class ErgmGraph scalar Ge, Gd, Gn
	class ErgmModel scalar Me, Md, Mn
	class ErgmTermData scalar tde, tdd, tdn
	real scalar n, md

	n = 14
	Ge = ErgmGraph()
	build_dir_net(Ge, n, 0.2, seedbase+1)
	Me = ErgmModel()
	Me.init()
	tde = ErgmTermData()
	tde.decay = 0.6
	tde.sptype = sptype
	Me.addterm("gwesp", 1, &stat_gwesp(), &change_gwesp(), tde, ("gwesp"))
	md = ErgmCertifyChangeStat(Me, Ge)
	printf("certify_gw_family(%s) gwesp: max diff = %9.2e\n", sptype, md)
	assert(md < 1e-6)

	Gd = ErgmGraph()
	build_dir_net(Gd, n-1, 0.25, seedbase+2)
	Md = ErgmModel()
	Md.init()
	tdd = ErgmTermData()
	tdd.decay = 0.5
	tdd.sptype = sptype
	Md.addterm("gwdsp", 1, &stat_gwdsp(), &change_gwdsp(), tdd, ("gwdsp"))
	md = ErgmCertifyChangeStat(Md, Gd)
	printf("certify_gw_family(%s) gwdsp: max diff = %9.2e\n", sptype, md)
	assert(md < 1e-6)

	Gn = ErgmGraph()
	build_dir_net(Gn, n-1, 0.22, seedbase+3)
	Mn = ErgmModel()
	Mn.init()
	tdn = ErgmTermData()
	tdn.decay = 0.55
	tdn.sptype = sptype
	Mn.addterm("gwnsp", 1, &stat_gwnsp(), &change_gwnsp(), tdn, ("gwnsp"))
	md = ErgmCertifyChangeStat(Mn, Gn)
	printf("certify_gw_family(%s) gwnsp: max diff = %9.2e\n", sptype, md)
	assert(md < 1e-6)

	printf("certify_gw_family(%s): OK\n", sptype)
}
certify_gw_family("RTP", 9410)

void certify_d_family(string scalar sptype, real scalar seedbase){
	class ErgmGraph scalar Ge, Gd
	class ErgmModel scalar Me, Md
	class ErgmTermData scalar tde, tdd
	real scalar n, md

	n = 14
	Ge = ErgmGraph()
	build_dir_net(Ge, n, 0.25, seedbase+1)
	Me = ErgmModel()
	Me.init()
	tde = ErgmTermData()
	tde.levels = (0\1\2)
	tde.sptype = sptype
	Me.addterm("esp", 3, &stat_esp(), &change_esp(), tde, ("esp0","esp1","esp2"))
	md = ErgmCertifyChangeStat(Me, Ge)
	printf("certify_d_family(%s) esp: max diff = %9.2e\n", sptype, md)
	assert(md < 1e-8)

	Gd = ErgmGraph()
	build_dir_net(Gd, n-1, 0.2, seedbase+2)
	Md = ErgmModel()
	Md.init()
	tdd = ErgmTermData()
	tdd.levels = (1)
	tdd.sptype = sptype
	Md.addterm("dsp", 1, &stat_dsp(), &change_dsp(), tdd, ("dsp1"))
	md = ErgmCertifyChangeStat(Md, Gd)
	printf("certify_d_family(%s) dsp: max diff = %9.2e\n", sptype, md)
	assert(md < 1e-8)

	printf("certify_d_family(%s): OK\n", sptype)
}
certify_d_family("RTP", 9440)

// --- identity: sum over d of esp(d) must equal the arc count, and sum
//     over d of dsp(d) must equal n*(n-1) - true for RTP too, including
//     its dsp form's own "iterate unordered pairs once, double the
//     contribution" convention (the sharpest available check that the
//     doubling factor is neither missing nor duplicated).
void test_sums_for_type(string scalar sptype, real scalar seed){
	class ErgmGraph scalar G
	class ErgmTermData scalar td
	real scalar n, i, maxd
	real rowvector s

	n = 15
	G = ErgmGraph()
	build_dir_net(G, n, 0.3, seed)
	maxd = n
	td = ErgmTermData()
	td.levels = J(maxd+1,1,0)
	for (i=0; i<=maxd; i++) td.levels[i+1] = i
	td.sptype = sptype
	s = stat_esp(G, td)
	printf("test_sums_for_type(%s) esp: sum=%g arcs=%g\n", sptype, sum(s), rows(G.all_ties()))
	assert(reldif(sum(s), rows(G.all_ties())) < 1e-8)

	maxd = n-2
	td = ErgmTermData()
	td.levels = J(maxd+1,1,0)
	for (i=0; i<=maxd; i++) td.levels[i+1] = i
	td.sptype = sptype
	s = stat_dsp(G, td)
	printf("test_sums_for_type(%s) dsp: sum=%g pairs=%g\n", sptype, sum(s), n*(n-1))
	assert(reldif(sum(s), n*(n-1)) < 1e-8)

	printf("test_sums_for_type(%s): OK\n", sptype)
}
test_sums_for_type("RTP", 9470)

end
