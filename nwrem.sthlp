{smcl}
{* *! version 1.0.0  28aug2026 author: Thomas Grund}{...}
{marker topic}
{helpb nw_topical##analysis_statmodels:[NW-2.6.7] Statistical Estimation of Networks}

{title:Title}

{p2colset 9 15 22 2}{...}
{p2col :nwrem  {hline 2}}Relational event model (ordinal partial likelihood, MLE){p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 17 2}
{cmdab: nwrem}
[{it:{help netname}}]
{cmd:,}
[{opt nodsnd}
{opt nidrec}
{opt nidsnd}
{opt nodrec}
{opt ntdegsnd}
{opt ntdegrec}
{opt frpsndsnd}
{opt frrecsnd}
{opth covsnd(varname)}
{opth covrec(varname)}
{opth covint(varname)}
{opth covevent(netname)}
{opt rsndsnd}
{opt rrecsnd}
{opt seed(#)}]


{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Degree effects}
{synopt:{opt nodsnd}}sender's normalized out-degree affects the sending rate (share of all prior events in which this actor was the sender){p_end}
{synopt:{opt nidrec}}receiver's normalized in-degree affects the receiving rate (share of all prior events in which this actor was the receiver){p_end}
{synopt:{opt nidsnd}}sender's normalized in-degree affects the sending rate{p_end}
{synopt:{opt nodrec}}receiver's normalized out-degree affects the receiving rate{p_end}
{synopt:{opt ntdegsnd}}sender's normalized total degree (in+out, averaged) affects the sending rate{p_end}
{synopt:{opt ntdegrec}}receiver's normalized total degree (in+out, averaged) affects the receiving rate{p_end}
{syntab:Inertia effects}
{synopt:{opt frpsndsnd}}"inertia": the fraction of the sender's own past sends that went specifically to this receiver affects the sending rate to that receiver{p_end}
{synopt:{opt frrecsnd}}"reciprocity of receipt": the fraction of the sender's own past receipts that came specifically from this receiver affects the sending rate to that receiver{p_end}
{syntab:Covariate effects}
{synopt:{opth covsnd(varname)}}a per-actor covariate affects the sending rate (an "ego" effect - {it:varname} is read from the CURRENT dataset, one row per actor, in {it:netname}'s own actor order - see {help nwload}'s {opt xvars} option below){p_end}
{synopt:{opth covrec(varname)}}a per-actor covariate affects the receiving rate (an "alter" effect){p_end}
{synopt:{opth covint(varname)}}a per-actor covariate affects both the sending and the receiving rate together (the same variable, one shared coefficient){p_end}
{synopt:{opth covevent(netname)}}a pairwise (dyad-level) covariate affects the rate of the event from sender to receiver directly - {it:netname} must already be a loaded network with the SAME actors as the event network, one value per ordered (sender,receiver) pair (read from its own tie values, exactly like {help nwergm}'s {opt edgecov()}){p_end}
{syntab:Recency effects}
{synopt:{opt rsndsnd}}"recency of sending": how RECENTLY (not how often) the sender previously sent to this receiver affects the sending rate to that receiver again (1/rank among the sender's own past receivers, most recent = rank 1; 0 if never sent to before){p_end}
{synopt:{opt rrecsnd}}"recency of receipt": how RECENTLY (not how often) the sender previously received from this receiver affects the sending rate back to that receiver (1/rank among the sender's own past senders, most recent = rank 1; 0 if never received from before) - a recency-based reciprocity effect{p_end}
{syntab:}
{synopt:{opt seed(#)}}set the random-number seed before estimation (affects only which of several internal optimizer restarts is tried first when the default starting point fails to converge - never affects the reported MLE once a fit succeeds){p_end}
{synoptline}
{p2colreset}{...}
{pstd}At least one effect must be specified.{p_end}


{title:Description}

{pstd}
{cmd:nwrem} fits a relational event model (Butts 2008, "A Relational Event Framework for Social
Action," {it:Sociological Methodology} 38(1), 155-200) to a timestamped sequence of dyadic
events, via the ordinal partial likelihood: at each event, the model asks "given that some event
happened next, which of the {it:n}({it:n}-1) possible ordered actor pairs was it," and estimates
which actor-level effects make the realized event more likely relative to every other pair that
could have happened instead - the same conditional-likelihood logic Cox proportional-hazards
models use.

{pstd}
Unlike {help nwergm} (static structure) and {help nwsaom} (discrete panel-wave evolution),
{cmd:nwrem} works directly on a raw, continuous-time event stream - no snapshot or aggregation
step. It requires {it:netname} to already be declared as an {bf:event}-type temporal network via
{help nwset}'s {opt eventtime(varname)} option:

	{cmd:. nwset sender receiver, eventtime(t) name(mynet)}
	{cmd:. nwrem mynet, nodsnd nidrec}

{pstd}
{bf:Speed}: on direct head-to-head wall-clock benchmarks against R's own {cmd:relevent::rem.dyad()}
1.2-1 (identical data, identical effect set, {cmd:ordinal=TRUE}, {cmd:fit.method="MLE"} on the R
side; {cmd:nwrem}'s own pure-Mata engine on this side - {bf:no native C backend yet}): a 2-effect
model ({bf:nodsnd}+{bf:nidrec}, 30 actors, 2000 events) runs in 0.78s vs. R's 1.54s - roughly 2x
faster; the full 8-effect degree+inertia model on the identical data runs in 8.36s vs. R's
107.75s - roughly {bf:13x faster}. The gap widens on the larger model because R's own
{cmd:optim(BFGS)} has no equivalent to {cmd:nwrem}'s own retry-based optimizer (see the note on
precision below) for escaping the degree-effect family's collinearity ridge, so a single R fit can
spend most of its own time on failed convergence attempts that {cmd:nwrem} sidesteps cheaply. See
{cmd:dev/rem_benchmark.R}/{cmd:.do} and {cmd:dev/rem_benchmark_multi.R}/{cmd:.do} in the package's
own source for the exact scripts.

{pstd}
{cmd:nwrem} fits any combination of the 14 effects above (at least one required). There is
deliberately no intercept option - a term constant across every candidate pair at a given event
cancels out exactly in the ordinal likelihood's own normalization (the same reason Cox
proportional-hazards models have no identifiable baseline intercept), so one is never estimable
here regardless of what is requested. Effects not yet implemented (triadic/shared-partner effects,
fixed effects, the full non-ordinal/waiting-time likelihood, Bayesian estimation) are tracked, not
silently missing - see the package's own development roadmap for what is planned next.

{pstd}
{bf:rsndsnd}/{bf:rrecsnd} are different from {bf:frpsndsnd}/{bf:frrecsnd}: the latter measure HOW
OFTEN a sender has contacted a given partner relative to their total activity (a fraction);
{bf:rsndsnd}/{bf:rrecsnd} measure HOW RECENTLY, via reciprocal RANK among that sender's own past
contacts, ignoring how many times contact happened before or since. A sender who contacted a
partner once, very recently, scores as high on {bf:rsndsnd} for that partner as one who contacted
them constantly and most recently - only the ordering matters, not the count.

{pstd}
{bf:Covariate effects} require the current Stata dataset, at the time {cmd:nwrem} is called, to
have exactly one row per actor in {it:netname}'s own actor order - NOT the event-level dataset
{it:netname} itself was declared from. Use {help nwload}'s {opt xvars} option first to load that
per-node dataset:

	{cmd:. nwload mynet, xvars}
	{cmd:. gen seniority = ...}
	{cmd:. nwrem mynet, nodsnd covsnd(seniority)}

{pstd}
This mirrors {help nwsaom}'s own {opt nodecov()} convention exactly, not a new mechanism specific
to {cmd:nwrem}.

{pstd}
{bf:covevent()} is different: it is a per-{it:pair} (not per-actor) covariate, so it is read
from ANOTHER already-loaded network's own tie values rather than from a Stata variable - the same
convention {help nwergm}'s {opt edgecov()} already uses for dyadic covariates. Declare the
pairwise covariate as its own network first, then reference it by name - {bf:nwset}'s
{opt edgelist} option is required here ({cmd:nwset} otherwise reads three bare variables as a
wide affiliation matrix, not an edgelist):

	{cmd:. nwset i j value, name(seatdist) edgelist}
	{cmd:. nwrem mynet, nodsnd covevent(seatdist)}

{pstd}
{cmd:covevent(seatdist)} must have the same actors as {cmd:mynet}; its tie value for the ordered
pair (sender,receiver) enters the sending rate directly for that pair (no ego/alter broadcasting,
unlike {opt covsnd()}/{opt covrec()}/{opt covint()}). Because the effect reads (sender,receiver)
values directly, {bf:nwset does not auto-symmetrize} an edgelist declaration: an ordered pair with
no explicit row gets value 0, even if its reverse pair {it:was} given a value. For a covariate
that is genuinely symmetric (e.g. physical distance), supply BOTH ordered pairs (i,j) and (j,i)
explicitly; for one that is genuinely directional (e.g. "i reports to j"), that asymmetry is
exactly what {bf:covevent()} is for.

{pstd}
{bf:A note on precision}: {cmd:nodsnd}/{cmd:nidrec}/{cmd:nidsnd}/{cmd:nodrec}/{cmd:ntdegsnd}/
{cmd:ntdegrec} are each a running average - the fraction of {it:all prior events} in which an
actor sent/received - and that fraction's cross-actor spread narrows as the event sequence grows
(it converges toward 1/{it:n} for every actor). This means, unlike an ordinary regression
covariate, point estimates from these effects can remain noisy even with several thousand events,
a genuine property of the effects themselves (verified against a real reference
relational-event-model implementation on identical data, not a limitation of this command).
Combining several of these degree-type effects in the same model (e.g. {cmd:nodsnd} with
{cmd:nidsnd} and {cmd:ntdegsnd} together) can also produce a nearly flat ridge in the likelihood
surface along some combination of their coefficients - different starting values can then
converge to visibly different individual coefficients while fitting the data almost equally
well; check whether the overall model fit (log likelihood) is what actually matters for your
question before over-interpreting any single coefficient in that situation. The fitted model
reliably improves on the no-effect baseline even when a single point estimate is imprecise;
interpret standard errors accordingly and prefer larger event counts where possible.


{title:Stored results}

	Scalars
	  {bf:e(N)}		number of events
	  {bf:e(nodes)}		number of actors
	  {bf:e(ll)}		log likelihood at the MLE

	Macros
	  {bf:e(cmd)}		{bf:nwrem}
	  {bf:e(title)}		"Relational event model (ordinal partial likelihood, MLE)"
	  {bf:e(depvar)}	name of the event network fit

	Matrices
	  {bf:e(b)}		coefficient vector
	  {bf:e(V)}		variance-covariance matrix (observed information)


{title:Examples}

{pstd}Fit a relational event model on a small event log:{p_end}

	{cmd:. clear}
	{cmd:. input sender receiver t}
	{cmd:. 1 2 1}
	{cmd:. 1 3 2}
	{cmd:. 2 1 3}
	{cmd:. 1 2 4}
	{cmd:. 3 2 5}
	{cmd:. 2 3 6}
	{cmd:. 1 3 7}
	{cmd:. 3 1 8}
	{cmd:. 2 1 9}
	{cmd:. 1 3 10}
	{cmd:. end}
	{cmd:. nwset sender receiver, eventtime(t) name(chat)}
	{cmd:. nwrem chat, nodsnd nidrec}

{pstd}
(a handful of events on very few actors, as above, has too little information to pin down either
coefficient precisely - the wide confidence intervals in this toy example are expected, not a
sign of a problem; see this help file's own note on precision above){p_end}

{pstd}Add an inertia effect (does a sender tend to keep sending to the same recent partner) alongside a degree effect:{p_end}

	{cmd:. nwrem chat, nidrec frpsndsnd}

{pstd}Add an actor-attribute covariate effect - does a per-actor variable affect the sending rate:{p_end}

	{cmd:. nwload chat, xvars}
	{cmd:. gen seniority = _n}
	{cmd:. nwrem chat, nodsnd covsnd(seniority)}

{pstd}Add a pairwise covariate effect - does a variable specific to the (sender,receiver) pair
itself, not to either actor alone, affect the sending rate (seat distance is symmetric, so both
ordered pairs are given explicitly - see the note on symmetry above):{p_end}

	{cmd:. clear}
	{cmd:. input i j value}
	{cmd:. 1 2 5}
	{cmd:. 2 1 5}
	{cmd:. 1 3 2}
	{cmd:. 3 1 2}
	{cmd:. 2 3 8}
	{cmd:. 3 2 8}
	{cmd:. end}
	{cmd:. nwset i j value, name(seatdist) edgelist}
	{cmd:. nwrem chat, nodsnd covevent(seatdist)}

{pstd}Add a recency effect - does a sender tend to return to whoever they contacted most recently,
regardless of how often (contrast with {cmd:frpsndsnd} above, which is about frequency):{p_end}

	{cmd:. nwrem chat, nodsnd rsndsnd}


{title:Also see}

{p 4 14 2}Help: {help nwset}, {help nwattime}, {help nwergm}, {help nwsaom}{p_end}
