cscript

do unw_core.do

* Long messages are printed as SMCL paragraphs ({p 0 0 2}...{p_end}), so that Stata wraps them at word boundaries.
* A plain display line longer than the linesize is cut at the column, in the middle of a word, and continued on
* a line starting with "> ". The helper runs a command at linesize 80 with its output written to a text log and
* checks that (1) no output line is such a "> " continuation line and (2) each needle (a piece of the message that
* the hard cut used to split) appears whole on one line.

capture program drop msgwrap_chk
program define msgwrap_chk
	gettoken cmd needles : 0
	local ls = c(linesize)
	set linesize 80
	tempfile lg
	quietly log using `"`lg'"', text replace name(msgwrap)
	capture noisily `cmd'
	local rc = _rc
	quietly log close msgwrap
	set linesize `ls'
	tempname fh
	local cont 0
	local nn : word count `needles'
	forvalues i = 1/`nn' {
		local found`i' 0
	}
	file open `fh' using `"`lg'"', read text
	file read `fh' line
	while r(eof) == 0 {
		if substr(`"`macval(line)'"', 1, 2) == "> " local cont 1
		forvalues i = 1/`nn' {
			local nd : word `i' of `needles'
			if strpos(`"`macval(line)'"', `"`nd'"') > 0 local found`i' 1
		}
		file read `fh' line
	}
	file close `fh'
	if `cont' {
		di as error "FAIL: {it:`cmd'} (rc `rc'): a message line was cut at the linesize"
		type `"`lg'"'
		exit 9
	}
	forvalues i = 1/`nn' {
		if !`found`i'' {
			local nd : word `i' of `needles'
			di as error `"FAIL: {it:`cmd'} (rc `rc'): "`nd'" not found on one line"'
			type `"`lg'"'
			exit 9
		}
	}
	di as text "  PASS: `cmd' (rc `rc')"
end

nwclear
set seed 20261111

* nwcug: the plot-saved note, the long statistic in the header (hanging indent), the census note
nwset, mat((0,1,1,0,0,0\1,0,1,0,0,0\1,1,0,0,0,0\0,0,0,0,1,1\0,0,0,1,0,1\0,0,0,1,1,0)) name(cugnet) undirected
msgwrap_chk "nwcug cugnet, stat(nwcomponents ##net##, generate(_component) replace) rname(components) reps(20) seed(1) plot name(cugwrapplot)" "dashed line marks the observed value)"
capture graph drop cugwrapplot
msgwrap_chk "nwcug cugnet, stat(nwclustering ##net##, generate(_clustering) replace) rname(cluster_global) reps(20) seed(1)" "Statistic: r(cluster_global) after nwclustering cugnet," "           replace"
nwset, mat((0,1,1,0\1,0,0,1\0,1,0,1\1,0,0,0)) name(dyadnet)
msgwrap_chk "nwcug dyadnet, stat(nwdyads ##net##) rname(reciprocity) reps(20) seed(1) condition(census)" "test is uninformative."

* nwqap: the plot-saved note
nwset, mat((0,1,0,1,0\1,0,1,0,1\0,1,0,0,1\1,0,0,0,0\0,1,1,0,0)) name(qapiv) undirected labs(A,B,C,D,E)
nwset, mat((0,2,0,2,0\2,0,2,0,2\0,2,0,0,2\2,0,0,0,0\0,2,2,0,0)) name(qapdv) undirected labs(A,B,C,D,E)
msgwrap_chk "nwqap qapdv qapiv, permutations(20) type(regress) plot name(qapwrapplot)" "QAP-permutation draws," "dashed line marks the observed coefficient)"
capture graph drop qapwrapplot

* nwplot on a signed network: the layout note
nwset, mat((0,1,-1,0\1,0,2,0\-1,2,0,1\0,0,1,0)) name(signednet) undirected
msgwrap_chk "nwplot signednet, layout(kk)" "(as igraph, whose layouts need positive weights)"
capture graph drop _all

* two-mode network refused by a command that offers onemode: the guard message with its tail
nwclear
nwuse data/davis, nwclear
msgwrap_chk "nwspectral davis" "which hold no ties." "The option onemode reads the two-mode network as a"

* nwuse of a plain Stata dataset
nwclear
clear
msgwrap_chk "nwuse data/example1, nwclear" "with nwfromedge or nwgenerate)"

di as result "ALL TESTS PASSED"
