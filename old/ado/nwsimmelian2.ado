capture program drop nwsimmelian
program nwsimmelian
	syntax [anything(name=netname)] [, name(string) nwreplace]
	nw_syntax `netname'
	
	if "`name'" == "" {
		local name "_simmelian"
	}
	nwvalidate `name'
	if "`r(exists)'" == "true" & "`nwreplace'" == "" {
		noi di "{err}No, network {bf:`name'} already exists; use differentname or option {bf:nwreplace}."
		error 3000
	}
	capture nwdrop `name'
	nwduplicate `netname', name(`name')
	nw_syntax
	mata: __nw_mutual = (*`netobj'->get_matrix_unvalued()) :* (*`netobj'->get_matrix_unvalued())'
	mata: __nw_mutual
	mata: __nw_simmel = (__nw_mutual) :* (__nw_mutual * __nw_mutual)
	mata: __nw_simmel = (__nw_simmel :!= 0)
	mata: __nw_simmel
	mata: `netobj'->set_edge(__nw_simmel)
	capture mata: mata drop __nw_simmel __nw_mutual
end
