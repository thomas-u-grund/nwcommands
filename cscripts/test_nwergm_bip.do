cscript

do unw_core.do
do unw_ergm.do
* Cross-validation of the bipartite (two-mode) terms against R ergm 4.12.0 (tag bip).
* For every case: the observed statistic (summary() in R) and, where R's pseudolikelihood is well identified, the MPLE coefficients and standard errors.
* Constants were produced by dev/bip_ref.R (networks from dev/bip_gen.R); the Stata run is dev/bip_run.do.
capture program drop _bipcase
program define _bipcase
	args net opts nstat statlist blist selist
	capture noisily nwergm `net', edges `opts' method(mple)
	if _rc {
		di as err "FAIL (error) `net': `opts'"
		exit 9
	}
	mata: st_matrix("__sst", __nwergm_last_M.full_statistic(__nwergm_last_G))
	local ok = 1
	local k = 0
	foreach s of local statlist {
		local ++k
		if abs(__sst[1,`=`k'+1'] - `s') > 1e-4 * max(1, abs(`s')) local ok = 0
	}
	if colsof(__sst) != `nstat' + 1 local ok = 0
	if `ok' == 0 {
		di as err "FAIL (statistic) `net': `opts'"
		matrix list __sst
		exit 9
	}
	if "`blist'" != "" {
		matrix b = e(b)
		matrix V = e(V)
		local k = 0
		foreach x of local blist {
			local ++k
			local se : word `k' of `selist'
			if abs(b[1,`=`k'+1'] - `x') > 1e-4 | abs(sqrt(V[`=`k'+1',`=`k'+1']) - `se') > 1e-3 * max(1, `se') {
				di as err "FAIL (MPLE) `net': `opts'"
				matrix list b
				exit 9
			}
		}
	}
end

