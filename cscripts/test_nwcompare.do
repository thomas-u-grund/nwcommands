* nwcompare: fit statistics of stored estimation results, error paths
cscript
do unw_core.do
capture program drop nwinstall
set graphics off
run nwcompare.ado

local nfail = 0

* fake fits that set e() the way the model packages do
capture program drop fake_lsm
program fake_lsm, eclass
    matrix b = (0.5, -0.2)
    matrix colnames b = x1 x2
    matrix V = I(2)
    matrix colnames V = x1 x2
    matrix rownames V = x1 x2
    ereturn post b V, obs(45)
    ereturn local cmd "nwlsm"
    ereturn scalar ll_mean = -123.4
    ereturn scalar N_nodes = 10
end
capture program drop fake_sbm
program fake_sbm, eclass
    ereturn clear
    ereturn scalar N = 20
    ereturn scalar PL = -88.5
    ereturn scalar npar = 7
    ereturn scalar ICL = -120.25
    ereturn local cmd "nwsbm"
end
capture program drop fake_ergm
program fake_ergm, eclass
    matrix b = (1, 2)
    matrix colnames b = edges mutual
    matrix V = I(2)
    matrix colnames V = edges mutual
    matrix rownames V = edges mutual
    ereturn post b V, obs(100)
    ereturn local cmd "nwergm"
    ereturn scalar ll = -50
    ereturn scalar df_m = 2
    ereturn scalar aic = 104
    ereturn scalar bic = 109.2
    ereturn local ll_method "exact"
end
capture program drop clear_e
program clear_e, eclass
    ereturn clear
end
capture program drop chk
program chk
    args what ok
    if `ok' di as txt "  ok   `what'"
    else {
        di as err "  FAIL `what'"
        global NWC_FAIL = $NWC_FAIL + 1
    }
end
global NWC_FAIL = 0

sysuse auto, clear
quietly logit foreign mpg
estimates store lg1
quietly logit foreign mpg weight
estimates store lg2
quietly regress price mpg
estimates store ols

* ---- a model with the Stata criteria ------------------------------------------------------------------------------
nwcompare lg1 lg2
matrix T = r(table)
quietly estimates restore lg2
quietly estat ic
matrix S = r(S)
chk "logit: N" `=(T[2,1] == 74)'
chk "logit: log likelihood" `=(abs(T[2,2] - e(ll)) < 1e-9)'
chk "logit: k" `=(T[2,3] == 3)'
chk "logit: AIC = -2ll + 2k" `=(abs(T[2,4] - S[1,5]) < 1e-6)'
chk "logit: BIC = -2ll + ln(N)k" `=(abs(T[2,5] - S[1,6]) < 1e-6)'
chk "logit: ICL missing" `=(missing(T[2,6]))'
nwcompare lg1 lg2
chk "r(names)" `=("`r(names)'" == "lg1 lg2")'
chk "r(commands)" `=("`r(commands)'" == "logit logit")'
chk "rows of r(table)" `=(rowsof(r(table)) == 2)'

* ---- sort ---------------------------------------------------------------------------------------------------------
nwcompare lg1 lg2, sort(aic)
nwcompare lg1 lg2, sort(bic)
nwcompare lg1 lg2, sort(ll)
nwcompare lg1 lg2, sort(icl)
nwcompare

* ---- active results and model families built by hand --------------------------------------------------------------
* a latent space fit: posterior mean log likelihood, no AIC
fake_lsm
estimates store lsm_fake
nwcompare lsm_fake
matrix T = r(table)
chk "nwlsm: log likelihood is the posterior mean" `=(abs(T[1,2] + 123.4) < 1e-9)'
chk "nwlsm: no AIC" `=(missing(T[1,4]))'
chk "nwlsm: k = number of coefficients" `=(T[1,3] == 2)'

* a block model fit: PL, npar, ICL; not storable, used as the active results
fake_sbm
nwcompare lg1 .
matrix T = r(table)
chk "nwsbm: PL as log likelihood" `=(abs(T[2,2] + 88.5) < 1e-9)'
chk "nwsbm: parameters" `=(T[2,3] == 7)'
chk "nwsbm: ICL" `=(abs(T[2,6] + 120.25) < 1e-9)'
chk "nwsbm: N" `=(T[2,1] == 20)'
* results without e(b) (nwsbm) cannot be stored and are lost when another model is restored: only the active results of such a fit are listed
fake_sbm
nwcompare .
chk "active results alone" `=(rowsof(r(table)) == 1)'

* an ERGM fit with its own AIC and BIC (stored by the model)
fake_ergm
estimates store ergm_fake
nwcompare ergm_fake
matrix T = r(table)
chk "nwergm: stored AIC kept" `=(abs(T[1,4] - 104) < 1e-9 & abs(T[1,5] - 109.2) < 1e-9)'
chk "nwergm: k from df_m" `=(T[1,3] == 2)'

* the active results survive a call with names
quietly logit foreign mpg weight
nwcompare lg1 ols
chk "active e() unchanged" `=("`e(cmd)'" == "logit")'

* all stored results when no list is given
nwcompare
chk "no list: all stored" `=(rowsof(r(table)) >= 5)'

* ---- error paths ---------------------------------------------------------------------------------------------------
capture nwcompare nosuchmodel
chk "unknown model: r(111)" `=(_rc == 111)'
capture nwcompare lg1, sort(foo)
chk "bad sort: r(198)" `=(_rc == 198)'
estimates clear
capture nwcompare
chk "nothing stored: r(198)" `=(_rc == 198)'
clear_e
capture nwcompare .
chk "no active results: r(301)" `=(_rc == 301)'

if $NWC_FAIL == 0 di as txt "PASS nwcompare tables, criteria and error paths"
else di as err "FAIL nwcompare: $NWC_FAIL checks"
