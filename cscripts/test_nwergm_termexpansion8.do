cscript

do unw_ergm.do

/*
	Certifies term-expansion wave 8: the directed "incoming two-path"
	(ITP), "outgoing shared partner" (OSP), and "incoming shared
	partner" (ISP) shared-partner definitions for gwesp/gwdsp/gwnsp/
	esp/dsp (td.sptype in {"ITP","OSP","ISP"}) - the three remaining
	members of R ergm's own `type=' argument beyond the OTP default
	(wave 5, test_nwergm_termexpansion5.do) and the undirected UTP
	default. Each primitive is checked against an independent O(n)
	brute-force definition matching the literal type description in
	the real `statnet/ergm' C source (`src/changestats_dgw_sp.h`'s own
	comments: "ITP - Incoming two-path (i<-k<-j)", "OSP - Outgoing
	shared partner (i->k<-j)", "ISP - Incoming shared partner
	(i<-k->j)"), independent of ErgmGraph's own neighbor-list
	machinery or of shared_partners_otp()/common_neighbors() (which
	the real implementations reuse) - so a bug in either the primitive
	or its reuse would be caught by mismatching the brute force, not
	just by self-consistency. Every gwesp/gwdsp/gwnsp/esp/dsp variant
	is additionally checked with the same brute-force
	ErgmCertifyChangeStat() every other term in this suite uses (change
	statistic vs. from-scratch recompute over many random toggles), and
	the same "sums to a known total" identities wave 5 used for OTP -
	including, for OSP/ISP specifically, confirming the `dsp' family's
	own "iterate unordered pairs once, double the contribution" convention
	(rather than OTP/ITP's doubled ORDERED-pair enumeration) still sums to
	the same n*(n-1) total - the sharpest possible check that the doubling
	factor is neither missing nor duplicated.
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

// brute-force ITP/OSP/ISP counts, independent of ErgmGraph's own
// neighbor lists and of shared_partners_otp()/common_neighbors() -
// scan every possible k directly against has_edge(), matching the
// literal C-source type descriptions verbatim.
real scalar brute_itp(class ErgmGraph G, real scalar i, real scalar j){
	real scalar k, cnt
	cnt = 0
	for (k=1; k<=G.n; k++) {
		if (k==i | k==j) continue
		if (G.has_edge(j,k) & G.has_edge(k,i)) cnt++	// i<-k<-j
	}
	return(cnt)
}
real scalar brute_osp(class ErgmGraph G, real scalar i, real scalar j){
	real scalar k, cnt
	cnt = 0
	for (k=1; k<=G.n; k++) {
		if (k==i | k==j) continue
		if (G.has_edge(i,k) & G.has_edge(j,k)) cnt++	// i->k<-j
	}
	return(cnt)
}
real scalar brute_isp(class ErgmGraph G, real scalar i, real scalar j){
	real scalar k, cnt
	cnt = 0
	for (k=1; k<=G.n; k++) {
		if (k==i | k==j) continue
		if (G.has_edge(k,i) & G.has_edge(k,j)) cnt++	// i<-k->j
	}
	return(cnt)
}

void test_dirtypes_match_bruteforce(){
	class ErgmGraph scalar G
	real scalar n, i, j, maxdiff_itp, maxdiff_osp, maxdiff_isp, d

	n = 18
	G = ErgmGraph()
	build_dir_net(G, n, 0.25, 8401)
	maxdiff_itp = 0
	maxdiff_osp = 0
	maxdiff_isp = 0
	for (i=1; i<=n; i++) {
		for (j=1; j<=n; j++) {
			if (i==j) continue
			d = abs(G.shared_partners_itp(i,j) - brute_itp(G,i,j))
			if (d > maxdiff_itp) maxdiff_itp = d
			d = abs(G.shared_partners_osp(i,j) - brute_osp(G,i,j))
			if (d > maxdiff_osp) maxdiff_osp = d
			d = abs(G.shared_partners_isp(i,j) - brute_isp(G,i,j))
			if (d > maxdiff_isp) maxdiff_isp = d
		}
	}
	printf("test_dirtypes_match_bruteforce: maxdiff itp=%g osp=%g isp=%g\n", maxdiff_itp, maxdiff_osp, maxdiff_isp)
	assert(maxdiff_itp == 0)
	assert(maxdiff_osp == 0)
	assert(maxdiff_isp == 0)
	printf("test_dirtypes_match_bruteforce: OK\n")
}
test_dirtypes_match_bruteforce()

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
certify_gw_family("ITP", 8410)
certify_gw_family("OSP", 8420)
certify_gw_family("ISP", 8430)

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
certify_d_family("ITP", 8440)
certify_d_family("OSP", 8450)
certify_d_family("ISP", 8460)

// --- identities: sum over d of esp(d) must equal the arc count, and sum
//     over d of dsp(d) must equal n*(n-1) - true for EVERY sptype,
//     including OSP/ISP, whose dsp forms visit each unordered pair once
//     and double the contribution rather than visiting both ordered
//     instances directly (wave 5's own comment on this identity, applied
//     here as the sharpest available check that the doubling factor is
//     neither missing nor duplicated).
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
test_sums_for_type("ITP", 8470)
test_sums_for_type("OSP", 8480)
test_sums_for_type("ISP", 8490)

// --- OSP/ISP symmetry sanity check: shared_partners_osp(i,j) ==
//     shared_partners_osp(j,i), and likewise for ISP - a property OTP/
//     ITP do NOT have, and the whole reason their dsp forms need the
//     x2 doubling convention checked above.
void test_osp_isp_symmetric(){
	class ErgmGraph scalar G
	real scalar n, i, j, maxdiff_osp, maxdiff_isp, d

	n = 16
	G = ErgmGraph()
	build_dir_net(G, n, 0.25, 8495)
	maxdiff_osp = 0
	maxdiff_isp = 0
	for (i=1; i<=n; i++) {
		for (j=1; j<=n; j++) {
			if (i==j) continue
			d = abs(G.shared_partners_osp(i,j) - G.shared_partners_osp(j,i))
			if (d > maxdiff_osp) maxdiff_osp = d
			d = abs(G.shared_partners_isp(i,j) - G.shared_partners_isp(j,i))
			if (d > maxdiff_isp) maxdiff_isp = d
		}
	}
	printf("test_osp_isp_symmetric: maxdiff osp=%g isp=%g\n", maxdiff_osp, maxdiff_isp)
	assert(maxdiff_osp == 0)
	assert(maxdiff_isp == 0)
	printf("test_osp_isp_symmetric: OK\n")
}
test_osp_isp_symmetric()

// --- ITP mirror-image identity: shared_partners_itp(i,j) ==
//     shared_partners_otp(j,i) exactly, by construction.
void test_itp_is_reversed_otp(){
	class ErgmGraph scalar G
	real scalar n, i, j, maxdiff

	n = 16
	G = ErgmGraph()
	build_dir_net(G, n, 0.25, 8496)
	maxdiff = 0
	for (i=1; i<=n; i++) {
		for (j=1; j<=n; j++) {
			if (i==j) continue
			maxdiff = max((maxdiff, abs(G.shared_partners_itp(i,j) - G.shared_partners_otp(j,i))))
		}
	}
	printf("test_itp_is_reversed_otp: maxdiff=%g\n", maxdiff)
	assert(maxdiff == 0)
	printf("test_itp_is_reversed_otp: OK\n")
}
test_itp_is_reversed_otp()

end
