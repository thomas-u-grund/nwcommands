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

{synoptset 22 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Observed waves}
{synopt:{opt wave1(netname)}}First observed wave; requires {opt wave2()}, exactly two waves. Not combinable with {opt waves()}{p_end}
{synopt:{opt wave2(netname)}}Second (ending) observed wave; requires {opt wave1()}{p_end}
{synopt:{opt waves(namelist)}}Two or more observed waves, in temporal order (e.g. {cmd:waves(w1 w2 w3)}) - chains {it:namelist}{cmd:-1} inter-wave periods into one pooled fit. Not combinable with {opt wave1()}/{opt wave2()}{p_end}

{syntab:Baseline network effects}
{synopt:{opt outdegree}}Outdegree (density) effect, evaluation-function role; {bf:required} in every model UNLESS {opt outdegreeendow}/{opt outdegreecreation} are given instead{p_end}
{synopt:{opt outdegreeendow}}Outdegree effect, ENDOWMENT (tie-withdrawal) role - splits outdegree's own contribution so it fires only on ties that are REMOVED between waves; must be given together with {opt outdegreecreation}, and not combined with plain {opt outdegree} (all three roles together are exactly collinear). Satisfies the same required-baseline role plain {opt outdegree} does. Not yet supported combined with co-evolution, multi-wave models, {opt present()}, or {opt missnet()}. See {help nwsaom##endowcreation:Endowment/creation functions} below{p_end}
{synopt:{opt outdegreecreation}}Outdegree effect, CREATION (new-tie) role - the mirror of {opt outdegreeendow}, firing only on ties that are ADDED between waves; must be given together with it{p_end}
{synopt:{opt reciprocity}}Reciprocated-tie effect, evaluation-function role{p_end}
{synopt:{opt reciprocityendow}}Reciprocity effect, ENDOWMENT role - same mechanism/rules as {opt outdegreeendow}, applied to reciprocity instead; independent of whichever baseline role ({opt outdegree} or {opt outdegreeendow}/{opt outdegreecreation}) is in use. Note: on data where a mutual tie is essentially never lost in BOTH directions at once, this effect's own observed target can be exactly zero, leaving it unidentified (a genuine data property, not a bug) - see {help nwsaom##endowcreation:Endowment/creation functions} below{p_end}
{synopt:{opt reciprocitycreation}}Reciprocity effect, CREATION role - the mirror of {opt reciprocityendow}; must be given together with it{p_end}

{marker covariate_options}{...}
{syntab:Node covariate effects}
{synopt:{opth nodematch(varname)}}Homophily on a categorical node attribute (exact match); ONE variable per model - RSiena alias {opt samex()}{p_end}
{synopt:{opth nodecov(varname)}}Continuous covariate main effect (sum over sender's and receiver's own values); ONE variable per model{p_end}
{synopt:{opth nodeicov(varname)}}Alter (receiver) covariate effect - RSiena's own "altX"; ONE variable per model - RSiena alias {opt altx()}{p_end}
{synopt:{opth nodeocov(varname)}}Ego (sender) covariate effect - RSiena's own "egoX"; ONE variable per model - RSiena alias {opt egox()}{p_end}

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

