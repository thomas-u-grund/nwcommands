"""Recipes for the scaling audit: one entry per core command (or documented variant).

Every recipe runs on the benchmark network `bench` built by network_gen.do:
  net   dir | undir | valued | valuedu | two | edges | none   (see network_gen.do)
  attr  True  -> node variables node_id, grp (1..5), bin (0/1), attr (normal) exist
  pre   untimed Stata lines run after the network is built (companion networks, files)
  line  the timed command; {N} is replaced by the number of nodes
  cat   scaling category by design, used to pick starting sizes:
          linear      sparse structural / vector result, expected near-linear
          allpairs    all-pairs distances or an NxN result network
          superlinear clique / motif / layout style, worse than linear on sparse input
          perm        permutation / simulation based, cost = reps x base
          io          reads or writes files
          manip       network manipulation
          gen         network generator (measured on its own at N, no input network)
          util        bookkeeping, cheap by design
  solo  run alone (no second Stata process): memory hogs that would distort the timing of others
  maxn  do not try larger N than this (recorded as NOT_TRIED_CAP)
"""
SPEC = []

def S(command, net, line, pre=None, attr=False, cat="linear", maxn=None, note="", solo=False):
    SPEC.append(dict(command=command, net=net, line=line, pre=pre or [], attr=attr,
                     cat=cat, maxn=maxn, note=note, solo=solo))

# ---------------------------------------------------------------- import / export
S("nwfromedge", "edges", "nwfromedge from to, name(bench)", cat="io")
S("nwfromedge[valued]", "edges", "nwfromedge from to val, name(bench)", cat="io")
S("nwfromedge[undirected]", "edges", "nwfromedge from to, name(bench) undirected", cat="io")
S("nw2fromedge", "edges", "nw2fromedge from to, name(bench)", cat="io",
  note="edge list from[1..N], to[1..N] is read as mode 1 x mode 2")
S("nwtoedge", "dir", "nwtoedge bench, ego(e_) alter(a_)", cat="io", note="creates an edge list in Stata variables")
S("nwtoedge[valued]", "valued", "nwtoedge bench, ego(e_) alter(a_)", cat="io")
S("nwtoedge[compress]", "dir", "nwtoedge bench, ego(e_) alter(a_) compress", cat="io", note="ties only")
S("nw2toedge", "two", "nw2toedge bench", cat="io")
S("nw2toedge[compress]", "two", "nw2toedge bench, compress", cat="io", note="ties only")
S("nwsave", "dir", "nwsave nwa_file, replace", cat="io")
S("nwload", "dir", "nwload bench", cat="io", note="writes the network back into Stata variables (no xvars)")
S("nwload[xvars]", "dir", "nwload bench, xvars", cat="io", note="one Stata variable per node; BE caps at 2,048 variables")
S("nwuse", "dir", "nwuse nwa_file, nwclear", pre=["nwsave nwa_file, replace", "nwclear"], cat="io")
S("nwexport[edgelist]", "dir", 'nwexport bench, type(edgelist) fname("nwa_out") replace', cat="io")
S("nwexport[pajek]", "dir", 'nwexport bench, type(pajek) fname("nwa_out") replace', cat="io")
S("nwexport[ucinet]", "dir", 'nwexport bench, type(ucinet) fname("nwa_out") replace', cat="io")
S("nwimport[edgelist]", "dir", 'nwimport "nwa_out.txt", type(edgelist) name(imp) nwclear',
  pre=['nwexport bench, type(edgelist) fname("nwa_out") replace'], cat="io",
  note="re-imports the edge list written by nwexport")
S("nwtostata", "dir", "nwtostata, mat(M) stub(m_)", pre=["nwtomata bench, mat(M)"], cat="io",
  note="writes the matrix to Stata variables; BE caps at 2,048 variables")
