adopath ++ "/private/tmp/claude-501/-Users-tgrund-FILES-NEW-SOFTWARE-nwcommands/f80eded9-2ca1-45e7-9a6b-23ada6a895b2/scratchpad/plugdev8"
* homXTransRecTrip sameXTransRecTrip diffXTransRecTrip egoXaltXRecip sameXCycle4 sameInXCycle4 avGroupEgoX totGroupEgoX (netx(), netbeh(), tvcov()), plugin protocol 50.
* siena07 agreement (observed statistics and estimates): dev/saom_rsiena_nx2.{R,do} equivalents (s50 age, _tv, alcohol, symmetric waves)
cscript
do unw_core.do
do unw_ergm.do
do unw_saom.do
nwclear
clear
set obs 40
mata:
mata set matastrict off
void cz_data() {
	n = 40
	rseed(777)
	A = (runiform(n, n) :< 0.10)
	A = A - diag(diag(A))
	for (w=1; w<=3; w++) {
		st_matrix("__W" + strofreal(w), A)
		B = ((A + A') :> 0)
		st_matrix("__S" + strofreal(w), B)
		F = (runiform(n, n) :< 0.04)
		A = abs(A - F)
		A = A - diag(diag(A))
	}
}
cz_data()
end
forvalues w = 1/3 {
	nwset, mat(__W`w') directed name(cd`w') nooutput
	nwset, mat(__S`w') directed name(cs`w') nooutput
}
gen double xa = mod(_n * 7, 4)
gen double tw1 = mod(_n, 4)
gen double tw2 = mod(_n + (_n > 20), 4) + 1
gen double tw3 = mod(_n + (_n > 20) + (_n > 10), 4)
gen double z1 = mod(_n * 7, 5)
gen double z2 = mod(_n * 7 + (_n > 20), 5)
gen double z3 = mod(_n * 7 + (_n > 20) + (_n > 10), 5)
nwsaom, waves(cd1 cd2 cd3) outdegree reciprocity netx(homxtransrectrip:xa) k0(10) k3(30) seed(3)
di "RC " _rc " " e(engine) " " colsof(e(b))