* ---- network A: 12 x 10
mata: BA = J(10, 12, 0)
mata: peA = (1\2\7\10\1\2\3\8\11\11\12\2\3\6\7\1\3\4\7\8\3\8\2\3\6\7\8\10\1\7\12\8\3\5\9)
mata: evA = (1\1\1\1\2\2\2\2\2\3\3\4\4\4\4\5\5\5\5\5\6\6\7\7\7\7\7\7\8\8\8\9\10\10\10)
mata: for (k=1;k<=35;k++) BA[evA[k],peA[k]] = 1
nwset, mat(BA) bipartite name(bipA) nooutput
clear
set obs 22
gen g = .
mata: st_store(., "g", (1\3\3\1\2\2\2\3\2\3\2\2\2\3\1\2\1\3\3\2\1\1))
gen x = .
mata: st_store(., "x", (40.36\66.92\56.36\39.7\39.95\46.28\71.13\58.5\20.13\35.49\39.98\45.68\58.91\42.89\28.28\60.16\46.55\47.05\44.81\34.44\49.42\50.32))
gen h = .
mata: st_store(., "h", (1\1\1\0\1\0\1\1\0\0\0\1\0\1\0\1\0\1\1\1\1\1))
tempfile nodesA
save `nodesA'
use `nodesA', clear
_bipcase bipA `"bconcurrent1(all)"' 1 `"9"' `"-0.4517892"' `"0.465073"'
_bipcase bipA `"bconcurrent2(all)"' 1 `"9"' `"-0.141523"' `"0.6218333"'
_bipcase bipA `"bconcurrent1(by(g))"' 3 `"1 4 4"' `""' `""'
_bipcase bipA `"bconcurrent1(by(g) levels(2 3))"' 2 `"4 4"' `""' `""'
_bipcase bipA `"bconcurrent2(by(g))"' 3 `"3 3 3"' `""' `""'
_bipcase bipA `"bmindegree1(0/3)"' 4 `"12 12 9 5"' `""' `""'
_bipcase bipA `"bmindegree2(1/2)"' 2 `"10 9"' `""' `""'
_bipcase bipA `"bdegrange1(1 3, to(3 .))"' 2 `"7 5"' `""' `""'
_bipcase bipA `"bdegrange1(1 2, to(3 4) by(g))"' 6 `"1 0 5 3 1 1"' `""' `""'
_bipcase bipA `"bdegrange1(1, to(3) by(g) homophily)"' 1 `"6"' `"-1.143098"' `"0.5102211"'
_bipcase bipA `"bdegrange2(1, to(4))"' 1 `"5"' `"0.06521388"' `"0.474467"'
_bipcase bipA `"bdegree1(1/3, by(g))"' 9 `"1 0 0 2 3 0 0 1 0"' `""' `""'
_bipcase bipA `"bdegree1(1/2, by(g) homophily)"' 2 `"5 1"' `"-0.0911323 -2.135551"' `"0.5742681 0.6628116"'
_bipcase bipA `"bdegree1(1/2, by(g) levels(1 3))"' 4 `"1 0 0 1"' `""' `""'
_bipcase bipA `"bdegree2(0/2, by(h))"' 6 `"0 0 1 0 1 1"' `""' `""'
_bipcase bipA `"bstar1(2, attr(g))"' 1 `"10"' `"1.004642"' `"0.3265392"'
_bipcase bipA `"bstar1(2 3, attr(g) levels(1))"' 2 `"23 13"' `"0.6857411 -0.3111415"' `"0.3801457 0.2999664"'
_bipcase bipA `"bstar2(2, attr(g))"' 1 `"13"' `"0.5312145"' `"0.2266393"'
_bipcase bipA `"bcovrange1(x)"' 1 `"141.48"' `"-0.05929615"' `"0.03416955"'
_bipcase bipA `"bcovrange2(x)"' 1 `"229.34"' `"-0.05713666"' `"0.02899277"'
_bipcase bipA `"bfactordistinct1(g)"' 1 `"24"' `"-0.006770507"' `"0.4031221"'
_bipcase bipA `"bfactordistinct2(g)"' 1 `"20"' `"-0.7118393"' `"0.4606028"'
_bipcase bipA `"bfactordistinct1(g, levels(1 2))"' 1 `"16"' `"-0.01555241"' `"0.4322614"'
_bipcase bipA `"bsociality1(-1)"' 11 `"4 6 1 1 2 5 5 1 2 2 2"' `"3.020447e-16 0.8109302 -1.791759 -1.791759 -0.9808293 0.4054651 0.4054651 -1.791759 -0.9808293 -0.9808293 -0.9808293"' `"0.9128709 0.9128709 1.23602 1.23602 1.020618 0.9036961 0.9036961 1.23602 1.020618 1.020618 1.020618"'
_bipcase bipA `"bsociality2(-1)"' 9 `"5 2 4 5 2 6 3 1 3"' `"0.3566749 -0.9162907 -9.682036e-16 0.3566749 -0.9162907 0.6931472 -0.4054651 -1.704748 -0.4054651"' `"0.8472644 0.9874089 0.8660253 0.8472644 0.9874089 0.8416253 0.9052301 1.210713 0.9052301"'
_bipcase bipA `"bsociality1(1/3)"' 3 `"4 4 6"' `"0.784119 0.784119 1.595049"' `"0.6919382 0.6919382 0.6919382"'
_bipcase bipA `"bsociality2(2 4)"' 2 `"5 4"' `"0.6539265 0.2972515"' `"0.6289676 0.6540207"'
_bipcase bipA `"bstarmix1(2, attr(g))"' 9 `"0 0 2 1 3 1 0 0 7"' `""' `""'
_bipcase bipA `"bstarmix1(2, attr(g) nodiff)"' 3 `"1 3 10"' `"-0.5205395 -0.350808 0.6869719"' `"0.777778 0.4915881 0.3139032"'
_bipcase bipA `"bstarmix2(2, attr(g))"' 9 `"1 2 1 0 2 2 0 1 10"' `""' `""'
_bipcase bipA `"bstarmix2(3, attr(g) nodiff)"' 3 `"0 0 5"' `""' `""'
_bipcase bipA `"bstarmix1(2, attr(g) base(1))"' 8 `"0 2 1 3 1 0 0 7"' `""' `""'
_bipcase bipA `"btwostar1(g, attr2(h))"' 9 `"1 1 0 4 8 13 1 4 19"' `""' `""'
_bipcase bipA `"btwostar1(g)"' 18 `"0 0 2 2 4 2 1 3 1 1 2 12 2 4 8 0 0 7"' `""' `""'
_bipcase bipA `"btwostar2(g, attr2(h))"' 12 `"1 0 3 3 1 4 6 3 4 17 2 11"' `""' `""'
_bipcase bipA `"btwostar1(g, attr2(h) base(1))"' 8 `"1 0 4 8 13 1 4 19"' `""' `""'
_bipcase bipA `"coincidence(active(1))"' 15 `"2 2 2 3 2 2 3 2 3 2 4 2 3 2 2"' `""' `""'
_bipcase bipA `"bdsp1(0/3)"' 4 `"32 19 10 4"' `"-0.1781238 -0.5021828 -0.261786 -0.1369991"' `"0.6407416 0.5565593 0.4669691 0.4152756"'
_bipcase bipA `"bdsp2(0/3)"' 4 `"15 15 10 4"' `"-0.6754739 -0.747675 -0.4190637 -0.05758731"' `"0.6030859 0.536243 0.4532521 0.4189909"'
_bipcase bipA `"bgwdsp1(0.5)"' 1 `"40.737047"' `"-0.2882901"' `"0.1741198"'
_bipcase bipA `"bgwdsp2(0.7)"' 1 `"38.945931"' `"0.07839312"' `"0.1673512"'
_bipcase bipA `"bgwdegree1(0.5, attr(g))"' 3 `"2.6092036 7.8135803 6.2784485"' `"-0.1102038 0.3577732 4.280708"' `"1.604677 1.109769 3.225509"'
_bipcase bipA `"bgwdegree2(0.5, attr(h))"' 2 `"4.6358453 10.375023"' `"2.789942 0.4824094"' `"2.988411 1.368933"'
_bipcase bipA `"bnodematch1(g)"' 1 `"19"' `"0.1431209"' `"0.2294457"'
_bipcase bipA `"bnodematch1(g, diff)"' 3 `"1 5 13"' `"0.5154592 -0.4979187 0.4759732"' `"0.9663278 0.3471225 0.2547959"'
_bipcase bipA `"bnodematch1(g, alpha(0.5))"' 1 `"13.974691"' `"-0.192616"' `"0.2992225"'
_bipcase bipA `"bnodematch1(g, beta(0.5))"' 1 `"15.585422"' `"0.6274344"' `"0.4219904"'
_bipcase bipA `"bnodematch1(g, byattr(h))"' 2 `"4 15"' `"-0.155548 0.1935961"' `"0.401518 0.2328418"'
_bipcase bipA `"bnodematch1(g, diff byattr(h))"' 6 `"1 0 1 4 2 11"' `""' `""'
_bipcase bipA `"bnodematch2(g, byattr(h))"' 2 `"0 14"' `""' `""'
_bipcase bipA `"bnodematch2(g, alpha(0.3) byattr(h))"' 2 `"0 9.3149668"' `""' `""'
_bipcase bipA `"bnodematch1(g, diff levels(2 3))"' 2 `"5 13"' `"-0.5319103 0.450168"' `"0.3412586 0.2491217"'
_bipcase bipA `"nodecov(x)"' 1 `"3496.77"' `"0.03829323"' `"0.0134659"'
_bipcase bipA `"nodefactor(g)"' 2 `"24 30"' `"0.09669041 0.7815667"' `"0.3874303 0.3886108"'
_bipcase bipA `"nodematch(g)"' 1 `"16"' `"0.880242"' `"0.4200704"'
_bipcase bipA `"nodematchdiff(g)"' 3 `"2 5 9"' `"0.1000835 0.2431843 2.297308"' `"0.8574213 0.5877309 0.7162046"'
_bipcase bipA `"nodemix(g)"' 8 `"5 4 2 5 4 1 3 9"' `"-0.2363888 2.375032e-10 0.4054651 0.1431008 0.4054651 -0.5108256 -0.5108256 2.197225"' `"0.9587831 0.9999971 1.190238 0.9713839 1.02062 1.36626 1.032763 1.054091"'
_bipcase bipA `"absdist(x)"' 1 `"459.39"' `"-0.0044768"' `"0.02096827"'
_bipcase bipA `"degree(0/3)"' 4 `"0 4 6 2"' `""' `""'
_bipcase bipA `"kstar(2 3)"' 2 `"106 98"' `"0.3076252 -0.08993139"' `"0.3514595 0.1317407"'
_bipcase bipA `"concurrent"' 1 `"18"' `"-0.3347696"' `"0.3701779"'
_bipcase bipA `"degrange(1) degrangeto(3)"' 1 `"10"' `"2.15246"' `"0.5519834"'
_bipcase bipA `"esp(0/2)"' 3 `"35 0 0"' `""' `""'
_bipcase bipA `"dsp(0/3)"' 4 `"167 34 20 8"' `"-0.1432102 -0.3311365 -0.04178124 0.09484247"' `"0.4470294 0.3424594 0.2651826 0.2874757"'
_bipcase bipA `"gwesp(0.5)"' 1 `"0"' `""' `""'
_bipcase bipA `"gwdsp(0.5)"' 1 `"77.474094"' `"-0.2321355"' `"0.1645497"'
_bipcase bipA `"gwnsp(0.5)"' 1 `"77.474094"' `"-0.2321355"' `"0.1645497"'
_bipcase bipA `"triangle"' 1 `"0"' `""' `""'