S("nwtomata", "dir", "nwtomata bench, mat(M)", cat="io", note="materialises a Mata matrix")
S("nwtomatafast", "dir", "nwtomatafast bench", cat="util")
S("nwreplacemat", "dir", "nwreplacemat bench, newmat(M) netonly", pre=["nwtomata bench, mat(M)"], cat="io")
S("nwset", "edges", "nwset from to, edgelist name(bench)", cat="io", note="edge-list form of nwset (stages 0-1 timed the matrix form on two variables: a 2-node network)")
S("nw2set", "edges", "nw2set from to, edgelist name(bench)", cat="io")
S("nwsync", "dir", "nwsync bench", cat="io")

# ---------------------------------------------------------------- description
S("nwdegree", "dir", "nwdegree bench, generate(d_out d_in)")
S("nwdegree[valued]", "valued", "nwdegree bench, generate(d_out d_in)")
S("nw2degree", "two", "nw2degree bench, generate(d2)")
S("nwsummarize", "dir", "nwsummarize bench")
S("nwdyads", "dir", "nwdyads bench")
S("nwtriads", "dir", "nwtriads bench", cat="superlinear")
S("nwmotifs", "undir", "nwmotifs bench, silent", cat="superlinear")
S("nwissymmetric", "dir", "nwissymmetric bench")
S("nwtabulate", "dir", "nwtabulate bench")
S("nwcurrent", "dir", "nwcurrent bench", cat="util")
S("nwnode", "dir", "nwnode bench, ego(n1)", cat="util")
S("nwvalue", "dir", "nwvalue bench, ego(n1) alter(n2)", cat="util")
S("nwdyadprob", "none", "nwdyadprob, mat(J({N},{N},.01)) name(bench)", cat="gen")
S("nwds", "dir", "nwds", cat="util")
S("nwvalidate", "dir", "nwvalidate bench", cat="util")
S("nwvalidvars", "dir", "nwvalidvars {N}, stub(zz_)", cat="util")
S("nwunab", "dir", "nwunab mynets : bench*", cat="util")

# ---------------------------------------------------------------- centrality
S("nwbetween", "dir", "nwbetween bench, generate(btw)", cat="allpairs")
S("nwcloseness", "dir", "nwcloseness bench, generate(clo far near)", cat="allpairs")
S("nwevcent", "undir", "nwevcent bench, generate(evc)")
S("nwkatz", "dir", "nwkatz bench, generate(katz)")
S("nwpagerank", "dir", "nwpagerank bench, generate(pr) silent")
S("nwrandomwalk", "dir", "nwrandomwalk bench, target(n1) generate(rw) silent", cat="allpairs")
S("nwconstraint", "undir", "nwconstraint bench, name(cons)")
S("nwburt", "undir", "nwburt bench, silent")
S("nwbalance", "valued", "nwbalance bench, generate(b_ b_bal b_clo)", cat="superlinear",
  note="signed-network balance; valued network used as a stand-in")
S("nwclustering", "undir", "nwclustering bench, generate(clu)")
S("nw2clustering", "two", "nw2clustering bench, generate(clu2)")
S("nwassortativity", "dir", "nwassortativity bench, attribute(attr) silent", attr=True)
S("nwbrokerage", "dir", "nwbrokerage bench, group(grp) generate(brk)", attr=True, cat="superlinear")
S("nwego", "undir", "nwego bench, sizevar(esz) densvar(edn)", cat="superlinear")
S("nwcontext", "dir", "nwcontext bench, attribute(attr) generate(ctx)", attr=True)
S("nwaltergen", "dir", "nwaltergen ag = mean(alter.attr), net(bench)", attr=True)
S("nwgen", "dir", "nwgen deg_g = degree(bench)")
S("nwgenerate", "dir", "nwgenerate deg_g2 = degree(bench)")
S("nwgenvar", "dir", "nwgenvar deg_g3 = degree(bench)")
S("nwinduced", "undir", "nwinduced bench, measure(degree) generate(ind) silent", cat="superlinear")
S("nwhomophily", "none", "nwhomophily hom, homophily(.8) density(.0001) nodes({N}) name(bench)",
  pre=["quietly set obs {N}", "quietly gen byte hom = ceil(runiform()*3)"], cat="gen")

