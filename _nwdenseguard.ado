*! _nwdenseguard: refuse, at once, a command whose dense n x n work would not fit in memory
*! Usage: _nwdenseguard, command(nwxxx) nodes(#) copies(#) [alternative(text) force]
*! A Mata real matrix takes 8 bytes per cell; copies() is the number of n x n matrices the command holds at its
*! peak (measured). The limit is nw_max_dense_gb (unw_defs.ado). Option force skips the test.
capture program drop _nwdenseguard
program _nwdenseguard
	syntax , COMmand(string) NODes(real) COPies(real) [ALTernative(string) force]
	unw_defs
	if "`force'" != "" exit
	local gb = `copies' * 8 * `nodes'^2 / 1e9
	if `gb' > `nw_max_dense_gb' {
		display as error "{bf:`command'} holds about `copies' dense `nodes' x `nodes' matrices at once (about `=round(`gb', .1)' GB) and is refused above `nw_max_dense_gb' GB."
		if `"`alternative'"' != "" {
			display as error "`alternative'"
		}
		display as error "Option {bf:force} runs it anyway."
		exit 484
	}
end