* ---- network B: 8 x 15
mata: BB = J(15, 8, 0)
mata: peB = (5\3\4\5\6\5\3\7\8\5\6\7\8\5\1\2\3\5\1\3\6\7)
mata: evB = (1\2\2\2\2\4\5\6\6\7\7\7\9\10\11\11\11\11\12\13\13\14)
mata: for (k=1;k<=22;k++) BB[evB[k],peB[k]] = 1
nwset, mat(BB) bipartite name(bipB) nooutput
clear
set obs 23
gen g = .
mata: st_store(., "g", (3\2\2\2\3\2\2\3\3\2\3\2\2\2\1\2\2\1\1\3\2\2\1))
gen x = .
mata: st_store(., "x", (41.98\54.45\55.58\42.79\56.3\48.96\53.92\38.47\41.89\61.25\47.82\46.42\46.5\50.64\44.01\61.49\47.31\53.72\62.24\56.81\48.54\50.79\44.09))
gen h = .
mata: st_store(., "h", (1\0\0\0\1\0\0\0\0\0\0\0\0\1\1\1\0\1\0\0\1\1\0))
tempfile nodesB
save `nodesB'
use `nodesB', clear
_bipcase bipB `"bconcurrent1(all)"' 1 `"6"' `"-0.5877867"' `"0.5962845"'
_bipcase bipB `"bconcurrent2(all)"' 1 `"5"' `"-1.504077"' `"0.5885257"'
_bipcase bipB `"bconcurrent1(by(g))"' 2 `"3 3"' `""' `""'
_bipcase bipB `"bconcurrent1(by(g) levels(2 3))"' 2 `"3 0"' `""' `""'
_bipcase bipB `"bconcurrent2(by(g))"' 3 `"2 3 0"' `""' `""'
_bipcase bipB `"bmindegree1(0/3)"' 4 `"8 8 6 4"' `""' `""'
_bipcase bipB `"bmindegree2(1/2)"' 2 `"12 5"' `"-0.4111631 -1.684545"' `"0.5616341 0.6334886"'
_bipcase bipB `"bdegrange1(1 3, to(3 .))"' 2 `"4 4"' `""' `""'
_bipcase bipB `"bdegrange1(1 2, to(3 4) by(g))"' 4 `"2 2 2 2"' `""' `""'
_bipcase bipB `"bdegrange1(1, to(3) by(g) homophily)"' 1 `"5"' `"0.04224366"' `"0.4800783"'
_bipcase bipB `"bdegrange2(1, to(4))"' 1 `"10"' `"-0.7111643"' `"0.417229"'
_bipcase bipB `"bdegree1(1/3, by(g))"' 6 `"2 0 2 0 2 0"' `""' `""'
_bipcase bipB `"bdegree1(1/2, by(g) homophily)"' 2 `"3 2"' `"-0.08965726 0.1721734"' `"0.5679994 0.5662198"'
_bipcase bipB `"bdegree1(1/2, by(g) levels(1 3))"' 4 `"2 0 0 0"' `""' `""'
_bipcase bipB `"bdegree2(0/2, by(h))"' 6 `"2 5 0 1 2 2"' `""' `""'
_bipcase bipB `"bstar1(2, attr(g))"' 1 `"5"' `"-0.07673637"' `"0.2819141"'
_bipcase bipB `"bstar1(2 3, attr(g) levels(1))"' 2 `"9 2"' `"0.3372607 -1.133621"' `"0.4994669 0.733173"'
_bipcase bipB `"bstar2(2, attr(g))"' 1 `"4"' `"0.1759382"' `"0.3424561"'
_bipcase bipB `"bcovrange1(x)"' 1 `"68.87"' `"-0.1315273"' `"0.05800381"'
_bipcase bipB `"bcovrange2(x)"' 1 `"57.24"' `"-0.05508138"' `"0.04578655"'
_bipcase bipB `"bfactordistinct1(g)"' 1 `"14"' `"-0.2719337"' `"0.4879499"'
_bipcase bipB `"bfactordistinct2(g)"' 1 `"16"' `"-0.3715636"' `"0.4733491"'
_bipcase bipB `"bfactordistinct1(g, levels(1 2))"' 1 `"12"' `"0.145182"' `"0.5332418"'
_bipcase bipB `"bsociality1(-1)"' 7 `"1 4 1 6 3 3 2"' `"-0.7672551 0.8602012 -0.7672551 1.466337 0.4855078 0.4855078 -1.960798e-15"' `"1.283761 0.9579873 1.283761 0.9244517 0.9967347 0.9967347 1.074089"'
_bipcase bipB `"bsociality2(-1)"' 14 `"4 0 1 1 2 3 0 1 1 4 1 2 1 0"' `""' `""'
_bipcase bipB `"bsociality1(1/3)"' 3 `"2 1 4"' `"-0.4855078 -1.252763 0.3746934"' `"0.8125616 1.074598 0.6513389"'
_bipcase bipB `"bsociality2(2 4)"' 2 `"4 1"' `"1.632695 -0.3132154"' `"0.7551938 1.101442"'
_bipcase bipB `"bstarmix1(2, attr(g))"' 6 `"0 3 5 2 0 0"' `""' `""'
_bipcase bipB `"bstarmix1(2, attr(g) nodiff)"' 2 `"5 5"' `"-0.1590048 0.1310593"' `"0.3130005 0.3214484"'
_bipcase bipB `"bstarmix2(2, attr(g))"' 6 `"2 1 4 0 0 0"' `""' `""'
_bipcase bipB `"bstarmix2(3, attr(g) nodiff)"' 3 `"0 1 0"' `""' `""'
_bipcase bipB `"bstarmix1(2, attr(g) base(1))"' 5 `"3 5 2 0 0"' `""' `""'
_bipcase bipB `"btwostar1(g, attr2(h))"' 6 `"3 7 5 9 4 1"' `"-0.1115085 -0.136958 -0.2923971 0.5845847 0.3306624 -1.453684"' `"0.4111781 0.2587125 0.3061137 0.3714327 0.3452185 0.9586353"'
_bipcase bipB `"btwostar1(g)"' 12 `"0 3 7 6 5 2 0 4 0 2 0 0"' `""' `""'
_bipcase bipB `"btwostar2(g, attr2(h))"' 6 `"4 2 7 3 1 0"' `""' `""'
_bipcase bipB `"btwostar1(g, attr2(h) base(1))"' 5 `"7 5 9 4 1"' `"-0.1244249 -0.2843531 0.6138659 0.3641019 -1.465386"' `"0.2549302 0.3071086 0.3585057 0.3239042 0.9630267"'
_bipcase bipB `"coincidence(all)"' 105 `"1 0 1 0 0 1 0 0 1 1 0 0 0 0 0 1 1 0 2 0 0 1 2 0 2 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 0 0 1 1 0 0 0 0 0 0 0 0 0 1 0 1 0 0 1 0 1 0 0 0 0 1 0 0 0 1 1 0 1 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 0 0 0 0 1 1 0 0 0 0 0 0 0 0"' `""' `""'
_bipcase bipB `"coincidence(active(1))"' 3 `"2 2 2"' `"1.815559 1.521971 2.222232"' `"0.8597689 0.8116059 0.9495247"'
_bipcase bipB `"bdsp1(0/3)"' 4 `"14 11 3 0"' `""' `""'
_bipcase bipB `"bdsp2(0/3)"' 4 `"79 23 3 0"' `""' `""'
_bipcase bipB `"bgwdsp1(0.5)"' 1 `"15.180408"' `"0.3581408"' `"0.2230953"'
_bipcase bipB `"bgwdsp2(0.7)"' 1 `"27.510244"' `"0.06801277"' `"0.1562354"'
_bipcase bipB `"bgwdegree1(0.5, attr(g))"' 2 `"6.7057786 4.4295419"' `"1.151051 4.286977"' `"1.237187 2.494951"'
_bipcase bipB `"bgwdegree2(0.5, attr(h))"' 2 `"8.2184073 6.3352261"' `"-0.4339632 0.0358468"' `"0.7700794 0.8934909"'
_bipcase bipB `"bnodematch1(g)"' 1 `"7"' `"0.1463113"' `"0.3037878"'
_bipcase bipB `"bnodematch1(g, diff)"' 2 `"6 1"' `"0.2357716 -0.6298545"' `"0.2998059 0.7777231"'
_bipcase bipB `"bnodematch1(g, alpha(0.5))"' 1 `"6.4142136"' `"0.2667112"' `"0.3626287"'
_bipcase bipB `"bnodematch1(g, beta(0.5))"' 1 `"6.1213203"' `"0.3263823"' `"0.4501257"'
_bipcase bipB `"bnodematch1(g, byattr(h))"' 2 `"5 2"' `"0.3042901 -0.2306395"' `"0.3273611 0.511162"'
_bipcase bipB `"bnodematch1(g, diff byattr(h))"' 4 `"4 2 1 0"' `""' `""'
_bipcase bipB `"bnodematch2(g, byattr(h))"' 2 `"6 4"' `"-0.1617424 0.2485703"' `"0.2948587 0.354549"'
_bipcase bipB `"bnodematch2(g, alpha(0.3) byattr(h))"' 2 `"5.2311444 4"' `"-0.3469931 0.2368751"' `"0.3322555 0.3493985"'
_bipcase bipB `"bnodematch1(g, diff levels(2 3))"' 2 `"1 0"' `""' `""'
_bipcase bipB `"nodecov(x)"' 1 `"2294.69"' `"0.06477584"' `"0.02734884"'
_bipcase bipB `"nodefactor(g)"' 2 `"24 12"' `"-0.5635416 -0.5740418"' `"0.5127587 0.5775613"'
_bipcase bipB `"nodematch(g)"' 1 `"10"' `"0.2316542"' `"0.475314"'
_bipcase bipB `"nodematchdiff(g)"' 3 `"0 8 2"' `""' `""'
_bipcase bipB `"nodemix(g)"' 5 `"4 8 4 0 2"' `""' `""'
_bipcase bipB `"absdist(x)"' 1 `"194.83"' `"0.04157613"' `"0.04296033"'
_bipcase bipB `"degree(0/3)"' 4 `"3 9 4 3"' `"-1.093151 -0.4786753 -1.138964 -0.8665048"' `"2.21851 1.637571 1.151111 0.6324235"'
_bipcase bipB `"kstar(2 3)"' 2 `"46 35"' `"0.09601678 0.01259963"' `"0.2911427 0.1150507"'
_bipcase bipB `"concurrent"' 1 `"11"' `"-1.099021"' `"0.4312178"'
_bipcase bipB `"degrange(1) degrangeto(3)"' 1 `"13"' `"0.2359011"' `"0.3074961"'
_bipcase bipB `"esp(0/2)"' 3 `"22 0 0"' `""' `""'
_bipcase bipB `"dsp(0/3)"' 4 `"213 34 6 0"' `""' `""'
_bipcase bipB `"gwesp(0.5)"' 1 `"0"' `""' `""'
_bipcase bipB `"gwdsp(0.5)"' 1 `"42.360816"' `"0.21228"' `"0.147276"'
_bipcase bipB `"gwnsp(0.5)"' 1 `"42.360816"' `"0.21228"' `"0.147276"'
_bipcase bipB `"triangle"' 1 `"0"' `""' `""'

* ---- network C: 20 x 6
mata: BC = J(6, 20, 0)
mata: peC = (1\2\5\6\8\12\13\1\4\5\6\13\16\1\3\11\12\18\1\2\12\13\15\17\1\2\3\4\7\1\2\8\17)
mata: evC = (1\1\1\1\1\1\1\2\2\2\2\2\2\3\3\3\3\3\4\4\4\4\4\4\5\5\5\5\5\6\6\6\6)
mata: for (k=1;k<=33;k++) BC[evC[k],peC[k]] = 1
nwset, mat(BC) bipartite name(bipC) nooutput
clear
set obs 26
gen g = .
mata: st_store(., "g", (2\2\2\1\2\1\2\1\2\3\3\2\2\2\1\2\1\3\1\1\2\1\3\1\1\1))
gen x = .
mata: st_store(., "x", (60.49\45.04\46.07\55.81\45.24\66.16\52.85\61.9\47.72\68.43\53.12\49.73\48.28\32.5\60.13\55.48\54.33\47.49\54.86\42.89\54.79\63\49.46\57.15\30.33\52.58))
gen h = .
mata: st_store(., "h", (0\0\1\0\1\1\1\0\0\0\1\0\0\1\1\1\1\0\0\0\1\0\1\1\1\1))
tempfile nodesC
save `nodesC'
use `nodesC', clear
_bipcase bipC `"bconcurrent1(all)"' 1 `"10"' `"0.3486428"' `"0.4325185"'
_bipcase bipC `"bconcurrent2(all)"' 1 `"6"' `""' `""'
_bipcase bipC `"bconcurrent1(by(g))"' 3 `"4 6 0"' `""' `""'
_bipcase bipC `"bconcurrent1(by(g) levels(2 3))"' 2 `"6 0"' `""' `""'
_bipcase bipC `"bconcurrent2(by(g))"' 3 `"4 1 1"' `""' `""'
_bipcase bipC `"bmindegree1(0/3)"' 4 `"20 15 10 4"' `""' `""'
_bipcase bipC `"bmindegree2(1/2)"' 2 `"6 6"' `""' `""'
_bipcase bipC `"bdegrange1(1 3, to(3 .))"' 2 `"11 4"' `"-1.386294 -2.367124"' `"0.5559593 0.8629582"'
_bipcase bipC `"bdegrange1(1 2, to(3 4) by(g))"' 6 `"5 4 4 4 2 0"' `""' `""'
_bipcase bipC `"bdegrange1(1, to(3) by(g) homophily)"' 1 `"12"' `"0.8939245"' `"0.4472935"'
_bipcase bipC `"bdegrange2(1, to(4))"' 1 `"0"' `""' `""'
_bipcase bipC `"bdegree1(1/3, by(g))"' 9 `"1 4 0 2 2 2 2 0 0"' `""' `""'
_bipcase bipC `"bdegree1(1/2, by(g) homophily)"' 2 `"10 2"' `"0.9173223 1.410219"' `"0.4611667 0.7929486"'
_bipcase bipC `"bdegree1(1/2, by(g) levels(1 3))"' 4 `"1 4 2 0"' `""' `""'
_bipcase bipC `"bdegree2(0/2, by(h))"' 6 `"0 0 0 0 0 0"' `""' `""'
_bipcase bipC `"bstar1(2, attr(g))"' 1 `"2"' `"-0.3990313"' `"0.5112619"'
_bipcase bipC `"bstar1(2 3, attr(g) levels(1))"' 2 `"4 0"' `""' `""'
_bipcase bipC `"bstar2(2, attr(g))"' 1 `"14"' `"0.06729811"' `"0.1480445"'
_bipcase bipC `"bcovrange1(x)"' 1 `"150.39"' `"0.0005006032"' `"0.02275587"'
_bipcase bipC `"bcovrange2(x)"' 1 `"104.22"' `"-0.04970628"' `"0.06903155"'
_bipcase bipC `"bfactordistinct1(g)"' 1 `"25"' `"-0.1605816"' `"0.4207496"'
_bipcase bipC `"bfactordistinct2(g)"' 1 `"12"' `"-2.382391"' `"1.044586"'
_bipcase bipC `"bfactordistinct1(g, levels(1 2))"' 1 `"20"' `"-0.06725222"' `"0.410296"'
_bipcase bipC `"bsociality1(-1)"' 19 `"4 2 2 2 2 1 2 0 0 1 3 3 0 1 1 2 1 0 0"' `""' `""'
_bipcase bipC `"bsociality2(-1)"' 5 `"6 5 6 5 4"' `"-0.2282587 -0.4795731 -0.2282587 -0.4795731 -0.7672551"' `"0.6766641 0.6974523 0.6766641 0.6974523 0.7295525"'
_bipcase bipC `"bsociality1(1/3)"' 3 `"6 4 2"' `""' `""'
_bipcase bipC `"bsociality2(2 4)"' 2 `"6 6"' `"0.1857171 0.1857171"' `"0.5501419 0.5501419"'
_bipcase bipC `"bstarmix1(2, attr(g))"' 9 `"2 10 0 0 0 0 0 0 0"' `""' `""'
_bipcase bipC `"bstarmix1(2, attr(g) nodiff)"' 3 `"2 10 0"' `""' `""'
_bipcase bipC `"bstarmix2(2, attr(g))"' 9 `"3 19 0 1 10 0 0 3 1"' `""' `""'
_bipcase bipC `"bstarmix2(3, attr(g) nodiff)"' 3 `"12 10 1"' `"-0.1182656 0.01833584 -0.4811636"' `"0.1087489 0.08652454 0.4113615"'
_bipcase bipC `"bstarmix1(2, attr(g) base(1))"' 8 `"10 0 0 0 0 0 0 0"' `""' `""'
_bipcase bipC `"btwostar1(g, attr2(h))"' 9 `"0 0 0 2 8 0 2 21 0"' `""' `""'
_bipcase bipC `"btwostar1(g)"' 18 `"2 10 0 2 11 0 0 0 0 0 6 0 0 2 0 0 0 0"' `""' `""'
_bipcase bipC `"btwostar2(g, attr2(h))"' 12 `"1 3 8 26 6 26 0 0 0 6 0 1"' `""' `""'
_bipcase bipC `"btwostar1(g, attr2(h) base(1))"' 8 `"0 0 2 8 0 2 21 0"' `""' `""'
_bipcase bipC `"coincidence(all)"' 15 `"4 2 4 2 3 1 2 2 1 2 2 1 2 3 2"' `""' `""'
_bipcase bipC `"coincidence(active(1))"' 12 `"4 2 4 2 3 2 2 2 2 2 3 2"' `"2.575426 0.4599717 2.027628 -0.6884977 1.121771 -0.7809905 1.196276 0.6627941 1.386487 0.3621976 1.324808 1.26604"' `"0.7577408 0.8737868 0.7903582 0.9365035 0.8376922 0.9052228 0.819765 0.8441557 0.7808835 0.9378476 0.8486963 0.9036181"'
_bipcase bipC `"bdsp1(0/3)"' 4 `"134 39 14 2"' `"2.574304 1.598224 1.332646 -0.1205986"' `"1.288783 1.066752 0.9341961 0.7763694"'
_bipcase bipC `"bdsp2(0/3)"' 4 `"0 3 8 2"' `""' `""'
_bipcase bipC `"bgwdsp1(0.5)"' 1 `"63.214349"' `"-0.7153393"' `"0.1889385"'
_bipcase bipC `"bgwdsp2(0.7)"' 1 `"22.309839"' `"1.484473"' `"0.4729833"'
_bipcase bipC `"bgwdegree1(0.5, attr(g))"' 3 `"6.5738774 11.13532 2"' `"-1.416974 -1.313493 -1.610387"' `"0.8449016 0.8100802 1.033921"'
_bipcase bipC `"bgwdegree2(0.5, attr(h))"' 2 `"1.6426032 8.1644655"' `""' `""'
_bipcase bipC `"bnodematch1(g)"' 1 `"37"' `"0.06842649"' `"0.137981"'
_bipcase bipC `"bnodematch1(g, diff)"' 3 `"4 32 1"' `"-0.527184 0.03113831 0.5671654"' `"0.3808459 0.1361582 0.8658679"'
_bipcase bipC `"bnodematch1(g, alpha(0.5))"' 1 `"28.949383"' `"-0.1746957"' `"0.1770367"'
_bipcase bipC `"bnodematch1(g, beta(0.5))"' 1 `"23.513625"' `"0.8903865"' `"0.4588563"'
_bipcase bipC `"bnodematch1(g, byattr(h))"' 2 `"7 30"' `"0.07151382 0.06768187"' `"0.2098529 0.1431879"'
_bipcase bipC `"bnodematch1(g, diff byattr(h))"' 6 `"1 3 6 26 0 1"' `""' `""'
_bipcase bipC `"bnodematch2(g, byattr(h))"' 2 `"11 1"' `"0.6170899 -1.222601"' `"0.2599729 0.7574645"'
_bipcase bipC `"bnodematch2(g, alpha(0.3) byattr(h))"' 2 `"7.1557221 1"' `"3.283164 -1.145141"' `"1.310623 0.7624157"'
_bipcase bipC `"bnodematch1(g, diff levels(2 3))"' 2 `"32 1"' `"0.1409006 0.8313132"' `"0.1155122 0.8581925"'
_bipcase bipC `"nodecov(x)"' 1 `"3478.92"' `"0.01449956"' `"0.01602877"'
_bipcase bipC `"nodefactor(g)"' 2 `"29 7"' `"0.6728653 -0.3447802"' `"0.3524499 0.4760657"'
_bipcase bipC `"nodematch(g)"' 1 `"14"' `"0.493126"' `"0.4216205"'
_bipcase bipC `"nodematchdiff(g)"' 3 `"7 5 2"' `"0.05129329 1.149906 1.843053"' `"0.5096807 0.6850535 1.252716"'
_bipcase bipC `"nodemix(g)"' 8 `"14 0 2 5 0 0 3 2"' `""' `""'
_bipcase bipC `"absdist(x)"' 1 `"300.9"' `"-0.0254946"' `"0.02630096"'
_bipcase bipC `"degree(0/3)"' 4 `"5 5 6 2"' `"3.529227 1.751869 1.011798 -0.3600954"' `"2.655039 1.9763 1.370634 0.7269435"'
_bipcase bipC `"kstar(2 3)"' 2 `"110 125"' `"0.7860927 -0.287084"' `"0.2695736 0.09000107"'
_bipcase bipC `"concurrent"' 1 `"16"' `"0.3486428"' `"0.4325185"'
_bipcase bipC `"degrange(1) degrangeto(3)"' 1 `"11"' `"-0.184034"' `"0.2789151"'
_bipcase bipC `"esp(0/2)"' 3 `"33 0 0"' `""' `""'
_bipcase bipC `"dsp(0/3)"' 4 `"254 42 22 4"' `"0.4928625 0.08898014 0.5347613 -0.5176941"' `"0.7837881 0.5728658 0.5762542 0.4632793"'
_bipcase bipC `"gwesp(0.5)"' 1 `"0"' `""' `""'
_bipcase bipC `"gwdsp(0.5)"' 1 `"83.677086"' `"-0.5629521"' `"0.1954978"'
_bipcase bipC `"gwnsp(0.5)"' 1 `"83.677086"' `"-0.5629521"' `"0.1954978"'
_bipcase bipC `"triangle"' 1 `"0"' `""' `""'

di as txt "PASS test_nwergm_bip"
