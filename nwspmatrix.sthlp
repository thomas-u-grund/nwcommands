{smcl}
{* *! version 1.0.0  19nov2026 author: Thomas Grund}{...}
{marker topic}
{helpb nwtopical##analysis_statmodels:[NW-2.6.7] Statistical tests}

{title:Title}

{p2colset 9 23 25 2}{...}
{p2col :nwspmatrix {hline 2}}Spatial weighting matrix from a network, for {cmd:spregress}{p_end}
{p2colreset}{...}

{title:Syntax}

{p 8 17 2}
{cmd:nwspmatrix} [{it:{help netname}}] [{cmd:,} {it:options}]

{synoptset 28 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt name(spmatname)}}name of the weighting matrix; default {cmd:W}{p_end}
{synopt:{opt weights(binary|valued)}}ties as 0/1 (default) or with their values{p_end}
{synopt:{opt dir:ection(out|in|symmetric|mutual)}}how to read directed ties; default {cmd:out}{p_end}
{synopt:{opt norm:alize(row|none|spectral|minmax)}}normalisation; default {cmd:row}{p_end}
{synopt:{opt idv:ar(varname)}}numeric variable that identifies the nodes in the data{p_end}
{synopt:{opt mat:rix(name)}}also store the matrix as an ordinary Stata matrix{p_end}
{synopt:{opt replace}}overwrite an existing weighting matrix{p_end}
{synopt:{opt silent}}do not show the summary{p_end}
{synoptline}

{title:Description}

{pstd}
{cmd:nwspmatrix} turns a network into a spatial weighting matrix of Stata's {help spmatrix:spmatrix}
system. The matrix can then be used in {help spregress}, {help spivregress} and the other commands of
the {help sp:spatial} suite. With a network as the weighting matrix, {cmd:spregress, ml dvarlag()} fits
the linear network autocorrelation (network effects) model

{p 8 8 2}
{it:y} = {it:rho} {it:W} {it:y} + {it:X} {it:b} + {it:e}

{pstd}
which is the model {cmd:lnam} of the R package sna fits when the disturbance is white noise.
Row-normalised, {it:W}{it:y} is the average of {it:y} over the neighbours of each node, so {it:rho} is
the strength of influence of the neighbours' average.

{pstd}
Observation {it:i} of the data set in memory must hold node {it:i} of the network, as everywhere in
nwcommands. Observations beyond the number of nodes should be missing on the variables of the model (they are then left out of the regression). The nodes are identified for Stata by an
{help spset:spatial-unit ID}: the one the data set already has, the variable named in
{opt idvar()}, or, if the data set is not {cmd:spset}, a new variable {cmd:_nwid} (the node number) that
{cmd:nwspmatrix} creates and {cmd:spset}s.

{title:Options}

{phang}
{opt name(spmatname)} names the weighting matrix; the default is {cmd:W}. An existing matrix of that name
is only overwritten with {opt replace}.

{phang}
{opt weights(binary|valued)}: {cmd:binary} (default) uses 1 for every tie; {cmd:valued} uses the tie values.
Values must not be negative. Self-loops are removed.

{phang}
{opt direction()} applies to directed networks only (an undirected network is symmetric already).
{cmd:out} (default): {it:W}{sub:ij} refers to the tie from {it:i} to {it:j}, so node {it:i} is influenced by the
nodes it names. {cmd:in}: the transpose, so node {it:i} is influenced by the nodes that name it.
{cmd:symmetric}: a tie in either direction counts (the larger of the two values with valued weights).
{cmd:mutual}: only reciprocated ties count (the smaller of the two values).

{phang}
{opt normalize()}: {cmd:row} (default) divides each row by its sum, so that rows sum to 1;
{cmd:none} leaves the matrix as it is; {cmd:spectral} and {cmd:minmax} are done by Stata as described in
{help spmatrix_normalize:spmatrix normalize}. Note that Stata's own default is {cmd:spectral}, not {cmd:row}.

{phang}
{opt idvar(varname)} sets the spatial-unit ID variable of the data to this numeric variable (it must
identify the observations uniquely; see {help spset}). Row {it:i} of the matrix is then labelled by the value of this variable in observation {it:i}.

{phang}
{opt matrix(name)} also stores the matrix as a Stata matrix (for {cmd:matrix list}, or for exporting
it). Stata limits the size of matrices ({help limits:matsize}); if the network is too large for it,
the weighting matrix {it:spmatname} is still created and a message says so.

{title:Remarks}