# ---------------------------------------------------------------- paths
S("nwgeodesic", "dir", "nwgeodesic bench, name(geo)", cat="allpairs")
S("nwgeodesic[vars]", "dir", "nwgeodesic bench, generate(ecc) name(geo)", cat="allpairs")
S("nwpath", "dir", "nwpath bench, egoid(1) alterid(2) generate(pth)", cat="superlinear")
S("nwreach", "dir", "nwreach bench, name(rch)", cat="allpairs")
S("nwlambda", "undir", "nwlambda bench, name(lam)", cat="allpairs")
S("nwmaxflow", "dir", "nwmaxflow bench, source(n1) sink(n2) generate(cut)", cat="superlinear")
S("nwneighbor", "dir", "nwneighbor bench, ego(n1) generate(nb)")
S("nwbridges", "undir", "nwbridges bench, name(brg)")
S("nwshared", "dir", "nwshared bench, name(shr)", cat="allpairs")

# ---------------------------------------------------------------- cohesion / communities
S("nwcomponents", "dir", "nwcomponents bench, generate(comp)")
S("nwkcomponents", "undir", "nwkcomponents bench, k(2) generate(kcomp)", cat="superlinear")
S("nwkcore", "undir", "nwkcore bench, generate(kc)")
S("nwcohesion", "undir", "nwcohesion bench, generate(coh)", cat="superlinear")
S("nwclique", "undir", "nwclique bench, generate(cliq)", cat="superlinear", solo=True)
S("nwnclique", "undir", "nwnclique bench, n(2) generate(ncliq)", cat="superlinear", solo=True)
S("nwnclan", "undir", "nwnclan bench, n(2) generate(nclan)", cat="superlinear", solo=True)
S("nwkplex", "undir", "nwkplex bench, k(2) generate(kpl)", cat="superlinear", solo=True)
S("nwcommunity", "undir", "nwcommunity bench, generate(com)")
S("nwcommunity[labelprop]", "undir", "nwcommunity bench, generate(com) algorithm(labelprop)")
S("nwmodularity", "undir", "nwmodularity bench, group(grp) silent", attr=True)
S("nwfactions", "undir", "nwfactions bench, groups(3) generate(fac) silent", cat="superlinear")
S("nwcoreperiphery", "undir", "nwcoreperiphery bench, generate(cp)", cat="superlinear")
S("nwmatching", "two", "nwmatching bench, generate(match) silent")
S("nwspectral", "undir", "nwspectral bench, generate(fied) silent")
S("nwconcor", "undir", "nwconcor bench, generate(cc)", cat="allpairs")
S("nwmixing", "dir", "nwmixing bench, attribute(grp) permutations(0)", attr=True, cat="perm")
S("nwturnover", "dir", "nwturnover bench bench2, generate(turn) silent", pre=["nwpermute bench, generate(bench2)"])

# ---------------------------------------------------------------- positions, similarity
S("nwsimilar", "dir", "nwsimilar bench, type(matches) name(sim)", cat="allpairs")
S("nwdissimilar", "dir", "nwdissimilar bench, type(euclidean) name(dis)", cat="allpairs")
S("nwsimindex", "undir", "nwsimindex bench, measure(jaccard) name(sidx)", cat="allpairs")
S("nwsimmelian", "undir", "nwsimmelian bench, name(simm)", cat="allpairs")
S("nwhierarchy", "dir", "nwhierarchy bench", cat="allpairs")
S("nwdendrogram", "dir", "nwdendrogram", pre=["nwhierarchy bench, groups(3) generate(role)"], cat="allpairs",
  note="the timed command is only the plot of a clustering produced by nwhierarchy")

