{smcl}
{* *! version 1.0.0  23oct2026}{...}
{title:Title}

{p2colset 9 33 34 2}{...}
{p2col :nwergm structural() {hline 2}}Structural terms of R's ergm package in {helpb nwergm}{p_end}
{p2colreset}{...}

{title:Syntax}

{p 8 17 2}
{cmd:nwergm} [{it:{help netname}}]{cmd:,} {opt edges} {opt structural(}{it:termlist}{opt )} [{it:other options}]

{p 8 17 2}
{cmd:nwergm simulate} {it:#nodes}{cmd:,} {opt edges} {opt structural(}{it:termlist}{opt )} {opt theta()} [{it:other options}]

{pstd}
{it:termlist} is a list of terms written like R's ergm terms, separated by blanks: {it:term} or {it:term}{cmd:(}{it:arguments}{cmd:)}.
Arguments have R's names and defaults ({it:name}{cmd:=}{it:value}); values are numbers, variable names, network names, or lists of numbers separated by blanks
(R's {cmd:c(1,2,3)} is written {cmd:d=1 2 3}), and R's logical arguments are written as bare words ({cmd:diff}, {cmd:fixed}, {cmd:semi}, {cmd:homophily}) or {it:name}{cmd:=TRUE}.
The first argument may be given without its name, as in R. Example:

{phang2}{cmd:. nwergm mynet, edges structural(twopath triangle(attr=sex diff) cycle(k=3 4) altkstar(lambda=0.8 fixed))}{p_end}

{pstd}
A node attribute is a numeric variable in the current data set (one row per node, in the node order of the network). The coefficients are named after R's coefficient names with
{cmd:_} instead of {cmd:.}, e.g. {cmd:triangle_sex_1}, {cmd:cycle3}, {cmd:odeg1_sex_2}, {cmd:threetrail_RRR}.
Terms that depend on more than a dyad's own covariates make the model dyad-dependent, so {cmd:method(mcmle)} is the default for them; all of these terms use the native plugin.
{cmd:density} and {cmd:meandeg} are collinear with {opt edges}; {opt edges} may be left out when one of them is used instead.

{title:Terms}

{pstd}
Undirected networks only: {cmd:isolatededges}, {cmd:degree1.5}, {cmd:degcrossprod}, {cmd:degcor}, {cmd:concurrentties}[{cmd:(by=}{it:attr}{cmd:)}], {cmd:concurrent}[{cmd:(by=}{it:attr}{cmd:)}],
{cmd:altkstar(lambda=}{it:#}{cmd: fixed)}, {cmd:tripercent}[{cmd:(attr=}{it:attr}[{cmd: diff}]{cmd:)}], {cmd:opentriad}, {cmd:degree(d=}{it:numlist}[{cmd: by=}{it:attr}][{cmd: homophily}]{cmd:)},
{cmd:degrange(from=}{it:numlist}[{cmd: to=}{it:numlist}][{cmd: by=}{it:attr}][{cmd: homophily}]{cmd:)}, {cmd:kstar(k=}{it:numlist}[{cmd: attr=}{it:attr}]{cmd:)}.

{pstd}
Directed networks only: {cmd:m2star}, {cmd:odegree1.5}, {cmd:idegree1.5}, {cmd:asymmetric}[{cmd:(attr=}{it:attr}[{cmd: diff}]{cmd:)}], {cmd:mutual}[{cmd:(same=}{it:attr}[{cmd: diff}]{cmd:)}], {cmd:mutual(by=}{it:attr}{cmd:)},
{cmd:transitive}, {cmd:intransitive}, {cmd:ttriple}[{cmd:(attr=}{it:attr}[{cmd: diff}]{cmd:)}], {cmd:ctriple}[{cmd:(attr=}{it:attr}[{cmd: diff}]{cmd:)}], {cmd:nearsimmelian}, {cmd:simmelian}, {cmd:simmelianties},
{cmd:odegree(d=}{it:numlist}[{cmd: by=}{it:attr}][{cmd: homophily}]{cmd:)}, {cmd:idegree(...)}, {cmd:odegrange(...)}, {cmd:idegrange(...)}, {cmd:ostar(k=}{it:numlist}[{cmd: attr=}{it:attr}]{cmd:)}, {cmd:istar(...)}.

{pstd}
Both kinds of network: {cmd:density}, {cmd:meandeg}, {cmd:twopath}, {cmd:isolates}, {cmd:cycle(k=}{it:numlist}[{cmd: semi}]{cmd:)} (semicycles for directed networks), {cmd:triangle}[{cmd:(attr=}{it:attr}[{cmd: diff}]{cmd:)}],
{cmd:threetrail}[{cmd:(keep=}{it:numlist}{cmd:)}] (four types RRR RRL LRR LRL for directed networks), {cmd:triadcensus}[{cmd:(levels=}{it:numlist or labels}{cmd:)}],
{cmd:localtriangle(x=}{it:netname}{cmd:)} (a binary network with the same nodes), {cmd:nsp(d=}{it:numlist}[{cmd: type=}{it:OTP|ITP|OSP|ISP|RTP}]{cmd:)}.

{title:Remarks}

{pstd}
Statistics, maximum pseudolikelihood estimates and maximum likelihood estimates are checked against R's ergm 4.12.0.
Three points where the result is not simply R's: (1) {cmd:opentriad}: in ergm 4.12.0 the change statistic for removing a tie overflows an unsigned integer, so R's estimation with this term is wrong
(its observed statistic is right); {cmd:nwergm} computes the correct change statistic. (2) {cmd:degcor} and {cmd:degcrossprod} are scaled by quantities of the observed network, as in R,
and are therefore not available in {cmd:nwergm simulate}. (3) {cmd:altkstar} is available with a fixed {cmd:lambda} only (R's default is the curved form with estimated {cmd:lambda}).

{pstd}
{cmd:structural()} needs the native plugin that ships with the package; there is no slower fallback. The {cmd:levels=} argument of the attribute terms is not available (all levels of the attribute are used).

{title:Also see}

{psee}
{helpb nwergm}, {helpb nwergm_estat}
