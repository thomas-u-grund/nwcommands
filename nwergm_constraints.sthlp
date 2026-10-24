{smcl}
{* *! version 1.0.0  23oct2026 author: Thomas Grund}{...}
{vieweralsosee "nwergm" "help nwergm"}{...}
{title:Title}

{p2colset 9 33 34 2}{...}
{p2col :nwergm constraints {hline 2}}Sample-space constraints, proposals and sampling controls of nwergm{p_end}
{p2colreset}{...}

{title:Syntax}

{p 8 16 2}
{cmd:nwergm} {it:netname}{cmd:,} {it:terms} {opt constraints(formula)} [{opt obsconstraints(formula)} {opt mcmcprop(hints)} {opt proposal(uniform|random|tnt)} {opt mcmcmaxedges(#)}]

{p 8 16 2}
{cmd:nwergm simulate} {it:nodes}{cmd:,} {it:terms} {opt theta(numlist)} {opt basis(netname)} {opt constraints(formula)} [{opt nsim(#)} {opt mcmcburnin(#)} {opt mcmcinterval(#)}]

{title:Description}

{pstd}
{opt constraints()} restricts the set of networks the model is defined on, exactly as {cmd:constraints=} does in R's {cmd:ergm} package. The formula is a list of constraint terms joined by {cmd:+} or {cmd:-}.
Arguments are written as in R, by position or by name ({cmd:name=value}); node attributes are variables of the current dataset, and networks are names of networks in memory.
The constraints refer to the network being fitted (or, for {cmd:simulate}, to {opt basis()}).

{pstd}
Constraints that only fix some dyads ({cmd:blocks}, {cmd:blockdiag}, {cmd:fixedas}, {cmd:fixallbut}, {cmd:observed}, {cmd:egocentric}) are combined from left to right: a term with {cmd:+} keeps only the dyads that may vary according to it
and to everything to its left, a term with {cmd:-} adds the dyads that may vary according to it. Constraints that tie the dyads together ({cmd:edges}, {cmd:degrees}, {cmd:odegrees}, {cmd:idegrees}, {cmd:b1degrees},
{cmd:b2degrees}, {cmd:degreedist}, {cmd:idegreedist}, {cmd:odegreedist}, {cmd:bd}) always restrict the sample space and may only carry a {cmd:+} sign. Constraints implied by others are dropped, as in R.

{pstd}
Statistics that a constraint holds constant (for example {cmd:edges} under {cmd:constraints(edges)} or {cmd:kstar()} under {cmd:constraints(degrees)}) are fixed at zero and ignored in the fit, with a note, as R does.
A dyad-dependent constraint makes the sample space dyad-dependent: the default method is then {cmd:mcmle}, started from zero, and {cmd:method(mple)} reports the pseudolikelihood over the free dyads.

{title:Constraint terms}

{p2colset 5 36 38 2}{...}
{p2col :{cmd:edges}}keep the number of ties{p_end}
{p2col :{cmd:degrees} ({cmd:nodedegrees})}keep each node's degree (undirected) or in- and out-degree (directed){p_end}
{p2col :{cmd:odegrees}, {cmd:idegrees}}keep out-degrees / in-degrees (directed networks){p_end}
{p2col :{cmd:b1degrees}, {cmd:b2degrees}}keep the degrees of mode-1 / mode-2 nodes (two-mode networks){p_end}
{p2col :{cmd:degreedist}, {cmd:idegreedist}}keep the degree distribution / in-degree distribution{p_end}
{p2col :{cmd:bd(}{it:attribs, maxout, maxin, minout, minin}{cmd:)}}bound degrees. {it:attribs} is a list of 0/1 node variables defining the alter groups that are counted (default: all nodes); each bound is a number or
node variable(s); defaults are 0 (minimum) and the number of nodes minus one (maximum){p_end}
{p2col :{cmd:blocks(}{it:attr, b1levels, b2levels, levels, levels2}{cmd:)}}fix blocks of dyads defined by the mixing of a categorical node variable. {it:levels2} chooses the fixed mixing types: {cmd:TRUE} (all), {cmd:FALSE} (none, the default),
or their positions {cmd:c(1,2)}, {cmd:-c(1,2)} in R's ordering{p_end}
{p2col :{cmd:blockdiag(}{it:attr, noncontig}{cmd:)}}only dyads within the same value of {it:attr} may vary; {it:noncontig} is {cmd:merge} (default, values must form runs) or {cmd:split}{p_end}
{p2col :{cmd:fixedas(}{it:fixed.dyads, present, absent}{cmd:)}}fix the dyads that are ties in the given networks; present/absent dyads must match the network being fitted{p_end}
{p2col :{cmd:fixallbut(}{it:free.dyads}{cmd:)}}only the dyads that are ties in the given network may vary{p_end}
{p2col :{cmd:observed}}only the missing dyads may vary{p_end}
{p2col :{cmd:egocentric(}{it:attr, direction}{cmd:)}}fix the dyads of nodes for which the 0/1 node variable {it:attr} is nonzero; {it:direction} is {cmd:both} (default), {cmd:out} or {cmd:in}{p_end}
{p2col :{cmd:dyadnoise(}{it:p01, p10}{cmd:)}}soft constraint: the sampled network is an observation of the given one with independent dyad errors of those probabilities{p_end}
{p2colreset}{...}

{pstd}
{cmd:hamming} stops with the same message as R's current release. {cmd:ChangeStats()}, {cmd:Dyads()} and {cmd:I()} are not available.

{title:Proposals}

{pstd}
The proposal is chosen from the constraints with R's rules. No constraint, dyad constraints and {cmd:bd}: toggle one dyad (tie/no-tie weighted, {opt proposal(tnt)}, default; or uniform, {opt proposal(uniform)} or {opt proposal(random)}).
{cmd:edges}: swap a tie with a non-tie, also with dyad constraints and {cmd:bd}. {cmd:degrees} (or {cmd:idegrees} with {cmd:odegrees}, or {cmd:b1degrees} with {cmd:b2degrees}): tetrad moves, plus hexad moves for directed networks.
{cmd:odegrees}, {cmd:idegrees}, {cmd:b1degrees}, {cmd:b2degrees}: move one end of a tie. {cmd:degreedist}, {cmd:idegreedist}: exchange the ends of a tie between nodes whose degrees differ by one. {cmd:dyadnoise}: tie/no-tie
proposal with the noise likelihood in the acceptance ratio. Other combinations stop with the message R gives. {cmd:odegreedist} and the degree-distribution constraints on two-mode networks are refused (R's released proposals for them fail).

{title:Observation process}

{pstd}
{opt obsconstraints(formula)} describes how the network was observed (for example the dyads that were not observed, as {cmd:fixallbut(}{it:unobserved}{cmd:)}). Two chains are run at every iteration, one under {opt constraints()} and one
under {opt constraints()} and {opt obsconstraints()} together, started from the network; the coefficients solve the equation that sets the two expected statistics equal, and the information is the difference of their
covariances. Requires {cmd:method(mcmle)}.

{title:Sampling controls}

{p2colset 5 36 38 2}{...}
{p2col :{opt mcmcburnin()}}R's {cmd:MCMC.burnin}{p_end}
{p2col :{opt mcmcinterval()}}R's {cmd:MCMC.interval}{p_end}
{p2col :{opt mcmcsamplesize()}}R's {cmd:MCMC.samplesize}{p_end}
{p2col :{opt mcmcprop(hints)}}R's {cmd:MCMC.prop}: {cmd:sparse} (default); {cmd:triadic} and {cmd:strat} are accepted but the tie/no-tie proposal is used, with a note, as R does when no proposal can use a hint{p_end}
{p2col :{opt proposal()}}R's {cmd:MCMC.prop.weights}: {cmd:tnt} (default) or {cmd:uniform} ({cmd:random}){p_end}
{p2col :{opt mcmcmaxedges(#)}}R's {cmd:MCMC.maxedges}: stop sampling if the network gets more ties than this{p_end}
{p2col :{opt seed(#)}}R's {cmd:seed}{p_end}
{p2colreset}{...}

{pstd}
{cmd:nwergm simulate} with {opt basis()} starts one chain from the basis network, burns in once and takes {opt mcmcinterval()} steps between the {opt nsim()} draws, as {cmd:simulate()} in R does. {cmd:estat gof}
simulates under the constraints of the fit.

{title:Examples}

{phang2}{cmd:. nwergm net1, edges triangle constraints(edges)}{p_end}
{phang2}{cmd:. nwergm net1, edges mutual constraints(odegrees)}{p_end}
{phang2}{cmd:. nwergm net1, edges triangle nodematch(g) constraints(blockdiag(g) + bd(maxout=5))}{p_end}
{phang2}{cmd:. nwergm net1, edges triangle obsconstraints(fixallbut(unobserved))}{p_end}
{phang2}{cmd:. nwergm simulate 12, edges triangle theta(-1 0.2) basis(net1) constraints(degrees) nsim(5) generate(sim)}{p_end}

{title:Author}

{pstd}Thomas Grund, University College Dublin and RWTH Aachen{p_end}
