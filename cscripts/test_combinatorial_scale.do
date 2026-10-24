cscript

do unw_core.do

/*
	Regression test for the combinatorial commands that used to stop at a few hundred
	nodes: nwcohesion, nwfactions, nwlambda, nwmotifs, nw2clustering, nwinduced,
	nwkplex, nwnclique, nwnclan.

	Each now calls a native kernel (native/nwcomb.h, nwcomb2.h) and keeps its older Mata
	code as the fallback for a platform whose plugin has not been rebuilt. The Mata code
	is the exact reference: this file runs every command on 32+ small random networks of
	different type and density (undirected, directed, valued, signed, with isolates) once
	with the kernels and once with them switched off (nwg_comb_state = 0) and requires
	identical results - the same sets in the same order, the same counts, the same
	variables, the same r() values (fitness to 1e-12). Besides that:
	  - nwmotifs against an independent brute-force count over all 4-subsets,
	  - nwkplex sets against a brute-force definition check (valid and maximal),
	  - nwinduced (degree) against a dense leave-one-out computation,
	  - the result limits (maxcliques(), maxtime()), countonly and nomatrix,
	  - and size checks: each command at 1,000 nodes (10 ties per node) in well under 60 s.
	Without the native kernels (plugin missing for the platform) the equality tests compare
	the Mata code with itself and only the size checks differ, which are then skipped.
*/

mata: mata set matastrict off

program define cs_mknet
	* cs_mknet n p kind seed -> network "tn" (kind 1 undirected, 2 directed, 3 valued undirected,
	* 4 valued directed, 5 undirected sparse, 6 signed directed)
	args n p kind seed
	set seed `seed'
	nwclear
	mata: A = (runiform(`n',`n') :< `p'); _diag(A,0)
	if inlist(`kind',3,4) mata: A = A :* ceil(5*runiform(`n',`n'))
	if inlist(`kind',1,5) mata: A = ((A + A') :> 0)
	if `kind' == 3 mata: A = (A :>= A') :* A + (A' :> A) :* A'
	if `kind' == 6 mata: A = A :* (2*(runiform(`n',`n') :< .8) :- 1)
	if inlist(`kind',1,3,5) nwset, mat(A) name(tn) undirected
	else nwset, mat(A) name(tn) directed
	capture mata: mata drop A
end

* ---- one program per command: run it and leave a row vector of everything it returned in R ----
program define cs_motifs
	nwmotifs tn, silent
	mata: R = (st_numscalar("r(path)"), st_numscalar("r(star)"), st_numscalar("r(cycle)"), st_numscalar("r(paw)"), st_numscalar("r(diamond)"), st_numscalar("r(k4)"), st_numscalar("r(disconnected)"))
end
program define cs_lambda
	capture nwdrop lam
	nwlambda tn, name(lam)
	nwtomata lam, mat(LM)
	mata: R = vec(LM)'
	mata: mata drop LM