# ---------------------------------------------------------------- statistical
S("nwcorrelate", "dir", "nwcorrelate bench bench2, permutations(5)", pre=["nwpermute bench, generate(bench2)"], cat="perm")
S("nwcorrelate[nodes]", "dir", "nwcorrelate bench, name(cor)", cat="allpairs")
S("nwcug", "dir", "nwcug bench, stat(nwcomponents ##net##, generate(_component) replace) rname(components) reps(5) seed(1) silent", cat="perm")
S("nwqap", "dir", "nwqap bench bench2, permutations(5) type(regress)",
  pre=["nwpermute bench, generate(bench2)"], cat="perm")
S("nwutility", "dir", "nwutility bench", cat="allpairs")

# ---------------------------------------------------------------- generators
S("nwrandom", "none", "nwrandom {N}, density(.0001) name(bench)", cat="gen")
S("nwrandom[prob]", "none", "nwrandom {N}, prob(.0001) name(bench)", cat="gen")
S("nwring", "none", "nwring {N}, k(5) name(bench)", cat="gen")
S("nwlattice", "none", "nwlattice 30 30, name(bench)", cat="gen", note="fixed 900 nodes; N is not used")
S("nwpref", "none", "nwpref {N}, name(bench)", cat="gen")
S("nwsmall", "none", "nwsmall {N}, k(5) prob(.1) name(bench)", cat="gen")
S("nwdyadprob[mat]", "none", "nwdyadprob, mat(J(30,30,.2)) name(bench)", cat="gen", note="30 nodes, fixed")

# ---------------------------------------------------------------- manipulation
S("nwduplicate", "dir", "nwduplicate bench, name(dup)", cat="manip")
S("nwrename", "dir", "nwrename bench bench_r", cat="manip")
S("nwdrop", "dir", "nwdrop bench", cat="manip")
S("nwkeep", "dir", "nwkeep bench", pre=["nwduplicate bench, name(other)"], cat="manip")
S("nwclear", "dir", "nwclear", cat="manip")
S("nwname", "dir", "nwname bench, newtitle(x)", cat="manip")
S("nwsym", "dir", "nwsym bench, generate(sym)", cat="manip")
S("nwsymmetrize", "dir", "nwsymmetrize bench, generate(sym)", cat="manip")
S("nwtranspose", "dir", "nwtranspose bench, generate(tr)", cat="manip")
S("nwpermute", "dir", "nwpermute bench, generate(perm)", cat="manip")
S("nwrecode", "valued", "nwrecode bench(1/2=1)(3/5=2), generate(rec)", cat="manip")
S("nwreplace", "dir", "nwreplace bench[1,2] = 1", cat="manip")
S("nwreplace[all]", "valued", "nwreplace bench = bench + 1", cat="manip")
S("nwdichotomize", "valued", "nwdichotomize bench, threshold(3) generate(dich)", cat="manip")
S("nwsubset", "dir", "nwsubset bench if _n <= _N/2, name(sub)", cat="manip", attr=True)
S("nwcollapse", "dir", "nwcollapse (max) bench, by(grp) generate(col)", attr=True, cat="manip")
S("nwdropnodes", "dir", "nwdropnodes bench, nodes(1 2 3) generate(dn)", cat="manip")
S("nwkeepnodes", "dir", "nwkeepnodes bench, nodes(1 2 3 4 5) generate(kn)", cat="manip")
S("nwaddnodes", "dir", "nwaddnodes bench, nodenames(zz1, zz2) generate(an)", cat="manip")
S("nwnoderename", "dir", "nwnoderename bench, old(n1) new(x1)", cat="manip")
S("nwappend", "dir", "nwappend using nwa_file, force", pre=["nwsave nwa_file, replace"], cat="manip")
S("nwexpand[attr]", "dir", "nwexpand attr, name(exp)", attr=True, cat="allpairs")
S("nwattime", "edges", "nwattime bench, at(1) name(att)",
  pre=["gen byte tt = ceil(runiform()*3)", "nwset from to, time(tt) name(bench) undirected"], cat="manip",
  note="snapshot of a 3-wave temporal network")
