*! _nwtimeguard: refuse, at once, a command that would run for many minutes on this many nodes
*! Usage: _nwtimeguard, command(nwxxx) nodes(#) model(bfs|power) [ties(#) netobj(name of the network object) rate(#) base(#) exponent(#) alternative(text) force]
*! model(bfs):   one search through all ties from every node; seconds = nodes * 2 * ties / rate (rate = tie visits per second,
*!               measured on a 2020 laptop with 10 ties per node)
*! model(power): seconds = base * (nodes/20000)^exponent (base = seconds measured at 20,000 nodes with 10 ties per node)
*! The limit is nw_max_seconds (unw_defs.ado). Option force skips the test.
capture program drop _nwtimeguard
program _nwtimeguard
	syntax , COMmand(string) NODes(real) MODel(string) [TIes(real 0) RATe(real 1e9) BASe(real 1) EXPonent(real 2) ALTernative(string) NETobj(string) force]
	unw_defs
	if "`force'" != "" exit
	if `nodes' < 5000 exit
	if "`model'" == "bfs" {
		if `ties' == 0 & "`netobj'" != "" {
			mata: st_local("ties", strofreal(2 * `netobj'->get_edges_count()))
		}
		local sec = `nodes' * 2 * `ties' / `rate'
	}
	else {
		local sec = `base' * (`nodes' / 20000)^`exponent'
	}
	if `sec' > `nw_max_seconds' {
		if `sec' < 5400 local est "`=round(`sec'/60)' minutes"
		else local est "`=round(`sec'/360)/10' hours"
		display as error "{bf:`command'} on `nodes' nodes would take about `est' (estimated from measured run times) and is refused above `=round(`nw_max_seconds'/60, .1)' minutes."
		if `"`alternative'"' != "" {
			display as error "`alternative'"
		}
		display as error "Option {bf:force} runs it anyway."
		exit 484
	}
end
