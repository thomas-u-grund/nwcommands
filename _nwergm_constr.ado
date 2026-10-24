*! _nwergm_constr: parse nwergm's constraints() / obsconstraints() formula (R ergm's sample-space constraints)
capture program drop _nwergm_constr
program _nwergm_constr
	version 14
	syntax , SPEC(string asis) NODES(integer) DIRECTED(string) TWOMODE(string) MATOBJ(string) [WEIGHTS(string) PREFIX(string)]
	if "`weights'" == "" local weights "default"
	local dir = ("`directed'" == "true")
	local bip = ("`twomode'" == "true")
	if `bip' {
		mata: _ergm_con_init(`nodes', `dir', `bip', strtoreal(`matobj'->get_modes())', *(`matobj'->get_matrix_mod(0,`dir')))
	}
	else {
		mata: _ergm_con_init(`nodes', `dir', `bip', J(`nodes',1,1), *(`matobj'->get_matrix_mod(0,`dir')))
	}
	mata: _ergm_con_split(`"`spec'"')
	forvalues t = 1/`__cn' {
		local sg  `__cs`t''
		local nm  `__cnm`t''
		local ar `"`__car`t''"'
		if inlist("`nm'", "fixedas", "fixallbut") {
			forvalues k = 1/3 {
				local __cb`k' ""
			}
			mata: _ergm_con_netnames(`"`nm'"', `"`ar'"')
			forvalues k = 1/`__cbn' {
				if `"`__cb`k''"' != "" {
					_nwsyntax `__cb`k'', max(1) other(cb)
					if `cbnodes' != `nodes' {
						di "{txt}Warning: network size of argument {bf:`__cb`k''} differs from that of the response network."
					}
					mata: __ncon_net`k' = *(`cbnetobj'->get_matrix_mod(0,`dir'))
				}
			}
		}
		mata: _ergm_con_apply(`"`nm'"', `sg', `"`ar'"')
	}
	mata: _ergm_con_finish("`weights'")
	if `"`__con_err'"' != "" {
		di as err `"`__con_err'"'
		error 198
	}
	foreach v in code dind implies maxonly hasdyad hasbd {
		c_local `prefix'con_`v' `"`__con_`v''"'
	}
end