S("nwcompressobs", "dir", "nwcompressobs", cat="manip")
S("nworder", "dir", "nworder bench bench2", pre=["nwduplicate bench, name(bench2)"], cat="manip")
S("nwpreserve", "dir", "nwpreserve", cat="manip")
S("nwproject", "two", "nwproject bench, project(1) name(proj)", cat="manip")
S("nw2project", "two", "nw2project bench, project(1) name(proj)", cat="manip")
S("nw2project[min]", "two", "nw2project bench, project(1) name(proj) stat(min)", cat="manip")

# ---------------------------------------------------------------- visualisation (static only)
S("nwplot[circle]", "dir", "nwplot bench, layout(circle)", cat="superlinear", maxn=20000)
S("nwplot[kk]", "undir", "nwplot bench, layout(kk) iterations(10)", cat="superlinear", maxn=5000)
S("nwplotmatrix", "dir", "nwplotmatrix bench", cat="allpairs")

# ---------------------------------------------------------------- not benchmarked (documented)
# nwinstall, nwversion, nwwebuse: installer/utility/internet.  nwmovie, nwmoviexy, animate: interactive.
# nwrestore: companion of nwpreserve (timed together in nwpreserve? no: see below).
S("nwrestore", "dir", "nwrestore", pre=["nwpreserve"], cat="manip")

def by_name():
    return {r["command"]: r for r in SPEC}

# ---------------------------------------------------------------- correctness checks (checks.do)
# chk: Stata lines run after the timed command (untimed); None = nwa_std bench (nodes, ties, labels, exact tie set of
# the unchanged benchmark network); [] = no check. Ground truth comes from the generator's edge list.
_V = lambda v, extra="": f"nwa_var {v}, n({{N}}){extra}"
_EDGE = lambda v, valued: [f'mata: st_numscalar("nwa_x", nwa_varcmp("e_", "a_", "{v}", {valued}))',
                           'nwa_check "edge list equals the generator ties" , c(scalar(nwa_x) == 0)']
