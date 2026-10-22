* network effects of a constant dyadic covariate (dyadx(): WWX cyWWX InWWX OutWWX WXX XWX XWX1 XWX2 XXW): the observed statistics and the estimates
* equal siena07 (s50, dev/saom_rsiena_dyadx.{R,do}); here: every effect fits natively, names, refusals
cscript
do unw_core.do
do unw_ergm.do
do unw_saom.do
nwclear
clear
set obs 40
mata:
mata set matastrict off
void dx_data() {
	n = 40
	rseed(8642)
	A = (runiform(n, n) :< 0.09)
	A = A - diag(diag(A))
	for (w=1; w<=3; w++) {
		st_matrix("__W" + strofreal(w), A)
		F = (runiform(n, n) :< 0.05)
		A = abs(A - F)
		A = A - diag(diag(A))
	}
	D = floor(runiform(n, n) :* 3)
	D = D - diag(diag(D))
	st_matrix("DW", D)
}
dx_data()
end
forvalues w = 1/3 {
	nwset, mat(__W`w') directed name(dx`w') nooutput
}
foreach ef in wwx cywwx inwwx outwwx wxx xwx xwx1 xwx2 xxw {
	capture nwsaom, waves(dx1 dx2 dx3) outdegree reciprocity dyadx(`ef':DW) k0(10) k3(40) seed(3)
	assert inlist(_rc, 0, 498)
	if _rc == 0 {
		assert "`e(engine)'" == "native" & colsof(e(b)) == 3
		local nm : colnames e(b)
		assert strpos("`nm'", "`ef'_DW") > 0
	}
}
capture noisily nwsaom, waves(dx1 dx2 dx3) outdegree dyadx(nosuch:DW) k3(50)
assert _rc == 198
capture noisily nwsaom, waves(dx1 dx2 dx3) outdegree dyadx(wwx:NOMAT) k3(50)
assert _rc == 111
matrix SM = J(5, 5, 1)
capture noisily nwsaom, waves(dx1 dx2 dx3) outdegree dyadx(wwx:SM) k3(50)
assert _rc == 198
di "PASS dyadx"
