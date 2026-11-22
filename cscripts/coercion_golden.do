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
}
file close __fh
