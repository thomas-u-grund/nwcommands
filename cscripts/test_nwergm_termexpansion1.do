cscript

do unw_ergm.do

/*
	Certifies term-expansion wave 1 (harmonisation unit 88,
	docs/CERTIFICATION.md - phase D): absdist, nodematch(diff=TRUE),
	nodefactor, nodemix, gwdsp. Uses the same brute-force change-statistic
	cross-check every existing term is certified with
	(ErgmCertifyChangeStat: compares change()'s own returned value against
	statistic()-before/toggle/statistic()-after/difference, over every
	dyad of several small hand-built networks) - the permanent contract
	every term must satisfy before any MCMC/estimation code is trusted to
	consume it.
*/

mata:
mata set matastrict off

void build_net(class ErgmGraph G, real scalar n, real scalar nedges, real scalar directed, real scalar seed) {
	real scalar t, i, j
	rseed(seed)
	G.init(n, directed)
	for (t=1; t<=nedges; t++) {
		i = ceil(runiform(1,1)*n)
		j = ceil(runiform(1,1)*n)
		if (i!=j & !G.has_edge(i,j)) G.toggle(i,j)
	}
}

void test_absdist(){
	class ErgmGraph scalar G
	class ErgmModel scalar M
	class ErgmTermData scalar td
	real colvector attr
	real scalar n, i, md

	n = 12
	G = ErgmGraph()
	build_net(G, n, 20, 0, 5101)
	attr = J(n,1,0)
	for (i=1; i<=n; i++) attr[i] = runiform(1,1)*10

	M = ErgmModel()
	M.init()
	td = ErgmTermData()
	td.attr = attr
	M.addterm("absdist", 1, &stat_absdist(), &change_absdist(), td, ("absdist"))
	md = ErgmCertifyChangeStat(M, G)
	printf("test_absdist: max diff = %9.2e\n", md)
	assert(md < 1e-8)
	printf("test_absdist: OK\n")
}
test_absdist()

void test_nodematch_diff(){
	class ErgmGraph scalar G
	class ErgmModel scalar M
	class ErgmTermData scalar td
	real colvector attr, levels
	real scalar n, i, md

	n = 15
	G = ErgmGraph()
	build_net(G, n, 25, 0, 5102)
	attr = J(n,1,0)
	for (i=1; i<=n; i++) attr[i] = mod(i,3) + 1   // 3 levels: 1,2,3
	levels = (1\2\3)

	M = ErgmModel()
	M.init()
	td = ErgmTermData()
	td.attr = attr
	td.levels = levels
	M.addterm("nodematch_diff", rows(levels), &stat_nodematch_diff(), &change_nodematch_diff(), td, ("nm_1","nm_2","nm_3"))
	md = ErgmCertifyChangeStat(M, G)
	printf("test_nodematch_diff: max diff = %9.2e\n", md)
	assert(md < 1e-8)
	printf("test_nodematch_diff: OK\n")
}
test_nodematch_diff()

void test_nodefactor(){
	class ErgmGraph scalar G
	class ErgmModel scalar M
	class ErgmTermData scalar td
	real colvector attr, levels
	real scalar n, i, md

	n = 14
	G = ErgmGraph()
	build_net(G, n, 22, 0, 5103)
	attr = J(n,1,0)
	for (i=1; i<=n; i++) attr[i] = mod(i,4) + 1   // 4 levels
	levels = (1\2\3\4)

	M = ErgmModel()
	M.init()
	td = ErgmTermData()
	td.attr = attr
	td.levels = levels
	M.addterm("nodefactor", rows(levels), &stat_nodefactor(), &change_nodefactor(), td, ("nf_1","nf_2","nf_3","nf_4"))
	md = ErgmCertifyChangeStat(M, G)
	printf("test_nodefactor: max diff = %9.2e\n", md)
	assert(md < 1e-8)
	printf("test_nodefactor: OK\n")
}
test_nodefactor()

void test_nodemix(){
	class ErgmGraph scalar G
	class ErgmModel scalar M
	class ErgmTermData scalar td
	real colvector attr
	real matrix levelpairs
	real scalar n, i, a, b, md, np

	n = 13
	G = ErgmGraph()
	build_net(G, n, 20, 0, 5104)
	attr = J(n,1,0)
	for (i=1; i<=n; i++) attr[i] = mod(i,3) + 1   // 3 levels -> 6 unordered pairs incl. within-level

	levelpairs = J(0,2,0)
	for (a=1; a<=3; a++) {
		for (b=a; b<=3; b++) {
			levelpairs = levelpairs \ (a,b)
		}
	}
	np = rows(levelpairs)

	M = ErgmModel()
	M.init()
	td = ErgmTermData()
	td.attr = attr
	td.levelpairs = levelpairs
	M.addterm("nodemix", np, &stat_nodemix(), &change_nodemix(), td, ("mix1","mix2","mix3","mix4","mix5","mix6"))
	md = ErgmCertifyChangeStat(M, G)
	printf("test_nodemix: max diff = %9.2e (npairs=%g)\n", md, np)
	assert(md < 1e-8)
	printf("test_nodemix: OK\n")
}
test_nodemix()

void test_gwdsp(){
	class ErgmGraph scalar G
	class ErgmModel scalar M
	class ErgmTermData scalar td
	real scalar n, md

	n = 12
	G = ErgmGraph()
	build_net(G, n, 22, 0, 5105)

	M = ErgmModel()
	M.init()
	td = ErgmTermData()
	td.decay = 0.5
	M.addterm("gwdsp", 1, &stat_gwdsp(), &change_gwdsp(), td, ("gwdsp_0.5"))
	md = ErgmCertifyChangeStat(M, G)
	printf("test_gwdsp: max diff = %9.2e\n", md)
	assert(md < 1e-8)
	printf("test_gwdsp: OK\n")
}
test_gwdsp()

end
