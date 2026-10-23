*! _nwsaom_postengine (split out of nwsaom.ado: a program of another ado-file is dropped without a trace when Stata evicts it, so cross-file helpers need their own file)
/* e(engine): "native" or "mata", the simulator the fit used (set by the
   estimators through SaomSetEngine(), unw_saom.do); e(engine_why): why
   Mata. A model the plugin covers must never fall back silently. */
capture program drop _nwsaom_postengine
program define _nwsaom_postengine, eclass
	capture mata: st_local("__eng", __nwsaom_engine)
	if _rc local __eng ""
	capture mata: st_local("__why", __nwsaom_engine_why)
	if _rc local __why ""
	ereturn local engine "`__eng'"
	ereturn local engine_why "`__why'"
end