{pstd}
{bf:Isolates.} A node without a tie (after the direction rule has been applied) gets a row of zeros: it
is influenced by nobody, so {it:W}{it:y} is 0 for it. Stata reports them as "islands". Row
normalisation leaves such a row at zero rather than dividing by zero. The estimator still uses these nodes
(their outcome enters the likelihood), which is the same as {cmd:lnam}.

{pstd}
{bf:Which direction.} With {cmd:direction(out)} on a nomination network ("whom do you name as a friend?")
a node is influenced by those it names. Use {cmd:in} if you want influence to run from the nominators to the
nominated, and {cmd:symmetric} or {cmd:mutual} if you want to treat the network as undirected.
The estimator accepts a non-symmetric matrix; with {cmd:ml} the autoregressive coefficient is
restricted to the range allowed by the eigenvalues of the matrix.

{pstd}
{bf:Comparison with R.} On the Glasgow example below, {cmd:spregress, ml} and {cmd:lnam}
(sna 2.8; same row-normalised matrix) agree in the coefficients, the standard errors and the log likelihood
to about 5 digits. Both maximise the same Gaussian likelihood of the autoregressive model. They differ in
what is offered and in details: {cmd:lnam} can also fit a network-lagged disturbance and does not restrict the
autoregressive coefficient to the range given by the eigenvalues of the weighting matrix, and its
standard errors come from a numerical Hessian; {cmd:spregress} adds the generalized spatial
two-stage least-squares estimator ({cmd:gs2sls}), lagged covariates ({cmd:ivarlag()}), an error lag and
several weighting matrices. This agreement is shown for one example;
other data, other weighting matrices or a very large autoregressive coefficient can show larger
differences.

{pstd}
{bf:Not covered.} {cmd:nwspmatrix} builds the weighting matrix from one network. Two-mode networks are
refused (make a one-mode network first, see {help nwproject}). {cmd:spregress} fits continuous outcomes only; for a binary outcome
that depends on the neighbours see the separate package nwalaam.
{cmd:estat moran, errorlag()} works after {cmd:regress} with a matrix from {cmd:nwspmatrix}.

{title:Stored results}

{pstd}
{cmd:nwspmatrix} stores the following in {cmd:r()}:

{synoptset 15 tabbed}{...}
{p2col 5 15 19 2: Scalars}{p_end}
{synopt:{cmd:r(nodes)}}number of nodes{p_end}
{synopt:{cmd:r(ties)}}number of nonzero cells of the matrix{p_end}
{synopt:{cmd:r(isolates)}}number of nodes with a row of zeros{p_end}
{p2col 5 15 19 2: Macros}{p_end}
{synopt:{cmd:r(name)}}name of the spatial weighting matrix{p_end}
{synopt:{cmd:r(network)}}network name{p_end}
{synopt:{cmd:r(weights)}, {cmd:r(direction)}, {cmd:r(normalize)}}options as used{p_end}

{title:Examples}

{pstd}Friends among 50 pupils in Glasgow: does a pupil's alcohol consumption follow that of the friends?{p_end}
{phang2}{cmd:. nwclear}{p_end}
{phang2}{cmd:. nwwebuse glasgow, nwclear}{p_end}
{phang2}{cmd:. nwspmatrix glasgow2, name(W)}{p_end}
{phang2}{cmd:. spregress alcohol2 smoke2 sport2, ml dvarlag(W)}{p_end}

{pstd}Treat the friendships as mutual only, without row normalisation, and compare{p_end}
{phang2}{cmd:. nwspmatrix glasgow2, name(Wm) direction(mutual) normalize(none)}{p_end}
{phang2}{cmd:. spregress alcohol2 smoke2 sport2, ml dvarlag(Wm)}{p_end}

{pstd}Influence also through the covariates of the friends (spatially lagged covariates){p_end}
{phang2}{cmd:. spregress alcohol2 smoke2 sport2, ml dvarlag(W) ivarlag(W: smoke2)}{p_end}

{title:References}

{phang}
Butts, C. T. 2008. Social network analysis with sna. {it:Journal of Statistical Software} 24(6): 1-51.

{phang}
Doreian, P. 1989. Network autocorrelation models: problems and prospects. In {it:Spatial Statistics: Past, Present, and Future}, ed. D. A. Griffith, 369-389. Ann Arbor: Institute of Mathematical Geography.

{phang}
Leenders, R. T. A. J. 2002. Modeling social influence through network autocorrelation: constructing the weight matrix. {it:Social Networks} 24: 21-47.

{title:Also see}

{psee}
{help nwqap}, {help nwcorrelate}, {help nwtomata}, {help spregress}, {help spmatrix}
{p_end}

{hline}
{pstd}{it:nwcommands version 3.32.0, 20 November 2026} ({help nwversion:check your installed version}){p_end}{* nwversion}
