* validation of nwsaom ..., ml and nwsaom bayes with a co-evolving behavior against RSiena (dev/saom_ml_coev.R). args: seed what (ml|bayes) opts
args seed what opts
do unw_core.do
do unw_ergm.do
do unw_saom.do
nwwebuse glasgow, nwclear
if "`what'" == "ml" {
	nwsaom, waves(glasgow1 glasgow2 glasgow3) outdegree reciprocity transtrip behsim behavior(alcohol1 alcohol2 alcohol3) linear quadratic avalt k3(500) seed(`seed') ml mloptions(seed(`seed') `opts')
	di "MLRESULT seed `seed' secs " scalar(__saom_ml_secs)
	matrix list e(b)
	matrix list e(rates_ml)
	matrix list e(rates_beh_ml)
	matrix V = e(V)
	matrix SE = vecdiag(V)
	forvalues k = 1/`=colsof(SE)' {
		matrix SE[1,`k'] = sqrt(SE[1,`k'])
	}
	matrix list SE
}
else {
	nwsaom, waves(glasgow1 glasgow2 glasgow3) outdegree reciprocity transtrip behsim behavior(alcohol1 alcohol2 alcohol3) linear quadratic avalt k3(500) seed(`seed')
	nwsaom bayes, seed(`seed') `opts'
	di "BAYESRESULT seed `seed'"
}
