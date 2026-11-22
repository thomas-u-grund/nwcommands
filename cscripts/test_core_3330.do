* Core 3.33.0: nwcompare k of nwsbm, nwburt on directed binary networks, nwcoreperiphery restarts(), nwmovie ffmpeg messages
cscript
do unw_core.do
capture program drop nwinstall
set graphics off
run nwcompare.ado

global C33_FAIL = 0
capture program drop chk
program chk
    args what ok
    if `ok' di as txt "  ok   `what'"
    else {
        di as err "  FAIL `what'"
        global C33_FAIL = $C33_FAIL + 1
    }
end

* ---------------------------------------------------------------------------------------------------------------------
* (A) nwcompare: k of a block model is e(npar) + (Q - 1) (+ (Q2 - 1) for a two-mode network)
* ---------------------------------------------------------------------------------------------------------------------
capture program drop fake_sbm
program fake_sbm, eclass
    args q q2
    ereturn clear
    ereturn scalar N = 71
    ereturn scalar PL = -1725.77
    ereturn scalar npar = 9
    ereturn scalar ICL = -1768.33
    ereturn scalar Q = `q'
    if "`q2'" != "" ereturn scalar Q2 = `q2'
    ereturn local cmd "nwsbm"
end
fake_sbm 3
qui nwcompare .
matrix T = r(table)
chk "fake nwsbm one-mode: k = npar + Q - 1 = 11" `=(T[1,3] == 11)'
fake_sbm 4 2
qui nwcompare .
matrix T = r(table)
chk "fake nwsbm two-mode: k = npar + (Q1 - 1) + (Q2 - 1) = 13" `=(T[1,3] == 13)'

capture which nwsbm
if _rc == 0 {
    capture mata: st_local("hasplug", strofreal(1))
    nwclear
    nwuse "data/lazega.nwdta"
    capture nwsbm lazega_fr, maxblocks(5) seed(1) nodisplay
    if _rc == 0 {
        local npar = e(npar)
        local q = e(Q)
        qui nwcompare .
        matrix T = r(table)
        di "real nwsbm on Lazega: Q=`q' npar=`npar' -> k printed " T[1,3]
        chk "real nwsbm (Lazega friendship): k = e(npar) + Q - 1" `=(T[1,3] == `npar' + `q' - 1)'
    }
    else di as txt "  (nwsbm fit not run: r(" _rc ")"
}
else di as txt "  (nwsbm not installed: only the stored-result check was run)"

