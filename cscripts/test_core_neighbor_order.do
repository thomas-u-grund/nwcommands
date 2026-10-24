cscript

do unw_core.do

* neighbors(i), neighbors_in(i) and edgelist() must return node indices in ascending order, whatever the order
* of the input (sparse-native construction from shuffled triplets) and whatever was loaded earlier in the
* session. Before the fix set_edge_from_triplets() sorted only by ego with a sort that does not keep the input
* order of ties, so the neighbor order of a node depended on the memory/sort state of the session.

capture mata: mata drop chk_sorted()
mata:
real scalar chk_sorted(pointer(class nw_def scalar) scalar p)
{
	real scalar n, i, bad
	real matrix nb
	n = p->get_nodes()
	bad = 0
	for (i=1; i<=n; i++) {
		nb = p->neighbors(i)
		if (rows(nb) > 1) if (any(nb[2::rows(nb)] :<= nb[1::(rows(nb)-1)])) bad++
		nb = p->neighbors_in(i)
		if (rows(nb) > 1) if (any(nb[2::rows(nb)] :<= nb[1::(rows(nb)-1)])) bad++
	}
	return(bad)
}

// build from shuffled triplets; dir=1 directed, 0 undirected (both directions supplied)
pointer(class nw_def scalar) scalar mk(real scalar n, real scalar m, real scalar dir, string scalar nm)
{
	pointer(class nw_def scalar) scalar p
	real matrix ego, alt, k, nodes
	string rowvector lab
	ego = ceil(runiform(m,1)*n); alt = ceil(runiform(m,1)*n)
	k = selectindex(ego :!= alt); ego = ego[k]; alt = alt[k]
	// unique pairs
	k = uniqrows((ego,alt)); ego = k[.,1]; alt = k[.,2]
	if (dir == 0) {
		ego = ego \ alt
		alt = alt \ k[.,1]
		k = uniqrows((ego,alt))
		ego = k[.,1]
		alt = k[.,2]
	}
	k = order(runiform(rows(ego),1),1); ego = ego[k]; alt = alt[k]
	lab = "n" :+ strofreal(1..n)
	p = &(nw_def())
	p->create_by_name_sparse(lab)
	p->set_name(nm)
	p->set_edge_from_triplets(ego, alt, J(rows(ego),1,1), dir)
	return(p)
}
end

set seed 12345
mata:
p1 = mk(3000, 40000, 1, "d1")
p2 = mk(3000, 40000, 0, "u1")
// load other (dense-path) networks in between, then build again
q = &(nw_def()); q->create_by_name(("a","b","c")); q->set_name("other")
p3 = mk(3000, 40000, 1, "d2")
p4 = mk(3000, 40000, 0, "u2")
assert(chk_sorted(p1) == 0)
assert(chk_sorted(p2) == 0)
assert(chk_sorted(p3) == 0)
assert(chk_sorted(p4) == 0)
// edgelist(): sorted by (ego, alter)
el = p1->edgelist()
assert(!any(el[2::rows(el),1] :< el[1::(rows(el)-1),1]))
chk = (el[2::rows(el),1] :== el[1::(rows(el)-1),1])
assert(!any(chk :& (el[2::rows(el),2] :<= el[1::(rows(el)-1),2])))
// the same network built from the same triplets in two different input orders gives identical adjacency
ego = ceil(runiform(20000,1)*500); alt = ceil(runiform(20000,1)*500)
k = selectindex(ego :!= alt); ego = ego[k]; alt = alt[k]
k = uniqrows((ego,alt)); ego = k[.,1]; alt = k[.,2]
lab = "n" :+ strofreal(1..500)
a = &(nw_def()); a->create_by_name_sparse(lab); a->set_name("A")
b = &(nw_def()); b->create_by_name_sparse(lab); b->set_name("B")
a->set_edge_from_triplets(ego, alt, J(rows(ego),1,1), 1)
ord = order(runiform(rows(ego),1),1)
b->set_edge_from_triplets(ego[ord], alt[ord], J(rows(ego),1,1), 1)
for (i=1; i<=500; i++) {
	assert(a->neighbors(i) == b->neighbors(i))
	assert(a->neighbors_in(i) == b->neighbors_in(i))
}
// dense path agrees
d = &(nw_def()); d->create_by_name(lab); d->set_name("D")
M = J(500,500,0)
for (i=1; i<=rows(ego); i++) M[ego[i],alt[i]] = 1
d->set_edge(M)
for (i=1; i<=500; i++) assert(a->neighbors(i) == d->neighbors(i))
printf("test_core_neighbor_order: ALL OK\n")
end