end
program define cs_cohesion
	capture drop coh
	nwcohesion tn, generate(coh) replace silent
	mata: R = (st_numscalar("r(blocks)"), vec(st_matrix("r(cohesion_matrix)"))', vec(st_matrix("r(cohesion_levels)"))', st_data(., "coh")')
end
program define cs_factions
	args g ms
	capture drop fac
	nwfactions tn, groups(`g') measure(`ms') generate(fac) replace silent
	mata: R = (st_data(., "fac")', st_numscalar("r(fitness)"))
end
program define cs_kplex
	args k
	capture drop kp
	nwkplex tn, k(`k') generate(kp) replace silent
	mata: R = (st_numscalar("r(kplexes)"), vec(st_matrix("r(kplex_matrix)"))', st_data(., "kp")')
end
program define cs_nclique
	args n
	capture drop nc
	nwnclique tn, n(`n') generate(nc) replace silent minsize(2)
	mata: R = (st_numscalar("r(ncliques)"), vec(st_matrix("r(nclique_matrix)"))', st_data(., "nc")')
end
program define cs_nclan
	args n
	capture drop nc
	nwnclan tn, n(`n') generate(nc) replace silent minsize(2)
	mata: R = (st_numscalar("r(nclans)"), vec(st_matrix("r(nclan_matrix)"))', st_data(., "nc")')
end
program define cs_induced
	capture drop ind_endog ind_induced ind_exog
	nwinduced tn, measure(degree) generate(ind) replace silent
	mata: R = (st_data(., "ind_endog")', st_data(., "ind_induced")', st_data(., "ind_exog")')
end

* brute-force helpers for the independent checks
mata:
void cs_tally(real matrix A, real rowvector q, real rowvector cnt)
{
	real matrix S, C
	real rowvector d
	real scalar e, conn

	S = A[q,q]
	e = sum(S) / 2
	d = sort(rowsum(S), 1)'
	C = I(4) + S
	C = C * C * C
	conn = all(C :> 0)
	if (conn & e == 3 & max(d) == 2) cnt[1] = cnt[1] + 1           // path
	else if (conn & e == 3) cnt[2] = cnt[2] + 1                    // star
	else if (conn & e == 4 & max(d) == 2) cnt[3] = cnt[3] + 1      // 4-cycle
	else if (conn & e == 4) cnt[4] = cnt[4] + 1                    // triangle with a pendant tie
	else if (e == 5) cnt[5] = cnt[5] + 1                           // diamond
	else if (e == 6) cnt[6] = cnt[6] + 1                           // complete
	else cnt[7] = cnt[7] + 1                                       // not connected
}

// sum of the degrees minus the sum of the degrees of the network without node v, for every v
real colvector cs_leaveoneout(real matrix A)
{
	real colvector ref
	real matrix B
	real scalar v, n

	n = rows(A)
	ref = J(n, 1, .)
	for (v = 1; v <= n; v++) {
		B = A
		B[v,.] = J(1, n, 0)
		B[.,v] = J(n, 1, 0)
		ref[v] = sum(A) - sum(B)
	}
	return(ref)
}

void cs_checkplex(real matrix A, real rowvector row, real scalar k)
{
	real rowvector S, T
	real scalar u

	S = selectindex(row)
	if (cols(S) == 0) return
	if (cols(S) > 1) assert(min(rowsum(A[S,S])) >= cols(S) - k)
	for (u = 1; u <= cols(A); u++) {
		if (row[u]) continue
		T = (S, u)
		assert(min(rowsum(A[T,T])) < cols(T) - k)
	}
}
end

* compare two result rows: same shape, same values, missing equal to missing; the fitness of
* nwfactions (last element) to 1e-12
mata:
real scalar cs_same(real rowvector a, real rowvector b, | real scalar tolLast)
{
	real scalar k
	if (cols(a) != cols(b)) return(0)
	k = cols(a)
	if (args() >= 3 & k > 0) {
		if (!all(a[1..(k-1)] :== b[1..(k-1)])) return(0)
		return(a[k] == b[k] | abs(a[k] - b[k]) < tolLast)
	}
	return(all(a :== b))
}
end

* elementwise equal up to tol (missing equal to missing)
mata:
real scalar cs_close(real rowvector a, real rowvector b, real scalar tol)
{
	if (cols(a) != cols(b)) return(0)
	return(all((a :== b) :| (abs(a :- b) :< tol)))
}
end

* Runs program `prog' (with its arguments) with the native kernels and with the Mata code and
* requires the same R
capture program drop cs_both
program define cs_both
	syntax anything, [last]
	mata: nwg_comb_state = .
	cs_`anything'
	mata: R1 = R
	mata: nwg_comb_state = 0
	cs_`anything'
	mata: R2 = R
	mata: nwg_comb_state = .
	if "`last'" == "" mata: assert(cs_same(R1, R2))
	else mata: assert(cs_same(R1, R2, 1e-12))
end

mata: printf("native combinatorial kernels available: %g\n", nwg_comb_ok())
local native = 0
mata: st_local("native", strofreal(nwg_comb_ok()))

* ---------------------------------------------------------------------------------
* 1. native == Mata on 32+ random networks per command
* ---------------------------------------------------------------------------------
forvalues it = 1/36 {
	local kind = 1 + mod(`it', 6)
	local n = 6 + mod(`it'*7, 12)
	local p = 0.08 + 0.045*mod(`it'*5, 9)
	cs_mknet `n' `p' `kind' `=500+`it''
	cs_both motifs
	cs_both lambda
	cs_both cohesion
	_nwsyntax tn
	mata: st_local("nties", strofreal(rows(nwg_sym01(`netobj'->edgelist()))))
	if `nties' > 0 {
		foreach g in 2 3 4 {
			foreach ms in binary valued {
				cs_both factions `g' `ms', last
			}
		}
	}
	cs_both kplex 2
	cs_both kplex 3
	cs_both nclique 2
	cs_both nclan 2
	cs_both nclan 3
	if inlist(`kind',1,3,5) cs_both induced
}
* sparser and larger: deeper cohesion hierarchies, many n-cliques
forvalues it = 1/12 {
	local n = 14 + mod(`it'*7, 9)
	local p = 0.05 + 0.015*mod(`it'*5, 7)
	cs_mknet `n' `p' `=1+mod(`it',2)' `=900+`it''
	cs_both cohesion
	cs_both nclique 2
	cs_both nclique 3
	cs_both nclan 2
	cs_both kplex 2
}
forvalues it = 1/6 {
	cs_mknet 70 `=0.06 + 0.01*`it'' 1 `=1300+`it''
	cs_both cohesion
	cs_both lambda
	cs_both motifs
}

* two-mode clustering: 12 affiliation matrices, binary and valued, all measures, both levels
forvalues it = 1/12 {
	local n1 = 5 + mod(`it'*3, 7)
	local n2 = 5 + mod(`it'*5, 8)
	set seed `=2000+`it''
	nwclear
	mata: R = (runiform(`n1',`n2') :< 0.3 + 0.03*mod(`it',10))
	if mod(`it',2)==0 mata: R = R :* ceil(4*runiform(`n1',`n2'))
	nwset, mat(R) name(tn) bipartite
	mata: mata drop R
	foreach lv in 1 2 {
		foreach ms in binary arithmetic geometric maximum minimum {
			mata: nwg_comb_state = .
			capture drop c2
			nw2clustering tn, generate(c2) replace measure(`ms') level(`lv')
			mata: R1 = (st_data(., "c2")', st_numscalar("r(C_avg)"), st_numscalar("r(C_global)"))
			mata: nwg_comb_state = 0
			capture drop c2
			nw2clustering tn, generate(c2) replace measure(`ms') level(`lv')
			mata: R2 = (st_data(., "c2")', st_numscalar("r(C_avg)"), st_numscalar("r(C_global)"))
			mata: nwg_comb_state = .
			* the geometric mean uses pow() in C and ^ in Mata, which can differ in the last bit
			mata: assert(cs_close(R1, R2, 1e-13))
		}
	}
}

* ---------------------------------------------------------------------------------
* 2. independent checks
* ---------------------------------------------------------------------------------
* nwmotifs against a brute-force count of the induced 4-node subgraphs
forvalues it = 1/10 {
	cs_mknet `=7 + mod(`it'*3, 9)' `=0.1 + 0.05*mod(`it',6)' `=1 + mod(`it', 2)' `=3000+`it''
	nwmotifs tn, silent
	mata: M7 = (st_numscalar("r(path)"), st_numscalar("r(star)"), st_numscalar("r(cycle)"), st_numscalar("r(paw)"), st_numscalar("r(diamond)"), st_numscalar("r(k4)"), st_numscalar("r(disconnected)"))
	_nwsyntax tn
	mata: A = *`netobj'->get_matrix_mod(0,0); _diag(A,0); A = (A :!= 0)
	mata: n = rows(A); cnt = J(1,7,0)
	mata: for (i=1;i<=n-3;i++) for (j=i+1;j<=n-2;j++) for (k=j+1;k<=n-1;k++) for (l=k+1;l<=n;l++) cs_tally(A, (i,j,k,l), cnt)
	mata: assert(cnt == M7)
	mata: assert(sum(cnt) == n*(n-1)*(n-2)*(n-3)/24)
}

* nwkplex: every returned set is a k-plex and no node can be added; nomatrix and countonly agree
forvalues it = 1/8 {
	cs_mknet `=10 + mod(`it'*3, 7)' `=0.15 + 0.05*mod(`it',4)' 1 `=4000+`it''
	foreach k in 2 3 {
		nwkplex tn, k(`k') generate(kpx) replace silent
		matrix KM = r(kplex_matrix)
		local nk = r(kplexes)
		_nwsyntax tn
		mata: A = *`netobj'->get_matrix_mod(0,0); _diag(A,0); A = (A :!= 0); K = st_matrix("KM"); n = rows(A)
		mata: for (r=1; r<=rows(K); r++) cs_checkplex(A, K[r,.], `k')
		mata: st_local("kvar", "kpx")
		* nomatrix gives the same per-node variable and the same count
		nwkplex tn, k(`k') generate(kpy) replace silent nomatrix
		assert r(kplexes) == `nk'
		capture assert kpx == kpy | (kpx >= . & kpy >= .)
		assert _rc == 0
		* countonly: the same count and a size table that adds up
		nwkplex tn, k(`k') countonly silent
		assert r(kplexes) == `nk'
		matrix T = r(size_table)
		mata: T = st_matrix("T"); assert(sum(T[.,2]) == `nk')
	}
}

* nwinduced, measure(degree): dense leave-one-out
forvalues it = 1/8 {
	cs_mknet `=6 + mod(`it'*3, 9)' `=0.15 + 0.05*mod(`it',5)' `=1 + 2*mod(`it',2)' `=5000+`it''
	capture drop ind_endog ind_induced ind_exog
	nwinduced tn, measure(degree) generate(ind) replace silent
	_nwsyntax tn
	mata: A = *`netobj'->get_matrix_mod(0,0); _diag(A,0); A = (A :!= 0); n = rows(A)
	mata: ref = cs_leaveoneout(A)
	mata: assert(st_data(., "ind_induced") == ref)
	mata: assert(st_data(., "ind_endog") :+ st_data(., "ind_exog") == st_data(., "ind_induced"))
}

* ---------------------------------------------------------------------------------
* 3. limits
* ---------------------------------------------------------------------------------
cs_mknet 40 0.08 1 7001
nwnclique tn, n(2) generate(ncq) replace silent minsize(2) countonly
local total = r(ncliques)
assert `total' > 3
capture nwnclique tn, n(2) generate(ncq) replace silent minsize(2) maxcliques(2)
if `native' assert _rc == 484
capture nwnclique tn, n(2) generate(ncq) replace silent minsize(2) maxcliques(`total')
assert _rc == 0
capture nwnclan tn, n(2) generate(ncq) replace silent minsize(2) maxcliques(1)
if `native' assert _rc == 484
* countonly needs no generate(); the counts of nwnclan and nwnclique agree with the matrices
nwnclan tn, n(2) countonly silent minsize(2)
local nclans = r(nclans)
nwnclan tn, n(2) generate(ncq) replace silent minsize(2)
assert r(nclans) == `nclans'
nwnclique tn, n(2) countonly silent minsize(2)
assert r(ncliques) == `total'
nwnclique tn, n(2) generate(ncq) replace silent minsize(2) nomatrix
assert r(ncliques) == `total'
cs_mknet 40 0.08 1 7002
capture nwkplex tn, k(2) generate(kq) replace silent maxplexes(2)
if `native' assert _rc == 484
capture nwkplex tn, k(2) generate(kq) replace silent maxtime(0.000001)
if `native' assert _rc == 484
nwkplex tn, k(2) generate(kq) replace silent maxplexes(1e9) nomatrix
assert r(kplexes) > 2

* ---------------------------------------------------------------------------------
* 4. size checks: a random network with 1,000 nodes and 10 ties drawn per node
* ---------------------------------------------------------------------------------
if `native' {
	set seed 20261025
	nwclear
	clear
	quietly set obs 10000
	quietly gen long from = ceil(_n/10)
	quietly gen long to = ceil(runiform()*1000)
	quietly drop if from == to
	nwfromedge from to, undirected name(big)
	local lim 60

	timer clear 1
	timer on 1
	nwcohesion big, generate(cohbig) silent
	local nblocks = r(blocks)
	timer off 1
	quietly timer list 1
	display "nwcohesion 1000 nodes: " r(t1) " s"
	assert r(t1) < `lim'
	assert `nblocks' >= 1

	timer clear 1
	timer on 1
	nwfactions big, groups(3) generate(facbig) silent
	timer off 1
	quietly timer list 1
	display "nwfactions 1000 nodes: " r(t1) " s"
	assert r(t1) < `lim'

	timer clear 1
	timer on 1
	nwlambda big, name(lambig)
	timer off 1
	quietly timer list 1
	display "nwlambda 1000 nodes: " r(t1) " s"
	assert r(t1) < `lim'

	timer clear 1
	timer on 1
	nwmotifs big, silent
	local tot = r(path) + r(star) + r(cycle) + r(paw) + r(diamond) + r(k4) + r(disconnected)
	timer off 1
	quietly timer list 1
	display "nwmotifs 1000 nodes: " r(t1) " s"
	assert r(t1) < `lim'
	_nwsyntax big
	assert `tot' == `nodes'*(`nodes'-1)*(`nodes'-2)*(`nodes'-3)/24

	timer clear 1
	timer on 1
	nwinduced big, measure(degree) generate(indbig) silent
	timer off 1
	quietly timer list 1
	display "nwinduced degree 1000 nodes: " r(t1) " s"
	assert r(t1) < `lim'

	timer clear 1
	timer on 1
	nwkplex big, k(2) generate(kpbig) silent countonly maxplexes(1e9)
	timer off 1
	quietly timer list 1
	display "nwkplex countonly 1000 nodes: " r(t1) " s"
	assert r(t1) < `lim'

	* the sets of nwnclique are too many to keep: the limit answers at once with a clear error
	timer clear 1
	timer on 1
	capture nwnclique big, n(2) generate(ncbig) silent
	local rc = _rc
	timer off 1
	quietly timer list 1
	assert `rc' == 484
	assert r(t1) < `lim'

	* two-mode, 1,000 x 500
	nwclear
	clear
	quietly set obs 10000
	quietly gen long from = ceil(_n/10)
	quietly gen long to = ceil(runiform()*500)
	nw2fromedge from to, name(big2)
	timer clear 1
	timer on 1
	nw2clustering big2, generate(c2big) replace
	timer off 1
	quietly timer list 1
	display "nw2clustering 1000 x 500: " r(t1) " s"
	assert r(t1) < `lim'
}

display "test_combinatorial_scale: all passed (native kernels: `native')"
