* Common header of every Stata benchmark do-file: clean PLUS, stale nwinstall removed, trees on the adopath.
* Environment: BENCH_PLUS (empty scratch PLUS directory), BENCH_ADOPATH (colon-separated list of directories).
capture program drop nwinstall
local plus : env BENCH_PLUS
sysdir set PLUS "`plus'"
sysdir set PERSONAL "`plus'/pers"
local paths : env BENCH_ADOPATH
while `"`paths'"' != "" {
	gettoken p paths : paths, parse(":")
	if `"`p'"' != ":" adopath ++ `"`p'"'
}
local nwc : env NWC
global nwwebpath "`nwc'/data"
nwclear
