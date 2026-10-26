*! _nwwlayout: layouts that use the tie values (nwplot, nwmovie): Kamada-Kawai (kk) and Fruchterman-Reingold (frucht)
*! Usage: _nwwlayout, pmat(<Mata matrix>) method(kk|frucht) iterations(#) out(<Mata name>) [start(<Mata matrix>) quiet]
*! pmat() is the raw tie matrix from nwtomata (missing diagonal allowed).  When the values can be used, out() is
*! set to the n x 2 coordinates (same box and isolate column as the unweighted layouts) and r(weighted) is 1.
*! Otherwise nothing is created, r(weighted) is 0 and the caller runs its unweighted code, unchanged:
*!   r(why) 1 = a tie value is not positive (signed network): igraph refuses such weights in layout_with_fr()/
*!              layout_with_kk() and plot() then ignores all weights with a warning; so do we (with a note)
*!   r(why) 2 = all ties have the same value (the weighted layout would be the unweighted one)
*!   r(why) 3 = fewer than two nodes
*! Conventions (see nwplot.sthlp): the values are strengths.  They are divided by their mean, so the layout does
*! not depend on the unit of the values.  kk: edge length 1/strength, distance = shortest weighted path;
*! frucht: attraction multiplied by the strength.  A tie in both directions counts with its larger value.
*! The Mata code lives here (not in the Mata library) so that no model package has to be rebuilt.
capture program drop _nwwlayout
program _nwwlayout, rclass
	syntax , PMAT(name) METHod(string) ITERations(integer) OUT(name) [START(name) QUIET]
	tempname rc
	mata: _nww_S = J(0, 0, .)
	mata: st_numscalar("`rc'", nw_wstrength(`pmat', _nww_S))
	local why = `rc'
	if `why' == 0 {
		if "`method'" == "kk" {
			if "`start'" != "" mata: `out' = nw_wkklayout(_nww_S, `iterations', `start')
			else mata: `out' = nw_wkklayout(_nww_S, `iterations')
		}
		else if "`method'" == "frucht" {
			mata: `out' = nw_wfruchtrein(_nww_S, `iterations')
		}
		else {
			capture mata: mata drop _nww_S
			di "{err}_nwwlayout: method() must be kk or frucht"
			error 198
		}
	}
	else if `why' == 1 & "`quiet'" == "" {
		di "{txt}Note: the network has tie values that are not positive; the layout does not use the values (as igraph, whose layouts need positive weights). Option {bf:binary} hides this note."
	}
	capture mata: mata drop _nww_S
	return scalar weighted = (`why' == 0)
	return scalar why = `why'
end

capture mata: mata drop nw_wstrength()
capture mata: mata drop nw_wdist()
capture mata: mata drop nw_wkklayout()
capture mata: mata drop nw_wfruchtrein()
capture mata: mata drop nw_wbox()
mata:

// P: raw tie matrix.  S: symmetric strength matrix (mean tie strength 1, zero diagonal) when the code is 0.
real scalar nw_wstrength(real matrix P, real matrix S)
{
	real scalar n, mu
	real matrix A
	real colvector v

	n = rows(P)
	if (n < 2) return(3)
	A = editmissing(P, 0)
	_diag(A, 0)
	v = select(vec(A), vec(A) :!= 0)
	if (length(v) == 0) return(3)
	if (min(v) <= 0) return(1)
	if (min(v) == max(v)) return(2)
	S = (A :> A') :* A + (A :<= A') :* A'
	mu = mean(select(vec(S), vec(S) :> 0))
	S = S :/ mu
	return(0)
}

// shortest weighted paths, edge length 1/strength.  Relaxation row by row until nothing changes (Gauss-Seidel).
real matrix nw_wdist(real matrix S)
{
	real scalar n, v, changed, big, mx
	real matrix D
	real rowvector nb, newrow, cand

	n = rows(S)
	big = 1e300
	D = J(n, n, big)
	_diag(D, 0)
	for (v = 1; v <= n; v++) {
		nb = selectindex(S[v, .] :> 0)
		if (length(nb) > 0) D[v, nb] = 1 :/ S[v, nb]
	}
	changed = 1
	while (changed) {
		changed = 0
		for (v = 1; v <= n; v++) {
			nb = selectindex(S[v, .] :> 0)
			if (length(nb) == 0) continue
			cand = colmin(D[nb, .] :+ (1 :/ S[v, nb])')
			newrow = colmin((D[v, .] \ cand))
			if (any(newrow :< D[v, .])) {
				D[v, .] = newrow
				changed = 1
			}
		}
	}
	// pairs in different components: farther than any connected pair
	mx = max(select(vec(D), vec(D) :< big))
	D = D :* (D :< big) :+ (D :>= big) :* (mx + mean(select(vec(1 :/ S), vec(S) :> 0)))
	return(D)
}

// The plotting box of kklayout(): non-isolates to x in [0.25, 1.25], y in [0, 1]; isolates in a column at x = 1.5.
real matrix nw_wbox(real matrix Pos, real matrix S)
{
	real matrix R
	real colvector noniso
	real scalar maxX, minX, maxY, minY, num_isol, k, i, V

	R = Pos
	V = rows(S)
	noniso = (rowsum(S) :!= 0)
	maxX = max(select(R[., 1], noniso))
	minX = min(select(R[., 1], noniso))
	maxY = max(select(R[., 2], noniso))
	minY = min(select(R[., 2], noniso))
	R[., 1] = (noniso :* (R[., 1] :- minX) :* (1 / (maxX - minX)) :+ 0.25) :+ ((noniso :== 0) :* R[., 1])
	R[., 2] = (noniso :* (R[., 2] :- minY) :* (1 / (maxY - minY))) :+ ((noniso :== 0) :* R[., 2])
	num_isol = sum(noniso :== 0)
	k = 1
	for (i = 1; i <= V; i++) {
		if (noniso[i] == 0) {
			R[i, 1] = 1.5
			R[i, 2] = k / num_isol
			k = k + 1
		}
	}
	return(R)
}

// Kamada-Kawai by stress majorization (as kklayout()), target distances = weighted shortest paths, weights 1/d^2.
// Node i moves to sum_j w_ij (x_j + d_ij (x_i - x_j)/|x_i - x_j|) / sum_j w_ij = [ sum_j w_ij x_j + sum_j (1/d_ij) dx_j/|.| ] / sum_j w_ij
// with w_ij = 1/d_ij^2; the two matrices 1/d and 1/d^2 are kept, so a node costs a few vector operations.
real matrix nw_wkklayout(real matrix S, real scalar Iter, | real matrix Start)
{
	real matrix Winv, W, Pos
	real colvector dx, dy, d, q, idx
	real scalar V, i, t, wsum, nx, ny, j

	V = rows(S)
	if (args() == 3 & rows(Start) == V & cols(Start) == 2) Pos = Start
	else Pos = jumble(circlelayout(V))
	Winv = nw_wdist(S)
	Winv = 1 :/ Winv
	_diag(Winv, 0)
	W = Winv :* Winv
	for (t = 1; t <= Iter; t++) {
		for (i = 1; i <= V; i++) {
			dx = Pos[i, 1] :- Pos[., 1]
			dy = Pos[i, 2] :- Pos[., 2]
			d = sqrt(dx :* dx :+ dy :* dy)
			d[i] = 1
			idx = selectindex(d :< 1e-8)
			if (length(idx) > 0) {
				for (j = 1; j <= length(idx); j++) {
					dx[idx[j]] = (runiform(1, 1) - 0.5) * 1e-6
					dy[idx[j]] = (runiform(1, 1) - 0.5) * 1e-6
					d[idx[j]] = sqrt(dx[idx[j]]^2 + dy[idx[j]]^2)
				}
			}
			q = Winv[., i] :/ d
			wsum = colsum(W[., i])
			nx = cross(W[., i], Pos[., 1]) + cross(q, dx)
			ny = cross(W[., i], Pos[., 2]) + cross(q, dy)
			Pos[i, .] = (nx, ny) :/ wsum
		}
	}
	return(nw_wbox(Pos, S))
}

// fruchtrein() of nwplot.ado with the attraction along a tie multiplied by its strength (igraph layout_with_fr(weights=))
real matrix nw_wfruchtrein(real matrix M, real scalar Iter)
{
	real matrix Pos, Disp
	real vector delta
	real scalar radius, i, v, u, e1, e2, W, L, area, V, temperature, k
	W = 2
	L = 2
	area = W * L
	radius = min((W, L)) / 2
	V = rows(M)
	Pos = runiform(V, 2) :- .5
	Pos[., 1] = floor(W) :* runiform(V, 1) :- W / 2
	Pos[., 2] = floor(L) :* runiform(V, 1) :- L / 2
	Disp = J(V, 2, 0)
	temperature = W / 3
	k = sqrt(area / V)
	for (i = 1; i <= Iter; i++) {
		for (v = 1; v <= V; v++) {
			for (u = 1; u <= V; u++) {
				if (v != u) {
					delta = Pos[v, .] - Pos[u, .]
					Disp[v, .] = Disp[v, .] + (delta / norm(delta)) * ((k^2) / norm(delta))
				}
			}
		}
		for (e1 = 1; e1 <= V; e1++) {
			for (e2 = e1 + 1; e2 <= V; e2++) {
				if (M[e1, e2] != 0) {
					delta = Pos[e1, .] - Pos[e2, .]
					Disp[e1, .] = Disp[e1, .] - M[e1, e2] * (delta / norm(delta)) * ((norm(delta) * norm(delta)) / k)
					Disp[e2, .] = Disp[e2, .] + M[e1, e2] * (delta / norm(delta)) * ((norm(delta) * norm(delta)) / k)
				}
			}
		}
		for (v = 1; v <= V; v++) {
			Pos[v, .] = Pos[v, .] + (Disp[v, .] / norm(Disp[v, .]) * min((norm(Disp[v, .]), temperature)))
			if (norm(Pos[v, .]) > radius) Pos[v, .] = radius * Pos[v, .] / (norm(Pos[v, .]))
		}
		temperature = temperature - temperature / 10
	}
	return(Pos)
}
end
