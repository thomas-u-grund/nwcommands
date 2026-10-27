* Model definitions shared by nwsaom_bench.do and cores_bench.do: one local
* cmd_<model> per model (the nwsaom options) and _bench_data, which loads the
* data a model needs. Use with -include-, so that the locals reach the caller.
local w3 "waves(glasgow1 glasgow2 glasgow3)"
local cmd_N1 "wave1(glasgow1) wave2(glasgow2) outdegree reciprocity"
local cmd_N2 "`w3' outdegree reciprocity gwesp(.69)"
local cmd_N4 "`w3' outdegree reciprocity gwesp(.69) samex(smoke1)"
local cmd_N5 "`w3' outdegree reciprocity gwesp(.69) indegpopularity outactivity"
local cmd_N6 "`w3' outdegree reciprocity gwesp(.69) egox(alcohol1) altx(alcohol1) simx(alcohol1)"
local cmd_N7 "`w3' outdegree reciprocity gwesp(.69) unconditional"
local cmd_U1 "wave1(u1) wave2(u2) outdegree"
local cmd_U2 "wave1(u1) wave2(u2) outdegree symtype(joint)"
local cmd_C1 "`w3' outdegree reciprocity gwesp(.69) behsim behavior(alcohol1 alcohol2 alcohol3) linear quadratic avalt"
local cmd_C2 "`w3' outdegree reciprocity gwesp(.69) behsim behavior(smoke1 smoke2 smoke3) linear quadratic avsim"
local cmd_C3 "waves(glasgow1 glasgow2) outdegree reciprocity behsim behavior(alcohol1 alcohol2) linear avalt"
local cmd_S100 "waves(t1 t2 t3) outdegree reciprocity gwesp(.69)"
local cmd_S200 "`cmd_S100'"
local cmd_S500 "`cmd_S100'"
local cmd_T200 "waves(t1 t2 t3) outdegree reciprocity gwesp(.69) behsim behavior(a1 a2 a3) linear quadratic avalt"
local rn "outdegree reciprocity gwesp(.69) transrectrip indegpopularity outpopularity samex(smoke1)"
local cmd_R1 "`w3' `rn' egox(alcohol1) altx(alcohol1) simx(alcohol1)"
local cmd_R2 "`w3' `rn' behsim behavior(alcohol1 alcohol2 alcohol3) linear quadratic avalt"
local cmd_R3 "wave1(u1) wave2(u2) outdegree gwesp(.69) samex(smoke1) simx(alcohol1)"
local cmd_R4 "waves(t1 t2 t3) `rn' egox(alc1) altx(alc1) simx(alc1)"
local cmd_R4 : subinstr local cmd_R4 "samex(smoke1)" "samex(smk1)"
local cmd_R5 "waves(t1 t2 t3) `rn' behsim behavior(a1 a2 a3) linear quadratic avalt"
local cmd_R5 : subinstr local cmd_R5 "samex(smoke1)" "samex(smk1)"

capture program drop _bench_data
program define _bench_data
	args m
	if substr("`m'", 1, 1) == "S" | substr("`m'", 1, 1) == "T" | inlist("`m'", "R4", "R5") {
		local n = cond(inlist("`m'", "R4", "R5"), 200, real(substr("`m'", 2, .)))
		local k = `n' / 50
		qui nwwebuse glasgow, nwclear
		forvalues t = 1/3 {
			qui nwtomata glasgow`t', mat(__g`t')
			mata: __a`t' = st_data(., "alcohol`t'")
		}
		mata: __s1 = st_data(., "smoke1")
		clear
		qui nwclear
		forvalues t = 1/3 {
			mata: __G = I(`k') # __g`t'
			qui nwset, mat(__G) directed name(t`t')
		}
		* behavior in the networks' node order (node labels are n1..nN)
		qui gen long __idx = real(substr(_nwnode, 2, .))
		forvalues t = 1/3 {
			mata: __v = J(`k', 1, 1) # __a`t'
			qui gen a`t' = .
			mata: st_store(., "a`t'", __v[st_data(., "__idx")])
		}
		mata: __v = J(`k', 1, 1) # __s1
		qui gen smk1 = .
		mata: st_store(., "smk1", __v[st_data(., "__idx")])
		qui gen alc1 = a1
		drop __idx
	}
	else {
		qui nwwebuse glasgow, nwclear
		if substr("`m'", 1, 1) == "U" | "`m'" == "R3" {
			qui nwsym glasgow1, generate(u1) mode(max)
			qui nwsym glasgow2, generate(u2) mode(max)
		}
	}
end
