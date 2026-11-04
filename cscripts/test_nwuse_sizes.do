* nwuse: networks of different sizes saved in one file come back with their own size (no isolates padded up to the largest network)
capture program drop nwinstall
cscript

tempfile f
local f "`c(tmpdir)'/nwuse_sizes_test"

nwclear
set seed 12345
nwrandom 10, prob(.3) name(small)
nwrandom 25, prob(.2) name(big)
nwrandom 12, prob(.08) undirected name(sparse)
nwrandom 8, prob(.4) name(tiny)
foreach n in small big sparse tiny {
	nwname `n'
	local nodes_`n' = r(nodes)
	local dir_`n' "`r(directed)'"
	quietly nwsummarize `n'
	local dens_`n' = r(density)
	nwtomata `n', mat(M_`n')
	mata: st_local("sum_`n'", strofreal(sum(M_`n')))
}
* node names that contain a comma ("Smith, J.") and are not all connected, next to a larger network
clear
input str12 e str12 a
"Smith, J." "Jones, K."
"Jones, K." "Lee, M."
end
nwfromedge e a, name(commas) undirected
nwname commas
local nodes_commas = r(nodes)
local dir_commas "`r(directed)'"
nwtomata commas, mat(M_commas)
mata: st_local("sum_commas", strofreal(sum(M_commas)))
nwsave "`f'", replace

nwclear
nwuse "`f'"
foreach n in small big sparse tiny commas {
	nwname `n'
	assert r(nodes) == `nodes_`n''
	assert "`r(directed)'" == "`dir_`n''"
	nwtomata `n', mat(N_`n')
	mata: assert(sum(N_`n') == `sum_`n'')
	mata: assert(rows(N_`n') == `nodes_`n'')
}
* the sparse network has isolates; they must survive
nwtomata sparse, mat(S)
mata: assert(sum(rowsum(S) :== 0 :& colsum(S)' :== 0) > 0)

* a file that was loaded before holds the networks again with the old behaviour for a file without _nw_modes: not testable here
capture erase "`f'.nwdta"
display "PASS test_nwuse_sizes"