* ---------------------------------------------------------------------------------------------------------------------
* (B) nwburt on a directed binary network: both directions of a tie count (Burt's constraint on p_ij = (z_ij+z_ji)/sum_k(z_ik+z_ki))
* ---------------------------------------------------------------------------------------------------------------------
mata:
real colvector burt_constraint_hand(real matrix A)
{
    real matrix Z, P
    real colvector C
    real scalar n, i, j, q, s
    n = rows(A)
    Z = A + A'
    _diag(Z, 0)
    P = Z :/ rowsum(Z)
    _editmissing(P, 0)
    C = J(n, 1, 0)
    for (i = 1; i <= n; i++) {
        for (j = 1; j <= n; j++) {
            if (j == i | Z[i, j] <= 0) continue
            s = P[i, j]
            for (q = 1; q <= n; q++) if (q != i & q != j) s = s + P[i, q] * P[q, j]
            C[i] = C[i] + s^2
        }
    }
    return(C)
}
end

nwclear
mata: A = J(5, 5, 0); el = (1,2 \ 2,1 \ 1,3 \ 3,4 \ 4,2 \ 2,5 \ 5,1 \ 3,5)
mata: for (k = 1; k <= rows(el); k++) A[el[k,1], el[k,2]] = 1
nwset, mat(A) name(dirbin)
qui nwburt dirbin, replace silent
mata: st_local("d1", strofreal(max(abs(st_data((1::5), "_constraint") - burt_constraint_hand(A)))))
chk "directed binary: constraint equals the hand computation (max abs diff `d1')" `=(`d1' < 1e-6)'
* igraph 2.3.2 constraint() of the same directed graph (unweighted and weights=1 agree)
mata: ig = (0.6614583333333333 \ 0.5434027777777778 \ 0.4822530864197531 \ 0.5 \ 0.7970679012345679)
mata: st_local("d2", strofreal(max(abs(st_data((1::5), "_constraint") - ig))))
chk "directed binary: constraint equals igraph::constraint (max abs diff `d2')" `=(`d2' < 1e-7)'
mata: st_matrix("BIN", st_data((1::5), ("_effsize", "_efficiency", "_constraint", "_hierarchy")))

* the same ties stored as a valued network (all ones): the same four measures
nwset, mat(A) name(dirval) valued
qui nwburt dirval, replace silent
mata: st_local("d3", strofreal(max(abs(st_matrix("BIN") - st_data((1::5), ("_effsize", "_efficiency", "_constraint", "_hierarchy"))))))
chk "directed: binary and all-ones valued give the same measures (max abs diff `d3')" `=(`d3' < 1e-12)'

* the dyadic networks of the dense path use both directions as well; their row sums are the constraint
qui nwburt dirbin, replace silent dyadconstraint dyadredundancy
mata: st_local("d4", strofreal(max(abs(st_matrix("BIN") - st_data((1::5), ("_effsize", "_efficiency", "_constraint", "_hierarchy"))))))
chk "directed: with dyadconstraint the node measures are the same (max abs diff `d4')" `=(`d4' < 1e-12)'
nwtomata dyadconstraint, mat(DC)
mata: DC = editvalue(DC, ., 0)
mata: st_local("d5", strofreal(max(abs(rowsum(DC) - burt_constraint_hand(A)))))
chk "directed: row sums of the dyadconstraint network equal the constraint (max abs diff `d5')" `=(`d5' < 1e-12)'
nwdrop dyadconstraint dyadredundancy

* a directed network whose ties are all mutual gives the measures of the undirected network of the same ties
nwclear
mata: S = J(6, 6, 0); sel = (1,2 \ 1,3 \ 2,3 \ 3,4 \ 4,5 \ 4,6 \ 5,6)
mata: for (k = 1; k <= rows(sel); k++) S[sel[k,1], sel[k,2]] = 1
mata: S = S + S'
nwset, mat(S) name(mutdir) directed
nwset, mat(S) name(mutund) undirected
qui nwburt mutdir, replace silent
mata: st_matrix("MD", st_data((1::6), ("_effsize", "_efficiency", "_constraint", "_hierarchy")))
qui nwburt mutund, replace silent
mata: st_local("d6", strofreal(max(abs(st_matrix("MD") - st_data((1::6), ("_effsize", "_efficiency", "_constraint", "_hierarchy"))))))
chk "directed network with mutual ties = undirected network (max abs diff `d6')" `=(`d6' < 1e-12)'

* ---------------------------------------------------------------------------------------------------------------------
* (C) nwcoreperiphery restarts()
* ---------------------------------------------------------------------------------------------------------------------
nwclear
nwuse "data/lazega.nwdta"
qui nwcoreperiphery lazega_adv, generate(core) silent sym
chk "default: core of 18" `=(r(core) == 18)'
chk "default: fitness .281096" `=(abs(r(fitness) - .2810960301) < 1e-8)'
chk "default: r(restarts) = 1" `=(r(restarts) == 1)'
qui nwcoreperiphery lazega_adv, generate(core2) restarts(1) silent sym
chk "restarts(1) = default (same core and fitness)" `=(r(core) == 18 & abs(r(fitness) - .2810960301) < 1e-8)'
qui count if core != core2
chk "restarts(1) = default (same members)" `=(r(N) == 0)'
local rseed0 = c(rngstate)
qui nwcoreperiphery lazega_adv, generate(core3) replace silent sym
chk "default leaves the random-number state alone" `=("`rseed0'" == c(rngstate))'

qui nwcoreperiphery lazega_adv, generate(core4) replace restarts(200) seed(1) silent sym
local f4 = r(fitness)
chk "restarts(200): core of 20" `=(r(core) == 20)'
chk "restarts(200): fitness .281280" `=(abs(r(fitness) - .2812797670) < 1e-8)'
chk "restarts(200): r(restarts) = 200" `=(r(restarts) == 200)'
chk "restarts(200): many starts reach the best (r(nbest) = `r(nbest)')" `=(r(nbest) > 30 & r(nbest) <= 200)'
chk "restarts(200): the best is not worse than the degree-based start" `=(`f4' >= .2810960301)'
qui nwcoreperiphery lazega_adv, generate(core5) replace restarts(200) seed(1) silent sym
qui count if core4 != core5
chk "same seed, same result" `=(r(N) == 0)'
qui nwcoreperiphery lazega_adv, generate(core6) replace restarts(5) seed(2) silent sym
chk "restarts(5): never below one start" `=(r(fitness) >= .2810960301 - 1e-12)'

* the two lawyers that join the core: n41 and n6
qui count if core4 == 1 & core == 0
local nadd = r(N)
qui count if core4 == 0 & core == 1
chk "restarts(200): the core of 18 plus 2 lawyers, none left out" `=(`nadd' == 2 & r(N) == 0)'

capture nwcoreperiphery lazega_adv, generate(core7) replace restarts(0) sym
chk "restarts(0): r(198)" `=(_rc == 198)'
capture nwcoreperiphery lazega_adv, generate(core7) replace seed(3) sym
chk "seed() without restarts: r(198)" `=(_rc == 198)'
capture nwcoreperiphery lazega_adv, generate(core7) replace restarts(3) seed(-1) sym
chk "seed(-1): r(198)" `=(_rc == 198)'

* ---------------------------------------------------------------------------------------------------------------------
* (D) nwmovie: the ffmpeg messages list what to install (checked on the source; the real conversion is Linux only)
* ---------------------------------------------------------------------------------------------------------------------
quietly findfile nwmovie.ado
local f "`r(fn)'"
mata:
fh = fopen(st_local("f"), "r")
f1 = f2 = f3 = 0
while ((ln = fget(fh)) != J(0, 0, "")) {
    f1 = f1 + (strpos(ln, "sudo apt install ffmpeg") > 0 & strpos(ln, "sudo dnf install ffmpeg") > 0)
    f2 = f2 + (strpos(ln, "RPM Fusion") > 0)
    f3 = f3 + (strpos(ln, "works without extra software") > 0)
}
fclose(fh)
st_local("found1", strofreal(f1)); st_local("found2", strofreal(f2)); st_local("found3", strofreal(f3))
end
run nwmovie.ado
chk "nwmovie messages name apt and dnf (2 messages)" `=(`found1' == 2)'
chk "nwmovie messages name RPM Fusion and the gif route" `=(`found2' >= 2 & `found3' >= 2)'
global NW_FAKE_NOFFMPEG "1"
capture _nwmovie_findffmpeg, ext(mp4)
chk "no ffmpeg: r(498)" `=(_rc == 498)'
global NW_FAKE_NOFFMPEG ""

if $C33_FAIL == 0 di as txt "PASS core 3.33.0: nwcompare k, nwburt directed, nwcoreperiphery restarts, nwmovie messages"
else {
    di as err "FAIL core 3.33.0: $C33_FAIL checks"
    exit 9
}
