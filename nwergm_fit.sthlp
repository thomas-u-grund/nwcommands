{smcl}
{* *! nwergm_fit.sthlp}{...}
{vieweralsosee "nwergm" "help nwergm"}{...}
{viewerjumpto "Missing" "nwergm_fit##missing"}{...}
{viewerjumpto "Fit" "nwergm_fit##fit"}{...}
{viewerjumpto "predict" "nwergm_fit##predict"}{...}
{title:Title}

{pstd}
{bf:nwergm} - missing data, fit statistics and prediction

{marker missing}{...}
{title:Missing data}

{pstd}
{bf:Missing dyads.} A tie that is missing (a missing value in the network's edge matrix; off the diagonal) is not
treated as a non-tie. As in R's {cmd:ergm}, {cmd:nwergm} detects missing dyads automatically and
{p_end}
{phang2}- drops them from the (pseudo)likelihood: the number of informative dyads {cmd:e(N)} excludes them, and for a dyad-independent
model the pseudolikelihood estimate is the maximum likelihood estimate;{p_end}
{phang2}- for a dyad-dependent model fitted by MCMLE, draws a second, constrained sample in which only the missing dyads are free
and every observed dyad is held fixed (Handcock and Gile 2010); the estimating equations compare the two samples and the
information matrix is the difference of their covariances. The missing dyads of the starting network are imputed at random with the
observed density, as R does;{p_end}
{phang2}- reports the number of missing dyads in {cmd:e(nmissing)}. Statistics of the observed network ({cmd:e(ties)}) count observed ties only.{p_end}

{pstd}
Missing dyads cannot yet be combined with {opt freedyads()}, {opt blockdiag()} or {opt fixdensity}.

{pstd}
{bf:Missing covariates.} As in R, a nodal attribute with a missing value in a term ({opt nodecov()}, {opt nodematch()}, {opt nodefactor()} ...)
and a dyadic covariate ({opt edgecov()}, {opt hamming()}) with missing dyads are refused with an error (rc 416): R's {cmd:ergm} does not support
them. Drop or impute the missing values first. For two-mode terms only the attribute of the term's own mode is checked.

{marker fit}{...}
{title:Fit statistics}

{pstd}
After every fit {cmd:nwergm} stores the log-likelihood as R's {cmd:logLik()}: exact for a dyad-independent model (the
pseudolikelihood is the likelihood), the pseudolikelihood after {opt method(mple)} of a dyad-dependent model, and for an MCMLE fit the
likelihood is evaluated by bridge sampling from the dyad-independent submodel (R: {cmd:ergm.bridge.dindstart.llk}); {cmd:e(ll_se)} is the
Monte Carlo standard error. The null model is the model with all coefficients zero ({it:N} x ln(1/2)).

{p2colset 5 24 26 2}{...}
{p2col:{cmd:e(ll)}, {cmd:e(ll_0)}}log-likelihood and null log-likelihood{p_end}
{p2col:{cmd:e(df_m)}, {cmd:e(df_resid)}}estimated coefficients (offsets excluded) and {it:N} - df_m{p_end}
{p2col:{cmd:e(deviance)}, {cmd:e(deviance_0)}}residual and null deviance, -2 ll{p_end}
{p2col:{cmd:e(aic)}, {cmd:e(bic)}}AIC and BIC, BIC with {it:N} = number of informative dyads{p_end}
{p2col:{cmd:e(ll_se)}}Monte Carlo standard error of {cmd:e(ll)} (0 when exact){p_end}
{p2colreset}{...}

{pstd}
{cmd:estat ic} displays them and {cmd:lrtest} works between nested fits (same network and the same {it:N}). The likelihood is not evaluated
for a model with a curved (free-decay) term fitted by MCMLE; the option {opt nologlik} skips the bridge sampling.

{marker predict}{...}
{title:predict}

{pstd}
{cmd:predict, matrix(}{it:name}{cmd:)} [{opt pr}|{opt xb}] and {cmd:predict, frame(}{it:name}{cmd:)} [{opt pr}|{opt xb}] give the conditional
probability ({opt pr}, the default) or the conditional log-odds ({opt xb}) of each informative dyad given the rest of the observed
network (R: {cmd:predict.ergm}). The frame holds one row per dyad ({it:tail}, {it:head}, {it:p}); the matrix is {it:n} x {it:n} with missing dyads
set to missing. The prediction is available for the most recent {cmd:nwergm} fit only.

{title:References}

{phang}Handcock, M. S. and Gile, K. J. 2010. Modeling social networks from sampled data. {it:Annals of Applied Statistics} 4: 5-25.{p_end}
