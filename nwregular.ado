*! nwregular: regular equivalence classes of the nodes of a network (3.20.1)
capture program drop nwregular
program nwregular, rclass
	version 12
	syntax [anything(name=netname)] , GENerate(string) [replace silent]

	_nwsyntax `netname'
	_nw2guard `netname', cmd(nwregular)

	capture confirm variable `generate', exact
	if _rc == 0 & "`replace'" == "" {
		di "{err}Variable {bf:`generate'} already exists; specify {bf:replace}"
		error 110
	}
	nwtomatafast `netname'
	local srcmata "`r(mata)'"
	tempname cls img IM
	mata: `cls' = nw_regular_exact(`srcmata')
	mata: st_local("ncl", strofreal(max(`cls')))
	mata: `img' = nw_regular_image(`srcmata', `cls')
	mata: st_matrix("`IM'", `img')

	qui if _N < `nodes' set obs `nodes'
	_nwsyncrows `netname'
	_nwsyntax `netname'
	capture drop `generate'
	qui gen `generate' = .
	mata: st_store((1::`nodes'), "`generate'", `cls')
	mata: mata drop `cls' `img'

	local rn ""
	forvalues i = 1/`ncl' {
		local rn "`rn' class`i'"
	}
	matrix rownames `IM' = `rn'
	matrix colnames `IM' = `rn'
	return matrix image = `IM'
	return scalar classes = `ncl'
	if "`silent'" == "" {
		di "{hline 40}"
		di "{txt}  Network name: {res}`netname'"
		di "{txt}  Classes of regularly equivalent nodes: {res}`ncl'"
		tab `generate'
	}
	qui nwload `netname', labelonly
end

capture mata: mata drop nw_regular_exact()
capture mata: mata drop nw_regular_image()
capture mata: mata drop nw_regular_renumber()
mata:
// Maximal regular equivalence (CATREGE for binary data; Borgatti and Everett 1993): start with
// all nodes in one class and split a class whenever two of its members differ in the set of
// classes they send ties to or receive ties from; stop when no class splits.
real colvector nw_regular_exact(real matrix A0)
{
	real matrix A, S
	real colvector c, cn
	real scalar n, k, kn, i, j

	n = rows(A0)
	A = (editmissing(A0, 0) :!= 0)
	_diag(A, 0)
	c = J(n, 1, 1)
	k = 1
	while (1) {
		// signature: own class, then which classes i sends to, then which classes i receives from
		S = J(n, 1 + 2 * k, 0)
		S[., 1] = c
		for (j = 1; j <= k; j++) {
			S[., 1 + j] = rowmax(A[., selectindex(c :== j)])
			S[., 1 + k + j] = rowmax(A[selectindex(c :== j), .]')
		}
		cn = J(n, 1, 0)
		kn = 0
		for (i = 1; i <= n; i++) {
			if (cn[i]) continue
			kn++
			for (j = i; j <= n; j++) {
				if (!cn[j]) {
					if (S[j, .] == S[i, .]) cn[j] = kn
				}
			}
		}
		if (kn == k) break
		c = cn
		k = kn
	}
	return(nw_regular_renumber(cn))
}

// number the classes in the order of their first node
real colvector nw_regular_renumber(real colvector c)
{
	real colvector m, out
	real scalar i, k

	m = J(max(c), 1, 0)
	out = c
	k = 0
	for (i = 1; i <= rows(c); i++) {
		if (!m[c[i]]) {
			k++
			m[c[i]] = k
		}
		out[i] = m[c[i]]
	}
	return(out)
}

// image: 1 if any member of class r sends a tie to a member of class s (for regular equivalence
// classes, every such block is regular: each member of r sends to some member of s and each
// member of s receives from some member of r)
real matrix nw_regular_image(real matrix A0, real colvector c)
{
	real matrix A, M
	real scalar k, r, s

	A = (editmissing(A0, 0) :!= 0)
	_diag(A, 0)
	k = max(c)
	M = J(k, k, 0)
	for (r = 1; r <= k; r++) {
		for (s = 1; s <= k; s++) {
			M[r, s] = (sum(A[selectindex(c :== r), selectindex(c :== s)]) > 0)
		}
	}
	return(M)
}
end
