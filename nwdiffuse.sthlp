{smcl}
{* *! version 1.0.0  19nov2026 author: Thomas Grund}{...}
{marker topic}
{helpb nwtopical##analysis_other:[NW-2.6.8] Other analysis tools}

{title:Title}

{p2colset 9 23 25 2}{...}
{p2col :nwdiffuse {hline 2}}Diffusion and contagion on a network: exposure, thresholds, adoption curve, hazard data, simulation{p_end}
{p2colreset}{...}

{title:Syntax}

{p 8 17 2}
{cmd:nwdiffuse exposure} [{it:{help netlist}}]{cmd:,} {it:when} {c -(}{opth gen:erate(stub)} | {opth cou:nt(stub)}{c )-} [{it:options}]

{p 8 17 2}
{cmd:nwdiffuse threshold} [{it:{help netlist}}]{cmd:,} {it:when} {c -(}{opth gen:erate(newvar)} | {opth cou:nt(newvar)}{c )-} [{it:options}]

{p 8 17 2}
{cmd:nwdiffuse curve} [{it:{help netname}}]{cmd:,} {it:when} [{opt graph} {opt plot}[{opt (cumulative|new|both)}] {opt mat:rix(name)} {opt silent} {opt name(string)} {opt saving(filename)} {opt export(filename[, options])} {it:twoway_options}]

{p 8 17 2}
{cmd:nwdiffuse long} [{it:{help netlist}}]{cmd:,} {it:when} {opt clear} [{opth keep(varlist)} {opt lag(#)} {it:options}]

{p 8 17 2}
{cmd:nwdiffuse simulate} [{it:{help netlist}}]{cmd:,} {opt model(cascade|threshold|fraction)} {opth gen:erate(newvar)} [{it:simulation options}]

{pstd}
where {it:when} says who adopts when, either

{phang2}{opth toa(varname)} the period of adoption of each node, a whole number; missing if the node never adopts, or{p_end}
{phang2}{opth adopt(varlist)} one 0/1 variable for each period (in the order of the periods): 1 once the node has adopted.{p_end}

{synoptset 24 tabbed}{...}
{synopthdr:options}
{synoptline}
{synopt:{opt t0(#)}}first period; default: the first period in {opt toa()}, or 1 with {opt adopt()}{p_end}
{synopt:{opt t1(#)}}last period; default: the last period in {opt toa()}{p_end}
{synopt:{opt lag(#)}}use adoption {it:#} periods earlier; default 0 ({cmd:long}: 1){p_end}
{synopt:{opt valued}}weight neighbours by tie values; default: ties count 0/1{p_end}
{synopt:{opt inc:oming}}neighbours are the nodes with a tie {it:to} the node; default: the nodes the node has a tie {it:to}{p_end}
{synopt:{opt self}}count a node's own adoption as exposure (the network must allow self-loops){p_end}
{synopt:{opt replace}}overwrite existing variables{p_end}
{synoptline}

{synoptset 26 tabbed}{...}
{synopthdr:simulation options}
{synoptline}
{synopt:{opt model(cascade)}}independent cascade; needs {opt prob(#)}{p_end}
{synopt:{opt model(threshold)}}adopt when at least {opt threshold(#)} neighbours have adopted (or at least the value of {opt thresholdvar()}){p_end}
{synopt:{opt model(fraction)}}adopt when the share of adopting neighbours is at least {opt threshold(#)}, a number in (0,1] (or {opt thresholdvar()}){p_end}
{synopt:{opt prob(#)}}probability that an adopter passes the behaviour on along one tie, per step{p_end}
{synopt:{opt thr:eshold(#)}}threshold of all nodes{p_end}
{synopt:{opth thresholdv:ar(varname)}}threshold of each node{p_end}
{synopt:{opt ns:eeds(#)}}number of initial adopters, drawn at random{p_end}
{synopt:{opth seedv:ar(varname)}}0/1 variable that marks the initial adopters{p_end}
{synopt:{opt sp:ont(#)}}probability that a node adopts spontaneously in a step, independent of the network; default 0{p_end}
{synopt:{opt steps(#)}}number of steps; default 20{p_end}
{synopt:{opt seed(#)}}random-number seed{p_end}
{synopt:{opt valued}, {opt incoming}, {opt self}, {opt replace}}as above{p_end}
{synoptline}

{title:Description}

{pstd}
{cmd:nwdiffuse} prepares and simulates the diffusion of a behaviour, an innovation or an infection through
a network. It follows the definitions of the R package netdiffuseR (Vega Yon and Valente), see below.
Observation {it:i} of the data set must hold node {it:i}, as everywhere in nwcommands. Periods are whole numbers.
The network may be the same in all periods (give one network) or change (give one network for each period,
in the order of the periods). Directed and undirected, binary and valued networks are allowed; two-mode networks are not.
Self-loops are ignored unless {opt self} is given.

{pstd}
{cmd:nwdiffuse exposure} creates, for each period {it:t} from {opt t0()} to {opt t1()}, the variable {it:stub}{it:t}
(for example {cmd:expo1990}): with {opt generate()} the {it:share} of a node's neighbours that have adopted by
period {it:t}; with {opt count()} their {it:number} (with {opt valued} the sum of the tie values to them).
A node without neighbours has exposure 0. The node's own adoption does not count unless {opt self} is given. With
{opt lag(#)}, period {it:t} holds the exposure of period {it:t}-{it:#} (network and adopters of that period); the first
{it:#} periods are missing.

{pstd}
{cmd:nwdiffuse threshold} creates, for each adopter, its threshold: its exposure in the period it adopts
(with {opt generate()} the share of adopting neighbours, with {opt count()} their number). The
exposure of the adoption period includes neighbours that adopt in that same period; use {opt lag(1)} to
count only neighbours that adopted earlier. Non-adopters, and adopters whose period lies before the
first period that the lag allows, are missing.

{pstd}
{cmd:nwdiffuse curve} shows the adoption curve (cumulative number and proportion of adopters, growth rate and
number of new adopters in each period); no network is needed. With {opt graph} it also draws the cumulative
proportion; other {cmd:twoway} options may be added. The matrix {cmd:r(curve)} has one row per period.

{pstd}
{cmd:nwdiffuse long} replaces the data in memory by a person-period (discrete-time event-history) data set
for hazard models: for each node one row for each period at risk, from {opt t0()}+{opt lag()} to the period of adoption
(or {opt t1()} if the node never adopts). Variables: {cmd:node}, {cmd:period}, {cmd:adopt} (1 in the period of adoption,
else 0), {cmd:exposure} (share of adopting neighbours, lagged by {opt lag()}, default 1) and {cmd:nexposed} (their number),
plus the numeric variables of {opt keep()}. Nodes that have adopted by the first period at risk have no rows. Fit
the hazard model with {help logit} or {help cloglog} on {cmd:adopt}; use {cmd:preserve} and {cmd:restore} to
keep your data. Exposure is lagged by default because exposure in the period of adoption already includes
that period's adopters.

{pstd}
{cmd:nwdiffuse simulate} runs a simple contagion in discrete steps and stores the period in which each node adopts
(missing if it never does). The initial adopters ({opt nseeds()} random nodes or the nodes marked by {opt seedvar()})
adopt in period 1. In each step all decisions are taken at the same time from the state of the previous
period. A step uses the network given for it (the single network, or the {it:s}th of the networks for step {it:s}).

{phang2}{cmd:cascade}: independent cascade. A node that adopted in the previous period passes the behaviour on to each of its
(not yet adopted) neighbours with probability {opt prob()}, once; it never tries again. A node influenced by {it:c} such
neighbours adopts with probability 1-(1-{opt prob()}){sup:{it:c}}. Tie values are ignored.{p_end}
{phang2}{cmd:threshold}: a node adopts when the number of its adopting neighbours (the sum of tie values with {opt valued}) reaches its threshold.{p_end}
{phang2}{cmd:fraction}: a node adopts when the share of its adopting neighbours reaches its threshold. A node without neighbours never adopts this way.{p_end}

{pstd}
With {opt spont()}, every node that has not adopted also adopts with that probability in each step, apart from the
network. The simulation stops early when nobody can adopt any more (no new adopters and {opt spont()} = 0 on a
single network). The default direction is that a node is influenced by the nodes it has ties to, as in
{cmd:exposure}; {opt incoming} reverses it.

{title:Graph of the curve}

{pstd}
{opt plot(cumulative)}, {opt plot(new)} and {opt plot(both)} choose the picture: {opt cumulative} (the default of {opt graph} and plain {opt plot}) is the cumulative proportion of adopters as a line,
{opt new} is a bar chart of the new adopters in each period (whole numbers on the y axis) and {opt both} draws the two side by side in one graph (the options then go to {helpb graph combine}).

{pstd}
{cmd:nwdiffuse curve} {opt graph} (or its synonym {opt plot}) draws the cumulative proportion of adopters. {opt name()} names the graph in memory (it stays unnamed when {opt name()}, {opt saving()} and
{opt export()} are all absent), {opt saving()} writes a {cmd:.gph} file and {opt export()} writes the graph with {helpb graph export}; the file extension sets the format and {cmd:width()} and the other
{cmd:graph export} options follow a comma. A graph or file of the same name is replaced. Other options go to {helpb twoway} and come last. {opt saving()} and {opt export()} need {opt graph} or {opt plot}.

{phang2}{cmd:. nwdiffuse curve, toa(toa) plot export(curve.png, width(1200))}{p_end}

{title:Remarks}

{pstd}
{bf:Agreement with netdiffuseR.} Exposure (share and count, binary and valued, outgoing and incoming, with and without
self, static and changing networks, with lags) and thresholds equal the results of {cmd:exposure()} and {cmd:threshold()} of
netdiffuseR 1.25.1 to 9 digits on the test networks. Deviations: netdiffuseR takes the adoption times from a {cmd:diffnet}
object and can weight exposure by node attributes, use structural-equivalence weights or group-wise exposure; {cmd:nwdiffuse} does not.
With a lag, netdiffuseR (and so {cmd:nwdiffuse}) uses the network of the lagged period as well.
The simulations are not a port of {cmd:rdiffnet()}; they implement the textbook models stated above.

{pstd}
{bf:Limits.} The network is held as a dense matrix, so the commands are meant for networks up to a few thousand nodes
(3,000 nodes with 40 simulated steps take about a second; memory grows with the square of the number of nodes, and with
one matrix for each period when the network changes). Exposure variables use one variable for each period. The time of adoption must be known
exactly (no interval censoring); adoption cannot be undone (no recovery or forgetting); a node must not adopt before {opt t0()}.

{title:Stored results}

{pstd}
All subcommands store the scalars {cmd:r(n)} (nodes) where applicable. {cmd:exposure}: {cmd:r(t0)}, {cmd:r(t1)}, {cmd:r(periods)},
{cmd:r(lag)}. {cmd:threshold}: {cmd:r(N)} (adopters with a threshold), {cmd:r(mean)}, {cmd:r(lag)}. {cmd:curve}: {cmd:r(t0)}, {cmd:r(t1)}, {cmd:r(adopters)},
matrix {cmd:r(curve)} (columns period, adopters, proportion, rate, new). {cmd:long}: {cmd:r(rows)}, {cmd:r(events)}, {cmd:r(lag)}.
{cmd:simulate}: {cmd:r(adopters)}, {cmd:r(share)}, {cmd:r(lastperiod)}, {cmd:r(model)}.

{title:Examples}

{pstd}Exposure and thresholds from adoption times{p_end}
{phang2}{cmd:. nwclear}{p_end}
{phang2}{cmd:. nwwebuse glasgow, nwclear}{p_end}
{phang2}{cmd:. generate toa = cond(smoke1 > 1, 1, cond(smoke2 > 1, 2, cond(smoke3 > 1, 3, .)))}{p_end}
{phang2}{cmd:. nwdiffuse exposure glasgow1, toa(toa) generate(expo) count(nexp) lag(1)}{p_end}
{phang2}{cmd:. nwdiffuse threshold glasgow1, toa(toa) generate(thresh) lag(1)}{p_end}
{phang2}{cmd:. nwdiffuse curve, toa(toa) graph}{p_end}
{phang2}{cmd:. nwdiffuse curve, toa(toa) plot(both) export(curve.png, width(1000))}{p_end}

{pstd}Hazard model of adoption with lagged exposure{p_end}
{phang2}{cmd:. preserve}{p_end}
{phang2}{cmd:. nwdiffuse long glasgow1, toa(toa) clear}{p_end}
{phang2}{cmd:. logit adopt exposure i.period}{p_end}
{phang2}{cmd:. restore}{p_end}

{pstd}Simulate an independent cascade and a threshold model on a random network{p_end}
{phang2}{cmd:. nwrandom 200, prob(0.03) name(rnd) directed}{p_end}
{phang2}{cmd:. nwdiffuse simulate rnd, model(cascade) prob(0.2) nseeds(5) seed(1) generate(t_ic) steps(30)}{p_end}
{phang2}{cmd:. nwdiffuse simulate rnd, model(fraction) threshold(0.3) nseeds(20) seed(1) generate(t_fr) steps(30)}{p_end}
{phang2}{cmd:. nwdiffuse curve rnd, toa(t_ic) graph}{p_end}

{title:References}

{phang}
Valente, T. W. 1995. {it:Network Models of the Diffusion of Innovations}. Cresskill, NJ: Hampton Press.

{phang}
Vega Yon, G. G., and T. W. Valente. 2021. netdiffuseR: Analysis of diffusion and contagion processes on networks.
R package. {browse "https://CRAN.R-project.org/package=netdiffuseR"}

{phang}
Granovetter, M. 1978. Threshold models of collective behavior. {it:American Journal of Sociology} 83: 1420-1443.

{phang}
Kempe, D., J. Kleinberg, and E. Tardos. 2003. Maximizing the spread of influence through a social network.
{it:Proceedings of the 9th ACM SIGKDD}: 137-146.

{title:Also see}

{psee}
{help nwspmatrix}, {help nwrandom}, {help nwnode}, {help nwturnover}
{p_end}

{hline}
{pstd}{it:nwcommands version 3.30.0, 20 November 2026} ({help nwversion:check your installed version}){p_end}{* nwversion}
