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


* ---------- estat gof: observed values equal R's gof() (florentine: undirected; sampson: directed)
capture program drop _chkvec
program _chkvec
	args mname want
	local i 0
	foreach w of local want {
		local ++i
		if abs(`mname'[`i',1] - `w') > 1e-9 {
			di as err "FAIL gof `mname' row `i': got " `mname'[`i',1] ", want `w'"
			exit 9
		}
	}
end
qui nwclear
qui clear
qui nwset, mat(Aflo) undirected name(flo)
qui nwergm flo, edges triangle estimate(mple)
qui estat gof, gof(degree espartners dspartners distance triadcensus model) nsim(30) seed(11) gofburnin(2000)
matrix G = r(gof_degree)
_chkvec G "1 4 2 6 2 0 1 0 0 0 0 0 0 0 0 0"
matrix G = r(gof_espartners)
_chkvec G "12 7 1 0 0 0 0 0 0 0 0 0 0 0 0"
matrix G = r(gof_dspartners)
_chkvec G "77 39 4 0 0 0 0 0 0 0 0 0 0 0 0"
matrix G = r(gof_distance)
_chkvec G "20 35 32 15 3 0 0 0 0 0 0 0 0 0 0 15"
matrix G = r(gof_triadcensus)
_chkvec G "324 195 38 3"
matrix G = r(gof_model)
_chkvec G "20 3"
assert r(sim_meandeg) > 0
qui nwclear
qui clear
qui nwset, mat(Asam) directed name(sam)
qui nwergm sam, edges mutual estimate(mple)
qui estat gof, gof(idegree odegree espartners dspartners distance triadcensus model) nsim(20) seed(12) gofburnin(2000)
matrix G = r(gof_idegree)
_chkvec G "0 0 3 5 1 3 2 1 1 0 1 1 0 0 0 0 0 0"
matrix G = r(gof_odegree)
_chkvec G "0 0 0 1 5 7 5 0 0 0 0 0 0 0 0 0 0 0"
matrix G = r(gof_espartners)
_chkvec G "19 23 20 14 11 1 0 0 0 0 0 0 0 0 0 0 0"
matrix G = r(gof_dspartners)
_chkvec G "101 96 63 30 14 2 0 0 0 0 0 0 0 0 0 0 0"
matrix G = r(gof_distance)
_chkvec G "88 136 77 5 0 0 0 0 0 0 0 0 0 0 0 0 0 0"
matrix G = r(gof_triadcensus)
_chkvec G "167 205 190 12 24 24 68 34 5 0 35 15 6 5 18 8"
* the MC p-values are in [0,1] and the observed value lies between min and max of a well-fitting model's draws for the edge count
matrix G = r(gof_model)
assert G[1,5] >= 0 & G[1,5] <= 1
capture estat gof, gof(bogus)
assert _rc == 198

