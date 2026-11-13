{smcl}
{* *! version 1.0.0  12nov2026 author: Thomas Grund}{...}
{marker topic}
{helpb nwtopical##visualization:[NW-2.8] Visualization}

{title:Title}

{p2colset 9 22 24 2}{...}
{p2col :nwegoplot {hline 2}}Draw the ego network of one node, ego in the center{p_end}
{p2colreset}{...}

{title:Syntax}

{p 8 17 2}
{cmd:nwegoplot} [{it:{help netname}}]{cmd:,} {opt ego(node)} [{opt hop(1|2)} {opth sort:by(varname)}
{opt gen:erate(xvar yvar)} {opt replace} {opt edgec:olor(...)} {it:{help nwplot:nwplot_options}}]

{synoptset 24 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt ego(node)}}the focal node: its name (as in {bf:_nwnode}) or its number; required{p_end}
{synopt:{opt hop(1|2)}}{cmd:1} (default) draws ego and its alters; {cmd:2} adds the contacts of the alters on an outer circle{p_end}
{synopt:{opth sort:by(varname)}}place alters with the same value of {it:varname} next to each other{p_end}
{synopt:{opt gen:erate(xvar yvar)}}keep the coordinates in two new variables (missing outside the ego network){p_end}
{synopt:{opt replace}}overwrite the variables of {opt generate()}{p_end}
{synopt:{opt edgec:olor(...)}}color the ties by another network, as in {help nwplot}; replaces the default coloring of the ties{p_end}
{synopt:{opt size(...)}}node size, as in {help nwplot}; replaces the default, ego drawn twice as large as the alters{p_end}
{synopt:{opt aspect:ratio(#)}}as in {help nwplot}; by default the proportions of the coordinates, so that the circles stay round{p_end}
{synopt:{it:nwplot_options}}any other option of {help nwplot}, such as {opt label()}, {opt color()}, {opt symbol()}, {opt size()}, {opt scheme()}, {opt lineopt()}, {opt arrowfactor()}{p_end}
{synoptline}

{title:Description}

{pstd}
{cmd:nwegoplot} draws the ego network of one node: ego in the center, its alters (the nodes it sends ties to
or receives ties from) evenly on a circle around it, and all ties among these nodes. Ego's own ties (the
spokes) are drawn in light gray and the ties among the alters in dark gray, so that the density of the ego
network, the ties among the alters, is what stands out. Ego is drawn twice as large as the other nodes.

{pstd}
The alters are ordered around the circle so that ties among them stay short: alters who are connected
with each other (directly or through other alters) are placed together, the largest such group first and
alters without ties to other alters last, and inside each group the nodes follow the spectral order of the
group (the Fiedler vector of its Laplacian). With {opt sortby()} the alters are first grouped by the
variable, then ordered in the same way inside each value.

{pstd}
With {opt hop(2)} the nodes at distance two from ego are placed on an outer circle, each near the
direction of the alters it is tied to.

{pstd}
The plot is drawn by {help nwplot} with {opt nodexy()} and {cmd:if}, so all options of {cmd:nwplot}
apply; {cmd:nwegoplot} itself changes no network and no variable (except those of {opt generate()}).
{help nwego} computes the size and density of every ego network, {help nwaltergen} the composition.

{title:Stored results}

{pstd}
{cmd:nwegoplot} stores the following in {cmd:r()}:

{synoptset 15 tabbed}{...}
{p2col 5 15 19 2: Scalars}{p_end}
{synopt:{cmd:r(alters)}}number of nodes drawn besides ego{p_end}
{p2col 5 15 19 2: Macros}{p_end}
{synopt:{cmd:r(ego)}}name of ego{p_end}

{title:Examples}

{phang2}{cmd:. nwwebuse lazega, nwclear}{p_end}
{phang2}{cmd:. nwegoplot lazega_adv, ego(n41) label(_nwnode) color(officenum) symbol(partner)}{p_end}
{phang2}{cmd:. nwegoplot lazega_adv, ego(n41) sortby(officenum) color(officenum) arrowfactor(0)}{p_end}

{phang2}{cmd:. nwwebuse glasgow, nwclear}{p_end}
{phang2}{cmd:. nwegoplot glasgow1, ego(n2) hop(2)}{p_end}

{title:Also see}

{psee}
{help nwplot}, {help nwego}, {help nwaltergen}, {help nwcontext}
{p_end}

{hline}
{pstd}{it:nwcommands version 3.24.0, 13 November 2026} ({help nwversion:check your installed version}){p_end}{* nwversion}
