
capture program drop nwcurrent
program nwcurrent
	syntax [anything(name=netname)] [,id(string)]
	unw_defs
	
	if ("`id'" != "") {
		mata: nw.nws.make_current(`id')
	}
	else if ("`netname'" != ""){
		nw_syntax `netname', max(1)
		mata: nw.nws.make_current_from_name("`netname'")
	}
	
	nw_syntax
	
	mata: st_rclear()
	mata: st_global("r(current)", `nws'.get_current_name())
	mata: st_numscalar("r(networks)", `nws'.get_number())
	mata: st_numscalar("r(nodes)", (*`netobj').get_nodes())
	di "{hline 40}"
	di "{txt}   Current network: {res} `r(current)'"
	di "{txt}   Number of nodes: {res} `r(nodes)'"
	di "{hline 40}"
		
end

