* test_nwergm_est.do -- estimation methods: MPLE variants (Firth penalised, MPLE existence check, init()),
* checked against R ergm (4.13 development version for the penalised fit; 4.12.0 errors there).
* R scripts: dev/ergm_reference/ref_est_*.R
clear
set more off
capture program drop _chk
program _chk
	args what got want tol
	if abs(`got' - `want') > `tol' {
		di as err "FAIL `what': got `got', want `want'"
		exit 9
	}
end
mata: st_matrix("Aflo", colshape(strtoreal(substr("0000000010000000000001101000000000001000100000000000001000100010001000000010001001000000000000000101000100000001000000100000000011100000000011010000000000000100000110000000001000000000000000000000000010000011000000001100000000011000001010000000001010001000", 1::256, 1)), 16))
mata: st_matrix("Nflo", colshape(strtoreal(tokens("10 53 36 65 55 0 44 12 20 22 32 0 8 21 42 0 103 53 48 0 49 42 3 0 27 38 10 35 146 74 48 0")), 2))
mata: st_matrix("Asep", colshape(strtoreal(substr("010111000000101110000000010111000000111011000000111101000000101110000000000000011111000000101111000000110101000000111010000000110101000000111010", 1::144, 1)), 12))
mata: st_matrix("Nsep", colshape(strtoreal(tokens("1 1 1 1 1 1 2 2 2 2 2 2")), 1))
mata: st_matrix("Asam", colshape(strtoreal(substr("011010010001010000100000100001011000110000000000100011000011000110000000100100001010100000100110001000000000110000010001000100110101001100000000000010010001000100000110011000110000000110010000010100110000100000010000000010100000000001110000000011001000110010100001010000110000100001001000011000000000100001111000100000100010", 1::324, 1)), 18))
mata: st_matrix("Nsam", colshape(strtoreal(tokens("3 1 3 1 2 1 1 1 1 1 1 0 3 1 1 0 1 0 1 0 1 0 3 0 2 0 3 0 3 0 3 0 2 0 2 0")), 2))

* ---------- Florentine marriage (undirected): glm and Firth MPLE, edges + triangle + nodecov(wealth)
qui nwclear
qui nwset, mat(Aflo) undirected name(flo)
qui svmat Nflo, names(c)
qui rename c1 wealth
qui rename c2 priorates
nwergm flo, edges triangle nodecov(wealth) estimate(mple)
matrix b = e(b)
matrix V = e(V)
_chk flo_glm_edges b[1,1] -2.6029122101 1e-4
_chk flo_glm_wealth b[1,2] 0.0104713879 1e-4
_chk flo_glm_triangle b[1,3] 0.0362866329 1e-4
_chk flo_glm_se_edges sqrt(V[1,1]) 0.545451946 1e-4
nwergm flo, edges triangle nodecov(wealth) estimate(mple) mpletype(penalized)
matrix b = e(b)
matrix V = e(V)
_chk flo_pen_edges b[1,1] -2.5341883116 1e-4
_chk flo_pen_wealth b[1,2] 0.0101819180 1e-4
_chk flo_pen_triangle b[1,3] 0.0617104628 1e-4
_chk flo_pen_se_edges sqrt(V[1,1]) 0.535445596 1e-4
_chk flo_pen_se_triangle sqrt(V[3,3]) 0.438647201 1e-4

* ---------- Sampson (directed): glm and Firth
qui nwclear
qui clear
qui nwset, mat(Asam) directed name(sam)
qui svmat Nsam, names(c)
qui rename c1 grp
nwergm sam, edges mutual nodematch(grp) estimate(mple)
matrix b = e(b)
matrix V = e(V)
_chk sam_glm_edges b[1,1] -2.264157 1e-4
_chk sam_glm_mutual b[1,2] 1.432993 1e-4
_chk sam_glm_se_mutual sqrt(V[2,2]) 0.3395524 1e-4
nwergm sam, edges mutual nodematch(grp) estimate(mple) mpletype(penalized)
matrix b = e(b)
matrix V = e(V)
_chk sam_pen_edges b[1,1] -2.238965 1e-4
_chk sam_pen_mutual b[1,2] 1.419664 1e-4
_chk sam_pen_se_nodematch sqrt(V[3,3]) 0.3330225 1e-4

* ---------- separated data: R warns "The MPLE does not exist!" and reports the glm iterate; Firth is finite
qui nwclear
qui clear
qui nwset, mat(Asep) undirected name(sep)
qui svmat Nsep, names(c)
qui rename c1 g
nwergm sep, edges nodematch(g) estimate(mple)
matrix b = e(b)
matrix V = e(V)
_chk sep_glm_edges b[1,1] -20.31201 1e-3
_chk sep_glm_nodematch b[1,2] 22.18381 1e-3
_chk sep_glm_se sqrt(V[1,1]) 2602.54 0.1
nwergm sep, edges nodematch(g) estimate(mple) mplecheck(off)
matrix b = e(b)
_chk sep_glm_off_edges b[1,1] -20.31201 1e-3
nwergm sep, edges nodematch(g) estimate(mple) mpletype(penalized)
matrix b = e(b)
matrix V = e(V)
_chk sep_pen_edges b[1,1] -4.290459 1e-4
_chk sep_pen_nodematch b[1,2] 6.063526 1e-4
_chk sep_pen_se_nodematch sqrt(V[2,2]) 1.533748 1e-4

* ---------- init(): complete init skips the pseudolikelihood start; partial init holds the given values during that step
qui nwclear
qui clear
qui nwset, mat(Aflo) undirected name(flo)
qui svmat Nflo, names(c)
qui rename c1 wealth
nwergm flo, edges triangle nodecov(wealth) method(mcmle) seed(7) init(-2.6 0.0105 0.04)
assert e(mcmle_iterations) >= 1
capture nwergm flo, edges triangle nodecov(wealth) init(1 2)
assert _rc == 198
capture nwergm flo, edges triangle nodecov(wealth) init(1 x 2)
assert _rc == 198

display "PASS test_nwergm_est (MPLE variants)"