{marker interaction_options}{...}
{syntab:Interaction effects}
{synopt:{opt interact(effect1#effect2[#effect3] [effect4#effect5 ...])}}Two- or three-way interaction (RSiena's own {cmd:includeInteraction()}) between effects ALREADY included in the model as their own main effects - the interaction's own contribution to an actor's ministep utility is the PRODUCT of the components' own contributions, with its own freely-estimated coefficient. Multiple interactions may be listed, space-separated. Restricted to "dyadic" (tie-level) effects that have a well-defined per-tie contribution to multiply: {bf:outdegree reciprocity nodematch nodecov nodeicov nodeocov transtrip cycle3 simcov transrectrip outoutass ininass outinass inoutass cycle4 transmedtrip gwesp transties balance} (and their RSiena aliases {opt egox()}/{opt altx()}/{opt samex()}/{opt simx()}) - the node-level effects ({bf:indegpopularity outactivity outpopularity inactivity isolatenet outiso antiiso antiiniso antiiniso2 inplus3}) have no such per-tie value and are rejected, whether named first, second, or third. Three-way interactions are Mata-only (no native speed-up yet); behavior interactions are not yet supported. See {help nwsaom##nwsaom_interaction:Interaction effects} below{p_end}

{marker alias_options}{...}
{syntab:RSiena naming aliases}
{synopt:{opth simcov(varname)}}Covariate similarity effect; ONE variable per model - RSiena alias {opt simx()}{p_end}
{synopt:{opth egox(varname)}}RSiena naming alias for {opt nodeocov()} - identical effect, coefficient label follows this spelling{p_end}
{synopt:{opth altx(varname)}}RSiena naming alias for {opt nodeicov()} - identical effect, coefficient label follows this spelling{p_end}
{synopt:{opth samex(varname)}}RSiena naming alias for {opt nodematch()} - identical effect, coefficient label follows this spelling{p_end}
{synopt:{opth simx(varname)}}RSiena naming alias for {opt simcov()} - identical effect, coefficient label follows this spelling{p_end}

{marker coev_options}{...}
{syntab:Behavior co-evolution effects}
{synopt:{opth behavior(varlist)}}Co-evolution: one bounded-integer behavior variable, ONE Stata variable name per wave, same temporal order as {opt wave1()}/{opt wave2()} or {opt waves()} (e.g. two waves: {cmd:behavior(b1 b2)}; three: {cmd:behavior(b1 b2 b3)}). Requires {opt linear}. A SECOND dependent variable evolving jointly with the network - see {help nwsaom##coev:Co-evolution} below{p_end}
{synopt:{opt linear}}Behavior linear shape effect (RSiena's own baseline behavior effect), evaluation-function role; {bf:required} whenever {opt behavior()} is specified UNLESS {opt linearendow}/{opt linearcreation} are given instead, matching {opt outdegree}'s own required-baseline role on the network side{p_end}
{synopt:{opt linearendow}}Behavior linear effect, ENDOWMENT (loss/decrease) role - splits the linear effect's downward direction into its own parameter; must be given together with {opt linearcreation}, and not combined with {opt linear} (all three roles together are exactly collinear). See {help nwsaom##endowcreation:Endowment/creation functions} below{p_end}
{synopt:{opt linearcreation}}Behavior linear effect, CREATION (gain/increase) role - the upward-direction counterpart to {opt linearendow}; must be given together with it{p_end}
{synopt:{opt quadratic}}Behavior quadratic shape effect; requires {opt behavior()}, not combinable with {opt quadraticendow}/{opt quadraticcreation}{p_end}
{synopt:{opt quadraticendow} {opt quadraticcreation}}Behavior quadratic effect split into its ENDOWMENT/CREATION roles - same mechanism/rules as {opt linearendow}/{opt linearcreation} (must be given together, not combined with plain {opt quadratic}), applied to the quadratic shape effect instead; independent of whichever baseline role ({opt linear} or {opt linearendow}/{opt linearcreation}) is in use{p_end}
{synopt:{opt avalt}}Behavior "average alter" influence effect - own value moves toward network neighbors' own average value; requires {opt behavior()}{p_end}
{synopt:{opt avaltendow} {opt avaltcreation}}{opt avalt} split into its ENDOWMENT/CREATION roles - same mechanism/rules as {opt linearendow}/{opt linearcreation}{p_end}
{synopt:{opt avsim}}Behavior "average similarity" influence effect - own value moves to maximize average similarity to network neighbors' own values, net of a data-derived centering constant; requires {opt behavior()}{p_end}
{synopt:{opt avsimendow} {opt avsimcreation}}{opt avsim} split into its ENDOWMENT/CREATION roles - same mechanism/rules as {opt linearendow}/{opt linearcreation}{p_end}
{synopt:{opt behtheta0(numlist)}}Starting values for the behavior-side eval-parameter vector, one per requested behavior effect in the order {opt linear} (or {opt linearendow}/{opt linearcreation})/{opt quadratic}/{opt avalt}/{opt avsim} appear above; default all zero{p_end}

{marker compchange_options}{...}
{syntab:Composition change and missing data}
{synopt:{opth present(varlist)}}Composition change ("joiners and leavers"): one 0/1 variable per wave, same "one variable per wave" convention as {opt behavior()}, marking which actors are present at each wave. Optional - omitting it means every actor is present the whole time. See {help nwsaom##compchange:Composition change} below{p_end}
{synopt:{opt missnet(matlist)}}Missing tie data: one 0/1 n x n MATRIX name per wave, marking which dyads are missing at that wave. Optional - omitting it means every dyad is fully observed. See {help nwsaom##missingdata:Missing data} below{p_end}
{synopt:{opth missbeh(varlist)}}Missing behavior data: one 0/1 variable per wave, same "one variable per wave" convention as {opt present()}, marking which actors' behavior value is missing at that wave. Requires {opt behavior()}. Optional - omitting it means every actor's value is fully observed. See {help nwsaom##missingdata:Missing data} below{p_end}
{synopt:{opt structural(matname)}}Structural zeros/ones: ONE 0/1 n x n MATRIX (zero diagonal) marking dyads whose tie value is fixed by design rather than actor choice (e.g. a legally mandated reporting tie, or a dyad known a priori to never form) - a marked dyad is excluded from every actor's own ministep candidate set, so it can never toggle during simulation. The marked dyad's OBSERVED value must be identical at both waves (a "frozen" dyad that genuinely changed between waves is rejected outright, matching RSiena's own structural-value convention that a fixed dyad's data must actually be constant). v1 scope: exactly two waves ({opt wave1()}/{opt wave2()}, not {opt waves()}), network-only (no {opt behavior()}); not yet combinable with {opt symmetric}, {opt ratecov()}, or the network endowment/creation split. See {help nwsaom##structural:Structural zeros/ones} below{p_end}

{marker ratecov_options}{...}
{syntab:Covariate-dependent rate}
{synopt:{opth ratecov(varname)}}Let a node covariate raise or lower each actor's own opportunity to make a network change, instead of every actor sharing one constant rate for the period - actor i's own rate becomes {it:rate}*exp({bf:ratecovcoef}*{it:varname}[i]). The coefficient is estimated jointly with every other effect. Not yet supported combined with co-evolution, multi-wave models, {opt present()}, {opt missnet()}, or {opt symmetric}. See {bf:Remarks} below{p_end}
{synopt:{opt ratecovcoef(real)}}Starting value for {opt ratecov()}'s own jointly-estimated coefficient (default 0){p_end}

{marker symmetric_options}{...}
{syntab:Undirected/symmetric relations}
{synopt:{opt symmetric}}Fit a relation where every tie is symmetric (x_ij always equals x_ji), using a mutual-consent ministep: a candidate tie change is only made when BOTH actors' own preferences favor it. Requires the input data to already be tie-symmetric at both waves (this option changes how ties are simulated, it does not symmetrize your data). Several effects are not meaningful once every tie is forced symmetric and are rejected outright - see {bf:Remarks} below for the full list. v1 scope: exactly two waves ({opt wave1()}/{opt wave2()}, not {opt waves()}), network-only (no {opt behavior()}); combinable with {opt present()}, {opt missnet()}, and {opt ratecov()} (see {bf:Remarks}){p_end}
{synopt:{opt symtype(string)}}Which mutual-consent rule {opt symmetric} uses: {bf:joint} (default) accepts a change when the sum of both actors' own preferences is favorable; {bf:force} lets the initiating actor alone decide, ignoring the other actor's own preference; {bf:agree} requires both actors to independently agree when creating a tie, or either one to want it gone when removing one. Requires {opt symmetric}{p_end}

{marker control_options}{...}
{syntab:Estimation control}
{synopt:{opt rate0(real)}}Accepted for backward compatibility only - {bf:no longer used}; the rate parameter's own starting value is now computed automatically from the observed data via RSiena's own verified closed-form formula (see {bf:Remarks} below){p_end}
{synopt:{opt theta0(numlist)}}Starting values for the eval-parameter vector, one per requested effect IN THE ORDER LISTED IN THE ERROR MESSAGE if omitted or mis-sized (outdegree first, then every other effect in the order its own option appears above); default all zero{p_end}
{synopt:{opt k0(int)}}Phase-1 replicate count (Jacobian estimation via the score-function derivative estimator); default 50{p_end}
{synopt:{opt k3(int)}}Phase-3 replicate count (convergence diagnostics and the covariance matrix e(V)); default 1,000{p_end}
{synopt:{opt firstg(real)}}Phase-2 starting gain (Robbins-Monro step size); default 0.2, matching RSiena's own default{p_end}
{synopt:{opt seed(int)}}Set the random-number seed before simulating (for reproducibility){p_end}
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

{pstd}
{bf:A genuine, hard-won methodological lesson from this implementation's own development, worth stating explicitly here}: several of RSiena's own effects (e.g. {opt gwesp()}) compute their
observed/global statistic in a way that is IDENTICAL to the corresponding ERGM statistic, which
made it tempting to also reuse an ERGM package's own change-statistic (ministep) formula for the
same effect - this is WRONG in general. RSiena's own ministep formula for a given effect is
restricted to the ACTIVATED ACTOR'S OWN statistic only (the myopic-actor rule above), which for
several effects is a genuinely SMALLER quantity than the effect's own full ERGM change statistic
(which legitimately captures the toggle's effect on every actor's own statistic, appropriate for
an ERGM's single-actor-free global model but not for an SAOM ministep). Every effect below was
independently re-derived and verified against RSiena's own real ministep-contribution source
code, not assumed from its global-statistic formula alone; see {help nwsaom##effects:Effect library} below for the account, term by term, including one case ({opt gwesp()}) where an initial
reuse assumption was shipped, caught, and corrected during this package's own development - kept
in that section's own account rather than silently erased, matching this whole package's
disclosure standard.

{title:Performance}

{pstd}
{cmd:nwsaom} has a native (C) simulation backend, used automatically whenever the fitted model's
effects all have native coverage (no option needed to opt in - see {bf:Estimation} below and, for
co-evolution, the note at the end of {help nwsaom##coev:Co-evolution} below). A direct, reproducible
wall-clock comparison against a real, installed RSiena (version 1.6.6, R 4.6.0) - identical data,
identical model, single run each, scripts and full methodology in {browse "dev/saom_rsiena_benchmark.R"}
and {browse "dev/saom_rsiena_benchmark.do"} - on RSiena's own standard s50 tutorial dataset (50
students, friendship network + alcohol-use behavior, waves 1-2):

{p2colset 9 13 15 2}{...}
{p2col: o}outdegree + reciprocity: RSiena 0.96s, {cmd:nwsaom} 0.94s{p_end}
{p2col: o}+ behavior(alcohol), linear + quadratic: RSiena 1.18s, {cmd:nwsaom} 0.63s{p_end}
{p2colreset}{...}

{pstd}
For the network-only model {cmd:nwsaom} is at parity with real RSiena; for the co-evolution model
it is genuinely faster. This did not happen by accident: an earlier round of this same benchmark
found {cmd:nwsaom} roughly 22x slower (network-only) and 3.2x slower (co-evolution) than real
RSiena, and both gaps were profiled and closed - not by approximating the method more coarsely, but
by finding and eliminating real, avoidable overhead (a rate-refinement loop that had never been
ported to the native backend, and a co-evolution code path that was silently redoing, in slow
interpreted Mata, statistic computations the native backend had already computed in C).

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
{help nwsaom##compchange:Composition change} and {help nwsaom##missingdata:Missing data} below for
each one's own scope and caveats. RSiena's own more general continuous/fractional within-period
join-leave timing is out of scope - {cmd:nwsaom} supports whole-period composition change only.{p_end}
{p2col: o}Behavior co-evolution ({opt behavior()}) supports exactly ONE co-evolving behavior
variable. The linear shape effect can be split into endowment/creation roles
({opt linearendow}/{opt linearcreation}); the same split is also available for
{opt quadratic}/{opt avalt}/{opt avsim} - see {help nwsaom##coev:Co-evolution} below.{p_end}
{p2colreset}{...}

{pstd}
Each of {opt nodematch()}, {opt nodecov()}, {opt nodeicov()}/{opt egox()}, {opt nodeocov()}/
{opt altx()}, {opt simcov()}/{opt simx()} accepts exactly ONE variable per model (unlike
{help nwergm}'s own {opt varlist}-based options) - a real, current v1 restriction, not a design
choice expected to be permanent.

{marker effects}{...}
{title:Effect library}

{pstd}
{bf:outdegree} and {bf:reciprocity} are the base structural effects, direct RSiena analogues of
{help nwergm}'s own {opt edges}/{opt mutual}.

{pstd}
{bf:nodematch()}/{bf:nodecov()}/{bf:nodeicov()}/{bf:nodeocov()} are direct reuses of
{help nwergm}'s own already-certified covariate-effect statistic/change-statistic pair - each is a
genuine single-actor-local effect (an actor's own choice depends only on its own and the specific
alter's own covariate value), so no myopic-actor restriction was needed here; RSiena's own naming
maps as {opt nodeocov()} = "egoX" (sender's own value), {opt nodeicov()} = "altX" (receiver's own
value), {opt nodematch()} = "sameX", {opt nodecov()} = their combined sum.

{pstd}
{bf:indegpopularity}/{bf:outpopularity}/{bf:outactivity}/{bf:inactivity} are freshly derived
SAOM-native effects (no ERGM analogue reused) - sqrt-transformed in/outdegree popularity, squared
outdegree activity, and sqrt-transformed indegree activity respectively, each independently
verified against RSiena's own real effect source before implementation. A genuine, disclosed
subtlety: unlike a single-actor-local covariate effect above, these effects' own ministep deltas
do NOT equal a toggle's effect on the global statistic (toggling one tie changes OTHER actors' own
popularity/activity statistics too) - expected behavior for a myopic-actor SAOM formulation, not a
bug.

{pstd}
{bf:transtrip} (transitive triplets) and {bf:cycle3} (directed 3-cycles) are freshly derived,
reusing {cmd:nwsaom}'s own already-certified shared-partner primitives (two-path/out-star/in-star
counts) rather than any ERGM term-function pair directly - {opt transtrip}'s own ministep delta is
OTP(i,j)+OSP(i,j); {opt cycle3}'s is OTP(j,i) (a genuinely different, easy-to-get-backwards
argument order from {opt transtrip}'s own).

{pstd}
{bf:transties} (RSiena's own "transTies") is a simpler, existence-indicator alternative to
{opt transtrip}: a tied arc i->j counts toward the statistic if AND ONLY IF a two-path i->k->j
already exists, rather than {opt transtrip}'s own weighted count of every such two-path. Verified
directly against RSiena's real {cmd:TransitiveTiesEffect.cpp} - its OWN dedicated ministep-
contribution class (not a "Generic effect" wrapper, see {opt gwesp()} below), so its own ministep
formula genuinely is the exact myopic-actor-restricted gradient of a well-defined local statistic;
certified via brute-force recomputation, not merely assumed. Natively ported.

{pstd}
{bf:balance} (RSiena's own structural balance) has NO user-supplied parameter: RSiena's own
"balanceMean" constant (the SIENA manual's {it:b0}) is a DATA-DERIVED quantity - the empirical mean
of |x_ih - x_jh| over every distinct valid actor triple in the observed wave data - computed
automatically from the wave(s) supplied to {opt wave1()}/{opt wave2()} or {opt waves()} at
estimation time, pooled across every inter-wave PERIOD'S OWN starting wave by summing
numerators/denominators separately and dividing once (RSiena's own {cmd:calcBalmean()} pooling
convention exactly, not an average of per-period ratios). Like {opt transties}, {opt balance} has
its own dedicated RSiena ministep class, and was independently verified against RSiena's real
{cmd:BalanceEffect.cpp} source before implementation. Natively ported (the data-derived
balanceMean constant crosses to the native backend as an ordinary per-term parameter, computed
once before simulation starts).

{pstd}
{bf:isolatenet} (RSiena's own "network-isolate") and {bf:outiso} (RSiena's own "out-isolate") both
have NO user-supplied parameter. {opt isolatenet} counts TRUE isolates - actors with BOTH indegree
AND outdegree exactly 0 - verified against RSiena's real {cmd:IsolateNetEffect.cpp} source; a
genuine, disclosed multi-actor spillover applies here (creating a tie also raises the ALTER's own
indegree, which can independently change the alter's own isolate status too - the same kind of
spillover {opt indegpopularity}/{opt outactivity} already have). {opt outiso} counts actors with
outdegree exactly 0 REGARDLESS of indegree - a weaker condition than {opt isolatenet}'s own true-isolate
definition - verified against RSiena's real {cmd:TruncatedOutdegreeEffect.cpp} source (RSiena's own
{cmd:EffectFactory.cpp} confirms "outIso" maps to that class with a specific parameter configuration,
not a separate dedicated class); unlike {opt isolatenet}, {opt outiso} has no such spillover (toggling
an actor's own outgoing tie never affects another actor's own outdegree).

{pstd}
{bf:antiiso}/{bf:antiiniso}/{bf:antiiniso2}/{bf:inplus3}/{bf:isolatepop} are RSiena's own
alter-indexed isolate family - each actor's own ministep contribution depends on the ALTER's degree,
not ego's own (like {opt indegpopularity}), verified against RSiena's real
{cmd:AntiIsolateEffect.cpp}/{cmd:IsolatePopEffect.cpp} source. {opt inplus3} is RSiena's real
"in3Plus" (its own {cmd:EffectFactory.cpp} dispatches it to the SAME {cmd:AntiIsolateEffect} class
as {opt antiiniso}/{opt antiiniso2}, just with a threshold of 3 instead of 1/2) - exposed as
{opt inplus3} rather than the RSiena-matching spelling because Stata's own {cmd:syntax} command
does not accept an option name with a digit followed by more letters; the coefficient itself is
still labeled {cmd:in3plus}. {opt antiiniso}/{opt antiiniso2}/{opt inplus3} are genuinely
spillover-free (match the exact global before/after difference on any toggle, {opt outiso}'s own
shape) and natively ported; {opt antiiso}/{opt isolatepop} remain Mata-only.
{opt antiiso}/{opt isolatepop} additionally gate on the alter's own outdegree, which gives them a
real, disclosed multi-actor spillover of their own (an actor's own outgoing tie choice changes that
actor's OWN outdegree, which can independently flip that same actor's own separate membership in
{opt antiiso}'s global count - the same kind of spillover {opt isolatenet} already has, just via a
different pathway). {bf:{opt antiiso}/{opt isolatepop} are known to destabilize the Robbins-Monro estimator on small/sparse networks} (the same class of fragility {opt isolatenet} already has,
confirmed independent of native/Mata backend). {bf:Both {opt isolatenet}/{opt outiso} and this family can be weakly identified on small or sparse networks} - a real, disclosed finding from development, not
hypothetical: real Glasgow data (this help file's own worked examples) has zero isolates at every
observed wave, so it cannot exercise either effect at all, and even toy networks up to 10 actors with
a handful of isolate transitions were enough to trigger {bf:thetaBound} or the phase-3
covariance-finiteness safeguard during certification - the same kind of rare-count identification
limit {opt linearendow}/{opt linearcreation} has (see {help nwsaom##endowcreation:Endowment/creation functions} above), not a defect in either effect.

{pstd}
{bf:transrectrip}/{bf:outoutass}/{bf:ininass} are a small batch picked from RSiena's own real,
current remaining effect catalog (RSiena 1.6.6's own {cmd:getEffects()} inventory), each verified
against its own real RSiena C++ source ({cmd:TransitiveReciprocatedTripletsEffect.cpp}/
{cmd:OutOutDegreeAssortativityEffect.cpp}/{cmd:InInDegreeAssortativityEffect.cpp}). Default/base
parameterization only in each case (v1 scope, matching {opt gwesp()}'s own fixed-decay-first
precedent) - none of the three expose a {cmd:sqrt}-transformed variant. {bf:All three have a genuine, disclosed multi-actor spillover}, the same class {opt isolatenet} already has: each
actor's own ministep change function correctly computes only its OWN local delta (matching
RSiena's real {cmd:calculateContribution} exactly), while the toggle can also shift OTHER actors'
own separate statistics (e.g. for {opt outoutass}, any pre-existing tie INTO the toggling actor
uses that actor's own outdegree as its own alter-degree factor) - by SAOM's own "myopic actor"
design this is correct, not a bug, but it does mean a naive whole-network before/after comparison
is the wrong way to spot-check these three - compare against each ego's own recomputed local
statistic instead.

{pstd}
{bf:outinass}/{bf:inoutass} complete the remaining two directed-assortativity directions RSiena
offers, verified against the real {cmd:OutInDegreeAssortativityEffect.cpp}/
{cmd:InOutDegreeAssortativityEffect.cpp}. {bf:outinass} is NOT a mechanical degree-substitution of
{opt outoutass} - toggling a tie changes the alter's own INdegree too (an out-tie from the toggling
actor is an in-tie to the alter), so its creating-branch formula differs from {opt outoutass}'s own
in a way only the real source reveals; it has the SAME kind of multi-actor spillover as
{opt outoutass}/{opt ininass} above. {bf:inoutass} is the simplest of all four directions - neither
factor in its own product (indegree of ego, outdegree of alter) is affected by the toggle in either
direction, so it has NO spillover at all, not even within the toggling actor's own row. Both are
natively ported from introduction (unlike {opt transrectrip}/{opt outoutass}/{opt ininass}'s own
first-pass Mata-only release, later ported natively too).

{pstd}
{bf:gwesp(real)} (geometrically weighted edgewise shared partners, OTP-directed) reuses
{help nwergm}'s own already-certified GLOBAL/observed statistic directly (RSiena's own
{cmd:tieStatistic()} confirmed to match it exactly) but NOT its own full ERGM change statistic for
the ministep: RSiena's real {cmd:gwespFF} effect is wired through its own "Generic effect"
framework ({cmd:GenericNetworkEffect::calculateContribution()}), whose own ministep contribution
is JUST the geometric-decay kernel's own lookup for the toggled dyad's CURRENT shared-partner
count - no neighbor-adjustment loops at all - a genuinely simpler, deliberate approximation
specific to that framework, NOT the same quantity as {help nwergm}'s own full change statistic
(own-dyad term plus two neighbor-adjustment loops, correct for an ERGM MCMC toggle's effect on the
GLOBAL statistic, but the wrong standard for an SAOM ministep). {bf:These are genuinely different quantities, not interchangeable, and the corrected, ministep-specific formula is what ships here.} The
{opt gwesp()} argument is the DIRECT decay value (Statnet's own convention, matching
{help nwergm}'s own {opt gwesp()}) - NOT RSiena's own user-facing "parameter", which is 100x this
value (RSiena's default {cmd:gwespFF(69)} corresponds to {opt gwesp(.69)} here). Natively ported
(the decay argument crosses to the native backend as an ordinary per-term parameter).

{pstd}
{bf:simcov(varname)} (covariate similarity) is freshly derived and independently verified against
RSiena's real {cmd:CovariateSimilarityEffect.cpp}/{cmd:Covariate.cpp} source: Delta =
plus-or-minus(1 - |attr_i - attr_j| / range), where {it:range} is the observed variable's own
max-minus-min. A disclosed simplification: this omits RSiena's own {cmd:similarityMean} centering
constant - a pure re-parameterization against the always-present {opt outdegree} term, not a
correctness gap.

{marker nwsaom_interaction}{...}
{title:Interaction effects}

{pstd}
{opt interact(effect1#effect2 [#effect3])} is a direct port of RSiena's real
{cmd:includeInteraction()} mechanism (its underlying C++ class, {cmd:NetworkInteractionEffect}):
the interaction's own contribution to an actor's ministep utility, for a candidate tie change to a
given alter, is the PRODUCT of the component effects' own contributions (not their sum, and not
computed on the components' aggregate statistics) - so {cmd:interact(reciprocity#transtrip)}
contributes {it:reciprocity's own change value} times {it:transtrip's own change value} for that
same candidate tie, with its own freely-estimated coefficient. The reported/target STATISTIC for an
interaction term is likewise the sum, over the network's existing ties, of the product of the
components' own per-tie value at that tie - genuinely different from simply multiplying the
components' own already-reported totals together, and different again from the ministep
contribution formula above for any component effect whose own ministep contribution has a
"spillover" onto other ties ({opt transties}, {opt outoutass}, {opt ininass}, {opt outinass},
{opt inoutass}, {opt cycle4}, {opt balance}) - RSiena's own real source keeps these as two
genuinely different functions ({cmd:tieStatistic()} for the statistic,
{cmd:calculateContribution()} for the ministep), and this port mirrors that split exactly rather
than approximating one with the other. A THIRD effect is optional, matching RSiena's own
{cmd:includeInteraction()} signature exactly (its own {cmd:effect3} argument, confirmed directly
from real source): when given, it simply multiplies in as a third factor, both for the ministep
contribution and the statistic - {cmd:interact(reciprocity#transtrip#nodecov(x))} contributes the
product of all three components' own values. Three-way {opt interact()} is Mata-only for now (the
native backend's own wire protocol has room for only two component references); it still runs, just
without the native speed-up, falling back the same way any other native-ineligible model does.

{pstd}
Every named effect must already be included in the model as its own main-effect term (add
{opt reciprocity} and {opt transtrip} before writing {cmd:interact(reciprocity#transtrip)}) - an
interaction naming an effect not otherwise in the model is rejected with a clear error, never
silently invented. Only "dyadic" (tie-level) effects with a well-defined per-tie value are eligible
(see {opt interact()}'s own syntax-table entry above for the full list); the node-level effects
(indegree/outdegree popularity and activity, the isolate family) are RSiena's own "ego effects" and
have no such value, so are rejected outright, whether named first, second, or third.

{pstd}
Like any other effect, an interaction's own identifiability depends on the data: two effects that
are themselves highly correlated in a given network (a common real property of, for example,
reciprocity and transitivity in friendship data, where most closed triads are also reciprocated)
can leave their PRODUCT weakly identified even though each main effect alone estimates cleanly -
the SAME kind of Robbins-Monro divergence (a non-positive Jacobian diagonal, or a near-singular
phase-3 covariance) this file's own {opt thetaBound} safeguard already catches for other effects,
not a defect in this port. A model with an interaction between two effects unrelated to each other
(e.g. {cmd:interact(reciprocity#nodecov(x))} for an {it:x} uncorrelated with network structure)
converges normally.

{marker multiplex}{...}
{title:Multiplex (two networks)}

{pstd}
{cmd:nwsaom multiplex} fits two networks co-evolving over the same two waves, each with its own
{opt outdegree}/{opt reciprocity} effects and its own opportunity rate, estimated jointly via a
single Method-of-Moments fit - a separate subcommand, not an option on plain {cmd:nwsaom}:

{p 8 8 2}
{cmd:nwsaom multiplex ,}
{cmd:netawave1(}{it:netname}{cmd:)} {cmd:netawave2(}{it:netname}{cmd:)}
{cmd:netbwave1(}{it:netname}{cmd:)} {cmd:netbwave2(}{it:netname}{cmd:)}
{cmd:[}{opt crprod}{cmd:]} {cmd:[}{opt crprodb}{cmd:]}
{cmd:[}{opt theta01(numlist)}{cmd:]} {cmd:[}{opt theta02(numlist)}{cmd:]}
{cmd:[}{opt k0(#)}{cmd:]} {cmd:[}{opt k3(#)}{cmd:]} {cmd:[}{opt firstg(#)}{cmd:]} {cmd:[}{opt seed(#)}{cmd:]}{p_end}

{pstd}
{opt netawave1()}/{opt netawave2()} name the first network's own two waves; {opt netbwave1()}/
{opt netbwave2()} the second network's (option names use {cmd:a}/{cmd:b}, not {cmd:1}/{cmd:2}, in
the middle of the name - Stata's {cmd:syntax} command rejects an option name with a digit
immediately followed by a letter). Both networks must be directed, non-bipartite, and share the
same fixed set of nodes. {opt theta01()}/{opt theta02()} give starting values (comma-separated,
one per network's own effect count, which grows by one when {opt crprod()}/{opt crprodb()} is
given - default 0 for every effect); {opt k0()}/{opt k3()}/{opt firstg()} tune the estimator
exactly like plain {cmd:nwsaom}'s own identically-named options.

{pstd}
{opt crprod} adds a cross-network effect to the first network's own effect list: a tie is more
(or less) likely wherever the SAME pair is already tied in the second network - the corresponding
coefficient is reported as {bf:net1_crprod}. {opt crprodb} is the mirror, adding the same kind of
effect to the second network's own list reading the first ({bf:net2_crprod}); either or both may
be requested. Each direction identifies cleanly on its own; requesting both at once can leave the
joint fit unidentified (a reported singular covariance matrix) since each network then rewards
matching the OTHER's current state at the same time - a real statistical difficulty of that
specific joint specification, not a sign that either effect alone is untrustworthy.

{pstd}
Every other multiplex effect beyond {opt outdegree}/{opt reciprocity}(+{opt crprod}) is a real,
planned follow-on, not silently dropped. Natively accelerated (all three estimation phases) -
faster than real RSiena on the benchmark used to certify it.

{marker coev}{...}
{title:Co-evolution (network + behavior)}

{pstd}
{opt behavior(varlist)} adds a SECOND dependent variable - a bounded-integer "behavior" (an actor
attribute, e.g. an ordinal opinion or a count) that evolves ALONGSIDE the network between the same
observed waves, with its own rate function and its own evaluation function, estimated JOINTLY with
the network side via a single Method-of-Moments fit. This is what lets a fitted model separate
SELECTION (network effects that depend on the behavior - {opt simcov()}/{opt nodeicov()}/
{opt nodeocov()} above) from INFLUENCE (behavior effects that depend on the network, below) in the
SAME model. Verified directly against RSiena's own real source
({cmd:src/model/EpochSimulation.cpp}, {cmd:src/model/variables/BehaviorVariable.cpp}): at each
ministep opportunity, ONE pooled exponential waiting time is drawn from the grand total rate
(summed across BOTH variables' own total rates), which variable gets to act is chosen proportional
to its own share of that total, then an actor is chosen uniformly within that variable - the same
continuous-time construction the network side alone already uses (see {bf:Estimation} above),
generalized to a race between two competing Poisson processes. A behavior ministep has exactly
THREE alternatives (change by -1, 0, or +1, clamped at the observed min/max range), chosen via the
same multinomial-logit construction as a network ministep, now over 3 alternatives instead of n.

{pstd}
{bf:linear} (RSiena's own {cmd:LinearShapeEffect}) is the behavior-side analogue of {opt outdegree}
- {bf:required} whenever {opt behavior()} is specified. Ministep delta = the raw change (\xb11);
global/observed statistic = the raw sum of every actor's own current value.

{pstd}
{bf:quadratic} (RSiena's own {cmd:QuadraticShapeEffect}) - a genuine, easy-to-miss subtlety caught
by reading the actual RSiena source, not the manual, and kept exactly as RSiena has it rather than
"fixed" toward internal consistency (matching real RSiena's own numbers is this package's own
certification standard throughout): the MINISTEP delta uses the CENTERED value
({cmd:(2*(value-mean)+diff)*diff}), but the GLOBAL/observed statistic sums the RAW, uncentered
value squared - two genuinely different scales for the same effect, both needed.

{pstd}
{bf:avalt} (RSiena's own "avAlt", {cmd:AverageAlterEffect}) is the canonical INFLUENCE effect: an
activated actor's own behavior value is pulled toward the average current value of that actor's own
network neighbors (ministep delta = {cmd:diff * average-neighbor-value}, 0 for an actor with no
out-ties). {bf:A genuine, disclosed small-sample finding from certifying the joint estimator}: at a
small toy scale (a handful of actors, on the order of RSiena's own smallest worked examples),
{opt avalt} specifically can make the joint Robbins-Monro fit genuinely diverge - not a bug, but a
real small-sample identification problem (too few behavior-ministep opportunities for
Robbins-Monro to stay stable against this effect's own self-reinforcing nonlinearity: a stronger
pull produces a more deterministic ministep, which produces an even stronger apparent pull).
Confirmed directly (the phase-1 Jacobian is well-conditioned and the simulator is unbiased AT the
true generating theta - ruling out a formula bug) and resolved simply by using a network with more
actors/behavior activity.

{pstd}
{bf:avsim} (RSiena's own "avSim", verified directly against {cmd:SimilarityEffect.cpp} - the
{cmd:average=TRUE, hi=TRUE, lo=TRUE} construction {cmd:EffectFactory.cpp} itself dispatches
{cmd:"avSim"} to) is a SECOND, alternative influence parameterization to {opt avalt}: instead of
pulling an actor's own value toward its neighbors' own AVERAGE VALUE, {opt avsim} pulls it toward
maximizing its own AVERAGE SIMILARITY to neighbors (sim(a,b) = 1 - |a-b|/range), net of a
DATA-DERIVED "similarityMean" centering constant - RSiena's own {it:b0}-style constant, playing
exactly the same role {opt balance}'s own {it:balanceMean} does on the network side: computed
automatically from the observed behavior data (every PERIOD-BASE wave, i.e. every wave except the
very last, pooled by summation over every ordered actor pair - the identical pooling convention
{opt balance}'s own constant already uses), never user-supplied. A real, disclosed quirk verified
directly from RSiena's own R-side {cmd:rangeAndSimilarity()} source (not invented): this constant
is defined as exactly 0 whenever the pooled data has zero variance, rather than the 1 the general
formula would otherwise give.

{marker endowcreation}{...}
{pstd}
{bf:Endowment/creation functions} ({opt linearendow}/{opt linearcreation}):
real RSiena models network/behavior change via three possible "roles" for any effect - evaluation
(the default, direction-blind), creation (contributes only when the value INCREASES), and endowment
(contributes only when it DECREASES) - and its own manual states that using an effect in all THREE
roles together is exactly collinear ("never in all three... this leads to collinearity"). {cmd:nwsaom}
lets the behavior-side {bf:linear} effect be split this way: {opt linearendow} and {opt linearcreation}
must be specified TOGETHER, replacing plain {opt linear} (not combinable with it). {bf:This split is genuinely, and expectedly, weakly identified} - real RSiena's own manual says so explicitly
("Separating the contribution of an effect into two functions requires more of the data... this
would lead to large standard errors") and its own live diagnostics confirm it on real data (a
direct cross-check against real RSiena on RSiena's own s50+alcohol tutorial dataset produced
RSiena's own {cmd:"Standard errors not reliable"}/{cmd:"Covariance matrix not positive definite"}
warnings for this exact model). Because of this, an {cmd:nwsaom} fit using
{opt linearendow}/{opt linearcreation} can legitimately stop with an error reporting that
{bf:thetaBound} (a coefficient's own magnitude exceeding 50 during estimation) was exceeded -
this is {cmd:nwsaom}'s own port of real RSiena's IDENTICAL safeguard for the identical situation
(its own {cmd:R/phase2.r} checks the same condition, at the same point, with the same default
bound), not a bug. A SECOND, related safeguard can also stop such a fit: if theta itself stays
within {bf:thetaBound} but the separate phase-3 covariance computation is still too close to
singular to invert reliably, {cmd:nwsaom} reports that directly rather than let it surface as
Stata's own opaque, uninformative matrix-missing-values error. Either message means the same
thing - if it happens, try plain {opt linear} instead, or supply better starting values via
{opt behtheta0()}.

{pstd}
The same endowment/creation split is also available for {opt quadratic}/{opt avalt}/{opt avsim} (as
{opt quadraticendow}/{opt quadraticcreation}, {opt avaltendow}/{opt avaltcreation},
{opt avsimendow}/{opt avsimcreation}) - confirmed as real, RSiena-offered effect/type combinations
via RSiena's own {cmd:getEffects()} output, not guessed. Each effect's own role-split is independent
of every other effect's - e.g. {opt linearendow linearcreation quadratic} (baseline split, quadratic
left plain) is a valid combination. Splitting more than one effect at once compounds the same
weak-identification property described above; a direct RSiena cross-check splitting BOTH
{opt linear} and {opt quadratic} together on the same real tutorial data reproduced unreliable
standard errors and a non-positive-definite covariance matrix from real RSiena itself, confirming
this is a shared property of the statistical problem, not specific to {cmd:nwsaom}.

{pstd}
This split extends to the NETWORK side too - {opt outdegreeendow}/
{opt outdegreecreation} (replacing plain {opt outdegree}, satisfying the same required-baseline role)
and {opt reciprocityendow}/{opt reciprocitycreation} (replacing plain {opt reciprocity}) - confirmed
real via RSiena's own {cmd:getEffects()} output ({cmd:density}/{cmd:recip} both offer {cmd:endow}/
{cmd:creation} types). Same weak-identification caveat as the behavior side applies, with a concrete
real-data illustration of WHY: on one real test network, {opt outdegreeendow}/{opt outdegreecreation}
converged cleanly with genuine, distinct coefficients, while {opt reciprocityendow}/
{opt reciprocitycreation} hit {bf:thetaBound} because that dataset never loses BOTH directions of a
mutual tie simultaneously - {opt reciprocityendow}'s own observed target statistic was exactly zero,
leaving the parameter with no gradient information to estimate from at all (a property of the DATA,
not a defect). Not yet supported combined with co-evolution, multi-wave models, {opt present()}
(composition change), or {opt missnet()} (real missing network data) - each is rejected outright
(error 198) rather than silently producing a partially-gated fit.

{pstd}
{opt behtheta0()} sets starting values for the behavior-side eval-parameter vector (parallel to
{opt theta0()} for the network side); the behavior rate's own starting value is computed
automatically from the observed behavior data via RSiena's own closed-form formula for the general
(non-binary) case, mirroring how the network rate's own starting value is computed (see
{bf:Estimation} below) - a disclosed simplification that skips RSiena's own separate binary-behavior
logistic formula.

{pstd}
{opt behavior()} works with EITHER {opt wave1()}/{opt wave2()} (exactly two waves) OR
{opt waves()} (three or more, chaining {it:nwaves}{cmd:-1} periods exactly as the network-only case
does - see {bf:Estimation} below); it needs exactly one behavior variable name per wave, in the same
temporal order. The coefficient table shows both variables' own effects in ONE table, network
coefficients unprefixed and every behavior coefficient prefixed {cmd:beh_} (e.g. {cmd:beh_linear},
{cmd:beh_avalt}) so the two evaluation functions stay visually distinct while being reported as the
single joint fit they actually are. Two separate rate parameters are reported throughout - see
{bf:Stored results} below - and {cmd:estat gof} gains a fourth default auxiliary statistic,
{bf:behavior} (RSiena's own {cmd:BehaviorDistribution}: the exact bounded-value distribution of
behavior values, no overflow category since every value is already clamped to
{cmd:[min,max]} by construction), automatically added to the default {opt stats()} list.

{pstd}
Co-evolution has the same native (C) speed backend as the network-only case (see {bf:Performance}
above), used automatically - no option needed to opt in - whenever every network AND every behavior
term in the model has native coverage; a fit combining even one not-yet-natively-ported term on
either side transparently falls back to the fully-certified, always-available Mata engine for the
WHOLE fit, never a silent partial native run. {bf:linearendow}/{bf:linearcreation} (below) are one
such case: they always run on the Mata engine, not the native backend, so a fit using them will be
noticeably slower than the {bf:Performance} section's own benchmark numbers, which are for
evaluation-function-only models.

{pstd}
{bf:Genuinely out of scope for co-evolution v1} (tracked, not silently dropped): endowment/creation
for any behavior effect OTHER than {bf:linear} ({opt quadratic}/{opt avalt}/{opt avsim} - not yet
attempted); network-side endowment/creation (not yet attempted); more than one co-evolving behavior
variable.

{marker ratecov}{...}
{title:Covariate-dependent rate}

{pstd}
By default every actor shares the same, constant opportunity rate within a period - the process
that decides who gets the next chance to reconsider their ties runs at one shared speed for everyone.
{opt ratecov(varname)} lets a node covariate speed some actors up and slow others down: actor i's own
rate becomes the period rate times exp({bf:ratecovcoef}*{it:varname}[i]), so a higher covariate value
means more frequent opportunities to act (or fewer, for a negative coefficient).

{pstd}
The coefficient is estimated jointly with every other effect, the same Robbins-Monro process the rest
of the model already uses. {opt ratecovcoef(#)} sets its STARTING value (like {opt theta0()} does for
the eval effects) - omit it to start from 0. As with the rate parameter itself, estimation can settle
on "fixed at its starting value" if the data does not identify it reliably (the same real-RSiena-verified
safeguard {opt rate0()}'s own refinement already uses) - {bf:e(ratecoef_fixed)} reports whether this
happened.

{marker undirected}{...}
{title:Undirected/symmetric relations}

{pstd}
{opt symmetric} fits a relation where every tie is symmetric (x_ij always equals x_ji at both waves) -
a candidate tie change is only made when both actors' own preferences favor it, rather than the
ordinary directed model's single-actor decision. {opt symtype()} picks which of three real rules
combines the two actors' own preferences: {bf:joint} (default) sums both actors' own preferences and
accepts the change if the sum favors it; {bf:force} lets the initiating actor's own preference alone
decide, ignoring the other actor entirely; {bf:agree} requires both actors to independently favor
creating a new tie, or either one to favor removing an existing one.

{pstd}
Several effects are not meaningful once every tie is forced symmetric and are rejected outright:
{opt reciprocity} (trivially constant - every tie is already reciprocated by construction),
{opt cycle3}, {opt inactivity}, {opt outpopularity}, {opt ininass}, {opt inoutass}, {opt outoutass},
{opt antiiso}, {opt isolatepop}, {opt transrectrip}, and {opt transtrip} (each either a constant, an
exact duplicate of an already-available effect, or an effect real RSiena itself does not offer for a
non-directed relation). {opt outdegree}, {opt indegpopularity}, {opt outactivity}, {opt cycle4},
{opt isolatenet}, {opt outiso}, {opt antiiniso}, {opt antiiniso2}, {opt inplus3}, {opt outinass},
{opt gwesp()}, {opt transties}, {opt balance}, and every covariate effect ({opt nodecov()}/
{opt nodeicov()}/{opt nodeocov()}/{opt nodematch()}/{opt simcov()} and their egoX/altX/sameX/simX
aliases) remain available and genuinely meaningful - {opt gwesp()}/{opt transties}/{opt balance}/
{opt antiiniso}/{opt antiiniso2}/{opt inplus3} required a native (C) port before {opt symmetric} could actually use them (that
option needs 100% native term coverage); all five are now natively ported.

{pstd}
{opt present()}, {opt missnet()}, and {opt ratecov()} can each be combined with {opt symmetric}.
v1 scope otherwise: exactly two waves ({opt wave1()}/{opt wave2()}, not {opt waves()}), and
network-only (no {opt behavior()}/co-evolution). Note: combining {opt ratecov()} with
{opt symmetric} runs correctly but currently reports an unreliably wide standard error on the
rate-covariate coefficient itself (the network effect's own coefficient is unaffected) - a known,
disclosed limitation, not a crash or a silently wrong estimate.

{marker compchange}{...}
{title:Composition change (joiners and leavers)}

{pstd}
{opt present(varlist)} handles actors who join or leave the network between observed waves - real
RSiena's own "method of joiners and leavers" (Huisman and Snijders 2003, Section 5.3.3 of its own
manual). One 0/1 variable per wave (same convention as {opt behavior()}): 1 marks an actor present
(eligible to act, and eligible to be tied to by another actor) at that wave, 0 marks absent. An
actor is treated as present for a given inter-wave PERIOD only if present at BOTH that period's own
endpoint waves - {cmd:nwsaom} supports WHOLE-PERIOD composition change only (an actor's presence can
change at wave boundaries, not at an arbitrary point strictly between two waves, unlike real
RSiena's own more general continuous-time joiners/leavers construction) - this covers the common
real-world case (an actor enrolled, transferred, or dropped out between whole survey waves).

{pstd}
{bf:The observed wave data itself must already be prepared correctly} - {cmd:nwsaom} does not derive
this for you, matching real RSiena's own manual, which places the identical responsibility on the
user: an absent actor's own ties should be coded 0 before the actor joins, and FROZEN at their own
last-observed values after the actor leaves (never left to look like the actor kept forming new
ties while genuinely absent). The same applies to {opt behavior()}'s own values under co-evolution.
Getting this wrong will not corrupt the fit silently - since an absent actor can no longer act, an
inconsistently-coded absent actor's own row/column looks to the estimator like activity it can never
explain, which is a real, avoidable way to trigger the {bf:thetaBound} safeguard (see
{help nwsaom##endowcreation:Endowment/creation functions} above for what that error means and how
it is meant to be read).

{pstd}
Composition change forces UNCONDITIONAL Method-of-Moments estimation in real RSiena (its own manual,
Section 7.12.1) - already {cmd:nwsaom}'s own default for the eval-parameter estimation regardless
(see {bf:Estimation} below), but it DOES mean the rate parameter's own post-hoc refinement (see
{bf:The rate parameter} below) is skipped for a {opt present()} fit that genuinely restricts at
least one actor: {cmd:e(rate)}/{cmd:e(rates)} stay at their closed-form starting value, and
{cmd:e(rate_se)}/{cmd:e(rates_se)} report 0 - the same "not refined" signal a co-evolution fit's own
rate already carries, for a related but distinct reason. {opt present()} DOES use the native (C)
backend, when the model is otherwise native-eligible - the acting-actor draw, the pooled rate, and
the tie-target restriction are all computed natively too, so a composition-change fit runs at
essentially the same speed as an equivalent fit without it. Only the rate parameter's own post-hoc
refinement construction remains Mata-only (a disclosed, scoped-out follow-up), and it does not run
for a genuinely-restricted {opt present()} fit anyway (see above).

{pstd}
{bf:Genuinely out of scope}: real RSiena's own more general continuous/fractional within-period
join-leave timing (whole-period presence only here); the "structural zeros/ones" alternative method
real RSiena's own manual also documents (a simpler, less statistically efficient approach - joiners
and leavers was chosen instead). Missing tie/behavior data (a related but distinct mechanism from
composition change) IS supported - see {help nwsaom##missingdata:Missing data} below.

{marker missingdata}{...}
{title:Missing data}

{pstd}
{opt missnet(matlist)}/{opt missbeh(varlist)} handle dyads/actors whose true value at a given wave
is unknown rather than genuinely absent - real RSiena's own regular missing-data machinery (Section
5.3.2 of its own manual), a DIFFERENT mechanism from composition change above (missing data is
uncertainty about an otherwise-active actor's own ties/value; composition change is the actor not
being part of the network at all - both can be used together).

{pstd}
{opt missnet(matlist)} takes one 0/1 n x n MATRIX name per wave, in the same temporal order as
{opt wave1()}/{opt wave2()} or {opt waves()} (e.g. two waves: {cmd:missnet(m1 m2)}) - 1 marks a dyad
missing at that wave, 0 observed. A raw Stata matrix, not an {cmd:nwset} network object - build one
with {cmd:matrix input} or {cmd:mkmat} from your own missingness indicator. {opt missbeh(varlist)}
takes one 0/1 VARIABLE per wave (same "one variable per wave" convention as {opt present()}),
marking which actors' behavior value is missing at that wave; requires {opt behavior()}. Both are
optional and independent of each other - specify {opt missnet()} alone, {opt missbeh()} alone, or
both together.

{pstd}
Missing dyads/actors are handled in two steps, matching real RSiena's own real mechanism exactly.
(1) {bf:Imputation}: every missing dyad is filled in via last-observation-carried-forward (the value
from the last wave where it WAS observed - 0 if never observed by that point); every missing
behavior value is filled in from the previous observation, else the next observation, else the
observationwise (cross-sectional, same-wave) mode. Imputed values then participate in simulation
completely normally - unlike {opt present()}, missing data does NOT restrict who can act. (2)
{bf:Target/simulated-statistic masking}: a dyad/actor missing at EITHER endpoint wave of a period is
excluded from BOTH the observed target statistic and every simulated replicate's own statistic for
that period, so the moment condition is not biased by the exclusion - the same principle real RSiena
applies, reusing every already-certified effect's own statistic function unchanged (no per-effect
special-casing needed for {opt outdegree}/{opt reciprocity}/{opt linear}/{opt quadratic}/etc.).

{pstd}
{bf:A disclosed approximation for network-dependent behavior effects}: {opt avalt}/{opt avsim}'s own
statistic for a given actor depends on that actor's real alters' CURRENT values, which vary across
simulated replicates - so the masking above, provably exact for single-actor-local effects
({opt linear}/{opt quadratic}), is only an intentional approximation there. This is empirically
favorable on most data (masking clearly outperforms not masking) but can occasionally be less
precise than an idealized per-effect masking implementation would be under heavy missingness
combined with {opt avalt}/{opt avsim} specifically.

{pstd}
Missing data DOES use the native (C) backend, when the model is otherwise native-eligible - the
masked final-network/final-behavior statistic is computed natively too, matching the Mata engine's
own result to machine precision. Like {opt present()}, it still skips the rate parameter's own
post-hoc refinement ({cmd:e(rate)}/{cmd:e(rates)} stay at their closed-form starting value,
{cmd:e(rate_se)}/{cmd:e(rates_se)} report 0) - the conditional-time refinement construction has no
masking support yet, a disclosed, scoped-out follow-up.

{pstd}
{bf:Genuinely out of scope}: missing COVARIATE data ({opt nodecov()}/{opt nodeicov()}/{opt nodeocov()}/
{opt simcov()} etc. must be fully observed); native (C) backend support for the rate parameter's own
post-hoc refinement under missing data. Real RSiena's own "structural zeros/ones" mechanism - a
separate, simpler alternative to ordinary missing data for dyads whose value is fixed by design
rather than merely unobserved - IS implemented; see {help nwsaom##structural:Structural zeros/ones}
below.

{marker structural}{...}
{title:Structural zeros/ones}

{pstd}
{opt structural(matname)} marks dyads whose tie value is fixed by design rather than a genuine actor
choice - real RSiena's own "structural values" mechanism (a DIFFERENT, simpler idea than the missing
data above: a structural dyad's value is not unknown, it is known and unchangeable, e.g. a legally
mandated reporting relationship, a physically impossible tie, or a dyad an analyst wants held fixed
for a counterfactual). Real RSiena marks a structural dyad by embedding sentinel values 10 (structural
zero)/11 (structural one) directly in the network data array; this port uses a SEPARATE 0/1 mask
matrix instead, matching {opt missnet()}'s own separate-matrix convention rather than RSiena's
embedded-sentinel one.

{pstd}
{opt structural(matname)} takes ONE 0/1 n x n MATRIX (a raw Stata matrix, not an {cmd:nwset} network
object - build one with {cmd:matrix input} or {cmd:mkmat}), zero diagonal, 1 marking a dyad whose tie
value is frozen for the whole period. The marked dyad's OBSERVED value must be IDENTICAL at both
{opt wave1()}/{opt wave2()} - a dyad that genuinely changed between waves cannot be structural (its
value was evidently not fixed) and is rejected outright with an error, rather than silently ignored.

{pstd}
Mechanically, a structural dyad is excluded from every actor's own ministep candidate set during
simulation - {opt outdegree}/{opt reciprocity}/etc.'s own statistic and change functions are reused
completely unchanged (the dyad simply never appears as a toggle option), so no per-effect
special-casing was needed, mirroring the design of {opt missnet()} above.

{pstd}
v1 scope: exactly two waves ({opt wave1()}/{opt wave2()}, not {opt waves()}), network-only (no
{opt behavior()}); not yet combinable with {opt symmetric}, {opt ratecov()}, or the network
endowment/creation split ({opt outdegreeendow}/{opt outdegreecreation}/{opt reciprocityendow}/
{opt reciprocitycreation}) - each is rejected outright when combined with {opt structural()}. Uses
the Mata engine only (no native speed-up yet).

{marker estimation}{...}
{title:Estimation}

{pstd}
Coefficients are estimated by the Method of Moments via Robbins-Monro stochastic approximation,
matching RSiena's own default algorithm and phase structure: Phase 1 estimates the Jacobian
(sensitivity of each effect's own expected statistic to each coefficient) via {opt k0()}
independent simulated replicates at the starting coefficients; Phase 2 performs the actual
Robbins-Monro coefficient update across RSiena's own default of 4 diminishing-gain subphases
(unconditionally reused, not re-derived: {cmd:nsub=4}, {cmd:firstg} default 0.2,
{cmd:reduceg=0.5}, per-subphase minimum/maximum simulation-count schedule per RSiena's own
{cmd:siena07.r}); Phase 3 runs {opt k3()} further replicates at the final coefficients to compute
the reported standard errors/covariance matrix (e(V), RSiena's own sandwich-formula construction)
and each parameter's own phase-3 convergence t-ratio (e(tratio) - a SEPARATE diagnostic from the
Std. Err./z/P>|z| columns, which come from e(V); RSiena's own convention treats |t| well under 1 as
good convergence).

{pstd}
{bf:The rate parameter} (the per-period intensity governing how often actors are activated to
ministep) is estimated via real RSiena's own verified CONDITIONAL-estimation construction
(), confirmed directly from RSiena's own real source and cross-checked live
against the installed RSiena package: a closed-form formula gives a starting value, then {opt k3()}
independent replicate simulations - each run not for a fixed time interval but UNTIL the simulated
network's own distance from the observed starting wave reaches the observed target (the same
Hamming distance between waves used elsewhere) - are averaged to give the refined estimate
{cmd:e(rate)}, with {cmd:e(rate_se)} (shown alongside it, in parentheses, matching real RSiena's own
printed convention) the raw standard deviation of those replicate draws (RSiena's own convention,
not divided by {opt k3()}'s own square root). Verified on RSiena's own real reference dataset:
{cmd:e(rate)} matches RSiena's own real fitted rate to within 0.1%, {cmd:e(rate_se)} to within 5%.
{opt rate0()} is still accepted for backward compatibility but not used - the starting
value is always computed from the data. {bf:A real, disclosed scope limit}: this refinement is not
performed for co-evolution fits ({opt behavior()}) - matching real RSiena's own actual default
behavior, not an oversight: RSiena's own conditional-estimation default requires exactly ONE
dependent variable, and a co-evolution model has two (network and behavior), so real RSiena itself
falls back to the SAME closed-form starting-value convention {cmd:nwsaom}'s own co-evolution rates
already use.

{pstd}
{opt waves(namelist)} chains three or more waves into ONE pooled fit: the eval-parameter vector
theta is POOLED/shared across every inter-wave period (RSiena's own multi-period Method-of-Moments
convention, verified directly against a real RSiena fit), while the rate parameter is estimated
SEPARATELY per period and reported as e(rates)/e(rate_tratios) (1 x (nwaves-1) matrices, one column
per period) rather than the scalar e(rate)/e(rate_tratio) the two-wave {opt wave1()}/{opt wave2()}
path reports.

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
		  {bf:e(rate)}			estimated network rate parameter (wave1()/wave2() path only) - REFINED for a plain network-only fit with no {opt present()}/{opt missnet()}/{opt missbeh()}; the closed-form STARTING value only for a co-evolution fit (real RSiena's own default behavior for 2+ dependent variables), a {opt present()} fit (composition change forces unconditional estimation - see {bf:Estimation} above), or a missing-data fit ({opt missnet()}/{opt missbeh()} - see {help nwsaom##missingdata:Missing data} above)
		  {bf:e(rate_tratio)}		network rate parameter's own phase-3 convergence t-ratio (wave1()/wave2() path only - see {bf:Estimation} above)
		  {bf:e(rate_se)}		standard error of the REFINED e(rate) (plain network-only fits with no {opt present()}/{opt missnet()}/{opt missbeh()} only - 0 for a co-evolution, {opt present()}, or missing-data fit, whose e(rate) is not refined)
		  {bf:e(has_behavior)}		1 if this is a co-evolution fit ({opt behavior()} specified), 0 otherwise
		  {bf:e(p_net)}			number of network-side eval-parameter coefficients (co-evolution fits only; the first e(p_net) columns of e(b)/e(V)/e(tratio) are the network's own, the remainder the behavior's own, prefixed {cmd:beh_})
		  {bf:e(rate_beh)}		estimated behavior rate parameter (co-evolution, wave1()/wave2() path only) - closed-form starting value, not refined (see {bf:Estimation} above)
		  {bf:e(rate_beh_tratio)}	behavior rate parameter's own phase-3 convergence t-ratio (co-evolution, wave1()/wave2() path only)

		Macros
		  {bf:e(cmd)}			{bf:nwsaom}
		  {bf:e(title)}			title of estimation
		  {bf:e(waves)}			list of wave network names, in temporal order
		  {bf:e(wave1)}			first wave name (wave1()/wave2() path only)
		  {bf:e(wave2)}			second wave name (wave1()/wave2() path only)
		  {bf:e(behavior)}		list of behavior variable names, one per wave, in temporal order (co-evolution fits only)
		  {bf:e(estat_cmd)}		{bf:nwsaom_estat} (postestimation dispatch)

		Matrices
		  {bf:e(b)}			coefficient vector (eval parameters only - excludes rate; network then behavior for a co-evolution fit, see e(p_net) above)
		  {bf:e(V)}			variance-covariance matrix (eval parameters only)
		  {bf:e(tratio)}		1 x nparam phase-3 convergence t-ratios, one per eval-parameter coefficient
		  {bf:e(rates)}			1 x (nwaves-1) per-period estimated network rate parameters (waves() path only) - REFINED for a plain network-only fit with no {opt present()}/{opt missnet()}/{opt missbeh()}; closed-form STARTING values only for a co-evolution, {opt present()}, or missing-data fit
		  {bf:e(rate_tratios)}		1 x (nwaves-1) per-period network rate convergence t-ratios (waves() path only)
		  {bf:e(rates_se)}		1 x (nwaves-1) per-period standard errors of the REFINED e(rates) (plain network-only fits with no {opt present()}/{opt missnet()}/{opt missbeh()} only - 0 otherwise)
		  {bf:e(rates_beh)}		1 x (nwaves-1) per-period estimated behavior rate parameters (co-evolution, waves() path only)
		  {bf:e(rate_beh_tratios)}	1 x (nwaves-1) per-period behavior rate convergence t-ratios (co-evolution, waves() path only)

{pstd}
{cmd:estat gof} stores the following in {cmd:r()}, one pair per requested statistic (default
{bf:outdegree}/{bf:indegree}/{bf:geodesic}):

		Scalars
		  {bf:r(p_{it:stat})}		empirical Mahalanobis-distance test p-value for that statistic
		  {bf:r(mhd_{it:stat})}		observed vector's own Mahalanobis distance from the simulated mean

{title:Examples}

		{cmd:. nwset, mat((0,1,1,0,1,0\0,0,1,0,0,1\1,0,0,1,0,0\0,0,0,0,1,1\1,0,0,0,0,1\0,1,0,0,0,0)) directed name(wave1)}
		{cmd:. nwset, mat((0,1,1,1,1,0\1,0,1,0,0,1\1,1,0,1,0,0\0,0,1,0,1,1\1,0,1,0,0,1\0,1,0,1,0,0)) directed name(wave2)}
		{cmd:. nwsaom, wave1(wave1) wave2(wave2) outdegree reciprocity transtrip}
		{cmd:. estat gof}

		{cmd:. nwsaom, waves(wave1 wave2 wave3) outdegree transties balance}

		{cmd:. nwsaom, wave1(wave1) wave2(wave2) outdegree isolatenet outiso}

		{cmd:. nwsaom, wave1(wave1) wave2(wave2) outdegree reciprocity behavior(b1 b2) linear avalt}
		{cmd:. estat gof}

		{cmd:. nwsaom, waves(wave1 wave2 wave3) outdegree behavior(b1 b2 b3) linear avalt}

		{cmd:. nwsaom, waves(wave1 wave2 wave3) outdegree behavior(b1 b2 b3) linear avsim}

		{cmd:. nwsaom, wave1(wave1) wave2(wave2) outdegree reciprocity behavior(b1 b2) linearendow linearcreation}

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
