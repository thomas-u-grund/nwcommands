*! nwegoplot: draw the ego network of one node, ego in the center and the alters on a circle (3.20.1)
capture program drop nwegoplot
program nwegoplot, rclass
	version 12
	syntax [anything(name=netname)] , ego(string) [hop(integer 1) SORTby(varname) GENerate(string) replace EDGEColor(string) *]

	_nwsyntax `netname'
	_nw2guard `netname', cmd(nwegoplot)
	if !inlist(`hop', 1, 2) {
		di "{err}hop() must be 1 or 2."
		error 198
	}
	if "`generate'" != "" {
		if wordcount("`generate'") != 2 {
			di "{err}generate() needs two new variable names, for the x and the y coordinate."
			error 198
		}
		foreach v of local generate {
			capture confirm variable `v', exact
			if _rc == 0 & "`replace'" == "" {
				di "{err}Variable {bf:`v'} already exists; specify {bf:replace}"
				error 110
			}
		}
	}

	qui if _N < `nodes' set obs `nodes'
	_nwsyncrows `netname'
	_nwsyntax `netname'

	// ego: a node name, or else a node number
	tempname names A grp
	mata: `names' = `netobj'->get_nodenames()
	mata: st_local("egoid", strofreal(nw_egoplot_find(`names', st_local("ego"))))
	if `egoid' == 0 {
		capture confirm integer number `ego'
		if _rc == 0 {
			if `ego' >= 1 & `ego' <= `nodes' local egoid = `ego'
		}
	}
	if `egoid' == 0 {
		di "{err}ego(): {bf:`ego'} is neither the name nor the number of a node of `netname'."
		error 198
	}
	mata: st_local("egoname", `names'[`egoid'])

	nwtomatafast `netname'
	local srcmata "`r(mata)'"
	if "`sortby'" != "" {
		mata: `grp' = st_data((1::`nodes'), "`sortby'")
	}
	else {
		mata: `grp' = J(`nodes', 1, 0)
	}
	tempvar x y inego
	qui gen double `x' = .
	qui gen double `y' = .
	qui gen byte `inego' = 0
	mata: nw_egoplot_xy(`srcmata', `egoid', `hop', `grp', "`x'", "`y'", "`inego'")
	mata: mata drop `grp'
	qui count if `inego' == 1
	local nalter = r(N) - 1
	if `nalter' == 0 {
		di "{err}`egoname' has no ties in `netname'; there is no ego network to draw."
		error 2000
	}

	// by default the ties of ego (the spokes) are drawn light and the ties among the other nodes dark (value v of the tie-type network takes word v+1 of the palette)
	local ecol ""
	local tienet ""
	if "`edgecolor'" == "" {
		local tienet "_nwegoplot_ties"
		capture nwdrop `tienet'
		tempname T
		mata: `T' = nw_egoplot_tietype(`srcmata', `egoid')
		local und = cond("`directed'" == "true", "", "undirected")
		mata: `names' = `netobj'->get_nodenames()
		qui nwset, mat(`T') name(`tienet') nodenames(`names') `und'
		mata: mata drop `T' `names'
		local ecol "edgecolor(`tienet', legendoff edgecolorpalette(white gs10 gs4))"
	}
	else {
		local ecol "edgecolor(`edgecolor')"
		mata: mata drop `names'
	}
	// quietly: nwplot reports the nodes it leaves out and its progress, which say nothing here; on an
	// error the call is repeated noisily, so that its message is shown
	capture quietly nwplot `netname' if `inego', nodexy(`x' `y') layout(nodexy, norescale) aspectratio(1) `ecol' `options'
	local rc = _rc
	if `rc' {
		// a failed nwplot can leave its temporary network for the if condition behind
		foreach t in __temp_if __temp_edgecolor_if __temp_edgesize_if {
			capture nwdrop `t'
		}
		capture noisily nwplot `netname' if `inego', nodexy(`x' `y') layout(nodexy, norescale) aspectratio(1) `ecol' `options'
	}
	if "`tienet'" != "" capture nwdrop `tienet'
	if `rc' exit `rc'

	if "`generate'" != "" {
		local gx : word 1 of `generate'
		local gy : word 2 of `generate'
		capture drop `gx'
		capture drop `gy'
		qui gen double `gx' = `x'
		qui gen double `gy' = `y'
	}
	return scalar alters = `nalter'
	return local ego "`egoname'"
end

capture mata: mata drop nw_egoplot_find()
capture mata: mata drop nw_egoplot_order()
capture mata: mata drop nw_egoplot_xy()
capture mata: mata drop nw_egoplot_tietype()
mata:
real scalar nw_egoplot_find(string matrix names, string scalar ego)
{
	real colvector i
	i = selectindex(vec(names) :== ego)
	return(rows(i) ? i[1] : 0)
}

// order a set of nodes around a circle so that ties among them stay short: connected groups
// together (largest first), and inside a group the order of the Fiedler vector of its Laplacian
real colvector nw_egoplot_order(real matrix S, real colvector g)
{
	real scalar n, k, c, i, j
	real colvector comp, out, idx, key, members, f, stack, gv
	real matrix L, V, Sub
	real rowvector lam

	n = rows(S)
	if (n == 0) return(J(0, 1, .))
	comp = J(n, 1, 0)
	k = 0
	for (i = 1; i <= n; i++) {
		if (comp[i]) continue
		k++
		stack = i
		comp[i] = k
		while (rows(stack)) {
			j = stack[rows(stack)]
			stack = (rows(stack) > 1 ? stack[1::rows(stack) - 1] : J(0, 1, .))
			idx = selectindex((S[j, .]' :> 0) :& (comp :== 0))
			if (rows(idx)) {
				comp[idx] = J(rows(idx), 1, k)
				stack = stack \ idx
			}
		}
	}
	// key: attribute group, then component (larger first, single nodes last), then position in the component
	key = J(n, 4, 0)
	key[., 1] = g
	key[., 4] = (1::n)
	for (c = 1; c <= k; c++) {
		members = selectindex(comp :== c)
		key[members, 2] = J(rows(members), 1, -rows(members) * 1e6 + c)
		if (rows(members) > 2) {
			Sub = S[members, members]
			L = diag(rowsum(Sub)) - Sub
			symeigensystem(L, V, lam)
			// eigenvalues in descending order: the Fiedler vector is the second to last column
			f = V[., cols(V) - 1]
			if (f[1] < 0) f = -f
			key[members, 3] = f
		}
	}
	gv = order(key, (1, 2, 3, 4))
	out = gv
	return(out)
}

// 1 for a tie of ego, 2 for any other tie
real matrix nw_egoplot_tietype(real matrix A0, real scalar ego)
{
	real matrix A
	A = (editmissing(A0, 0) :!= 0)
	_diag(A, 0)
	A = A :* 2
	A[ego, .] = A[ego, .] :/ 2
	A[., ego] = A[., ego] :/ 2
	return(A)
}

void nw_egoplot_xy(real matrix A0, real scalar ego, real scalar hop, real colvector g,
	string scalar xv, string scalar yv, string scalar inv)
{
	real matrix A, S
	real scalar n, i, j, m, r
	real colvector alt, ord, ang, x, y, in, two, a2, sub
	real colvector cx, cy, theta, o2

	n = rows(A0)
	A = (editmissing(A0, 0) :!= 0)
	_diag(A, 0)
	S = ((A + A') :> 0)
	x = J(n, 1, .)
	y = J(n, 1, .)
	in = J(n, 1, 0)
	x[ego] = 0
	y[ego] = 0
	in[ego] = 1
	alt = selectindex(S[., ego])
	m = rows(alt)
	if (m) {
		ord = alt[nw_egoplot_order(S[alt, alt], g[alt])]
		ang = (0::m - 1) :* (2 * pi() / m) :+ pi() / 2
		x[ord] = cos(ang)
		y[ord] = sin(ang)
		in[ord] = J(m, 1, 1)
	}
	if (hop == 2 & m) {
		// contacts of the alters who are not ego and not alters, on an outer ring at the mean
		// direction of the alters they are tied to, then spread evenly in that order
		two = selectindex((rowsum(S[., alt]) :> 0) :& (in :== 0))
		r = rows(two)
		if (r) {
			theta = J(r, 1, .)
			for (i = 1; i <= r; i++) {
				sub = selectindex(S[alt, two[i]])
				cx = mean(x[alt[sub]])
				cy = mean(y[alt[sub]])
				theta[i] = atan2(cy, cx)
				if (theta[i] >= .) theta[i] = 0
			}
			o2 = order(theta, 1)
			two = two[o2]
			theta = theta[o2]
			// keep the order, but start the spread at the first node's own direction
			ang = theta[1] :+ (0::r - 1) :* (2 * pi() / r)
			x[two] = 2 :* cos(ang)
			y[two] = 2 :* sin(ang)
			in[two] = J(r, 1, 1)
		}
	}
	st_store(., xv, x)
	st_store(., yv, y)
	st_store(., inv, in)
}
end
