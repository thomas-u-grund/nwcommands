{smcl}
{* *! version 1.0.0  3sept2014}{...}
{marker topic}
{helpb nwtopical##analysis_statmodels:[NW-2.6.6] Statistical Estimation of Networks}

{title:Title}

{p2colset 9 18 22 2}{...}
{p2col :nwutility  {hline 2}}Calculate utility scores according to Jackson and Wollinsky (1996){p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 17 2}
{cmdab: nwutility}
[{help netname}]
{cmd:,}
[{opth benefit(real)}
{opth cost(real)}
{opt intrvalue(netname)}
{opt intrcost(netname)}
{it:{help nwgeodesic:geodesic_options}}]


{synoptset 30 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opth benefit(real)}}benefit from connected node; default = 1{p_end}
{synopt:{opth cost(real)}}cost of connection; default = 1{p_end}
{synopt:{opt intrvalue(netname)}}intrinsic value w_ij a node i gives to a connection with node j; default = 1 for every tied pair{p_end}
{synopt:{opt intrcost(netname)}}per-dyad cost y_ij, replacing the constant {it:cost} for direct connections; default = {it:cost} for every tied pair{p_end}


{title:Description}

{pstd}
{cmd:nwutility} calculates node-level utility scores according to the connections model in Jackson and Wollinsky (1996). The command generates the variables _benefit, _cost and _util.
In this model of strategic network formation, each node i is assigned a utility score, which is calculated as:

{pmore}
		U(i) = w_ii + sum_j[benefit^(d_ij) * w_ij] - sum_j_in_N(i)[cost * y_ij]

{pstd}
{it:benefit} essentially defines the decay of benefit from non-direct (but connected) network neighbors. When benefit = 1, a node i gains
as much benefit from a directly connected node as from an indirectly connected node.

{pstd}
{it:cost} defines the cost of node i for maintaining a network link (hence, only direct connections are considered).

{pstd}
The command can also be used in more complicated ways using the intrinsic value w_ij a node i gives to a connection with node j, via {opt intrvalue()}, and/or a per-dyad cost y_ij (in place of the constant {it:cost}), via {opt intrcost()}. Both must be networks of the same size as the network being analyzed. For example, one could
imagine that nodes only get benefit from nodes who have the same attribute. To do that one would first
generate a new network that holds information on whether two nodes have the same value on an attribute (see {help nwexpand}).

	{cmd:. nwclear}
	{cmd:. nwrandom 20, prob(.2)}
	{cmd:. gen attr = round(uniform())}
	{cmd:. nwexpand attr, mode(same) name(same)}

{pstd}
Then one can use {opt intrvalue()} in {cmd:nwutility}:

	{cmd:. nwutility network, benefit(.5) cost(.3) intrvalue(same)}

{pstd}
{bf:Important}: the w_ii term (a node's intrinsic self-value) is read from {opt intrvalue()}'s own network diagonal. {help nwset} treats the diagonal as "no self-tie" (missing) by default for any network, {opt intrvalue()} included - a network built without the {opt selfloop} option will have a missing diagonal, and {cmd:nwutility} will report {it:_benefit}/{it:_util} as missing rather than silently substituting a wrong number. To supply real w_ii values, build the {opt intrvalue()} network with {help nwset}'s own {opt selfloop} option so the diagonal is preserved.


{title:Supported network types}

{pstd}
Binary: yes. Directed: not checked (the connections model as implemented here assumes an undirected notion of reachability via {help nwgeodesic}). Weighted: {bf:W1}, native - the network under analysis only needs to be binary for the underlying geodesic-distance calculation, but {opt intrvalue()}/{opt intrcost()} let tie strength (as a full per-dyad value, not the analyzed network's own weight) enter the utility formula directly, not as a distance. Signed: not checked. Two-mode: not checked.


{title:Bibliography}

{pstd}
Jackson, M. and Wollinsky, A. (1996) A Strategic Model of Social and Economic Networks. {it:Journal of Economic Theory}, 71, pp. 44-74.


{title:Remarks}

{pstd}
When not specified otherwise, benefit = 1, cost = 1, w_ij = 1 (for i != j), y_ij = {it:cost}, and w_ii = 0 (i.e. {opt intrvalue()} is not given).


