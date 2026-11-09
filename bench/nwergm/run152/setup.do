* setup.do: called at the top of every do-file in stata/. Run the do-files from the folder replication/
* (the folder of README.md), for example:  stata -e do stata/01_compare_estimates.do
* By default the installed packages are used (see README.md). To use source trees instead, set the globals
* NWPLUS (a PLUS folder without other copies), NWCORE and NWERGM before running a do-file.
clear all
set more off
set linesize 120
if `"$NWPLUS"' != "" sysdir set PLUS `"$NWPLUS"'
foreach t in NWCORE NWERGM {
	if `"${`t'}"' != "" {
		adopath ++ `"${`t'}"'
		adopath ++ `"${`t'}/lib"'
		adopath ++ `"${`t'}/lib/plugins/macos"'
	}
}
capture mkdir results
* expnet: writes the adjacency matrix of a network as a CSV file without header (as read by R/common.R)
capture program drop expnet
program expnet
	args name file
	_nwsyntax `name', max(1)
	mata: M = *`netobj'->get_matrix_mod(1, 1)
	mata: _editmissing(M, 0)
	capture erase "`file'"
	mata: fh = fopen("`file'", "w")
	mata: for (i = 1; i <= rows(M); i++) fput(fh, invtokens(strofreal(M[i, .]), ","))
	mata: fclose(fh)
	mata: st_local("nt", strofreal(sum(M)))
	display "exported `file': sum of cells = `nt'"
end