CHK = {
    "nwfromedge": ["nwa_std bench, kind(dir)"],
    "nwfromedge[valued]": ["nwa_std bench, kind(dir) valued"],
    "nwfromedge[undirected]": ["nwa_std bench, kind(undir)"],
    "nw2fromedge": ["nwa_std bench, kind(two)"],
    "nwtoedge": ['nwa_check "rows N*N" , c(_N == {N}*{N})'] + _EDGE("bench", 0),
    "nwtoedge[valued]": ['nwa_check "rows N*N" , c(_N == {N}*{N})'] + _EDGE("bench", 1),
    "nwtoedge[compress]": ['nwa_check "rows = ties" , c(_N == scalar(nwa_t_ties) + {N})'] + _EDGE("bench", 0),
    "nw2toedge": [], "nw2toedge[compress]": [],
    "nwset": ["nwa_std bench, kind(dir)"],
    "nw2set": ["nwa_std bench, kind(two)"],
    "nwtostata": [],
    "nwimport[edgelist]": ["nwa_std imp, kind(dir)"],
    "nwdegree": ['mata: st_numscalar("nwa_x", nwa_degcmp("d_out", "d_in", 0))', 'nwa_check "degrees equal the generator degrees" , c(scalar(nwa_x) == 0)'],
    "nwdegree[valued]": ['mata: st_numscalar("nwa_x", nwa_degcmp("d_out", "d_in", 0))', 'nwa_check "degrees of the valued network equal the tie counts" , c(scalar(nwa_x) == 0)'],
    "nwdyads": ['nwa_check "dyad census sums to N(N-1)/2" , c(r(_001) + r(_010) + r(_100) == {N}*({N}-1)/2)',
                'nwa_check "asymmetric + 2*mutual = ties" , c(r(_010) + 2*r(_100) == scalar(nwa_t_ties))'],
    "nwtriads": ['nwa_check "triad census sums to C(N,3)" , c(r(_003)+r(_012)+r(_102)+r(_021D)+r(_021U)+r(_021C)+r(_111D)+r(_111U)+r(_030T)+r(_030C)+r(_201)+r(_120D)+r(_120U)+r(_120C)+r(_210)+r(_300) == {N}*({N}-1)*({N}-2)/6)'],
    "nwcomponents": ['nwa_check "components" , c(r(components) == scalar(nwa_t_ncomp))',
                     'mata: st_numscalar("nwa_x", nwa_compcmp("comp"))', 'nwa_check "component membership equals union-find" , c(scalar(nwa_x) == 0)'],
    "nwbetween": [_V("btw", " min(0)")],
    "nwcloseness": [_V("far"), 'mata: nwa_f = nwa_farcmp("far")', 'mata: st_numscalar("nwa_x", min(nwa_f))',
                    'nwa_check "farness equals BFS sum of distances (sample sources)" , c(scalar(nwa_x) == 0)'],
    "nwevcent": [_V("evc", " min(-1e-6)")],
    "nwpagerank": [_V("pr", " sum(1) tol(1e-4)")],
    "nwkatz": [_V("katz_in"), _V("katz_out")],
    "nwclustering": ['mata: st_numscalar("nwa_x", nwa_clustcmp("clu", 40))', 'nwa_check "clustering equals independent count (sample)" , c(scalar(nwa_x) == 0)'],
    "nwkcore": ['mata: nwa_kc = nwa_kcore()', 'mata: st_numscalar("nwa_x", sum(st_data((1, rows(nwa_kc)), "kc") :!= nwa_kc))',
                'nwa_check "coreness equals independent peeling" , c(scalar(nwa_x) == 0)'],
    "nwgeodesic": ['nwa_netp geo', 'mata: st_numscalar("nwa_x", nwa_rowcmp(nwa_p, 0))', 'nwa_check "geodesics equal BFS (sample rows)" , c(scalar(nwa_x) == 0)'],
    "nwgeodesic[vars]": ['nwa_netp geo', 'mata: st_numscalar("nwa_x", nwa_rowcmp(nwa_p, 0))', 'nwa_check "geodesics equal BFS (sample rows)" , c(scalar(nwa_x) == 0)'],
    "nwreach": ['nwa_netp rch', 'mata: st_numscalar("nwa_x", nwa_rowcmp(nwa_p, 1))', 'nwa_check "reachability equals BFS (sample rows)" , c(scalar(nwa_x) == 0)'],
    "nwmixing": ['nwa_check "ties counted" , c(r(N) == scalar(nwa_t_ties))'],
    "nwsummarize": ['nwa_check "nodes" , c(r(nodes) == scalar(nwa_t_nodes))', 'nwa_check "arcs" , c(r(arcs) == scalar(nwa_t_ties))'],
    "nwtranspose": ["nwa_edges tr, mode(2) noweights"],
    "nwpermute": ['nwa_netp perm', 'nwa_check "nodes" , c(scalar(nwa_n) == scalar(nwa_t_nodes))', 'nwa_check "arcs" , c(scalar(nwa_arcs) == scalar(nwa_t_ties))', 'nwa_check "labels" , c(scalar(nwa_labbad) == 0)'],
    "nwduplicate": ["nwa_edges dup, mode(0) noweights"],
    "nwsym": ["nwa_edges sym, mode(1) noweights"],
    "nwsymmetrize": ["nwa_edges sym, mode(1) noweights"],
    "nwdropnodes": ['nwa_edges dn, mode(0) noweights keep(4::st_numscalar(\"nwa_t_nodes\"))'],
    "nwkeepnodes": ['nwa_edges kn, mode(0) noweights keep(1::5)'],
    "nwaddnodes": ['nwa_netp an', 'nwa_check "nodes + 2" , c(scalar(nwa_n) == scalar(nwa_t_nodes) + 2)', 'nwa_check "arcs unchanged" , c(scalar(nwa_arcs) == scalar(nwa_t_ties))'],
    "nwsubset": ['nwa_edges sub, mode(0) noweights keep(1::floor(st_numscalar(\"nwa_t_nodes\")/2))'],
    "nwdichotomize": ['nwa_netp dich', 'nwa_check "nodes" , c(scalar(nwa_n) == scalar(nwa_t_nodes))'],
    "nwrecode": ['nwa_netp rec', 'nwa_check "nodes" , c(scalar(nwa_n) == scalar(nwa_t_nodes))'],
    "nwrename": ["nwa_std bench_r"],
}
CHK.update({
    "nwcommunity": ['mata: st_numscalar("nwa_x", nwa_modq("com"))', 'nwa_check "modularity equals independent Q of the partition" , c(abs(scalar(nwa_x) - r(modularity)) < 1e-6)', _V("com")],
    "nwcommunity[labelprop]": ['mata: st_numscalar("nwa_x", nwa_modq("com"))', 'nwa_check "modularity equals independent Q of the partition" , c(abs(scalar(nwa_x) - r(modularity)) < 1e-6)', _V("com")],
    "nwmodularity": ['mata: st_numscalar("nwa_x", nwa_modq("grp"))', 'nwa_check "modularity equals independent Q" , c(abs(scalar(nwa_x) - r(modularity)) < 1e-6)'],
    "nwmotifs": ['nwa_check "graphlet counts sum to C(N,4)" , c(6*(r(disconnected)+r(k4)+r(diamond)+r(paw)+r(cycle)+r(star)+r(path)) == ({N}*({N}-1)/2)*(({N}-2)*({N}-3)/2))'],
    "nwspectral": ['nwa_check "components" , c(r(components) == scalar(nwa_t_ncomp))'],
    "nwkcomponents": ['nwa_check "at least one 2-component" , c(r(kcomponents) >= 1)'],
    "nwcohesion": ['nwa_check "blocks" , c(r(blocks) >= 1)', _V("coh")],
    "nwclique": ['nwa_check "cliques found" , c(r(cliques) >= 1)', 'quietly count if !missing(cliq)', 'nwa_check "clique members" , c(r(N) >= 3 & r(N) <= {N})'],
    "nwcoreperiphery": [_V("cp")],
    "nwconcor": [_V("cc")],
    "nwfactions": ['nwa_check "groups" , c(r(groups) == 3)'],
    "nwego": [_V("esz"), _V("edn")],
    "nwburt": ['nwa_check "nodes" , c(r(nodes) == scalar(nwa_t_nodes))'],
    "nwring": ['nwa_netp bench', 'nwa_check "nodes" , c(scalar(nwa_n) == {N})', 'nwa_check "arcs 2*k*N" , c(scalar(nwa_arcs) == 10*{N})', 'nwa_check "labels" , c(scalar(nwa_labbad) == 0)'],
    "nwsmall": ['nwa_netp bench', 'nwa_check "nodes" , c(scalar(nwa_n) == {N})', 'nwa_check "arcs 2*k*N" , c(scalar(nwa_arcs) == 10*{N})', 'nwa_check "labels" , c(scalar(nwa_labbad) == 0)'],
    "nwlattice": ['nwa_netp bench', 'nwa_check "nodes" , c(scalar(nwa_n) == 900)', 'nwa_check "arcs" , c(scalar(nwa_arcs) == 3480)', 'nwa_check "labels" , c(scalar(nwa_labbad) == 0)'],
    "nwpref": ['nwa_netp bench', 'nwa_check "nodes" , c(scalar(nwa_n) == {N})', 'nwa_check "arcs 2(N-1)" , c(scalar(nwa_arcs) == 2*({N}-1))', 'nwa_check "labels" , c(scalar(nwa_labbad) == 0)'],
    "nwrandom": ['nwa_netp bench', 'nwa_check "nodes" , c(scalar(nwa_n) == {N})', 'nwa_check "ties near density*N*(N-1)" , c(abs(scalar(nwa_arcs) - .0001*{N}*({N}-1)) <= max(2, 5*sqrt(.0001*{N}*({N}-1))))', 'nwa_check "labels" , c(scalar(nwa_labbad) == 0)'],
    "nwrandom[prob]": ['nwa_netp bench', 'nwa_check "nodes" , c(scalar(nwa_n) == {N})', 'nwa_check "ties near prob*N*(N-1)" , c(abs(scalar(nwa_arcs) - .0001*{N}*({N}-1)) <= max(2, 5*sqrt(.0001*{N}*({N}-1))))', 'nwa_check "labels" , c(scalar(nwa_labbad) == 0)'],
    "nwdyadprob": ['nwa_netp bench', 'nwa_check "nodes" , c(scalar(nwa_n) == {N})', 'nwa_check "ties near p*N*(N-1)" , c(abs(scalar(nwa_arcs) - .01*{N}*({N}-1)) <= 5*sqrt(.01*{N}*({N}-1)))', 'nwa_check "labels" , c(scalar(nwa_labbad) == 0)'],
    "nwdyadprob[mat]": ['nwa_netp bench', 'nwa_check "nodes" , c(scalar(nwa_n) == 30)', 'nwa_check "labels" , c(scalar(nwa_labbad) == 0)'],
    "nwhomophily": ['nwa_netp bench', 'nwa_check "nodes" , c(scalar(nwa_n) == {N})', 'nwa_check "some ties" , c(scalar(nwa_arcs) > 0)', 'nwa_check "labels" , c(scalar(nwa_labbad) == 0)'],
    "nw2degree": ['nwa_netp bench', 'mata: st_numscalar("nwa_ton", nwa_nto())', 'nwa_check "nodes" , c(scalar(nwa_n) == {N} + scalar(nwa_ton))'],
    "nw2clustering": ['nwa_netp bench', 'mata: st_numscalar("nwa_ton", nwa_nto())', 'nwa_check "nodes" , c(scalar(nwa_n) == {N} + scalar(nwa_ton))'],
    "nwdrop": ["nwa_gone"],
    "nwclear": ["nwa_gone"],
    "nwnoderename": ['nwa_netp bench', 'mata: st_local("nwa_l1", nwa_p->get_nodenames()[1])', 'nwa_check "node 1 renamed" , c("`nwa_l1\'" == "x1")', 'nwa_check "nodes" , c(scalar(nwa_n) == {N})'],
    "nwreplace": ['nwa_netp bench', 'nwa_check "nodes" , c(scalar(nwa_n) == {N})', 'nwa_check "ties T or T+1" , c(inlist(scalar(nwa_arcs), scalar(nwa_t_ties), scalar(nwa_t_ties)+1))'],
    "nwreplace[all]": ['nwa_netp bench', 'nwa_check "nodes" , c(scalar(nwa_n) == {N})'],
    "nwattime": ['nwa_netp att', 'nwa_check "nodes" , c(scalar(nwa_n) == {N})'],
    "nwproject": ['nwa_netp proj', 'nwa_check "nodes = mode-1 nodes" , c(scalar(nwa_n) == {N})'],
    "nw2project": ['nwa_netp proj', 'nwa_check "nodes = mode-1 nodes" , c(scalar(nwa_n) == {N})'],
    "nw2project[min]": ['nwa_netp proj', 'nwa_check "nodes = mode-1 nodes" , c(scalar(nwa_n) == {N})'],
    "nwmatching": ['nwa_check "matched pairs at most the smaller mode" , c(r(matched) >= 1 & r(matched) <= {N}/2)'],
})
for _r in SPEC:
    if _r["command"] in CHK:
        _r["chk"] = [l.replace("{N}", "{N}") for l in CHK[_r["command"]]]
