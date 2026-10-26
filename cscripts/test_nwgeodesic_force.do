* nwgeodesic on an unvalued network with force used the Mata Dijkstra routine (37 s at 600 nodes); it now uses the
* same hop-count routine as without force.  Distances must equal a Floyd-Warshall reference and be fast.
clear all
capture mata: mata drop nwtest_fw()
mata:
void nwtest_fw(real matrix F)
{
	real scalar i, j, k, n
	n = rows(F)
	for (k = 1; k <= n; k++) {
		for (i = 1; i <= n; i++) {
			for (j = 1; j <= n; j++) {
				if (F[i,k] < . & F[k,j] < . & (F[i,j] >= . | F[i,k] + F[k,j] < F[i,j])) F[i,j] = F[i,k] + F[k,j]
			}
		}
	}
}
end
set seed 11
foreach d in undirected directed {
	capture nwdrop g
	capture nwdrop gd
	clear
	qui set obs 400
	gen ego = ceil(runiform()*120)
	gen alter = ceil(runiform()*120)
	qui drop if ego == alter
	qui nwfromedge ego alter, name(g) `d'
	qui nwgeodesic g, name(gd) nwreplace force
	_nwsyntax gd
	mata: D = *`netobj'->get_matrix()
	_nwsyntax g
	mata: A = *`netobj'->get_matrix()
	mata: F = editvalue(A, 0, .); _diag(F, 0)
	mata: nwtest_fw(F); _diag(F, .)
	mata: st_local("same", strofreal(F == D))
	assert `same' == 1
}
* speed: 600 nodes, force, 2,600 observations in memory
clear
qui set obs 7800
gen ego = ceil(runiform()*600)
gen alter = ceil(runiform()*600)
qui drop if ego == alter
capture nwdrop g
qui nwfromedge ego alter, name(g) undirected
clear
qui set obs 2600
timer clear 1
timer on 1
qui nwgeodesic g, name(g1) nwreplace force
timer off 1
qui timer list 1
assert r(t1) < 10
di "PASS test_nwgeodesic_force"
