* Exports the ties of the two data sets used by tools/verify_native380.R as biadjacency cells (i = row of mode 1, j = column of mode 2,
* in the order of the nodes of each mode in the network) to cscripts/native380_fixture/.  Run from the repository root with
* the repository on the adopath:  stata -e do tools/export_native380_nets.do
mata:
real matrix ijlist(real matrix B)
{
	real matrix ij
	real scalar a, b
	ij = J(0, 2, .)
	for (a = 1; a <= rows(B); a++) {
		for (b = 1; b <= cols(B); b++) {
			if (editmissing(B[a, b], 0) != 0) ij = ij \ (a, b)
		}
	}
	return(ij)
}
end
foreach x in davis ftdirectors_se {
	nwclear
	nwuse data/`x', nwclear
	_nwsyntax `x', max(1)
	mata: md = strtoreal(`netobj'->get_modes()); B = (*`netobj'->get_matrix())[selectindex(md :== 1), selectindex(md :== 2)]
	mata: st_local("n1", strofreal(rows(B))); st_local("n2", strofreal(cols(B)))
	di "`x' `n1' x `n2'"
	mata: ij = ijlist(B)
	preserve
	clear
	mata: st_addobs(rows(ij)); st_addvar("int", ("i", "j")); st_store(., ("i","j"), ij)
	list in 1/3
	export delimited "cscripts/native380_fixture/`x'_cells.csv", replace
	restore
}
