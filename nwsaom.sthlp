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
[{opt endow(effects)} {opt creation(effects)}]
[{it:{help nwsaom##covariate_options:covariate_options}}
{it:{help nwsaom##structural_options:structural_options}}
{it:{help nwsaom##interaction_options:interaction_options}}
{it:{help nwsaom##alias_options:alias_options}}
{it:{help nwsaom##coev_options:coev_options}}
{it:{help nwsaom##compchange_options:compchange_options}}
{it:{help nwsaom##ratecov_options:ratecov_options}}
{it:{help nwsaom##symmetric_options:symmetric_options}}
{it:{help nwsaom##control_options:control_options}}]

{pstd}
Two networks that change together ({help nwsaom##multiplex:nwsaom multiplex}):

{p 8 17 2}
{cmd:nwsaom multiplex}
{cmd:,}
{opt netawave1(netname)} {opt netawave2(netname)}
{opt netbwave1(netname)} {opt netbwave2(netname)}
[{it:{help nwsaom##multiplex_options:multiplex_options}}]

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
{synopt:{opt tvcov(groups)}}Time-varying covariates (RSiena's {cmd:varCovar}): {cmd:tvcov(a1 a2 a3 | s1 s2 s3)} declares covariates with one variable per wave ('|' separates covariates); period {it:p} takes the value of wave {it:p} (the last wave's value is not used). Each is named after its first variable without trailing digits ({cmd:a}, {cmd:s}) and used by that name in {opt nodeocov()}/{opt nodeicov()}/{opt nodecov()}/{opt nodematch()}/{opt simcov()} (or {opt egox()}/{opt altx()}/{opt samex()}/{opt simx()}), e.g. {cmd:tvcov(a1 a2 a3) egox(a) simx(a)}. Centred by the mean of all values, as RSiena. No missing values; also with {opt behavior()} (network covariate effects; not yet as behavior covariates), also with two-mode networks (nodeocov/nodeicov, egosqx/altsqx and the two-mode netx effects below), not with {opt interact()}, {opt symmetric} or {cmd:estat gof}. See {help nwsaom_remarks##tvcov:Time-varying covariates}{p_end}
{synopt:{opt actormode(#)}}Two-mode networks: the mode whose nodes are the actors (they choose their ties to the other mode, the events); 1 or 2, default 2 = the {it:rows} of the affiliation matrix given to {cmd:nwset, bipartite}. Covariate effects in a two-mode network (protocol 56, native; the covariate is a variable on the nodes of one mode, other nodes ignored): {cmd:egosqx()} (actors), {cmd:altsqx()} (events), {cmd:netx(altindist2 totindist2 simegoindist2 sameegoindist2 crossxoutact samexcycle4 avgroupegox totgroupegox:}{it:var}{cmd:)} on the actor mode, {cmd:netx(sameinxcycle4 homxoutact2:}{it:var}{cmd:)} on the event mode ({cmd:homxoutact2} needs {cmd:xparam(3)} for RSiena's default); a {cmd:tvcov()} covariate works in all of them ({cmd:avgroupegox/totgroupegox} only with {cmd:tvcov()}, as in RSiena). RSiena's {cmd:sameXOutAct}/{cmd:diffXOutAct} cannot be evaluated by siena07 in a two-mode network and are not offered. See {help nwsaom_remarks##twomode:Two-mode networks}{p_end}

{syntab:Baseline network effects}
{synopt:{opt endow(effects)}}Endowment role (RSiena effect type "endow": the effect counts only for tie/value withdrawals). {it:effects} is a list of {bf:outdegree reciprocity transties cycle4 gwesp balance transtrip cycle3 transmedtrip transrectrip inpop outpop inact outactsqrt indegpopularity outpopularity outactivity inactivity} (network; the degree effects follow RSiena's inPop, outPop, inAct, outActSqrt, inPopSqrt, outPopSqrt, outAct, inActSqrt split, the creation statistic of the ego-activity ones on the start-network degrees as RSiena does; {bf:gwesp} takes its decay from {opt gwesp(#)}, which with {opt endow()}/{opt creation()} gives the parameter and not an evaluation role) and {bf:linear quadratic avalt avsim} (behavior). An effect named in {it:both} {opt endow()} and {opt creation()} is split into its two roles and takes the place of the plain effect; naming it in only one list, or also giving the plain effect, is an error. The long option pairs below ({opt outdegreeendow}/{opt outdegreecreation}, {opt reciprocityendow}/..., {opt transtiesendow}/..., {opt linearendow}/...) are the same thing and still work. Example: {cmd:nwsaom, waves(w1 w2 w3) outdegree reciprocity endow(transties) creation(transties)}. See {help nwsaom_remarks##endowcreation:Endowment/creation functions} in nwsaom_remarks{p_end}
{synopt:{opt endow(eff:var)}}Covariate effects are split per variable: {cmd:endow(altx:alc) creation(altx:alc)} (effect {cmd:egox}, {cmd:altx}, {cmd:samex}, {cmd:simx} or {cmd:nodecov}, a colon, the variable; the same token in both options). The split takes the place of the plain effect for that variable (do not also give it in {opt altx()}); coefficients {cmd:altxendow_alc}, {cmd:altxcreation_alc}. No missing values yet{p_end}
{synopt:{opt creation(effects)}}Creation role (RSiena effect type "creation": the effect counts only for new ties / value gains); see {opt endow()}{p_end}
{synopt:{opt outdegree}}Outdegree (density) effect, evaluation-function role; {bf:required} in every model UNLESS {opt outdegreeendow}/{opt outdegreecreation} are given instead{p_end}
{synopt:{opt outdegreeendow}}Outdegree effect, ENDOWMENT (tie-withdrawal) role - splits outdegree's own contribution so it fires only on ties that are REMOVED between waves; must be given together with {opt outdegreecreation}, and not combined with plain {opt outdegree} (all three roles together are exactly collinear). {bf:Currently refused}: the endowment and creation statistics (lost and gained ties) add up to the rate's distance statistic, so with the rate estimated the model is not identified (RSiena reports a singular covariance matrix for it too). See {help nwsaom_remarks##endowcreation:Endowment/creation functions} in nwsaom_remarks{p_end}
{synopt:{opt outdegreecreation}}Outdegree effect, CREATION (new-tie) role - the mirror of {opt outdegreeendow}, firing only on ties that are ADDED between waves; must be given together with it{p_end}
{synopt:{opt reciprocity}}Reciprocated-tie effect, evaluation-function role{p_end}
{synopt:{opt reciprocityendow}}Reciprocity effect, ENDOWMENT role - same mechanism/rules as {opt outdegreeendow}, applied to reciprocity instead, with {opt outdegree}. Works with {opt waves()}, {opt present()} and {opt missnet()}, and with co-evolution ({opt behavior()}; native plugin preferred, Mata fallback available). See {help nwsaom_remarks##endowcreation:Endowment/creation functions} in nwsaom_remarks{p_end}
{synopt:{opt reciprocitycreation}}Reciprocity effect, CREATION role - the mirror of {opt reciprocityendow}; must be given together with it{p_end}
{synopt:{opt transtiesendow}}Transitive ties ({opt transties}), ENDOWMENT role (RSiena: transTies, type endow) - the effect counts only for tie withdrawals, and its statistic is minus the number of lost ties that had a two-path in the start network; must be given together with {opt transtiescreation} and not with plain {opt transties}. Works with {opt waves()}, {opt present()} and {opt missnet()} and {opt behavior()}; not yet with {opt symmetric}{p_end}
{synopt:{opt transtiescreation}}Transitive ties, CREATION role - counts only new ties; its statistic is the number of gained ties that have a two-path in the end network; must be given together with {opt transtiesendow}{p_end}

{marker covariate_options}{...}
{syntab:Node covariate effects}
{synopt:{opt absdiffx(varlist)}}Absolute difference of a covariate between sender and receiver, |x_j - x_i| (RSiena {cmd:absDiffX}); one effect per variable. Missing values: ties with a missing value are skipped in the statistic (RSiena).{p_end}
{synopt:{opt egoxaltx(varlist)}}Product of sender and receiver values of a (centred) covariate, x_i * x_j (RSiena {cmd:egoXaltX}); one effect per variable. Missing values: ties with a missing value are skipped in the statistic (RSiena).{p_end}
{synopt:{opt diffx(varlist)}}RSiena {cmd:diffX}: sum over ties of x_j - x_i (centred covariate){p_end}
{synopt:{opt higher(varlist)}}RSiena {cmd:higher}: sum over ties of 1 if x_i > x_j (0.5 if equal, as RSiena){p_end}
{synopt:{opt egosqx(varlist)}}RSiena {cmd:egoSqX}: sum over ties of x_i^2{p_end}
{synopt:{opt altsqx(varlist)}}RSiena {cmd:altSqX}: sum over ties of x_j^2{p_end}
{synopt:{opt samexrecip(varlist)}}RSiena {cmd:sameXRecip}: number of reciprocated ties between actors with the same value (counted per tie){p_end}
{synopt:{opt simrecipx(varlist)}}RSiena {cmd:simRecipX}: similarity (as {opt simx}) summed over reciprocated ties{p_end}
{synopt:{opt dyadcov(matnames)}}Dyadic covariate (RSiena's {cmd:X} effect): each name is a Stata {it:n} x {it:n} matrix (rows and columns in the node order of the waves) whose value x_ij enters an actor's utility for the tie i -> j. Centred by the mean of its non-missing off-diagonal cells (not with {opt nocenter}); missing cells ({bf:.}) count as 0 after centring and are left out of the statistic, as in RSiena. One effect and coefficient ({cmd:dyadcov_}{it:name}) per matrix; constant over time. Uses {it:n} native attribute columns per matrix (Stata variable limit). Not combinable with {opt interact()}{p_end}
{synopt:{opt dyadcovrecip(matnames)}}RSiena's {cmd:XRecip}: the same matrices, but the value counts only when the reverse tie j -> i exists{p_end}
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
{synopt:{opt outpopularity}}Outdegree popularity, sqrt-transformed (RSiena's outPopSqrt as documented; see {help nwsaom_remarks##nwsaom_interaction:the note on RSiena's default}){p_end}
{synopt:{opt outactivity}}Outdegree activity, squared (concentrates out-ties on already-active senders){p_end}
{synopt:{opt inpop}}RSiena {cmd:inPop}: indegree popularity, sum of squared indegrees (evaluation role; actor i's term is the sum over its ties of the alter's indegree). Compare {opt indegpopularity} (inPopSqrt){p_end}
{synopt:{opt outpop}}RSiena {cmd:outPop}: outdegree popularity, sum over ties of the alter's outdegree{p_end}
{synopt:{opt inact}}RSiena {cmd:inAct}: indegree activity, sum of own outdegree x own indegree (same total statistic as {opt outpop}, so the pair is not identified: RSiena accepts it with arbitrary estimates, {cmd:nwsaom} refuses it){p_end}
{synopt:{opt outactsqrt}}RSiena {cmd:outActSqrt}: sum of outdegree^1.5{p_end}
{synopt:{opt outtrunc(#)}}RSiena {cmd:outTrunc}: sum over actors of min(outdegree, #); one term per value given, # a positive integer{p_end}
{synopt:{opt outmore(#)}}RSiena {cmd:outMore}: sum over actors of max(outdegree - #, 0){p_end}
{synopt:{opt outthreshold(#)}}RSiena {cmd:outThreshold}: number of actors with outdegree greater than #{p_end}
{synopt:{opt outinv(#)}}RSiena {cmd:outInv}: sum over actors of 1/(outdegree + #), # at least 1{p_end}
{synopt:{opt outsqinv(#)}}RSiena {cmd:outSqInv}: sum over actors of 1/((outdegree + #)(outdegree + # + 1)){p_end}
{synopt:{opt gwdspff(#)}}RSiena {cmd:gwdspFF}: geometrically weighted dyadwise shared partners, sum over ordered pairs of the weight of the number of two-paths i->k->j; # is the decay (RSiena's parameter / 100, e.g. 0.69). Copied from RSiena exactly (its simulation contribution only changes the ego's own row){p_end}
{synopt:{opt gwdspfb(#)}}RSiena {cmd:gwdspFB}: as {opt gwdspff()} for common out-neighbours i->k<-j{p_end}
{synopt:{opt between}}RSiena {cmd:between}: betweenness, the number of open two-paths h->i->j (no tie h->j). Copied from RSiena exactly{p_end}
{synopt:{opt gwespfb(#)}, {opt gwespbf(#)}, {opt gwespbb(#)}, {opt gwesprr(#)}}RSiena {cmd:gwespFB}, {cmd:gwespBF}, {cmd:gwespBB}, {cmd:gwespRR}: geometrically weighted edgewise shared partners over ties i->j, with the shared partners being common out-neighbours (FB), common in-neighbours (BF), two-paths j->h->i (BB) or actors with mutual ties to both (RR); # is the decay (RSiena's parameter / 100, e.g. 0.69). {opt gwesp(#)} is gwespFF{p_end}
{synopt:{opt nbrdist2}, {opt dblnbrdist2}}RSiena {cmd:nbrDist2} (number of actors at distance two from some actor, i.e. reached by at least one two-path and not a direct tie) and {cmd:nbrDist2twice} (at least two two-paths; the option is {opt dblnbrdist2} because Stata's {cmd:syntax} rejects option names with a digit followed by letters). Copied from RSiena exactly (its simulation contribution only follows the ego's row){p_end}
{synopt:{opt sqrtcycle4}}RSiena {cmd:cycle4} (= {cmd:sharedPop}, the same effect) with parameter 2: square root of the three-paths, copied from RSiena exactly{p_end}
{synopt:{opt recipop}}RSiena {cmd:reciPop}: sum over ties of the alter's reciprocal degree (its number of mutual ties). Copied from RSiena exactly, including that its simulation uses a contribution that is not the change of this statistic{p_end}
{synopt:{opt recipopsqrt}}RSiena {cmd:reciPopSqrt}: as {opt recipop} with the square root of the reciprocal degree{p_end}
{synopt:{opt reciact}}RSiena {cmd:reciAct}: sum over ties of the sender's reciprocal degree (copied exactly, as {opt recipop}){p_end}
{synopt:{opt reciactsqrt}}RSiena {cmd:reciAct} with parameter 2: the square root of the sender's reciprocal degree{p_end}
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
{synopt:{opt interact(effect1#effect2[#effect3] [effect4#effect5 ...])}}Two- or three-way interaction (RSiena's {cmd:includeInteraction()}) of network effects already in the model as main effects, with its own coefficient; its contribution to a ministep is the product of the components' contributions. Several interactions may be listed. The effects allowed follow RSiena's rule: each effect is an ego effect ({opt egox()}, {opt inactivity}, {opt isolatenet}, {opt isolatepop}), a dyadic effect ({opt outdegree}, {opt reciprocity}, {opt samex()}, {opt altx()}, {opt nodecov()}, {opt simx()}, {opt gwesp()}, {opt outpopularity}, {opt inoutass}) or another effect ({opt transtrip}, {opt transmedtrip}, {opt transrectrip}, {opt cycle3}, {opt cycle4}, {opt transties}, {opt balance}, {opt indegpopularity}, {opt outactivity}, {opt outiso}, {opt outoutass}, {opt outinass}, {opt ininass}); two effects need an ego effect or two dyadic effects, three effects two ego effects or only ego and dyadic effects. Interactions RSiena accepts but cannot compute are refused too: {opt outiso} and {opt isolatenet} only with {opt egox()} (and {opt outdegree}), and the anti-isolate effects not at all. A covariate effect given for several variables is named by its coefficient name, e.g. {cmd:interact(samex_smoke1#egox_alcohol1)} (either spelling, {cmd:nodematch_smoke1} or {cmd:samex_smoke1}); with one variable the effect type alone works ({cmd:interact(samex#egox)}). Coefficients are named interact_{it:A}_{it:B}, or ix_{it:A}_{it:B} when that is longer than 32 characters; RSiena's name is in {bf:e(rsiena_labels)} and listed under the table with {opt detail}. Behavior interactions are not supported. See {help nwsaom_remarks##nwsaom_interaction:Interaction effects} in nwsaom_remarks{p_end}

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
{synopt:{opth behavior(varlist)}}Co-evolution: one bounded-integer behavior variable (several behaviors: {cmd:behavior(a1 a2 a3 : linear avalt | s1 s2 s3 : linear)}, see {help nwsaom_remarks##multibeh:Several behaviors}), ONE Stata variable name per wave, same temporal order as {opt wave1()}/{opt wave2()} or {opt waves()} (e.g. two waves: {cmd:behavior(b1 b2)}; three: {cmd:behavior(b1 b2 b3)}). Requires {opt linear}. A SECOND dependent variable evolving jointly with the network - see {help nwsaom_remarks##coev:Co-evolution} in nwsaom_remarks{p_end}
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
{synopt:{opt behegox}, {opt behaltx}, {opt behegoplusalt}}Network-side SELECTION effects on the co-evolving behavior, RSiena's {cmd:egoX}, {cmd:altX} and {cmd:egoPlusAltX} with the dependent behavior as the covariate ("alcohol ego", "alcohol alter", "alcohol ego and alt"): the tie contribution is the sender's, the receiver's or the sum of both CURRENT behavior values minus the behavior's overall mean. As {opt behsim} the statistic uses the starting behavior and the simulation the live one. Network effects; require {opt behavior()} (the first behavior){p_end}
{synopt:{opt beheff(tokens)}}Behavior effects of network position, alters and similarity (RSiena's behavior-section effects of the network). Tokens: {cmd:indeg outdeg recipdeg isolate outisolate} (ego's behavior times in-/out-/reciprocated degree, or indicator of being an in-/out-isolate), {cmd:totalt avaltpop totaltpop maxalt minalt avrecalt totrecalt} (sum, popularity-weighted average/sum, maximum, minimum of the alters' behavior; average/sum over reciprocated alters), {cmd:totsim avatthigher avattlower totatthigher totattlower avsimpopalt totsimpopalt avsimpopego avinsim totinsim avinsimpopalt totinsimpopalt avsimrecip totsimrecip avsimrecpop totsimrecpop popalt totpopalt avinalt totinalt} (total similarity and the attraction-to-higher/lower, popularity-weighted and ego-popularity-weighted similarity variants). All 20 observed statistics equal siena07's targets, estimates agree within noise for the identified effects. Requires {opt behavior()}; also allowed inside a {opt behavior(vars : ...)} group{p_end}
{synopt:{it:more beheff() tokens}}{cmd:avinsim totinsim avinsimpopalt totinsimpopalt avsimrecip totsimrecip avsimrecpop totsimrecpop popalt totpopalt avinalt totinalt avaltdist2 totaltdist2 avtaltdist2 totaaltdist2 avinaltdist2 totinaltdist2 avtinaltdist2 totainaltdist2}: RSiena's (the last eight: avAltDist2, totAltDist2, avTAltDist2, totAAltDist2, avInAltDist2, totInAltDist2, avTInAltDist2, totAInAltDist2)  avInSim, totInSim, avInSimPopAlt, totInSimPopAlt, avSimRecip, totSimRecip, avSimRecPop, totSimRecPop, popAlt, totPopAlt, avInAlt, totInAlt (in-/reciprocated-alter similarity and averages, popularity of the alters). Estimates agree with siena07. Native only (protocol 44){p_end}
{synopt:{opt behfrom(varlist)}}Covariate main effects on the co-evolving behavior (RSiena's {cmd:effFrom}): for each numeric variable the behavior's tendency to be higher where the covariate is higher (contribution = change x centred covariate; coefficient {cmd:beh_from_}{it:var}). Constant covariates or {opt tvcov()} covariates (use the stem; period {it:p} takes wave {it:p}), the first behavior, at most 8; missing values are set to the mean. Observed statistics and estimates equal siena07. Requires {opt behavior()}{p_end}
{synopt:{opt netx(effect:var ...)}, {opt xparam(#)}}Further covariate network effects, native only (protocol 46): {it:effect} is one of {cmd:crossxoutact homxoutact2 outxmore indties transtripx jumpxtranstrip altdist2 totdist2 simdist2 simegodist2 sameegodist2 altindist2 totindist2 simegoindist2 sameegoindist2 homxtransrectrip samextransrectrip diffxtransrectrip egoxaltxrecip samexcycle4 sameinxcycle4 avgroupegox totgroupegox} (RSiena's crossXOutAct, homXOutAct2, outXMore, IndTies, transTripX, jumpXTransTrip, altDist2, totDist2, simDist2, simEgoDist2, sameEgoDist2, altInDist2, totInDist2, simEgoInDist2, sameEgoInDist2, homXTransRecTrip, sameXTransRecTrip, diffXTransRecTrip, egoXaltXRecip, sameXCycle4, sameInXCycle4 - {opt xparam(1|2)} is their parameter -, avGroupEgoX, totGroupEgoX - changing covariate or dependent behavior only) and {it:var} a numeric variable or a {opt tvcov()} stem (not for the three similarity versions). {opt xparam()} is outXMore's c (default 1). homXOutAct2 needs categories 1, 2, .... The observed statistic is computed by the plugin itself. Directed and symmetric relations. Estimates agree with siena07. With {opt netbeh()}: the same effects (except homxoutact2; the similarity versions simdist2 simegodist2 simegoindist2 use the behavior's range and similarity mean) with the dependent behavior as the covariate{p_end}
{synopt:{opt netbeh(effects)}}Network effects with the {it:dependent behavior} as the covariate (RSiena's "a behavior variable" contexts): any of {cmd:samex diffx higher egosqx altsqx samexrecip absdiffx egoxaltx samextranstrip diffxtranstrip homxtranstrip samexoutact diffxoutact samexreciact diffxreciact homxoutact altxoutact inpopx outpopx inactx outactx samexinpop diffxinpop egoplusaltsqx diffsqx egodiffx althigheregox unequalx egolthresholdx egorthresholdx altlthresholdx altrthresholdx degabsdiffx degposdiffx degnegdiffx}. The value is the behavior's current value minus its overall mean in the simulation and its value at the start of the period in the statistic (like {opt behsim}). First behavior only; coefficients {cmd:bv_}{it:effect}. Estimates agree with siena07. {bf:Native plugin only} (protocol 45){p_end}
{synopt:{opt behx(family:var ...)}}Behavior effects of the network x a covariate (RSiena's avXInAlt, totXInAlt, avXRecAlt, totXRecAlt, avSameXInAlt, totSameXInAlt, avSameXRecAlt, totSameXRecAlt, avAltSameX, totAltSameX, avRecAltSameX, totRecAltSameX, avAltAltX, avSimAltX, totSimAltX, minXAlt, maxXAlt, degAbsContrX, degPosContrX, degNegContrX): {it:family} is the lower-case effect name, {it:var} a numeric variable or a {opt tvcov()} stem, e.g. {cmd:behx(avsamexinalt:sex maxxalt:age)}; shares the covariate slots (at most 8 different covariates) with {opt behfrom()}. {it:var} may also be {cmd:beh2}, {cmd:beh3}, ...: another {it:co-evolving behavior} of {opt behavior()} as the covariate (the statistics read its start-of-period values, the ministeps its current values; plugin protocol 53; same for {opt behfrom()}, {opt behavxalt()} ...). Coefficients {cmd:beh_}{it:family}{cmd:_}{it:var}. Estimates agree with siena07. {bf:Native plugin only} (protocol 43){p_end}
{synopt:{opt tvdyadcov(stem ...)} {opt tvdyadcovrecip(stem ...)} {opt tvdyadx(effect:stem ...)}}Changing dyadic covariates (RSiena varDyadCovar): the matrices {it:stem}1 ... {it:stem}P (Stata matrices, P = waves - 1, the matrix of period p is the one of the period's start wave) for {opt dyadcov} / {opt dyadcovrecip} (centred by the overall mean, as RSiena) and for the {opt dyadx()} effects (raw). Directed and symmetric relations. Statistics and estimates agree with siena07{p_end}
{synopt:{opt netx(samexv:v1:v2) netx(samexvinpop:v1:v2[:#])}}RSiena's sameXV, sameXVInPop (= sameXVInPop2) for two integer category covariates (0 .. 20, uncentred); part of {opt netx()}. Estimates agree with siena07{p_end}
{synopt:{opt ownx(effect[:#] ...)}}Own-network effects without a covariate (native, protocol 54; protocol 56 adds {cmd:outinass[:2]} {cmd:outoutass[:2]} {cmd:ininass[:2]} {cmd:inoutass[:2]} (RSiena outInAss, outOutAss, inInAss, inOutAss; default parameter 2 = square roots, :1 = plain products); protocol 61 adds the primary-setting effects {cmd:primary primcompress nonpcompress primdegact primdegactlog primdegactsqrt primdegactinv primdegactdiff primdegactdiffsqrt}, {cmd:inpopdya[:2]} (inPop_dya), {cmd:inisdegree}, {cmd:instructeq} (inStructEq) and {cmd:densetriads[:5|6]}; also in two-mode and non-directed networks, together with {cmd:gwdspfb()}, {cmd:avdeg()} and {cmd:outtrunc()}/{cmd:outmore()}/{cmd:outthreshold()} there): {cmd:jin jout transtrip1 transtrip2 transrectrip2 transtripfr transtripfe transtripee outpopmore:}{it:#} {cmd:outpopsqrtmore:}{it:#} {cmd:outpopthreshold:}{it:#} (RSiena Jin, Jout, transTrip1, transTrip2, transRecTrip2, transTrip.FR/FE/EE, outPopMore, outPopSqrtMore, outPopThreshold) and the ego degree effects {cmd:outactego[:2] outactmoreego:}{it:#} {cmd:outactsqrtmoreego:}{it:#} {cmd:outmoreego:}{it:#} {cmd:divoutego[:2] inactego[:2] divinego[:2] reciactego[:2]} (RSiena's *_ego forms; parameter 2 = square root). Statistics and estimates agree with siena07{p_end}
{synopt:{opt dyadx(effect:matrix ...)}}Network effects of a constant dyadic covariate W (RSiena's WWX, cyWWX, InWWX, OutWWX, WXX, XWX, XWX1, XWX2, XXW): {it:effect} is the lower-case name, {it:matrix} a Stata {it:n} x {it:n} matrix used {bf:raw} (not centred, missing cells = 0), e.g. {cmd:dyadx(xwx:DM wwx:DM)}. Coefficients {cmd:nat_}{it:effect}{cmd:_}{it:matrix}. Observed statistics and estimates agree with siena07. {bf:Native plugin only} (protocol 49){p_end}
{synopt:{opt behshape(effect[:#] ...)}}RSiena's further behavior shape effects (native, protocol 51): {cmd:quad_cc} and {cmd:quad_nc} (centred / non-centred quadratic shape - use them {it:instead of} {cmd:quadratic}), {cmd:threshold:}{it:#}, {cmd:simallnear:}{it:#} (default 2), {cmd:simallfar:}{it:#} (default 4), {cmd:avgroup}[{cmd::}{it:#}], {cmd:totgroup}[{cmd::}{it:#}] (default parameter 1), {cmd:constant} (minus the sum of the absolute changes: equal to minus the behavior rate statistic, so the fit stops with a singular Jacobian). Coefficients {cmd:beh_}{it:effect}[{cmd:(}{it:#}{cmd:)}]. Estimates agree with siena07{p_end}
{synopt:{opt behnet2(effect[:#] ...)}}Further RSiena behavior effects of the network (native, protocol 55): {cmd:indegavgroup[:}{it:#}{cmd:] indegtotgroup[:}{it:#}{cmd:] avaltcc totaltcc avinaltdist2nc totinaltdist2nc avtinaltdist2nc totainaltdist2nc avinsimdist2 totinsimdist2 totgwdspffalt[:}{it:#}{cmd:] totgwdspfbalt[:}{it:#}{cmd:] totgwdspffaltnc[:}{it:#}{cmd:] totgwdspfbaltnc[:}{it:#}{cmd:] varalt avsimvaralt behdensetriads[:5|6] simdensetriads[:5|6]} (RSiena indegAvGroup, indegTotGroup, avAlt_cc, totAlt_cc, avInAltDist2_nc, totInAltDist2_nc, avTInAltDist2_nc, totAInAltDist2_nc, avInSimDist2, totInSimDist2, totGwdspFFAlt, totGwdspFBAlt and the _nc versions; the number is RSiena's effect parameter: centring value of the group effects (default 1), gwdsp weight (default 69)). Estimates agree with siena07{p_end}
{synopt:{opt tvbehw(family:stem ...)}}The same ten effects with a changing dyadic covariate (RSiena varDyadCovar): the Stata matrices {it:stem}1 ... {it:stem}(waves-1), one per period (native, protocol 57). May be combined with {opt behw()}; estimates agree with siena07{p_end}
{synopt:{opt behw(family:matrix ...)}}Behavior effects of the network x a constant dyadic covariate W (RSiena's avAltW, totAltW, avInAltW, totInAltW, avWAlt, totWAlt, avWInAlt, totWInAlt, avSimW, totSimW): {it:family} is the lower-case effect name, {it:matrix} a Stata {it:n} x {it:n} matrix (centred like {opt dyadcov()}), e.g. {cmd:behw(avsimw:DM totaltw:DM)}; at most 8 different matrices. Coefficients {cmd:beh_}{it:family}{cmd:_}{it:matrix}. Observed statistics and estimates agree with siena07; avAltW and avSimW with parameter 2 (RSiena's default) are unstable in siena07 as well when the weights nearly sum to zero. {bf:Native plugin only} (protocol 48){p_end}
{synopt:{opt behwparam(#)}}RSiena's effect parameter of avAltW, avInAltW and avSimW: 2 (default, the denominator is the sum of the weights) or 1 (the number of alters); the names then carry {cmd:_p1}{p_end}
{synopt:{opt outrate}, {opt inrate}, {opt reciprate}, {opt outrateinv}, {opt inrateinv}, {opt reciprateinv}, {opt outratelog}, {opt inratelog}, {opt recipratelog}}Structural rate effects (RSiena's outRate, inRate, recipRate and their Inv / Log versions): the actor's rate is the period rate times exp(sum of b_k f_k) with f = out-, in- or reciprocated degree (or 1/(d+1), log(d+1) of it) of the actor in the {it:current} network; the rate changes with every tie change of the simulation. Each adds one covariate-rate coefficient (e(ratecoefs), like {opt ratecov()}); the statistic is the sum over the differing dyads of the degree function at the start of the period. Directed one-mode relations, plain waves only (no behavior, present(), missnet(), symmetric, two-mode). Estimates agree with siena07. {bf:Native plugin only} (protocol 42){p_end}
{synopt:{opt egoplusaltsqx(varlist)}, {opt diffsqx()}, {opt egodiffx()}, {opt althigheregox()}, {opt unequalx()}, {opt egolthresholdx()}, {opt egorthresholdx()}, {opt altlthresholdx()}, {opt altrthresholdx()}, {opt degabsdiffx()}, {opt degposdiffx()}, {opt degnegdiffx()}, {opt covthreshold(#)}}Covariate contrast and threshold effects (RSiena's egoPlusAltSqX, diffSqX, egoDiffX, altHigherEgoX, unequalX, egoLThresholdX, egoRThresholdX, altLThresholdX, altRThresholdX, degAbsDiffX, degPosDiffX, degNegDiffX). The four threshold effects compare the {it:centred} covariate with {opt covthreshold(#)} (default 0, as RSiena's internal parameter). The deg*DiffX effects compare the outdegree with floor of the centred covariate (copied from RSiena). Directed relations, no missing values. Observed statistics and estimates equal siena07. {bf:Native plugin only} (protocol 41){p_end}
{synopt:{opt inpopc}, {opt outpopc}, {opt outactc}, {opt inactc}, {opt degplus}, {opt degplusc}, {opt avdeg(#)}, {opt transtriads}}Centred and combined degree effects and the triangle count (RSiena's inPop.c, outPop.c, outAct.c, inAct.c, degPlus, degPlus.c, avDeg, transTriads). The centring constant is the average degree over all waves (degplusc: twice the average out-degree; avdeg: the constant {it:#} you give, RSiena's default is 2). {opt degplus}, {opt degplusc} and {opt transtriads} are offered for a non-directed relation ({opt symmetric}) only, {opt outpopc} and {opt inactc} for a directed relation only. Observed statistics and estimates equal siena07. {bf:Native plugin only} (protocol 40){p_end}
{synopt:{opt samextranstrip(varlist)}, {opt diffxtranstrip()}, {opt simxtranstrip()}, {opt homxtranstrip()}, {opt samexoutact()}, {opt diffxoutact()}, {opt samexreciact()}, {opt diffxreciact()}, {opt homxoutact()}, {opt altxoutact()}, {opt inpopx()}, {opt outpopx()}, {opt inactx()}, {opt outactx()}, {opt samexinpop()}, {opt diffxinpop()}}Covariate x triad / popularity / activity effects (RSiena's sameXTransTrip, diffXTransTrip, simXTransTrip, homXTransTrip, sameXOutAct, diffXOutAct, sameXReciAct, diffXReciAct, homXOutAct, altXOutAct, inPopX, outPopX, inActX, outActX, sameXInPop, diffXInPop; internal parameter 1). One numeric covariate per name, no missing values, directed one-mode networks. Observed statistics and estimates equal siena07. {bf:Native plugin only} (protocol 39): there is no Mata implementation of the simulation{p_end}
{synopt:{opt behavxalt(varlist)}, {opt behavsamexalt(varlist)}, {opt behtotxalt(varlist)}, {opt behtotsamexalt(varlist)}}Covariate-moderated influence on the co-evolving behavior (RSiena's {cmd:avXAlt}, {cmd:avSameXAlt}, {cmd:totXAlt}, {cmd:totSameXAlt}): the ego's behavior times the average (av) or sum (tot) over its out-alters of the centred covariate (X) or of the indicator that the alter has the ego's covariate value (SameX). Constant covariates, first behavior; together with {opt behfrom()} at most 8 different covariates. Coefficients {cmd:beh_avxalt_}{it:var} etc.; estimates equal siena07{p_end}
{synopt:{opt behtheta0(numlist)}}Starting values for the behavior-side eval-parameter vector, one per requested behavior effect in the order {opt linear} (or {opt linearendow}/{opt linearcreation})/{opt quadratic}/{opt avalt}/{opt avsim} appear above; default all zero{p_end}

{synoptline}
{p2colreset}{...}

{synoptset 22 tabbed}{...}
{synopthdr}
{synoptline}
{marker compchange_options}{...}
{syntab:Composition change and missing data}
{synopt:{opth present(varlist)}}Composition change ("joiners and leavers"): one 0/1 variable per wave, same "one variable per wave" convention as {opt behavior()}, marking which actors are present at each wave. Optional - omitting it means every actor is present the whole time. See {help nwsaom_remarks##compchange:Composition change} in nwsaom_remarks{p_end}
{synopt:{opth joinat(varname)}, {opth leaveat(varname)}}Composition change with joiners and leavers at {it:fractional} times inside a period, exactly as RSiena's {cmd:sienaCompositionChange()} (option 1): one numeric node variable each, on RSiena's time scale (wave 1 = time 1, the last wave = time W). An actor is active from {opt joinat()} to {opt leaveat()}; a missing value means from the first wave / to the last wave; one interval per actor, and every interval must contain a wave. Alternative to {opt present()} (which is the special case of whole-period presence). Works with {opt behavior()} (one or several behaviors; not with behsim or endowment/creation effects). Works with {opt symmetric} (not together with {opt ratecov()}). Not yet with {opt endow()}/{opt creation()}. See {help nwsaom_remarks##compchange:Composition change} in nwsaom_remarks{p_end}
{synopt:{opt missnet(matlist)}}Missing tie data: one 0/1 n x n MATRIX name per wave, marking which dyads are missing at that wave. Optional - omitting it means every dyad is fully observed. See {help nwsaom_remarks##missingdata:Missing data} in nwsaom_remarks{p_end}
{synopt:{opth missbeh(varlist)}}Missing behavior data: one 0/1 variable per wave, same "one variable per wave" convention as {opt present()}, marking which actors' behavior value is missing at that wave. Requires {opt behavior()}. Optional - omitting it means every actor's value is fully observed. See {help nwsaom_remarks##missingdata:Missing data} in nwsaom_remarks{p_end}
{synopt:{opt structural(matname)}}Structural zeros/ones: ONE 0/1 n x n MATRIX (zero diagonal) marking dyads whose tie value is fixed by design rather than actor choice (e.g. a legally mandated reporting tie, or a dyad known a priori to never form) - a marked dyad is excluded from every actor's own ministep candidate set, so it can never toggle during simulation. The marked dyad's OBSERVED value must be identical at both waves (a "frozen" dyad that genuinely changed between waves is rejected outright, matching RSiena's own structural-value convention that a fixed dyad's data must actually be constant). v1 scope: exactly two waves ({opt wave1()}/{opt wave2()}, not {opt waves()}), network-only (no {opt behavior()}); not yet combinable with {opt symmetric}, {opt ratecov()}, or the network endowment/creation split. See {help nwsaom_remarks##structural:Structural zeros/ones} in nwsaom_remarks{p_end}

{marker ratecov_options}{...}
{syntab:Covariate-dependent rate}
{synopt:{opt fix(namelist)}}Hold the named effects fixed at their {opt theta0()} values (RSiena's {cmd:fix = TRUE}): they are not estimated and have no standard error; {cmd:fix(_all)} fixes every effect. Used to fit a restricted model for {help nwsaom_estat##estat_score:estat score}, to simulate at chosen coefficients ({cmd:nwsaom simulate}) and to profile models. Works with {opt behavior()}; not with {cmd:nwsaom multinet}{p_end}
{synopt:{opth ratecov(varlist)}}Let node covariates raise or lower each actor's own opportunity to make a network change, instead of every actor sharing one constant rate for the period - actor i's own rate becomes {it:rate}*exp(sum of {it:b_k}*{it:x_k}[i]) over the variables, one coefficient each (RSiena's RateX effects). The coefficient is estimated jointly with every other effect. Works with {opt waves()} (one shared coefficient per variable, as RSiena's RateX) and with {opt symmetric}; not yet supported combined with co-evolution, {opt present()}, or {opt missnet()}. See {help nwsaom_remarks:Remarks}{p_end}
{synopt:{opt ratecovcoef(numlist)}}Starting values for the {opt ratecov()} coefficients, one per variable or one for all (default 0){p_end}
{synopt:{opt nocenter}}Use the raw values of the covariates of {opt egox()}, {opt altx()}, {opt nodecov()} and {opt ratecov()}. By default they are centred by their means (missing values set to the mean), as RSiena's {cmd:coCovar(centered = TRUE)}, so that all coefficients, including outdegree and the rate, are RSiena's; the means are returned in {bf:e(covmeans)} and listed under the table with {opt detail}. Centring changes only the outdegree coefficient (and the rate intercept), not the covariate coefficients. {opt samex()} does not depend on it; {opt simx()} is centred by its similarity mean either way{p_end}

{marker symmetric_options}{...}
{syntab:Undirected/symmetric relations}
{synopt:{opt symmetric}}Model a non-directed relation (x_ij always equals x_ji). Not needed for waves declared undirected ({cmd:nwset ..., undirected}, {help nwsym}) or directed waves that are all tie-symmetric: like RSiena, {cmd:nwsaom} then models a non-directed relation automatically (tie-symmetric directed waves stay directed only with {opt reciprocity} or where the non-directed model does not apply: outdegree/reciprocity endowment/creation effects). With directed waves that are not tie-symmetric {opt symmetric} is an error; it does not symmetrize data. Several effects are not meaningful for a non-directed relation and are rejected - see {help nwsaom_remarks##undirected:Remarks}. Combinable with {opt waves()}, {opt present()}, {opt missnet()}, {opt ratecov()} (not with {opt behavior()}) and with co-evolution ({opt behavior()}; native plugin required){p_end}
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
{synopt:{opt detail}}Also display RSiena's names of the covariate, interaction and behavior effects, the covariates' centring means, an explanation of the conditional rate, and the convergence t-ratio of every parameter. By default only the overall maximum convergence ratio is shown, with any parameter whose t-ratio is 0.1 or more in absolute value; the full information is always stored in {bf:e(rsiena_labels)}, {bf:e(covmeans)} and {bf:e(tconv)}{p_end}
{synoptline}
{p2colreset}{...}

{marker multiplex_options}{...}
{synoptset 22 tabbed}{...}
{synopthdr:multiplex_options}
{synoptline}
{syntab:Waves (all required)}
{synopt:{opt netawave1(netname)}}first network (A) at the first wave{p_end}
{synopt:{opt netawave2(netname)}}network A at the second wave{p_end}
{synopt:{opt netbwave1(netname)}}second network (B) at the first wave{p_end}
{synopt:{opt netbwave2(netname)}}network B at the second wave{p_end}
{syntab:Effects}
{synopt:{opt crprod}}effect of a tie in B on the same tie in A (coefficient {bf:net1_crprod}){p_end}
{synopt:{opt crprodb}}effect of a tie in A on the same tie in B (coefficient {bf:net2_crprod}){p_end}
{syntab:Estimation}
{synopt:{opt theta01(numlist)}}starting values for network A's effects, in the order {bf:outdegree}, {bf:reciprocity}, {bf:crprod}; default 0{p_end}
{synopt:{opt theta02(numlist)}}starting values for network B's effects, in the order {bf:outdegree}, {bf:reciprocity}, {bf:crprodb}; default 0{p_end}
{synopt:{opt k0(#)}}Phase 1 simulations; default 30{p_end}
{synopt:{opt k3(#)}}Phase 3 simulations; default 200{p_end}
{synopt:{opt firstg(#)}}initial Robbins-Monro gain; default 0.2{p_end}
{synopt:{opt seed(#)}}random-number seed{p_end}
{synopt:{opt detail}}list the convergence t-ratio of every parameter{p_end}
{synoptline}
{p2colreset}{...}

{marker multinet}{...}
{title:Several dependent networks: nwsaom multinet}

{p 8 17 2}
{cmd:nwsaom multinet,} {opt net1(namelist)} {opt net2(namelist)} [{opt eff1(effects)} {opt eff2(effects)} {opt cross1(effects)} {opt cross2(effects)} [{opt sym1}] [{opt sym2}]
[{opt beh:avior(namelist)} {opt beheff1(effects)} {opt beheff2(effects)}] {opt k0(#)} {opt k3(#)} {opt firstg(#)} {opt seed(#)}]

{p 4 4 2}
Two one-mode networks (directed, or undirected with {opt sym1}/{opt sym2}) on the same actors evolve together (RSiena: two dependent network variables; unconditional Method of Moments, rates per
network and period). {opt net1()} and {opt net2()} list the waves (the same number, at least two). {opt eff1()} / {opt eff2()}: the within-network effects of
each network (default {cmd:outdegree reciprocity}): {cmd:outdegree reciprocity transtrip cycle3 transmedtrip cycle4 indegpop outact} and, with a variable,
{cmd:egox:}{it:var} {cmd:altx:}{it:var} {cmd:samex:}{it:var} {cmd:simx:}{it:var}. {opt cross1()} lists the cross-network effects of network 1 that depend on network 2,
{opt cross2()} those of network 2 on network 1: {cmd:crprod crprodrecip crprodmutual from frommutual fromany to toback torecip clxwx clxwx1 clxwx2 mixedinxw}
(RSiena's crprod, crprodRecip, crprodMutual, from, fromMutual, fromAny, to, toBack, toRecip, cl.XWX, cl.XWX1, cl.XWX2, mixedInXW; a parameter after a colon,
e.g. {cmd:from:2}, is RSiena's effect parameter). The cross-network statistics read the other network at the start of the period, the simulation its current
state, as RSiena. {opt sym1} / {opt sym2} declare the first / second network non-directed (undirected {cmd:nwset}, forcing model, protocol 62). {bf:Native plugin only} (protocol 52); observed statistics and estimates agree with siena07.

{p 4 4 2}
{bf:A co-evolving behavior.} {opt behavior(}{it:b1 b2 ...}{opt )} adds one behavior variable (one variable per wave, as in {cmd:nwsaom}) that
evolves together with the two networks (own rate per period, like each network). {opt beheff1()} lists the behavior effects of the behavior itself
and of the {it:first} network on it ({cmd:linear quadratic avalt avsim} and the other tokens of the behavior effects of {cmd:nwsaom}; default
{cmd:linear quadratic avalt}), {opt beheff2()} the behavior effects driven by the {it:second} network (for example {cmd:avalt}; they are shown
as {cmd:beh2_}{it:effect}). The behavior can also be a covariate of the network effects: {cmd:behsim behegox behaltx behegoplusalt} in
{opt eff1()}/{opt eff2()}, and of the cross-network effects: {it:effect}{cmd::behavior} in {opt cross1()}/{opt cross2()} (any of the covariate
cross-network effects below, e.g. {cmd:cross1(samewwclosure:behavior)}). {bf:Native plugin only} (protocols 64 and 65).

{p 4 4 2}
Further cross-network effects (all validated against siena07; the names are RSiena's short names in lower case, see the effects inventory): the degree and distance-two
families ({cmd:inpopintn inactintn crprodinactintn outpopintn outactintn divoutegointn divinegointn divoutaltintn divinaltintn avdegintn absoutdiffintn both outoutactintn
outoutavintn dist2outinactintn outoutdist2actintn outoutdist2avintn ndist2actintn doubleoutact}), closure and mixed-triad effects ({cmd:closure cyclosure sharedin wwxee wwxfr wxxfe
wxxer xwxer xwxfe jinmix joutmix gwespffmix gwespbbmix gwespbfmix gwespfbmix gwesprrmix inpopoutw sharedto avalt2mtie avalt2mtot doubleinpop}).
{bf:With a covariate} of the actors (a variable in the current dataset, written {it:effect}{cmd::}{it:var}[{cmd::}{it:#}], e.g. {cmd:cross1(covnetnet:alc homcovnetnet:alc)}), protocol 56:
{cmd:samewwclosure diffwwclosure jumpwwclosure jumpfrom jumpsharedin samewxclosure diffwxclosure jumpwxclosure homwxclosure samexwclosure diffxwclosure covnetnet homcovnetnet
contrastcovnetnet alldifcovnetnet covnetnetin homcovnetnetin contrastcovnetnetin alldifcovnetnetin inpopintnx inactintnx outpopintnx outactintnx samexinpopintn samexinactintn
samexoutpopintn samexoutactintn altdist2w totdist2w simdist2w altindist2w totindist2w simegodist2w simegoindist2w} (RSiena sameWWClosure, diffWWClosure, jumpWWClosure, jumpFrom,
jumpSharedIn, sameWXClosure, ..., covNetNet, homCovNetNet, ..., inPopIntnX, ..., altDist2W, ..., simEgoInDist2W; the number is RSiena's effect parameter).

{title:Description}

{pstd}
{cmd:nwsaom} fits a stochastic actor-oriented model (SAOM, Snijders-style) between two or more
observed panel waves of the same network on a fixed set of actors. It fits the same models as
the {browse "https://www.stats.ox.ac.uk/~snijders/siena/":RSiena} package (Ripley, Snijders et
al.), with the same effects and estimation algorithm, and gives the same estimates; no R or other
outside software is needed. {cmd:nwsaom} is not affiliated with or endorsed by the RSiena
project.

{pstd}
An SAOM models network change as a sequence of unobserved, actor-driven "ministeps": between
consecutive observed waves, actors are activated one at a time (at a rate governed by the model's
own rate parameter) and each activated actor may create or drop exactly one of its own outgoing
ties, choosing among the available alternatives (including "no change") via a multinomial-logit
choice model on a linear combination of effect-specific "change statistics", weighted by the
effect's estimated coefficient. An actor evaluates a choice only by its own resulting
statistics, not by its effect on other actors; this distinguishes an SAOM from an ERGM (see
{help nwergm}), which describes a probability distribution over whole networks. Coefficients are
estimated by the Method of Moments via Robbins-Monro stochastic approximation, RSiena's default.

{marker multiplex}{...}
{pstd}
{cmd:nwsaom multiplex} fits two directed networks on the same actors that change together
between two waves, for example friendship and advice. Each network has its own
{bf:outdegree} and {bf:reciprocity} effects and its own rate; {opt crprod} adds the effect of a
tie in the second network on the same tie in the first, and {opt crprodb} the reverse. In a
ministep the other network's current state counts; the {opt crprod} statistics use the other
network at the start of the period, as RSiena does for effects linking two dependent variables.
Both rates are estimated with the effects (unconditional Method of Moments, RSiena's default for
two dependent variables). Other effects, more than two waves, and {cmd:estat gof} are not
available for multiplex models. On a friendship network and a simulated advice network, every
parameter agrees with RSiena 1.6.6 within 0.06 standard errors (five seeds). See
{help nwsaom_remarks##multiplex:Multiplex} in nwsaom_remarks for details.

{title:Performance}

{pstd}
{cmd:nwsaom} has a native (C) simulation backend, used automatically whenever the fitted model's
effects all have native coverage (no option needed to opt in). See {help nwsaom_remarks:Remarks}
for a full wall-clock benchmark against real RSiena and the performance-tuning history behind it.

{title:Supported network types}

{pstd}
Binary: yes (only) - a valued/weighted wave is rejected. Directed one-mode: yes (the default
model; an actor controls its own outgoing ties). Non-directed (undirected or tie-symmetric waves,
RSiena's non-directed model types): yes, see {opt symmetric}. Two-mode (bipartite, actors choose
events): yes, see {opt actormode()}. Several co-evolving networks: {help nwsaom##multinet:nwsaom multinet}.
Signed: not applicable/not supported.

{title:Limitations (v1 scope)}

{pstd}
{cmd:nwsaom} estimates {bf:binary} SAOMs (directed one-mode, non-directed and two-mode); remaining limits:

{p2colset 9 13 15 2}{...}
{p2col: o}Two-mode (bipartite) waves are supported (see {help nwsaom_remarks##twomode:Two-mode networks}); temporal-metadata
and valued/weighted waves are rejected with an explicit error - never silently coerced.{p_end}
{p2col: o}Composition change (actors joining/leaving between waves, {opt present()}) and missing
tie/behavior data ({opt missnet()}/{opt missbeh()}) are both supported - see
{help nwsaom_remarks##compchange:Composition change} and {help nwsaom_remarks##missingdata:Missing data} in nwsaom_remarks for
each one's own scope and caveats. Joiners and leavers at fractional times inside a period are supported through
{opt joinat()}/{opt leaveat()} (RSiena's {cmd:sienaCompositionChange()} option 1).{p_end}
{p2col: o}Behavior co-evolution ({opt behavior()}) supports several co-evolving behaviors
({cmd:behavior(a1 a2 a3 : linear quadratic avalt | s1 s2 s3 : linear avalt)}), which interact only through the
network; see {help nwsaom_remarks##multibeh:Several behaviors}. The linear shape effect can be split into endowment/creation roles
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

{marker simulate}{...}
{title:Simulation without estimation: nwsaom simulate}

{p 8 17 2}
{cmd:nwsaom simulate,} {it:model options of nwsaom} {opt theta(numlist)} [{opt behtheta(numlist)}] {opt rates(numlist)}
[{opt ratesbeh(numlist)} {opt nsim(int)} {opt seed(int)} {opt gen:erate(stub)}]

{pstd}
Simulates a model at coefficients chosen by you, without estimating anything (RSiena's {cmd:siena07} with
{cmd:simOnly = TRUE}). The model is specified exactly as in {cmd:nwsaom} (waves, effects, covariates, {opt behavior()},
...). {opt theta()} gives one coefficient per network effect in the order of the coefficient table of a fit of the same model (the order {cmd:nwsaom} lists the effects, not necessarily the order you typed them), {opt behtheta()} one
per behavior effect, {opt rates()} the rate of every period and {opt ratesbeh()} the behavior rates. The result is that of
{help nwsaom_estat##estat_simulate:estat simulate}. After a fit, {cmd:estat simulate} simulates the fitted model.

{pstd}
{bf:Syntax rule.} A property of the data (two-mode, non-directed) is detected from the network; an option changes
how a model is specified or fitted ({opt behavior()}, {opt present()}, {opt fix()}); a different job is a subcommand
({cmd:nwsaom multinet}, {cmd:nwsaom simulate}) or a postestimation command ({cmd:estat}). {cmd:nwsaom multiplex} is
deprecated: use {cmd:nwsaom multinet}.

{title:Remarks}

{pstd}
A user manual and reference (nwsaom_manual.pdf, in the {cmd:manual} folder of the package source) covers the model, every option, the complete effects reference, the validation against siena07 and a list of what RSiena offers that nwsaom does not (yet). See {help nwsaom_remarks} for the full effect-derivation library (every effect's own ministep
formula and how it was verified against RSiena's real source), interaction/multiplex/co-evolution
mechanics, composition-change/missing-data/structural-zero handling, the full performance
benchmark, and the estimation-algorithm background (Method-of-Moments phase structure, rate
estimation). That material was split into its own file purely to keep this file's own length
within Stata's interactive Viewer's rendering limits - it is not optional/secondary content,
just relocated.

{title:Postestimation}

{pstd}
{cmd:estat gof} is available after {cmd:nwsaom} (not after {cmd:nwsaom multiplex}).

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
To combine the same model fitted to several networks (for example school classes) see {help nwsaom_meta}, the counterpart of RSiena's {cmd:siena08}.

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
		  {bf:e(rsiena_labels)}	RSiena's effect names of the coefficients, in {bf:e(b)}'s order, separated by "|" (e.g. "alcohol1 ego", "same smoke1", "alcohol1 ego x reciprocity")
		  {bf:e(rate_actor)}		non-directed fits only: the rate at which an actor gets an opportunity to change, the scale of every other {cmd:nwsaom} rate (differs from e(rate), RSiena's rate, only for the pairwise types force/agree/joint)
		  {bf:e(conditional)}		1 for conditional estimation, 0 for unconditional
		  {bf:e(centered)}		1 if the covariates were centred (the default), 0 with {opt nocenter}
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
		  {bf:e(covmeans)}		means of the covariates of {opt egox()}/{opt altx()}/{opt nodecov()}/{opt ratecov()}, columns named by the variables (subtracted unless {opt nocenter})
		  {bf:e(tconv)}			RSiena-style convergence t-ratios (phase-3 mean deviation / its standard deviation), one per parameter including the rates; all below 0.1 in absolute value indicates good convergence. Printed after the coefficient table, followed by e(tconv_max). (Before 2026-10-01 e(tratio) and the rate t-ratios were mean / (sd/sqrt(k3)), about 31.6 times this scale with the default k3(1000))

{pstd}
{cmd:estat gof} stores the following in {cmd:r()}, one pair per requested statistic (default
{bf:outdegree}/{bf:indegree}/{bf:geodesic}):

		Scalars
		  {bf:r(p_{it:stat})}		empirical Mahalanobis-distance test p-value for that statistic
		  {bf:r(mhd_{it:stat})}		observed vector's own Mahalanobis distance from the simulated mean

{pstd}
{cmd:nwsaom multiplex} stores the following in {cmd:e()}:

		Scalars
		  {bf:e(N)}			number of actors
		  {bf:e(rate1)}, {bf:e(rate2)}	rates of networks A and B
		  {bf:e(rate1_se)}, {bf:e(rate2_se)}	their standard errors
		  {bf:e(tconv_max)}		overall maximum convergence ratio
		Macros
		  {bf:e(cmd)}			{bf:nwsaom_multiplex}
		  {bf:e(engine)}		{bf:native} or {bf:mata}
		Matrices
		  {bf:e(b)}			coefficients: {bf:net1_outdegree}, {bf:net1_reciprocity}, [{bf:net1_crprod}], {bf:net2_outdegree}, {bf:net2_reciprocity}, [{bf:net2_crprod}]
		  {bf:e(V)}			their covariance matrix
		  {bf:e(tconv)}			convergence t-ratios of the coefficients and the two rates

{title:Examples}

{pstd}
All examples except the last use the Glasgow friendship data (RSiena's s50 data): three waves of
friendship among 50 pupils ({cmd:glasgow1}-{cmd:glasgow3}) and smoking, alcohol and sport at each
wave ({cmd:smoke1}-{cmd:smoke3}, {cmd:alcohol1}-{cmd:alcohol3}, {cmd:sport1}-{cmd:sport3}).

		{cmd:. nwwebuse glasgow, nwclear}

{pstd}{bf:Network change between two waves, and over three waves}{p_end}
		{cmd:. nwsaom, wave1(glasgow1) wave2(glasgow2) outdegree reciprocity seed(1)}
		{cmd:. nwsaom, waves(glasgow1 glasgow2 glasgow3) outdegree reciprocity seed(1)}

{pstd}{bf:Triadic closure and degree effects}{p_end}
		{cmd:. nwsaom, waves(glasgow1 glasgow2 glasgow3) outdegree reciprocity transtrip cycle3 seed(1)}
		{cmd:. nwsaom, waves(glasgow1 glasgow2 glasgow3) outdegree reciprocity gwesp(.69) indegpopularity outactivity seed(1)}

{pstd}{bf:Covariate effects} (homophily on smoking; ego, alter and similarity effects of alcohol and
sport); {opt detail} also lists RSiena's effect names, the covariate means and every convergence
t-ratio{p_end}
		{cmd:. nwsaom, waves(glasgow1 glasgow2 glasgow3) outdegree reciprocity gwesp(.69) samex(smoke1) egox(alcohol1 sport1) altx(alcohol1 sport1) simx(alcohol1) seed(1)}
		{cmd:. nwsaom, waves(glasgow1 glasgow2 glasgow3) outdegree reciprocity gwesp(.69) samex(smoke1) seed(1) detail}

{pstd}{bf:Interaction}: does the effect of reciprocity depend on the sender's alcohol use?{p_end}
		{cmd:. nwsaom, waves(glasgow1 glasgow2 glasgow3) outdegree reciprocity gwesp(.69) egox(alcohol1) interact(egox#reciprocity) seed(1)}

{pstd}{bf:Goodness of fit}{p_end}
		{cmd:. estat gof}

{pstd}{bf:Restarting from the estimates} when the overall maximum convergence ratio is above 0.25{p_end}
		{cmd:. nwsaom, waves(glasgow1 glasgow2 glasgow3) outdegree reciprocity gwesp(.69) seed(1)}
		{cmd:. matrix b = e(b)}
		{cmd:. nwsaom, waves(glasgow1 glasgow2 glasgow3) outdegree reciprocity gwesp(.69) theta0(`=b[1,1]' `=b[1,2]' `=b[1,3]') seed(2)}

{pstd}{bf:Unconditional estimation} (RSiena's {cmd:cond = FALSE}; restart it with {opt rate0()} as well
as {opt theta0()}){p_end}
		{cmd:. nwsaom, waves(glasgow1 glasgow2 glasgow3) outdegree reciprocity gwesp(.69) unconditional seed(1)}

{pstd}{bf:Covariate-dependent rate}: do heavier drinkers change their friendships more often?{p_end}
		{cmd:. nwsaom, wave1(glasgow1) wave2(glasgow2) outdegree reciprocity ratecov(alcohol1) seed(1)}

{pstd}{bf:Co-evolution of friendship and drinking}: selection ({opt behsim}) and influence
({opt avalt}, or {opt avsim} as the alternative influence effect){p_end}
		{cmd:. nwsaom, waves(glasgow1 glasgow2 glasgow3) outdegree reciprocity gwesp(.69) behsim behavior(alcohol1 alcohol2 alcohol3) linear quadratic avalt seed(1)}
		{cmd:. nwsaom, waves(glasgow1 glasgow2 glasgow3) outdegree reciprocity gwesp(.69) behsim behavior(alcohol1 alcohol2 alcohol3) linear quadratic avsim seed(1)}
		{cmd:. estat gof}

{pstd}{bf:Separate effects for increasing and decreasing behavior} (endowment and creation){p_end}
		{cmd:. nwsaom, wave1(glasgow1) wave2(glasgow2) outdegree reciprocity behavior(alcohol1 alcohol2) linear quadraticendow quadraticcreation seed(1)}

{pstd}{bf:Undirected networks}: symmetrized friendship; RSiena's default model type (forcing), and
the pairwise model in which both actors decide jointly{p_end}
		{cmd:. nwsym glasgow1, generate(u1) mode(max)}
		{cmd:. nwsym glasgow2, generate(u2) mode(max)}
		{cmd:. nwsaom, wave1(u1) wave2(u2) outdegree gwesp(.69) samex(smoke1) seed(1)}
		{cmd:. nwsaom, wave1(u1) wave2(u2) outdegree symtype(joint) seed(1)}

{pstd}{bf:Composition change}: three pupils leave after the first wave ({cmd:p1}, {cmd:p2} mark who
is present){p_end}
		{cmd:. generate byte p1 = 1}
		{cmd:. generate byte p2 = _n > 3}
		{cmd:. nwsaom, wave1(glasgow1) wave2(glasgow2) outdegree reciprocity present(p1 p2) seed(1)}

{pstd}{bf:Missing data}: a missing behavior value ({opt missbeh()}: one 0/1 variable per wave) and
missing tie values ({opt missnet()}: one 0/1 matrix per wave){p_end}
		{cmd:. generate byte mb1 = _n == 5}
		{cmd:. generate byte mb2 = 0}
		{cmd:. nwsaom, wave1(glasgow1) wave2(glasgow2) outdegree reciprocity behavior(alcohol1 alcohol2) linear avalt missbeh(mb1 mb2) seed(1)}
		{cmd:. matrix miss1 = J(50, 50, 0)}
		{cmd:. matrix miss1[1,2] = 1}
		{cmd:. matrix miss2 = J(50, 50, 0)}
		{cmd:. nwsaom, wave1(glasgow1) wave2(glasgow2) outdegree reciprocity missnet(miss1 miss2) seed(1)}

{pstd}{bf:Structural zeros}: dyads that cannot change (a 0/1 matrix; here, ties from pupil 1 to
pupils 11-20, which are absent at both waves){p_end}
		{cmd:. matrix zeros = J(50, 50, 0)}
		{cmd:. forvalues j = 11/20 {c -(}}
		{cmd:.     matrix zeros[1,`j'] = 1}
		{cmd:. {c )-}}
		{cmd:. nwsaom, wave1(glasgow1) wave2(glasgow2) outdegree reciprocity structural(zeros) seed(1)}

{pstd}{bf:Threads}: the same results on one thread (the default uses all physical cores){p_end}
		{cmd:. nwsaom, waves(glasgow1 glasgow2 glasgow3) outdegree reciprocity gwesp(.69) cores(1) seed(1)}

{pstd}{bf:Two networks that change together} ({cmd:nwsaom multiplex}). The Glasgow data have one
network, so this example simulates a second one, "advice", that overlaps with friendship:{p_end}
		{cmd:. nwtomata glasgow1, mat(F1)}
		{cmd:. nwtomata glasgow2, mat(F2)}
		{cmd:. set seed 20261001}
		{cmd:. mata: A1 = (F1 :* (runiform(50, 50) :< 0.7) + (runiform(50, 50) :< 0.005)) :> 0}
		{cmd:. mata: _diag(A1, 0)}
		{cmd:. mata: A2 = (A1 :* (runiform(50, 50) :< 0.8) + F2 :* (1 :- A1) :* (runiform(50, 50) :< 0.4)) :> 0}
		{cmd:. mata: _diag(A2, 0)}
		{cmd:. nwset, mat(A1) directed name(advice1)}
		{cmd:. nwset, mat(A2) directed name(advice2)}

{pstd}Each network with outdegree and reciprocity, and the effect of each network on the other:{p_end}
		{cmd:. nwsaom multiplex, netawave1(glasgow1) netawave2(glasgow2) netbwave1(advice1) netbwave2(advice2) crprod crprodb seed(1)}

{pstd}Restarting from the estimates (one starting value per effect of each network):{p_end}
		{cmd:. matrix b = e(b)}
		{cmd:. nwsaom multiplex, netawave1(glasgow1) netawave2(glasgow2) netbwave1(advice1) netbwave2(advice2) crprod crprodb theta01(`=b[1,1]' `=b[1,2]' `=b[1,3]') theta02(`=b[1,4]' `=b[1,5]' `=b[1,6]') seed(2)}

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
