{smcl}
{* *! version 1.2.0  02sep2026 author: Thomas Grund}{...}
{marker topic}
{helpb nwtopical##analysis_statmodels:[NW-2.6.6] Statistical Estimation of Networks}

{title:Title}

{p2colset 9 21 22 2}{...}
{p2col :nwsaom {hline 2}}Stochastic actor-oriented model (SAOM) estimation between observed network waves{p_end}
{p2colreset}{...}

{title:Syntax}

{p 8 17 2}
{cmdab: nwsaom}
{cmd:,}
{opt wave1(netname)} {opt wave2(netname)}
{it:or}
{opt waves(namelist)}
{opt outdegree} [{opt reciprocity}]
{it:or} {opt outdegreeendow} {opt outdegreecreation} [{opt reciprocity} {it:or} {opt reciprocityendow} {opt reciprocitycreation}]
[{it:{help nwsaom##covariate_options:covariate_options}}
{it:{help nwsaom##structural_options:structural_options}}
{it:{help nwsaom##interaction_options:interaction_options}}
{it:{help nwsaom##alias_options:alias_options}}
{it:{help nwsaom##coev_options:coev_options}}
{it:{help nwsaom##compchange_options:compchange_options}}
{it:{help nwsaom##ratecov_options:ratecov_options}}
{it:{help nwsaom##symmetric_options:symmetric_options}}
{it:{help nwsaom##control_options:control_options}}]

{synoptset 20}{...}
{p2col:{it:options}}Description{p_end}
{p2line}
{p2col:{it:{help nwsaom##covariate_options:covariate_options}}}node covariate main effects ({opt nodematch()}, {opt nodecov()}, {opt nodeicov()}, {opt nodeocov()}){p_end}
{p2col:{it:{help nwsaom##structural_options:structural_options}}}structural network effects (popularity, activity, triadic closure, isolates, assortativity, {opt gwesp()}){p_end}
{p2col:{it:{help nwsaom##interaction_options:interaction_options}}}two- or three-way interaction effects between already-included effects ({opt interact()}){p_end}
{p2col:{it:{help nwsaom##alias_options:alias_options}}}RSiena-spelling aliases for the covariate effects above ({opt simcov()}/{opt egox()}/{opt altx()}/{opt samex()}/{opt simx()}){p_end}
{p2col:{it:{help nwsaom##coev_options:coev_options}}}behavior co-evolution: a second, jointly-evolving dependent variable and its own effects{p_end}
{p2col:{it:{help nwsaom##compchange_options:compchange_options}}}composition change (joiners/leavers) and missing tie/behavior data{p_end}
{p2col:{it:{help nwsaom##ratecov_options:ratecov_options}}}covariate-dependent opportunity rate{p_end}
{p2col:{it:{help nwsaom##symmetric_options:symmetric_options}}}undirected/symmetric relations{p_end}
{p2col:{it:{help nwsaom##control_options:control_options}}}estimation method, starting values, replicate counts, and the random seed{p_end}

{p2colreset}{...}
{synoptset 22 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Observed waves}
{synopt:{opt wave1(netname)}}First observed wave; requires {opt wave2()}, exactly two waves. Not combinable with {opt waves()}{p_end}
{synopt:{opt wave2(netname)}}Second (ending) observed wave; requires {opt wave1()}{p_end}
{synopt:{opt waves(namelist)}}Two or more observed waves, in temporal order (e.g. {cmd:waves(w1 w2 w3)}) - chains {it:namelist}{cmd:-1} inter-wave periods into one pooled fit. Not combinable with {opt wave1()}/{opt wave2()}{p_end}

{syntab:Baseline network effects}
{synopt:{opt outdegree}}Outdegree (density) effect, evaluation-function role; {bf:required} in every model UNLESS {opt outdegreeendow}/{opt outdegreecreation} are given instead{p_end}
{synopt:{opt outdegreeendow}}Outdegree effect, ENDOWMENT (tie-withdrawal) role - splits outdegree's own contribution so it fires only on ties that are REMOVED between waves; must be given together with {opt outdegreecreation}, and not combined with plain {opt outdegree} (all three roles together are exactly collinear). {bf:Currently refused}: the endowment and creation statistics (lost and gained ties) add up to the rate's distance statistic, so with the rate estimated the model is not identified (RSiena reports a singular covariance matrix for it too). See {help nwsaom_remarks##endowcreation:Endowment/creation functions} in nwsaom_remarks{p_end}
{synopt:{opt outdegreecreation}}Outdegree effect, CREATION (new-tie) role - the mirror of {opt outdegreeendow}, firing only on ties that are ADDED between waves; must be given together with it{p_end}
{synopt:{opt reciprocity}}Reciprocated-tie effect, evaluation-function role{p_end}
{synopt:{opt reciprocityendow}}Reciprocity effect, ENDOWMENT role - same mechanism/rules as {opt outdegreeendow}, applied to reciprocity instead, with {opt outdegree}. Not yet supported combined with co-evolution, multi-wave models, {opt present()}, or {opt missnet()}. See {help nwsaom_remarks##endowcreation:Endowment/creation functions} in nwsaom_remarks{p_end}
{synopt:{opt reciprocitycreation}}Reciprocity effect, CREATION role - the mirror of {opt reciprocityendow}; must be given together with it{p_end}

{marker covariate_options}{...}
{syntab:Node covariate effects}
{synopt:{opth nodematch(varlist)}}Homophily on categorical node attributes (exact match), one effect per variable - RSiena alias {opt samex()}{p_end}
{synopt:{opth nodecov(varlist)}}Continuous covariate main effect (sum over sender's and receiver's own values), one effect per variable{p_end}
{synopt:{opth nodeicov(varlist)}}Alter (receiver) covariate effect - RSiena's own "altX", one effect per variable - RSiena alias {opt altx()}{p_end}
{synopt:{opth nodeocov(varlist)}}Ego (sender) covariate effect - RSiena's own "egoX", one effect per variable - RSiena alias {opt egox()}{p_end}

{synoptline}
{p2colreset}{...}

{synoptset 22 tabbed}{...}
{synopthdr}
{synoptline}
{marker structural_options}{...}
{syntab:Structural network effects}
{synopt:{opt indegpopularity}}Indegree popularity, sqrt-transformed ("preferential attachment" toward already-popular alters){p_end}
{synopt:{opt outpopularity}}Outdegree popularity, sqrt-transformed{p_end}
{synopt:{opt outactivity}}Outdegree activity, squared (concentrates out-ties on already-active senders){p_end}
{synopt:{opt inactivity}}Indegree activity, sqrt-transformed{p_end}
{synopt:{opt transtrip}}Transitive triplets (weighted count of transitive closures i->j via existing two-paths){p_end}
{synopt:{opt transmedtrip}}Transitive mediated triplets: for each tie i->j, the number of other actors with an incoming tie to both i and j (RSiena's own "transMedTrip") - a distinct measure of shared incoming ties from `transtrip'{p_end}
{synopt:{opt cycle3}}Directed 3-cycles (i->j->h->i){p_end}
{synopt:{opt cycle4}}Directed four-cycles effect: a directed three-path i->h<-k->j, closed by the tie
	i->j itself (RSiena's own "four cycles" effect). Base/fixed (non-sqrt) parameterization only{p_end}
{synopt:{opt transties}}Existence-indicator triadic closure - simpler, more robust alternative to {opt transtrip} (RSiena's own "transTies"); no parameter{p_end}
{synopt:{opt balance}}Structural balance effect (RSiena's own {cmd:balance}); no user-supplied parameter - the "balanceMean" constant is computed automatically from the observed wave data{p_end}
{synopt:{opt isolatenet}}Counts actors with BOTH indegree and outdegree exactly 0, true isolates (RSiena's own "network-isolate"); no parameter{p_end}
{synopt:{opt outiso}}Counts actors with outdegree exactly 0, regardless of indegree (RSiena's own "out-isolate"); no parameter{p_end}
{synopt:{opt antiiso}}Counts actors with indegree>=1 AND outdegree=0, a "pure receiver" (RSiena's own "anti isolates"); no parameter{p_end}
{synopt:{opt antiiniso}}Counts actors with indegree>=1, the complement of an in-isolate (RSiena's own "anti in-isolates"); no parameter{p_end}
{synopt:{opt antiiniso2}}Counts actors with indegree>=2 (RSiena's own "anti in-near-isolates"); no parameter{p_end}
{synopt:{opt inplus3}}Counts actors with indegree>=3 (RSiena's own "in3Plus", same effect family as {opt antiiniso}/{opt antiiniso2} with a higher threshold); no parameter{p_end}
{synopt:{opt isolatepop}}For each actor, counts its own ties to alters with indegree exactly 1 and outdegree 0 (RSiena's own "isolate - popularity"); no parameter{p_end}
{synopt:{opt transrectrip}}Like {opt transtrip}, but only counting two-paths i->j->h whose final leg j->h is itself reciprocated (RSiena's own "transitive reciprocated triplets"); no parameter{p_end}
{synopt:{opt outoutass}}Actors with high outdegree preferentially tie to other high-outdegree actors, default/non-sqrt parameterization only (RSiena's own "out-out degree assortativity"); no parameter{p_end}
{synopt:{opt ininass}}The {opt outoutass} sibling using indegree instead, default/non-sqrt parameterization only (RSiena's own "in-in degree assortativity"); no parameter{p_end}
{synopt:{opt outinass}}Actors with high outdegree preferentially tie to actors with high indegree, default/non-sqrt parameterization only (RSiena's own "out-in degree assortativity"); no parameter{p_end}
{synopt:{opt inoutass}}Actors with high indegree preferentially tie to actors with high outdegree, default/non-sqrt parameterization only (RSiena's own "in-out degree assortativity"); no parameter{p_end}
{synopt:{opt gwesp(real)}}Geometrically weighted edgewise shared partners (OTP-directed), fixed decay - argument is the DIRECT decay value (Statnet's own {opt gwesp(decay=)} scale), NOT RSiena's own "parameter" (RSiena's own value is 100x this one - RSiena {cmd:gwespFF(69)} = {opt gwesp(.69)} here){p_end}

{synoptline}
{p2colreset}{...}

{synoptset 22 tabbed}{...}
{synopthdr}
{synoptline}
{marker interaction_options}{...}
{syntab:Interaction effects}
{synopt:{opt interact(effect1#effect2[#effect3] [effect4#effect5 ...])}}Two- or three-way interaction (RSiena's own {cmd:includeInteraction()}) between effects ALREADY included in the model as their own main effects - the interaction's own contribution to an actor's ministep utility is the PRODUCT of the components' own contributions, with its own freely-estimated coefficient. Multiple interactions may be listed, space-separated. Restricted to "dyadic" (tie-level) effects that have a well-defined per-tie contribution to multiply: {bf:outdegree reciprocity nodematch nodecov nodeicov nodeocov transtrip cycle3 simcov transrectrip outoutass ininass outinass inoutass cycle4 transmedtrip gwesp transties balance} (and their RSiena aliases {opt egox()}/{opt altx()}/{opt samex()}/{opt simx()}) - the node-level effects ({bf:indegpopularity outactivity outpopularity inactivity isolatenet outiso antiiso antiiniso antiiniso2 inplus3}) have no such per-tie value and are rejected, whether named first, second, or third. A covariate effect given for several variables is named by its coefficient name, e.g. {cmd:interact(samex_smoke1#transtrip)} (either spelling, {cmd:nodematch_smoke1} or {cmd:samex_smoke1}); with one variable the effect type alone still works ({cmd:interact(samex#transtrip)}). Coefficients are named interact_{it:A}_{it:B}, or ix_{it:A}_{it:B} when that is longer than 32 characters. Three-way interactions run natively too (since 2026-10-01); behavior interactions are not yet supported. See {help nwsaom_remarks##nwsaom_interaction:Interaction effects} in nwsaom_remarks{p_end}

{marker alias_options}{...}
{syntab:RSiena naming aliases}
{synopt:{opth simcov(varlist)}}Covariate similarity effect, 1 - |x_i - x_j|/range minus its mean over all pairs (RSiena's simX; before 2026-10-01 not centred, which changed only the outdegree coefficient), one effect per variable - RSiena alias {opt simx()}{p_end}
{synopt:{opth egox(varlist)}}RSiena naming alias for {opt nodeocov()} - identical effect, coefficient label follows this spelling{p_end}
{synopt:{opth altx(varlist)}}RSiena naming alias for {opt nodeicov()} - identical effect, coefficient label follows this spelling{p_end}
{synopt:{opth samex(varlist)}}RSiena naming alias for {opt nodematch()} - identical effect, coefficient label follows this spelling{p_end}
{synopt:{opth simx(varlist)}}RSiena naming alias for {opt simcov()} - identical effect, coefficient label follows this spelling{p_end}

{synoptline}
{p2colreset}{...}

{synoptset 22 tabbed}{...}
{synopthdr}
{synoptline}
{marker coev_options}{...}
{syntab:Behavior co-evolution effects}
{synopt:{opth behavior(varlist)}}Co-evolution: one bounded-integer behavior variable, ONE Stata variable name per wave, same temporal order as {opt wave1()}/{opt wave2()} or {opt waves()} (e.g. two waves: {cmd:behavior(b1 b2)}; three: {cmd:behavior(b1 b2 b3)}). Requires {opt linear}. A SECOND dependent variable evolving jointly with the network - see {help nwsaom_remarks##coev:Co-evolution} in nwsaom_remarks{p_end}
{synopt:{opt linear}}Behavior linear shape effect (RSiena's own baseline behavior effect), evaluation-function role; {bf:required} whenever {opt behavior()} is specified UNLESS {opt linearendow}/{opt linearcreation} are given instead, matching {opt outdegree}'s own required-baseline role on the network side{p_end}
{synopt:{opt linearendow}}Behavior linear effect, ENDOWMENT (loss/decrease) role - splits the linear effect's downward direction into its own parameter; must be given together with {opt linearcreation}, and not combined with {opt linear} (all three roles together are exactly collinear). {bf:Currently refused}: the two statistics (decreases and increases) add up to the behavior rate's distance statistic, so with the behavior rate estimated the model is not identified (RSiena reports a singular covariance matrix for it too); use {opt linear}. See {help nwsaom_remarks##endowcreation:Endowment/creation functions} in nwsaom_remarks{p_end}
{synopt:{opt linearcreation}}Behavior linear effect, CREATION (gain/increase) role - the upward-direction counterpart to {opt linearendow}; must be given together with it{p_end}
{synopt:{opt quadratic}}Behavior quadratic shape effect; requires {opt behavior()}, not combinable with {opt quadraticendow}/{opt quadraticcreation}{p_end}
{synopt:{opt quadraticendow} {opt quadraticcreation}}Behavior quadratic effect split into its ENDOWMENT/CREATION roles - same mechanism/rules as {opt linearendow}/{opt linearcreation} (must be given together, not combined with plain {opt quadratic}), applied to the quadratic shape effect instead; independent of whichever baseline role ({opt linear} or {opt linearendow}/{opt linearcreation}) is in use{p_end}
{synopt:{opt avalt}}Behavior "average alter" influence effect - own value moves toward network neighbors' own average value; requires {opt behavior()}{p_end}
{synopt:{opt avaltendow} {opt avaltcreation}}{opt avalt} split into its ENDOWMENT/CREATION roles - same mechanism/rules as {opt linearendow}/{opt linearcreation}{p_end}
{synopt:{opt avsim}}Behavior "average similarity" influence effect - own value moves to maximize average similarity to network neighbors' own values, net of a data-derived centering constant; requires {opt behavior()}{p_end}
{synopt:{opt avsimendow} {opt avsimcreation}}{opt avsim} split into its ENDOWMENT/CREATION roles - same mechanism/rules as {opt linearendow}/{opt linearcreation}{p_end}
{synopt:{opt behsim}}Network-side SELECTION effect on the co-evolving behavior (RSiena's {cmd:simX} with the dependent behavior, e.g. "drinking similarity"): actors prefer ties to others whose CURRENT behavior value is similar to their own. Tie-level contribution 1 - |z_i - z_j|/range - simMean, with range and simMean the behavior's own (the same constants {opt avsim} uses). Unlike {opt simcov()}, which reads a fixed covariate, the values change during the simulation as the behavior co-evolves. A network effect: its coefficient appears among the network coefficients, after the other network effects. Requires {opt behavior()}{p_end}
{synopt:{opt behtheta0(numlist)}}Starting values for the behavior-side eval-parameter vector, one per requested behavior effect in the order {opt linear} (or {opt linearendow}/{opt linearcreation})/{opt quadratic}/{opt avalt}/{opt avsim} appear above; default all zero{p_end}

{synoptline}
{p2colreset}{...}

{synoptset 22 tabbed}{...}
{synopthdr}
{synoptline}
{marker compchange_options}{...}
{syntab:Composition change and missing data}
{synopt:{opth present(varlist)}}Composition change ("joiners and leavers"): one 0/1 variable per wave, same "one variable per wave" convention as {opt behavior()}, marking which actors are present at each wave. Optional - omitting it means every actor is present the whole time. See {help nwsaom_remarks##compchange:Composition change} in nwsaom_remarks{p_end}
{synopt:{opt missnet(matlist)}}Missing tie data: one 0/1 n x n MATRIX name per wave, marking which dyads are missing at that wave. Optional - omitting it means every dyad is fully observed. See {help nwsaom_remarks##missingdata:Missing data} in nwsaom_remarks{p_end}
{synopt:{opth missbeh(varlist)}}Missing behavior data: one 0/1 variable per wave, same "one variable per wave" convention as {opt present()}, marking which actors' behavior value is missing at that wave. Requires {opt behavior()}. Optional - omitting it means every actor's value is fully observed. See {help nwsaom_remarks##missingdata:Missing data} in nwsaom_remarks{p_end}
{synopt:{opt structural(matname)}}Structural zeros/ones: ONE 0/1 n x n MATRIX (zero diagonal) marking dyads whose tie value is fixed by design rather than actor choice (e.g. a legally mandated reporting tie, or a dyad known a priori to never form) - a marked dyad is excluded from every actor's own ministep candidate set, so it can never toggle during simulation. The marked dyad's OBSERVED value must be identical at both waves (a "frozen" dyad that genuinely changed between waves is rejected outright, matching RSiena's own structural-value convention that a fixed dyad's data must actually be constant). v1 scope: exactly two waves ({opt wave1()}/{opt wave2()}, not {opt waves()}), network-only (no {opt behavior()}); not yet combinable with {opt symmetric}, {opt ratecov()}, or the network endowment/creation split. See {help nwsaom_remarks##structural:Structural zeros/ones} in nwsaom_remarks{p_end}

{marker ratecov_options}{...}
{syntab:Covariate-dependent rate}
{synopt:{opth ratecov(varlist)}}Let node covariates raise or lower each actor's own opportunity to make a network change, instead of every actor sharing one constant rate for the period - actor i's own rate becomes {it:rate}*exp(sum of {it:b_k}*{it:x_k}[i]) over the variables, one coefficient each (RSiena's RateX effects). The coefficient is estimated jointly with every other effect. Not yet supported combined with co-evolution, multi-wave models, {opt present()}, or {opt missnet()}; combinable with {opt symmetric}. See {help nwsaom_remarks:Remarks}{p_end}
{synopt:{opt ratecovcoef(numlist)}}Starting values for the {opt ratecov()} coefficients, one per variable or one for all (default 0){p_end}

{marker symmetric_options}{...}
{syntab:Undirected/symmetric relations}
{synopt:{opt symmetric}}Model a non-directed relation (x_ij always equals x_ji). Not needed for waves declared undirected ({cmd:nwset ..., undirected}, {help nwsym}) or directed waves that are all tie-symmetric: like RSiena, {cmd:nwsaom} then models a non-directed relation automatically (tie-symmetric directed waves stay directed only with {opt reciprocity} or where the non-directed model does not apply: {opt waves()}, {opt behavior()}, endowment/creation effects). With directed waves that are not tie-symmetric {opt symmetric} is an error; it does not symmetrize data. Several effects are not meaningful for a non-directed relation and are rejected - see {help nwsaom_remarks##undirected:Remarks}. v1 scope: exactly two waves ({opt wave1()}/{opt wave2()}), network-only; combinable with {opt present()}, {opt missnet()}, and {opt ratecov()}{p_end}
{synopt:{opt symtype(string)}}Model type of a non-directed relation, by name or RSiena's modelType number: {bf:forcing} (2; default, RSiena's default for a symmetric network) - an actor chooses a tie to change and imposes it; {bf:confirmation} (3) - as forcing, but a new tie needs the alter's confirmation; {bf:force} (4), {bf:agree} (5), {bf:joint} (6) - pairwise: a random pair meets and the tie changes if the initiator wants it (force), if both want a new tie or either wants to end one (agree), or if their summed preferences favor it (joint). Before 2026-10-01 the default was {bf:joint} and types 2/3 were not available. See {help nwsaom_remarks##undirected:Remarks}{p_end}

{synoptline}
{p2colreset}{...}

{synoptset 22 tabbed}{...}
{synopthdr}
{synoptline}
{marker control_options}{...}
{syntab:Estimation control}
{synopt:{opt unconditional}}Estimate a network-only model by UNCONDITIONAL Method of Moments (RSiena's {cmd:cond = FALSE}): the rates become Method-of-Moments parameters. The default for a network-only model is CONDITIONAL estimation, RSiena's default for a single dependent network ({cmd:cond = TRUE}); co-evolution and {cmd:nwsaom multiplex} models are always unconditional, as in RSiena (see {help nwsaom_remarks##estimation:Estimation} in nwsaom_remarks){p_end}
{synopt:{opt rate0(numlist)}}Starting value(s) of the network rate(s) of an unconditional network-only fit: one value, or one per inter-wave period; default RSiena's closed-form starting value, computed from the data. With {opt theta0()}, restarts a fit from earlier estimates. For {opt symmetric} fits on RSiena's scale, as e(rate). Not used under conditional estimation, where the rates are not estimated by Robbins-Monro (see {help nwsaom_remarks##estimation:Estimation} in nwsaom_remarks){p_end}
{synopt:{opt theta0(numlist)}}Starting values for the eval-parameter vector, one per requested effect IN THE ORDER LISTED IN THE ERROR MESSAGE if omitted or mis-sized (outdegree first, then every other effect in the order its own option appears above); default all zero, except that a network-only model starts {opt outdegree} at RSiena's data-derived starting value{p_end}
{synopt:{opt k0(int)}}Phase-1 replicate count (Jacobian estimation via the score-function derivative estimator); default 50{p_end}
{synopt:{opt k3(int)}}Phase-3 replicate count (convergence diagnostics and the covariance matrix e(V)); default 1,000{p_end}
{synopt:{opt firstg(real)}}Phase-2 starting gain (Robbins-Monro step size); default 0.2, matching RSiena's own default{p_end}
{synopt:{opt seed(int)}}Set the random-number seed before simulating (for reproducibility){p_end}
{synopt:{opt cores(#)}}Number of threads the native simulator uses; default 0, all physical cores; {cmd:cores(1)} runs single-threaded. Every simulation draws from its own random stream derived from the seed and its position, so results for a given {opt seed()} are identical whatever the number of threads. Applies to fits with the native backend; see {help nwsaom_remarks##estimation:Estimation} in nwsaom_remarks{p_end}
{synoptline}
{p2colreset}{...}

{title:Description}

{pstd}
{cmd:nwsaom} fits a stochastic actor-oriented model (SAOM, Snijders-style) between two or more
observed panel waves of the same directed network on a fixed actor set - a fully native
Stata/Mata implementation, no R or other external statistical software called at any point. The
{browse "https://www.stats.ox.ac.uk/~snijders/siena/":RSiena} package (Ripley, Snijders et al.)
was studied in detail as the methodological reference throughout development - both its published
manual and, where the manual alone was not enough, its own real R/C++ source (read directly via
{cmd:gh api} against {browse "https://github.com/stocnet/rsiena":github.com/stocnet/rsiena} during
development) - and used, during development only, to certify {cmd:nwsaom}'s own independently
written implementation against real reference output. {cmd:nwsaom} is an independent
reimplementation and is not affiliated with or endorsed by the RSiena project.

{pstd}
An SAOM models network change as a sequence of unobserved, actor-driven "ministeps": between
consecutive observed waves, actors are activated one at a time (at a rate governed by the model's
own rate parameter) and each activated actor may create or drop exactly one of its own outgoing
ties, choosing among the available alternatives (including "no change") via a multinomial-logit
choice model on a linear combination of effect-specific "change statistics", weighted by the
effect's own estimated coefficient. This actor-oriented, MYOPIC formulation - an actor's own
choice is evaluated purely from that actor's own resulting local network statistic, never from
how the choice would affect any OTHER actor's own statistics - is what genuinely distinguishes an
SAOM from an ERGM (see {help nwergm}): an ERGM has no actors or ministeps at all, only a single
global probability distribution over entire graphs. Coefficients are estimated by the Method of
Moments via Robbins-Monro stochastic approximation (RSiena's own default estimation algorithm),
not maximum likelihood.

{title:Performance}

{pstd}
{cmd:nwsaom} has a native (C) simulation backend, used automatically whenever the fitted model's
effects all have native coverage (no option needed to opt in). See {help nwsaom_remarks:Remarks}
for a full wall-clock benchmark against real RSiena and the performance-tuning history behind it.

{title:Supported network types}

{pstd}
Binary: yes (only) - a valued/weighted wave is rejected. Directed: yes (required) - SAOM's own
ministep formulation is inherently directed (an actor controls only its own outgoing ties); an
undirected wave is rejected. Two-mode: no (rejected). Signed: not applicable/not supported.

{title:Limitations (v1 scope)}

{pstd}
{cmd:nwsaom} estimates {bf:binary, directed, one-mode} SAOMs:

{p2colset 9 13 15 2}{...}
{p2col: o}Two-mode (bipartite), temporal-metadata, valued/weighted, or undirected waves are all
rejected with an explicit error - never silently coerced.{p_end}
{p2col: o}Composition change (actors joining/leaving between waves, {opt present()}) and missing
tie/behavior data ({opt missnet()}/{opt missbeh()}) are both supported - see
{help nwsaom_remarks##compchange:Composition change} and {help nwsaom_remarks##missingdata:Missing data} in nwsaom_remarks for
each one's own scope and caveats. RSiena's own more general continuous/fractional within-period
join-leave timing is out of scope - {cmd:nwsaom} supports whole-period composition change only.{p_end}
{p2col: o}Behavior co-evolution ({opt behavior()}) supports exactly ONE co-evolving behavior
variable. The linear shape effect can be split into endowment/creation roles
({opt linearendow}/{opt linearcreation}); the same split is also available for
{opt quadratic}/{opt avalt}/{opt avsim} - see {help nwsaom_remarks##coev:Co-evolution} in nwsaom_remarks.{p_end}
{p2colreset}{...}

{pstd}
Each of {opt nodematch()}/{opt samex()}, {opt nodecov()}, {opt nodeicov()}/{opt altx()},
{opt nodeocov()}/{opt egox()}, {opt simcov()}/{opt simx()} and {opt ratecov()} takes a varlist:
one effect, with its own coefficient, per variable (as RSiena allows any number). Coefficients are
named {it:effect}_{it:variable}, using the spelling of the option given ({cmd:samex(smoke1 sport1)}
gives {cmd:samex_smoke1} and {cmd:samex_sport1}); with one variable the name is the same as it
always was. In e(b), and so in {opt theta0()}, the effect types come in their fixed order and,
within a type, the variables in the order listed; {cmd:matrix list e(b)} shows it. (Before
2026-10-01 each of these options took one variable.)

{marker effects}{...}

{title:Remarks}

{pstd}
See {help nwsaom_remarks} for the full effect-derivation library (every effect's own ministep
formula and how it was verified against RSiena's real source), interaction/multiplex/co-evolution
mechanics, composition-change/missing-data/structural-zero handling, the full performance
benchmark, and the estimation-algorithm background (Method-of-Moments phase structure, rate
estimation). That material was split into its own file purely to keep this file's own length
within Stata's interactive Viewer's rendering limits - it is not optional/secondary content,
just relocated.

{title:Postestimation}

{pstd}
{cmd:estat gof} reports RSiena's own goodness-of-fit methodology
({cmd:sienaGOF()}/{cmd:plot.sienaGOF()}, Lospinoso & Snijders 2019) - a fundamentally different,
more rigorous construction than a simple descriptive comparison: for each requested auxiliary
statistic (out-degree distribution, in-degree distribution, geodesic-distance distribution - the
same trio RSiena itself uses by default), {opt nsim()} fresh post-fit replicates are simulated at
the fitted coefficients (a genuine, disclosed architectural difference from real RSiena, which
reuses networks already stored during the fit itself - statistically equivalent, since the
Mahalanobis test is agnostic to how its reference draws were generated, only that they are genuine
independent draws at the fitted parameters), and a Mahalanobis-distance hypothesis test (a direct,
verified port of RSiena's own {cmd:applyTest()} construction, including its own Moore-Penrose
pseudoinverse handling of the collinear covariance matrix every distribution-category vector
produces) compares the observed wave's own auxiliary-statistic vector against that simulated
reference distribution. A small p-value (below 0.05, RSiena's own convention) is evidence AGAINST
the fitted model on that statistic. With three or more waves, the auxiliary-statistic vector is
POOLED (summed) across every period before the single test is run - RSiena's own {cmd:join=TRUE}
default, matching this package's own established summation-pooling convention for theta/the
Jacobian. Each statistic's own result is additionally rendered as a violin plot (kernel-density
shape per category, a thin embedded interquartile box, dashed 95% envelope lines, and the observed
value as a red overlay - Stata's standard DIY {cmd:kdensity}+{cmd:twoway rarea, horizontal}
technique, reproducing RSiena's own {cmd:plot.sienaGOF()} panel layout as closely as Stata's
graphics primitives allow) with the test's own p-value as the plot's x-axis title, matching
RSiena's own convention exactly.

{pstd}
See {help nwsaom_estat} for the full option reference for {cmd:estat gof} (and {cmd:estat mems},
Duxbury's Micro Effects on Macro Structure sensitivity analysis).

{title:Stored results}

{pstd}
{cmd:nwsaom} stores the following in {cmd:e()}:

		Scalars
		  {bf:e(N)}			number of actors (= e(nodes))
		  {bf:e(nodes)}			number of actors
		  {bf:e(nwaves)}		number of waves supplied
		  {bf:e(rate)}			network rate parameter (wave1()/wave2() path only): conditional estimation, the mean simulated time to reach the observed distance (RSiena's rate); unconditional, a Method-of-Moments estimate (see {help nwsaom_remarks##estimation:Estimation} in nwsaom_remarks). {opt symmetric} fits: on RSiena's scale for pairwise models (see {help nwsaom_remarks##undirected:Undirected/symmetric relations} in nwsaom_remarks)
		  {bf:e(ratecoefs)}		{opt ratecov()} fits: 1 x K covariate-rate coefficients, columns named by the variables; also {bf:e(ratecoefs_se)}, {bf:e(ratecoefs_tratio)}, {bf:e(ratecoefs_fixed)} (with one variable also the scalars {bf:e(ratecoef)}, {bf:e(ratecoef_se)}, {bf:e(ratecoef_tratio)}, {bf:e(ratecoef_fixed)})
		  {bf:e(engine)}		{bf:native} if the simulations ran in the C plugin, {bf:mata} if in Mata (then also a note after the table and {bf:e(engine_why)})
		  {bf:e(rate_actor)}		non-directed fits only: the rate at which an actor gets an opportunity to change, the scale of every other {cmd:nwsaom} rate (differs from e(rate), RSiena's rate, only for the pairwise types force/agree/joint)
		  {bf:e(conditional)}		1 for conditional estimation, 0 for unconditional
		  {bf:e(rate_tratio)}		network rate parameter's convergence t-ratio on RSiena's scale, missing under conditional estimation (wave1()/wave2() path only - see {help nwsaom_remarks##estimation:Estimation} in nwsaom_remarks)
		  {bf:e(rate_se)}		standard error of e(rate) (wave1()/wave2() path only); conditional estimation: RSiena's, the standard deviation of the simulated times
		  {bf:e(has_behavior)}		1 if this is a co-evolution fit ({opt behavior()} specified), 0 otherwise
		  {bf:e(p_net)}			number of network-side eval-parameter coefficients (co-evolution fits only; the first e(p_net) columns of e(b)/e(V)/e(tratio) are the network's own, the remainder the behavior's own, prefixed {cmd:beh_})
		  {bf:e(rate_beh)}		estimated behavior rate parameter (co-evolution, wave1()/wave2() path only), estimated jointly with the other parameters (see {help nwsaom_remarks##coev:Co-evolution} in nwsaom_remarks)
		  {bf:e(rate_beh_se)}		standard error of e(rate_beh) (co-evolution, wave1()/wave2() path only)
		  {bf:e(rate_beh_tratio)}	behavior rate parameter's convergence t-ratio on RSiena's scale (co-evolution, wave1()/wave2() path only)
		  {bf:e(tconv_max)}		RSiena's overall maximum convergence ratio; below 0.25 indicates good convergence

		Macros
		  {bf:e(cmd)}			{bf:nwsaom}
		  {bf:e(title)}			title of estimation
		  {bf:e(waves)}			list of wave network names, in temporal order
		  {bf:e(symtype)}		non-directed fits only: the model type, {bf:forcing}, {bf:confirmation}, {bf:force}, {bf:agree}, or {bf:joint}
		  {bf:e(modeltype)}		non-directed fits only: RSiena's modelType number of e(symtype) (2, 3, 4, 5, 6)
		  {bf:e(wave1)}			first wave name (wave1()/wave2() path only)
		  {bf:e(wave2)}			second wave name (wave1()/wave2() path only)
		  {bf:e(behavior)}		list of behavior variable names, one per wave, in temporal order (co-evolution fits only)
		  {bf:e(estat_cmd)}		{bf:nwsaom_estat} (postestimation dispatch)

		Matrices
		  {bf:e(b)}			coefficient vector (eval parameters only - excludes rate; network then behavior for a co-evolution fit, see e(p_net) above)
		  {bf:e(V)}			variance-covariance matrix (eval parameters only)
		  {bf:e(tratio)}		1 x nparam convergence t-ratios on RSiena's scale (phase-3 mean deviation / its standard deviation), one per coefficient of e(b) - the matching columns of e(tconv)
		  {bf:e(rates)}			1 x (nwaves-1) per-period network rate parameters (waves() path only), as e(rate)
		  {bf:e(rate_tratios)}		1 x (nwaves-1) per-period network rate convergence t-ratios (waves() path only)
		  {bf:e(rates_se)}		1 x (nwaves-1) per-period standard errors of e(rates) (waves() path only)
		  {bf:e(rates_beh)}		1 x (nwaves-1) per-period estimated behavior rate parameters (co-evolution, waves() path only)
		  {bf:e(rate_beh_tratios)}	1 x (nwaves-1) per-period behavior rate convergence t-ratios (co-evolution, waves() path only)
		  {bf:e(rates_beh_se)}		1 x (nwaves-1) per-period standard errors of e(rates_beh) (co-evolution, waves() path only)
		  {bf:e(tconv)}			RSiena-style convergence t-ratios (phase-3 mean deviation / its standard deviation), one per parameter including the rates; all below 0.1 in absolute value indicates good convergence. Printed after the coefficient table, followed by e(tconv_max). (Before 2026-10-01 e(tratio) and the rate t-ratios were mean / (sd/sqrt(k3)), about 31.6 times this scale with the default k3(1000))

{pstd}
{cmd:estat gof} stores the following in {cmd:r()}, one pair per requested statistic (default
{bf:outdegree}/{bf:indegree}/{bf:geodesic}):

		Scalars
		  {bf:r(p_{it:stat})}		empirical Mahalanobis-distance test p-value for that statistic
		  {bf:r(mhd_{it:stat})}		observed vector's own Mahalanobis distance from the simulated mean

{title:Examples}

{pstd}Friendship among 50 pupils, RSiena's s50 data:{p_end}
		{cmd:. nwwebuse glasgow, nwclear}
		{cmd:. nwsaom, waves(glasgow1 glasgow2 glasgow3) outdegree reciprocity transtrip seed(1)}
		{cmd:. estat gof}

{pstd}Restarting from the estimates when the overall maximum convergence ratio is above 0.25:{p_end}
		{cmd:. matrix b = e(b)}
		{cmd:. nwsaom, waves(glasgow1 glasgow2 glasgow3) outdegree reciprocity transtrip theta0(`=b[1,1]' `=b[1,2]' `=b[1,3]') seed(2)}

{pstd}The same model by unconditional estimation (RSiena's {cmd:cond = FALSE}), restarted with the rates too:{p_end}
		{cmd:. nwsaom, waves(glasgow1 glasgow2 glasgow3) outdegree reciprocity transtrip unconditional seed(1)}
		{cmd:. matrix b = e(b)}
		{cmd:. matrix r = e(rates)}
		{cmd:. nwsaom, waves(glasgow1 glasgow2 glasgow3) outdegree reciprocity transtrip unconditional theta0(`=b[1,1]' `=b[1,2]' `=b[1,3]') rate0(`=r[1,1]' `=r[1,2]') seed(2)}

{pstd}Other networks {cmd:wave1}, {cmd:wave2}, {cmd:wave3} and behavior variables {cmd:b1}-{cmd:b3}:{p_end}

		{cmd:. nwsaom, waves(wave1 wave2 wave3) outdegree transties balance}

		{cmd:. nwsaom, wave1(wave1) wave2(wave2) outdegree isolatenet outiso}

		{cmd:. nwsaom, wave1(wave1) wave2(wave2) outdegree reciprocity behavior(b1 b2) linear avalt}
		{cmd:. estat gof}

		{cmd:. nwsaom, waves(wave1 wave2 wave3) outdegree behavior(b1 b2 b3) linear avalt}

		{cmd:. nwsaom, waves(wave1 wave2 wave3) outdegree behavior(b1 b2 b3) linear avsim}

{pstd}Co-evolution of friendship and drinking (selection and influence), RSiena's s50 data:{p_end}
		{cmd:. nwwebuse glasgow, nwclear}
		{cmd:. nwsaom, waves(glasgow1 glasgow2 glasgow3) outdegree reciprocity transtrip behsim behavior(alcohol1 alcohol2 alcohol3) linear quadratic avalt seed(12345)}

		{cmd:. nwsaom, wave1(wave1) wave2(wave2) outdegree reciprocity behavior(b1 b2) linear quadraticendow quadraticcreation}

		{cmd:. nwsaom, wave1(wave1) wave2(wave2) outdegree reciprocity present(p1 p2)}

{title:References}

{pstd}
Snijders, T.A.B. (2001). The statistical evaluation of social network dynamics. {it:Sociological Methodology}, 31(1), 361-395. (SAOM/Method of Moments)

{pstd}
Snijders, T.A.B., van de Bunt, G.G., Steglich, C.E.G. (2010). Introduction to stochastic
actor-based models for network dynamics. {it:Social Networks}, 32(1), 44-60.

{pstd}
Ripley, R.M., Snijders, T.A.B., Boda, Z., Voros, A., Preciado, P. (2024). Manual for RSiena.
University of Oxford. {browse "https://www.stats.ox.ac.uk/~snijders/siena/":stats.ox.ac.uk/~snijders/siena/}

{pstd}
Lospinoso, J., Snijders, T.A.B. (2019). Goodness of fit for stochastic actor-oriented models.
{it:Methodological Innovations}, 12(3).

{pstd}
{cmd:nwsaom} is an independent, native reimplementation and is not affiliated with or endorsed by
the RSiena project.

{title:See also}

	{help nwergm}, {help nwset}, {help nwrandom}