* ---------- simulate from the fit: statistics agree with R's simulate() at the same coefficients (4000 draws there)
qui nwclear
qui clear
qui nwset, mat(Aflo) undirected name(flo)
qui svmat Nflo, names(c)
qui rename c1 wealth
qui nwergm flo, edges triangle nodecov(wealth) estimate(mple)
matrix CO = (-2.5749662, 0.01100831, -0.12030239)
nwergm simulate, nsim(1500) output(stats) seed(5) burnin(16384) interval(1024) coef(CO)
matrix S = r(stats)
mata: S = st_matrix("S"); st_matrix("MU", mean(S)); st_matrix("SD", sqrt(diagonal(variance(S)))')
_chk sim_mean_edges MU[1,1] 20.19475 0.7
_chk sim_mean_wealth MU[1,2] 2198.384 100
_chk sim_mean_triangle MU[1,3] 3.103 0.4
_chk sim_sd_edges SD[1,1] 3.841486 0.4
_chk sim_sd_wealth SD[1,2] 433.4497 45
_chk sim_sd_triangle SD[1,3] 2.420611 0.3
nwergm simulate, nsim(2) generate(simz) seed(2)
nwsummarize simz_1
assert r(nodes) == 16
nwergm simulate, nsim(2) output(edgelist) clear seed(3)
assert _sim[_N] == 2

* ---------- mcmc.diagnostics() building blocks agree with R (ergm 4.12.0, coda) on a fixed autocorrelated sample
mata: SS = colshape(strtoreal(tokens("0 0 5 -0.564698 0.252911 8.66061 0.108774 1.17864 48.3398 0.927328 1.74099 96.2255 1.25322 0.630797 185.769 0.696775 2.20661 229.974 2.3291 0.369194 -40.4475 1.23689 1.25766 139.395 2.93788 1.07114 162.409 1.73797 -0.849889 61.9457 2.0734 -1.69869 -94.026 3.06654 0.113099 -20.226 0.289691 2.18844 4.01414 0.315332 1.44672 154.15 0.326303 2.08542 130.416 1.22924 2.35925 108.19 0.851386 0.822154 341.185 -2.03228 1.04897 48.0647 -3.3281 0.0236846 107.41 -0.472325 0.345559 135.61 -0.492582 1.18034 150.042 -1.81123 0.963925 188.906 -0.957199 -0.157304 136.239 0.666327 0.695569 216.094 2.39412 0.351631 -82.7489 0.932684 0.878984 -144.313 0.422177 -0.0625074 -99.4499 -1.54769 -0.168981 -55.5765 -0.409451 0.177481 9.15089 -0.825602 -0.404704 77.846 -0.0713158 0.355892 -98.0001 0.737505 0.874119 -58.7872 1.60818 0.588151 25.8231 0.377121 1.51987 154.324 1.01257 2.58688 126.304 -0.652843 0.50627 295.49 -1.03574 -0.511824 194.233 -1.51257 0.0448747 128.451 -3.22202 -1.6584 117.41 -2.03545 -1.61575 19.6131 -1.21629 -0.253444 66.7207 -1.06854 -0.898227 -84.1454 0.00150371 -2.41251 -69.5194 -1.20839 -0.978975 -149.477 -2.21661 -2.85107 -170.17 -1.33436 -3.24478 -46.1964 -2.18091 -5.27907 17.495 -0.789403 -1.92358 81.0531 -1.24244 -0.967902 -1.87769 -0.20885 -0.029068 -8.4777 0.203333 0.888223 -158.921 -0.496395 0.0791338 -132.018 1.3235 -0.781157 90.0631 1.20136 0.552493 -0.672723 0.848993 1.76857 -111.763 1.08872 -0.448533 -42.2673 1.17749 -0.579712 81.0588 0.609736 -0.381996 -118.215 -2.74023 -2.45645 -117.931 -1.68613 -1.02588 -66.9563 -1.48292 -1.54465 141.983 -0.924477 0.418368 17.3319 0.16628 0.371132 179.489 1.56375 1.54896 90.2776 0.426927 2.47075 -16.8108 2.02723 2.06601 -76.8477 1.84376 2.47965 -45.2464 2.53006 2.06711 6.11652 2.70038 0.206609 -0.346858 2.22041 0.651463 94.4094 0.286194 1.10811 86.2475 0.285981 1.19625 71.7356 1.0172 0.781831 13.6685 -0.247871 -0.943337 -109 -0.865346 -0.186481 -288.112 0.0764134 -1.23662 -177.375 0.562119 -1.88769 -145.32 0.389773 -0.410412 -4.84804 -0.757381 -1.69457 16.6689 -1.84768 -1.10769 63.5429 0.293423 -0.312117 39.011 0.353946 -1.35874 -61.0275 0.00782231 0.418946 -41.5538 -0.0328833 -0.440142 14.7231 -1.30011 0.60124 -78.5387 0.0301833 -0.183891 -36.5265 -0.237619 -0.781324 172.151 -0.467336 -0.383057 -5.1219 0.604373 -0.355029 140.275 1.07713 -0.10592 66.2591 1.95258 -0.337447 187.531 0.510731 -1.1435 30.0021 0.697443 0.250236 -10.0524 1.81778 -0.185677 26.4067 -0.166325 -1.58868 -5.89453 -1.26834 -1.68527 32.4722 -2.1537 -2.19879 -18.5509 -3.06197 -4.12664 78.3481 -2.39881 -2.84745 9.2247 -1.21164 -1.49588 34.6431 0.247503 -0.288771 -115.452 1.12065 0.451723 -152.416 -0.307714 -1.08074 6.07019 1.46617 -0.409793 36.8591 0.0429983 -1.2418 -3.28215 -0.119626 -1.30265 -36.7697 -0.747384 -2.12117 25.916 -0.950171 -2.40381 -40.679 -0.805662 -0.811895 -61.855 -0.478276 -0.848524 -217.798 -0.453066 -1.01791 12.3416 -0.340164 1.14855 69.0961 -0.439414 0.465163 158.108 -0.648468 -0.323944 -66.4304 -2.07606 -0.0765104 -49.673 -1.51871 -0.931996 -63.2383 -1.51915 0.458862 -189.933 1.97332 0.324779 -40.418 -0.231567 -0.667317 91.2761 -0.121253 -1.44031 -1.88609 -1.84716 -0.946484 -50.8179 -2.6572 0.232648 129.227 -1.26366 -0.361695 -52.4257 -1.75135 -0.439029 39.5721 -1.03536 -0.0746533 -0.474118 -1.00228 1.13048 -5.64388 -0.928809 0.989942 -34.9249 -2.32825 -1.27064 112.094 -2.73613 -1.92956 -44.1945 -1.6839 -2.12847 44.6505 -0.767382 -1.02903 140.936 -1.11307 -0.678078 -79.9862 -0.73661 -0.221417 -174.064 0.680837 -0.706034 -61.1989 1.6663 -0.329714 -155.176 -0.263254 0.254036 -192.868 -0.20867 -0.219895 -171.383 1.04484 -0.616735 -156.062 -0.0288643 0.440833 -55.9775 0.0201105 0.180412 -88.995 -0.0391653 -0.933079 -48.3739 -1.09544 0.8631 22.9612 -0.863604 -0.922899 -112.63 -0.680371 -2.52105 -159.581 -1.28548 -4.02986 -70.566 -0.386745 -1.49112 -158.433 -0.988059 -1.71891 -390.413 -1.3105 -1.87417 -386.02 -0.385643 -1.08865 -216.732 -1.48235 -1.65796 -212.33 -1.17276 -2.93208 -211.86 -2.77125 -4.40542 -212.984 -1.21039 -2.98595 -147.123 -1.52445 -1.86719 -203.052 -1.66448 -3.84255 -121.237 -2.90558 -2.54544 -92.9149 -2.08586 -1.42881 -198.902 -2.21241 -0.182997 -159.979 -1.76479 -0.510581 -154.702 0.232571 -0.0520275 -64.7185 -0.0603432 0.47914 -197.067 -1.00854 -0.281182 27.4153 -0.437641 -0.278755 155.72 -0.654816 -0.0472358 23.2692 0.226966 0.839655 -46.2148 1.72291 0.442848 -106.268 0.026251 -0.467643 -88.022 0.375297 -1.08073 -119.73 0.0714128 -1.62019 -94.9132 0.61009 -0.403753 -285.293 0.0189198 1.03037 -194.086 1.05291 -0.337832 -112.31 -1.24405 -0.900527 -250.252 0.837566 -1.42204 -156.625 1.03265 0.303358 -136.109 0.467529 -0.218186 -116.962 -1.24018 -0.447481 -88.864 -0.116184 0.0575775 -23.7184 0.43197 -0.918808 21.4181 0.0431465 -0.556385 -47.6366 0.063478 -0.542286 71.7856 -0.658288 0.270338 36.8701 0.0673989 -1.01307 23.0854 0.128435 -1.65325 91.4558 -0.540554 -0.142891 130.888 -1.65671 -1.00364 23.4398 -0.394605 -1.17922 -91.3306 0.105265 -0.521619 -154.21 -0.883787 -1.01082 -235.089 -2.274 0.482874 -356.095 -0.926425 -0.0243543 -193.405 -0.850228 -0.257769 -143.323 -0.258065 0.61896 -34.6249 -1.30957 -0.170058 -8.97581 -1.70035 -0.494891 40.5895 0.0686089 -1.17913 -19.3889 0.204997 -2.84886 -132.077 0.127415 -2.74074 -71.348 1.33588 -0.938213 -27.9108 0.662557 -1.40334 -218.188 -1.92382 -0.846324 -95.5446 -0.874349 0.0352624 -248.102 0.706229 0.237496 -170.789 2.4884 0.452512 -157.027 0.0573779 -1.40867 -127.105 -1.40161 -1.56873 -6.36705 -1.77643 -1.71148 -151.444 -2.35563 -0.966822 -154.63 -2.11115 0.150026 143.387 -1.29539 0.43138 -30.2926 -1.81446 -1.42746 -65.9636 0.771673 1.20853 -66.4422 0.766184 1.73445 -5.47367 0.676521 1.24492 -25.5703 1.10992 -1.31544 -22.1632 0.373685 -1.58286 61.4321 -0.24687 -0.896317 -7.47142 1.16421 0.662284 4.98041 0.544102 -0.743762 48.2009 -1.13854 2.51375 57.8042 0.273607 -1.10514 148.32 -0.424792 -0.7863 87.0427 -0.908444 -0.821964 -21.6148 -1.72308 -1.57247 -30.446 -0.816593 -1.29949 -137.265 -0.874877 -0.27125 -106.337 -0.0110158 -1.08082 -107.902 -0.456477 -2.87252 -107.415 -1.4795 -1.87593 -238.311 0.0761181 -1.08629 -222.267 -0.447917 -0.921691 -285.243 0.521738 0.095797 -254.483 -0.900684 -0.521044 -125.162 -1.05669 0.113389 -67.088 -0.817289 -2.21848 52.9826 -1.276 -2.53137 47.9188 0.153394 -0.76415 3.2708 -0.092762 -0.772201 87.4175 0.0396941 0.657638 166.977 -0.789409 -0.752732 -8.64061 -1.30604 -0.0184467 74.3482 0.289115 -0.456671 138.807 1.32327 -0.825044 181.988 1.79842 -0.104976 13.571 -0.430485 -0.213204 239.003 1.77486 -0.5463 -92.3043 1.86604 -0.663392 -84.0018 0.848264 -1.5057 -69.9547 0.86053 0.404714 -97.6416 -0.425757 0.652574 10.8693")), 3)
mata: infl = .; rnk = .; MV = ergm_spec0_mvar(SS, infl, rnk); st_matrix("MV", MV); st_numscalar("INFL", infl)
_chk mv11 MV[1,1] 7.15289449897 1e-6
_chk mv23 MV[2,3] 482.756778989 1e-4
_chk mv33 MV[3,3] 75849.281767636 1e-3
_chk infl INFL 3.73561295233 1e-7
mata: T2=.; prm=.; df=.; pv=.; VV=.; ergm_hotelling(SS, J(0,3,.), J(1,3,0), T2, prm, df, pv, VV); st_numscalar("T2", T2); st_numscalar("DF", df); st_numscalar("PV", pv)
_chk hotelling_T2 T2 6.245071847218 1e-6
_chk hotelling_df DF 65.923421454588 1e-5
_chk hotelling_p PV 0.120163975427 1e-6
mata: st_matrix("GZ", ergm_geweke_z2(SS, 0.1, 0.5)); st_numscalar("GP", ergm_geweke_mv(SS, 0.1, 0.5))
_chk geweke_z1 GZ[1,1] 1.46979845927 1e-6
_chk geweke_z2 GZ[1,2] 4.55059844875 1e-6
_chk geweke_z3 GZ[1,3] 5.80176335948 1e-6
_chk geweke_joint GP 0.00301436100697 1e-6
mata: st_matrix("AC", ergm_autocorr(SS, 5)[., 2]')
_chk acf_lag1 AC[1,2] 0.621993251664 1e-6
_chk acf_lag3 AC[1,4] 0.289285246291 1e-6
mata: st_numscalar("SP3", ergm_spec0_ar(SS[., 3]))
_chk spec0ar3 SP3 84395.64350873492 1e-2

display "PASS test_nwergm_est"
