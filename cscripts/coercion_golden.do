* Numbers of undirected binary networks, one line per number (hexadecimal, exact). Run by test_core_coercion.do and
* written to the file named in the global tcc_out; the stored copy cscripts/coercion_golden/undirected_binary.txt was
* made with the branch before the coercion sweep (3.34.0 + directed betweenness/closeness/evcent), so the sweep must
* not change a single number for an undirected binary network.
capture program drop _g
program _g
	args fh label
	if "`3'" == "" exit
	file write `fh' "`label' " %21x (`3') _n
end
capture program drop _gv
program _gv
	args fh label v n
	qui forvalues i = 1/`n' {
		file write `fh' "`label'[`i'] " %21x (`v'[`i']) _n
	}
end
nwclear
nwuse data/zachary, nwclear
nwuse data/florentine, nwappend
nwset
qui nwset, detail
local nets `r(nets)'
set seed 4711
nwrandom 40, prob(.12) undirected name(rnd40)
file open __fh using "$tcc_out", write replace
foreach n in zachary flomarriage rnd40 {
	capture _nwsyntax `n'
	if _rc continue
	file write __fh "== `n'" _n
	* --- nwassortativity
	qui nwassortativity `n', silent
	_g __fh assort_`n' `r(assortativity)'
	_g __fh assortties_`n' `r(ties)'
	* --- nwcomponents
	qui nwcomponents `n', generate(gc_`n') silent
	_g __fh comps_`n' `r(components)'
	_gv __fh gc_`n' gc_`n' `c(N)'
	* --- nwclustering
	qui nwclustering `n', generate(gcl_`n') silent
	_g __fh clg_`n' `r(cluster_global)'
	_g __fh cla_`n' `r(cluster_avg)'
	_gv __fh gcl_`n' gcl_`n' 20
	* --- nwkatz, nwrandomwalk, nwevcent, nwbalance, nwkcore, nwdegree on the undirected networks
	capture nwkatz `n', alpha(.3) generate(gk_`n')
	capture _gv __fh gk_`n' gk_`n' 20
	capture nwkatz `n', walks alpha(.05) generate(gw_`n')
	capture _gv __fh gw_`n' gw_`n' 20
	capture nwevcent `n', generate(ge_`n')
	capture _gv __fh ge_`n' ge_`n' 20
	capture nwkcore `n', generate(gkc_`n') silent
	capture _gv __fh gkc_`n' gkc_`n' 20
	capture nwdegree `n', generate(gd_`n') silent
	capture _gv __fh gd_`n' gd_`n' 20
	capture nwbalance `n'
	if _rc == 0 {
		_g __fh bal_`n' `r(balance)'
		_g __fh balc_`n' `r(closed_triad)'
	}
	capture nwclique `n', generate(gq_`n') silent
	capture _g __fh cliques_`n' `r(cliques)'
	capture nwcohesion `n', generate(gh_`n') silent
	capture _gv __fh gh_`n' gh_`n' 20
	capture nwspectral `n', generate(gsp_`n') silent
	capture _g __fh algconn_`n' `r(algebraic_connectivity)'
	capture nwcoreperiphery `n', generate(gcp_`n') silent
	capture _g __fh cpfit_`n' `r(fitness)'
	capture nwfactions `n', generate(gfa_`n') silent
	capture nwmaxflow `n', source(`=1') sink(`=2') silent
}
file close __fh
